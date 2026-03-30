import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:banalyze/core/api_client.dart';
import 'package:banalyze/shared/models/scan_history.dart';

/// Result of a single classification inference.
class ClassificationResult {
  final String label;
  final double confidence;
  final Map<String, double> allProbabilities;

  const ClassificationResult({
    required this.label,
    required this.confidence,
    required this.allProbabilities,
  });
}

/// Repository that handles TFLite model loading, preprocessing, and inference.
/// Singleton — call [init] once at app start, then [classify] as needed.
class ClassificationRepository {
  static const String _modelPath =
      'assets/model_ai/EfficientNetV2B0_quantized.tflite';
  static const String _labelsPath = 'assets/model_ai/labels.txt';
  static const int _inputSize = 224;

  Interpreter? _interpreter;
  List<String> _labels = [];
  bool _isInitialized = false;

  bool get isReady => _isInitialized;

  /// Load model & labels into memory. Safe to call multiple times.
  Future<void> init() async {
    if (_isInitialized) return;

    // Load labels
    final labelsRaw = await rootBundle.loadString(_labelsPath);
    _labels = labelsRaw
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    // Load TFLite model
    _interpreter = await Interpreter.fromAsset(
      _modelPath,
      options: InterpreterOptions()..threads = 2,
    );

    _isInitialized = true;
  }

  /// Classify an image file.
  /// Returns a [ClassificationResult] with the top label and confidence.
  Future<ClassificationResult> classify(File imageFile) async {
    if (!_isInitialized || _interpreter == null) {
      throw StateError(
        'ClassificationRepository not initialized. Call init() first.',
      );
    }

    // Read & decode image
    final bytes = await imageFile.readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) {
      throw ArgumentError('Could not decode image file.');
    }

    // Preprocess: resize to 224x224
    final resized = img.copyResize(
      image,
      width: _inputSize,
      height: _inputSize,
      interpolation: img.Interpolation.linear,
    );

    // Build input tensor — shape [1, 224, 224, 3]
    // EfficientNet quantized expects uint8 input [0..255]
    final input = _imageToInputTensor(resized);

    // Prepare output tensor — shape [1, numLabels]
    final outputShape = _interpreter!.getOutputTensor(0).shape;
    final outputType = _interpreter!.getOutputTensor(0).type;

    // Run inference based on output type
    if (outputType == TensorType.uint8) {
      // Quantized output
      final output = List.generate(
        outputShape[0],
        (_) => List<int>.filled(outputShape[1], 0),
      );
      _interpreter!.run(input, output);

      // Convert to Uint8List for processing
      final uint8Output = Uint8List.fromList(output[0]);
      return _processQuantizedOutput(uint8Output);
    } else {
      // Float output
      final output = List.generate(
        outputShape[0],
        (_) => List<double>.filled(outputShape[1], 0.0),
      );
      _interpreter!.run(input, output);

      // Convert to Float32List for processing
      final floatOutput = Float32List.fromList(output[0]);
      return _processFloatOutput(floatOutput);
    }
  }

  /// Convert decoded image to uint8 input tensor [1, 224, 224, 3].
  List<List<List<List<int>>>> _imageToInputTensor(img.Image image) {
    return List.generate(1, (_) {
      return List.generate(_inputSize, (y) {
        return List.generate(_inputSize, (x) {
          final pixel = image.getPixel(x, y);
          return [pixel.r.toInt(), pixel.g.toInt(), pixel.b.toInt()];
        });
      });
    });
  }

  /// Process quantized uint8 output → probabilities via softmax-like scaling.
  ClassificationResult _processQuantizedOutput(Uint8List output) {
    // Dequantize: get zero point & scale from output tensor
    final outputTensor = _interpreter!.getOutputTensor(0);
    final params = outputTensor.params;
    final scale = params.scale;
    final zeroPoint = params.zeroPoint;

    // Dequantize to float
    final floats = Float32List(output.length);
    for (int i = 0; i < output.length; i++) {
      floats[i] = (output[i] - zeroPoint) * scale;
    }

    return _buildResult(floats);
  }

  /// Process float32 output directly.
  ClassificationResult _processFloatOutput(Float32List output) {
    return _buildResult(output);
  }

  /// Build result from raw logits/probabilities.
  ClassificationResult _buildResult(Float32List values) {
    // Model already outputs probabilities (softmax applied during training/export)
    // Map label → probability
    final allProbabilities = <String, double>{};
    int bestIdx = 0;
    double bestProb = 0;

    for (int i = 0; i < values.length && i < _labels.length; i++) {
      allProbabilities[_labels[i]] = values[i];
      if (values[i] > bestProb) {
        bestProb = values[i];
        bestIdx = i;
      }
    }

    debugPrint('--- Model Output Debug ---');
    debugPrint('Probabilities: ${values.toList()}');
    debugPrint('Mapped predictions: $allProbabilities');
    debugPrint(
      'Best match: ${_labels[bestIdx]} (${(bestProb * 100).toStringAsFixed(2)}%)',
    );
    debugPrint('--------------------------');

    return ClassificationResult(
      label: bestIdx < _labels.length ? _labels[bestIdx] : 'unknown',
      confidence: bestProb,
      allProbabilities: allProbabilities,
    );
  }

  /// Save a classification result to the remote history via POST /api/history-classify.
  /// Builds the payload from [ScanHistory.toMap] and attaches the image file.
  Future<void> saveHistory({
    required File imageFile,
    required ScanHistory history,
  }) async {
    final payload = history.toMap();
    final formData = FormData.fromMap({
      ...payload,
      'file': await MultipartFile.fromFile(
        imageFile.path,
        filename: imageFile.path.split(RegExp(r'[/\\]')).last,
      ),
    });

    await apiClient.post(
      '/history-classify',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
  }

  /// Release model resources.
  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _isInitialized = false;
  }
}
