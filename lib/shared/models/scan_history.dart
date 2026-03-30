import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:banalyze/core/constants/app_colors.dart';

enum RipenessLevel {
  unripe,
  partiallyRipe,
  ripe,
  overripe;

  String get label {
    switch (this) {
      case RipenessLevel.unripe:
        return 'Unripe';
      case RipenessLevel.partiallyRipe:
        return 'Partially_Ripe';
      case RipenessLevel.ripe:
        return 'Ripe';
      case RipenessLevel.overripe:
        return 'Overripe';
    }
  }

  Color get color {
    switch (this) {
      case RipenessLevel.unripe:
        return AppColors.unripe;
      case RipenessLevel.partiallyRipe:
        return AppColors.primary;
      case RipenessLevel.ripe:
        return AppColors.ripe;
      case RipenessLevel.overripe:
        return AppColors.overripe;
    }
  }

  String get advice {
    switch (this) {
      case RipenessLevel.unripe:
        return 'Best for cooking';
      case RipenessLevel.partiallyRipe:
        return 'Almost ready';
      case RipenessLevel.ripe:
        return 'Ready to eat';
      case RipenessLevel.overripe:
        return 'Handle with care';
    }
  }
}

class ScanHistory {
  final String id;
  final String title;
  final RipenessLevel ripeness;
  final double confidence;
  final DateTime dateTime;
  final String model;
  final String? imageUrl;

  const ScanHistory({
    required this.id,
    required this.title,
    required this.ripeness,
    required this.confidence,
    required this.dateTime,
    this.model = 'EfficientNetV2',
    this.imageUrl,
  });

  factory ScanHistory.fromMap(Map<String, dynamic> map) {
    // Normalize predicted_class: "Partially Ripe" or "Partially_Ripe" → consistent match
    final rawClass = (map['predicted_class'] as String? ?? '').replaceAll(
      ' ',
      '_',
    );
    return ScanHistory(
      id: map['id'].toString(),
      title: map['title'] as String? ?? 'Scan',
      ripeness: RipenessLevel.values.firstWhere(
        (e) => e.label == rawClass,
        orElse: () => RipenessLevel.partiallyRipe,
      ),
      confidence: (map['confidence'] as num).toDouble(),
      dateTime: DateTime.parse(map['created_at'] as String).toLocal(),
      model: map['model_used'] as String? ?? 'EfficientNetV2',
      imageUrl: (map['image_path'] ?? map['imageUrl']) as String?,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'predicted_class': ripeness.label,
    'confidence': confidence,
    // 'created_at': dateTime.toIso8601String(),
    'model_used': model,
    if (imageUrl != null) 'imageUrl': imageUrl,
  };

  String toJson() => jsonEncode(toMap());

  factory ScanHistory.fromJson(String source) =>
      ScanHistory.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
