import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

import 'package:banalyze/features/classifications/repositories/classification_repository.dart';

/// Provider for realtime camera-based banana ripeness classification.
///
/// Uses [CameraController.startImageStream] so the preview never stutters.
/// Inference is throttled to ~1 fps via [_inferenceIntervalMs].
/// All dispose races are guarded with [_isInitializing] + [_disposed] flags.
class RealtimeClassificationProvider extends ChangeNotifier {
  final ClassificationRepository _repository;

  CameraController? _controller;
  ClassificationResult? _currentResult;
  bool _isInitialized = false;
  bool _isProcessing = false;
  bool _disposed = false;

  /// True while [CameraController.initialize] is awaiting.
  /// [dispose] must NOT call [CameraController.dispose] during this window —
  /// instead it sets [_disposed] and lets [init] clean up in its finally block.
  bool _isInitializing = false;

  String? _error;
  int _lastInferenceMs = 0;

  /// Minimum confidence (0–100) to display a meaningful class label.
  static const int threshold = 70;

  /// Minimum gap between consecutive inferences (ms).
  static const int _inferenceIntervalMs = 900;

  RealtimeClassificationProvider(this._repository);

  // ── Public Getters ──────────────────────────────────────────────────────────

  CameraController? get controller => _controller;
  bool get isInitialized => _isInitialized;
  String? get error => _error;

  int get confidencePercent =>
      _currentResult == null ? 0 : (_currentResult!.confidence * 100).round();

  bool get isBelowThreshold =>
      _currentResult == null || confidencePercent < threshold;

  String get detectedClass {
    if (_currentResult == null) return '—';
    if (isBelowThreshold) return 'Undefined';
    switch (_currentResult!.label) {
      case 'matang':
        return 'Ripe';
      case 'setengah_matang':
        return 'Partially Ripe';
      case 'terlalu_matang':
        return 'Overripe';
      default:
        return _currentResult!.label;
    }
  }

  // ── Initialisation ──────────────────────────────────────────────────────────

  /// Initialises back camera + TFLite model. Safe to call multiple times.
  Future<void> init() async {
    // Prevent re-entrant calls; also skip if already disposed.
    if (_disposed || _isInitializing) return;
    _isInitializing = true;
    _error = null;

    // Stop any running stream before recreating the controller.
    try {
      if (_controller?.value.isStreamingImages == true) {
        await _controller!.stopImageStream();
      }
    } catch (_) {}

    try {
      if (!_repository.isReady) await _repository.init();

      final cameras = await availableCameras();
      if (_disposed) return;

      if (cameras.isEmpty) {
        _error = 'No camera available on this device.';
        _safeNotify();
        return;
      }

      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      // Swap controller: null the public reference FIRST so any concurrent
      // guard check sees null immediately, then dispose the old one.
      final oldCtrl = _controller;
      _controller = null;
      _isInitialized = false;
      try {
        await oldCtrl?.dispose();
      } catch (_) {}

      if (_disposed) return;

      // Use low resolution — plenty for 224×224 inference, much faster stream.
      final newCtrl = CameraController(
        back,
        ResolutionPreset.low,
        enableAudio: false,
        // No imageFormatGroup — let the plugin use the platform default
        // (yuv420 on Android, bgra8888 on iOS). _convertCameraImage handles both.
      );
      _controller = newCtrl;

      await newCtrl.initialize();
      // ↑ If _disposed was called while initialize() was awaiting, we must NOT
      //   call notifyListeners on the disposed ChangeNotifier, and we must
      //   properly clean up the freshly initialised controller.
      if (_disposed) {
        _controller = null;
        try {
          await newCtrl.dispose();
        } catch (_) {}
        return;
      }

      _isInitialized = true;
      _safeNotify();
      _startImageStream();
    } on CameraException catch (e) {
      if (!_disposed) {
        _error = e.description ?? e.code;
        debugPrint('Camera init error: ${e.code} – ${e.description}');
        _safeNotify();
      }
    } catch (e) {
      if (!_disposed) {
        _error = e.toString();
        debugPrint('RealtimeClassification init error: $e');
        _safeNotify();
      }
    } finally {
      _isInitializing = false;
      // If dispose() was called while we were initialising, finish cleanup now.
      if (_disposed) {
        final ctrl = _controller;
        _controller = null;
        try {
          await ctrl?.dispose();
        } catch (_) {}
      }
    }
  }

  // ── Image Stream ───────────────────────────────────────────────────────────

  void _startImageStream() {
    if (_disposed || _controller == null) return;
    try {
      _controller!.startImageStream(_onFrameAvailable);
    } catch (e) {
      debugPrint('startImageStream error: $e');
    }
  }

