import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image/image.dart' as img;
import 'package:banalyze/core/constants/app_colors.dart';

/// Opens an interactive crop UI for the user (best for gallery-picked images).
/// Returns the cropped [File], or null if the user cancelled.
Future<File?> cropImageInteractive(
  File imageFile, {
  required BuildContext context,
}) async {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  final croppedFile = await ImageCropper().cropImage(
    sourcePath: imageFile.path,
    uiSettings: [
      AndroidUiSettings(
        toolbarTitle: 'Crop Banana',
        toolbarColor: isDark ? const Color(0xFF1C1C1C) : Colors.white,
        toolbarWidgetColor: isDark ? Colors.white : Colors.black87,
        activeControlsWidgetColor: AppColors.primary,
        initAspectRatio: CropAspectRatioPreset.square,
        lockAspectRatio: false,
      ),
      IOSUiSettings(
        title: 'Crop Banana',
        aspectRatioLockEnabled: false,
        resetAspectRatioEnabled: true,
      ),
    ],
  );

  if (croppedFile == null) return null;
  return File(croppedFile.path);
}

/// Programmatically center-crops the image to a square.
///
/// Used for camera-captured images to mimic the scan overlay box:
/// the center square (where the banana should be) is kept, removing
/// background noise around the edges.
///
/// Returns a new [File] with the cropped JPEG. Falls back to the
/// original file if decoding fails.
Future<File> centerCropSquare(File imageFile) async {
  final bytes = await imageFile.readAsBytes();
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return imageFile;

  // Determine the largest centered square
  final side = decoded.width < decoded.height ? decoded.width : decoded.height;
  final x = (decoded.width - side) ~/ 2;
  final y = (decoded.height - side) ~/ 2;

  final cropped = img.copyCrop(decoded, x: x, y: y, width: side, height: side);

  // Write to temp file next to original
  final timestamp = DateTime.now().millisecondsSinceEpoch;
  final outPath = '${imageFile.parent.path}/center_crop_$timestamp.jpg';
  final outFile = File(outPath);
  await outFile.writeAsBytes(img.encodeJpg(cropped, quality: 90));

  return outFile;
}
