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
  ClassificationResult? _stableResult;
  bool _isInitialized = false;
  bool _isProcessing = false;
  bool _disposed = false;

  /// True while [CameraController.initialize] is awaiting.
  /// [dispose] must NOT call [CameraController.dispose] during this window —
  /// instead it sets [_disposed] and lets [init] clean up in its finally block.
  bool _isInitializing = false;

  String? _error;
  int _lastInferenceMs = 0;

  // ── Temporal Smoothing Buffer ───────────────────────────────────────────────
  /// Stores the last [_bufferSize] raw inference results.
  final List<ClassificationResult> _buffer = [];

  /// How many frames to keep in the sliding window.
  static const int _bufferSize = 5;

  /// Minimum frames in the buffer that must agree on the same label
  /// (AND each above [threshold]) before we show a confirmed class.
  static const int _minConsensus = 4;

  /// Minimum confidence (0–100) per individual frame to enter the buffer.
  static const int threshold = 75;

  /// Minimum gap between consecutive inferences (ms).
  static const int _inferenceIntervalMs = 900;

  RealtimeClassificationProvider(this._repository);

  // ── Public Getters ──────────────────────────────────────────────────────────

  CameraController? get controller => _controller;
  bool get isInitialized => _isInitialized;
  String? get error => _error;

  /// Confidence from the stable (buffered) result — 0 if not yet confirmed.
  int get confidencePercent =>
      _stableResult == null ? 0 : (_stableResult!.confidence * 100).round();

  /// True while the buffer hasn't reached consensus yet.
  bool get isBelowThreshold => _stableResult == null;

  /// True while the buffer is still warming up (< [_bufferSize] frames seen).
  bool get isBuffering => _buffer.length < _bufferSize;

  String get detectedClass {
    if (_stableResult == null) return isBuffering ? 'Scanning...' : '—';
    switch (_stableResult!.label) {
      case 'matang':
        return 'Ripe';
      case 'setengah_matang':
        return 'Partially Ripe';
      case 'terlalu_matang':
        return 'Overripe';
      default:
        return _stableResult!.label;
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

      // ── Temporal smoothing ──────────────────────────────────────────────
      _buffer.add(_currentResult!);
      if (_buffer.length > _bufferSize) _buffer.removeAt(0);

      if (_buffer.length >= _bufferSize) {
        // Count how many frames per label are above the per-frame threshold.
        final counts = <String, int>{};
        for (final r in _buffer) {
          if ((r.confidence * 100).round() >= threshold) {
            counts[r.label] = (counts[r.label] ?? 0) + 1;
          }
        }

        // Find the dominant label.
        String? topLabel;
        int topCount = 0;
        for (final e in counts.entries) {
          if (e.value > topCount) {
            topCount = e.value;
            topLabel = e.key;
          }
        }

        if (topLabel != null && topCount >= _minConsensus) {
          // Stable: average confidence of the agreeing frames.
          final agreeing = _buffer.where((r) => r.label == topLabel).toList();
          final avgConf =
              agreeing.map((r) => r.confidence).reduce((a, b) => a + b) /
              agreeing.length;
          _stableResult = ClassificationResult(
            label: topLabel,
            confidence: avgConf,
            allProbabilities: _buffer.last.allProbabilities,
          );
        } else {
          // No consensus — clear the stable result.
          _stableResult = null;
        }
      } else {
        // Buffer still warming up.
        _stableResult = null;
      }
      // ───────────────────────────────────────────────────────────────────

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
    if (!_disposed && _isInitialized) {
      // Clear buffer so old frames don't contaminate the new session.
      _buffer.clear();
      _stableResult = null;
      _startImageStream();
    }
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