  void _onFrameAvailable(CameraImage frame) {
    if (_disposed || _isProcessing) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastInferenceMs < _inferenceIntervalMs) return;
    _lastInferenceMs = now;

    _isProcessing = true;
    // Run synchronously on the raster/UI thread — inference is fast (<50 ms).
    try {
      final converted = _convertCameraImage(frame);
      if (converted == null || _disposed) return;
      _currentResult = _repository.classifyImage(converted);
      _safeNotify();
    } catch (e) {
      debugPrint('Realtime inference error: $e');
    } finally {
      _isProcessing = false;
    }
  }

  // ── Image Conversion ───────────────────────────────────────────────────────

  /// Converts a [CameraImage] from the stream into an [img.Image] suitable
  /// for the TFLite pipeline.
  ///
  /// - **Android** (yuv_420_888): downsamples directly to 256×256 during
  ///   YUV→RGB conversion — ~65 K iterations instead of the full 1 M+.
  /// - **iOS** (bgra8888): single memory-copy via [img.Image.fromBytes].
  img.Image? _convertCameraImage(CameraImage frame) {
    try {
      if (frame.format.group == ImageFormatGroup.bgra8888) {
        // iOS fast path
        return img.Image.fromBytes(
          width: frame.width,
          height: frame.height,
          bytes: frame.planes[0].bytes.buffer,
          order: img.ChannelOrder.bgra,
        );
      }

      if (frame.format.group == ImageFormatGroup.yuv420) {
        // Android: downsample to 256×256 during YUV→RGB conversion.
        const tW = 256;
        const tH = 256;
        final srcW = frame.width;
        final srcH = frame.height;
        final result = img.Image(width: tW, height: tH);

        final yBuf = frame.planes[0].bytes;
        final uBuf = frame.planes[1].bytes;
        final vBuf = frame.planes[2].bytes;
        final yStride = frame.planes[0].bytesPerRow;
        final uvStride = frame.planes[1].bytesPerRow;
        final uvPixStride = frame.planes[1].bytesPerPixel ?? 1;

        final xScale = srcW / tW;
        final yScale = srcH / tH;

        for (int ty = 0; ty < tH; ty++) {
          final sy = (ty * yScale).toInt().clamp(0, srcH - 1);
          for (int tx = 0; tx < tW; tx++) {
            final sx = (tx * xScale).toInt().clamp(0, srcW - 1);

            final yp = yBuf[sy * yStride + sx];
            final uvIdx = (sy >> 1) * uvStride + (sx >> 1) * uvPixStride;
            final up = uBuf[uvIdx] - 128;
            final vp = vBuf[uvIdx] - 128;

            result.setPixelRgb(
              tx,
              ty,
              (yp + 1.402 * vp).clamp(0, 255).toInt(),
              (yp - 0.344136 * up - 0.714136 * vp).clamp(0, 255).toInt(),
              (yp + 1.772 * up).clamp(0, 255).toInt(),
            );
          }
        }
        return result;
      }
    } catch (e) {
      debugPrint('CameraImage conversion error: $e');
    }
    return null;
  }

  // ── Public Actions ─────────────────────────────────────────────────────────

  /// Stops the stream, captures a still JPEG file for full analysis.
  /// Returns null on failure. Caller must call [resumeInference] when done.
  Future<File?> captureStill() async {
    if (_disposed || _controller == null || !_controller!.value.isInitialized) {
      return null;
    }

    // Stop stream to free the camera for takePicture.
    try {
      if (_controller!.value.isStreamingImages) {
        await _controller!.stopImageStream();
      }
    } catch (_) {}

    // Wait for any in-flight inference to finish.
    int waited = 0;
    while (_isProcessing && waited < 20) {
      await Future.delayed(const Duration(milliseconds: 50));
      waited++;
      if (_disposed) return null;
    }

    try {
      if (_disposed || _controller == null) return null;
      final xFile = await _controller!.takePicture();
      return File(xFile.path);
    } catch (e) {
      debugPrint('Capture still error: $e');
      if (!_disposed) _startImageStream();
      return null;
    }
  }

  /// Restarts the image stream after returning from the result page.
  void resumeInference() {
    if (!_disposed && _isInitialized) _startImageStream();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  // ── Dispose ────────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _disposed = true;
    _isInitialized = false;

    // If init() is mid-flight, its finally block will dispose the controller
    // once initialize() completes. Do NOT call dispose() here in that case —
    // calling CameraController.dispose() while initialize() is awaiting is
    // what causes the "used after disposed" crash.
    if (!_isInitializing) {
      final ctrl = _controller;
      _controller = null;
      try {
        ctrl?.dispose();
      } catch (_) {}
    } else {
      // Null the public reference immediately; finally block handles cleanup.
      _controller = null;
    }

    super.dispose();
  }
}
