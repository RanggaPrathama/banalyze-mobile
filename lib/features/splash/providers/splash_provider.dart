import 'package:flutter/foundation.dart';

class SplashProvider extends ChangeNotifier {
  int _currentStep = 1;
  String _loadingText = 'Preparing application...';
  final int totalSteps = 4;

  int get currentStep => _currentStep;
  String get loadingText => _loadingText;

  void updateProgress(double progress) {
    int step;
    String text;

    if (progress < 0.25) {
      step = 1;
      text = 'Preparing application...';
    } else if (progress < 0.55) {
      step = 2;
      text = 'Initializing neural networks...';
    } else if (progress < 0.8) {
      step = 3;
      text = 'Loading classification model...';
    } else {
      step = 4;
      text = 'Almost ready...';
    }

    if (_currentStep != step) {
      _currentStep = step;
      _loadingText = text;
      notifyListeners();
    }
  }
}
