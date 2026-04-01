import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:banalyze/features/classifications/repositories/classification_repository.dart';
import 'package:banalyze/shared/models/scan_history.dart';

/// State for a classification attempt.
enum ClassificationStatus { idle, loading, success, error }

class ClassificationProvider extends ChangeNotifier {
  final ClassificationRepository _repository;

  ClassificationProvider(this._repository);

  ClassificationStatus _status = ClassificationStatus.idle;
  ClassificationResult? _result;
  String? _errorMessage;
  File? _selectedImage;
  bool _isSaving = false;
  String? _saveError;
  bool _savedSuccessfully = false;
  final ImagePicker _picker = ImagePicker();

  ClassificationStatus get status => _status;
  ClassificationResult? get result => _result;
  String? get errorMessage => _errorMessage;
  File? get selectedImage => _selectedImage;
  String? get imagePath => _selectedImage?.path;
  bool get isSaving => _isSaving;
  String? get saveError => _saveError;
  bool get savedSuccessfully => _savedSuccessfully;
  ClassificationRepository get repository => _repository;

  bool get isLoading => _status == ClassificationStatus.loading;

  /// Set the selected image for review.
  void setImage(File image) {
    _selectedImage = image;
    notifyListeners();
  }

  /// Pick a new image from the given source and update selectedImage.
  /// Returns true if an image was picked, false if cancelled.
  Future<bool> pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (picked != null) {
        _selectedImage = File(picked.path);
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Image pick error: $e');
    }
    return false;
  }

  /// Initialize the TFLite model. Should be called early (e.g., at app start).
  Future<void> initModel() async {
    try {
      await _repository.init();
    } catch (e) {
      debugPrint('Failed to init classification model: $e');
    }
  }

  /// Run classification on the currently selected image.
  Future<void> classify() async {
    if (_selectedImage == null) {
      _errorMessage = 'No image selected';
      _status = ClassificationStatus.error;
      notifyListeners();
      return;
    }

    _status = ClassificationStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      if (!_repository.isReady) {
        await _repository.init();
      }

      _result = await _repository.classify(_selectedImage!);
      _status = ClassificationStatus.success;
    } catch (e) {
      _errorMessage = e.toString();
      _status = ClassificationStatus.error;
      debugPrint('Classification error: $e');
    }

    notifyListeners();
  }

  /// Map model label to user-facing ripeness string.
  String get ripenessLabel {
    if (_result == null) return '';
    if (confidencePercent < 70) return 'Unrecognized';

    switch (_result!.label) {
      case 'matang':
        return 'Ripe';
      case 'setengah_matang':
        return 'Partially_Ripe';
      case 'terlalu_matang':
        return 'Overripe';
      default:
        return _result!.label;
    }
  }

  /// Map model label to [RipenessLevel] enum.
  RipenessLevel get _ripenessLevel {
    switch (_result?.label) {
      case 'matang':
        return RipenessLevel.ripe;
      case 'setengah_matang':
        return RipenessLevel.partiallyRipe;
      case 'terlalu_matang':
        return RipenessLevel.overripe;
      default:
        return RipenessLevel.unripe;
    }
  }

  /// Confidence as integer percentage (0–100).
  int get confidencePercent {
    if (_result == null) return 0;
    return (_result!.confidence * 100).round();
  }

  /// Human-readable description based on ripeness.
  String get ripenessDescription {
    if (confidencePercent < 70) {
      return 'The object in the image is either not a banana or the image quality is too low for a confident prediction. Please try scanning again with better lighting and a clearer view of the banana.';
    }

    switch (_result?.label) {
      case 'matang':
        return 'Perfect for immediate consumption or retail display. The sugar spots indicate peak sweetness. Best used within 24 hours.';
      case 'setengah_matang':
        return 'The banana is still developing its sugars. Best stored at room temperature for 1-2 days before consumption.';
      case 'terlalu_matang':
        return 'Ideal for baking, smoothies, or banana bread. The high sugar content adds natural sweetness to recipes.';
      default:
        return 'Object not recognized properly. Please try again.';
    }
  }

  /// Detected attributes based on ripeness.
  List<String> get detectedAttributes {
    if (confidencePercent < 70) {
      return ['Unrecognized', 'Low Quality', 'Try Again'];
    }

    switch (_result?.label) {
      case 'matang':
        return ['Sugar Spots', 'Soft Texture', 'Yellow > 80%', 'Sweet Aroma'];
      case 'setengah_matang':
        return ['Green Tips', 'Firm Texture', 'Yellow 50-80%', 'Mild Aroma'];
      case 'terlalu_matang':
        return ['Brown Spots', 'Very Soft', 'Dark Patches', 'Strong Aroma'];
      default:
        return [];
    }
  }

  /// Build the result data map for navigation to ClassificationResultPage.
  Map<String, dynamic> toResultData() {
    return {
      'imagePath': imagePath,
      'ripeness': ripenessLabel,
      'confidence': confidencePercent,
      'description': ripenessDescription,
      'attributes': detectedAttributes,
      'model': 'EfficientNetV2',
      'allProbabilities': _result?.allProbabilities ?? {},
    };
  }

  /// Reset state for a new scan.
  void reset() {
    _status = ClassificationStatus.idle;
    _result = null;
    _errorMessage = null;
    _selectedImage = null;
    _isSaving = false;
    _saveError = null;
    _savedSuccessfully = false;
    notifyListeners();
  }

  /// Save the current classification result to remote history.
  Future<bool> saveHistory() async {
    if (_selectedImage == null || _result == null) {
      _saveError = 'No classification result to save.';
      notifyListeners();
      return false;
    }

    _isSaving = true;
    _saveError = null;
    _savedSuccessfully = false;
    notifyListeners();

    try {
      final history = ScanHistory(
        id: '',
        title: ripenessLabel,
        ripeness: _ripenessLevel,
        confidence: _result!.confidence,
        dateTime: DateTime.now(),
        model: 'EfficientNetV2',
      );
      await _repository.saveHistory(
        imageFile: _selectedImage!,
        history: history,
      );
      _savedSuccessfully = true;
      return true;
    } catch (e) {
      _saveError = e.toString();
      debugPrint('Save history error: $e');
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }
}
