import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:banalyze/core/constants/app_colors.dart';
import 'package:banalyze/router/app_router.dart';
import 'package:banalyze/features/classifications/providers/classification_provider.dart';
import 'package:banalyze/shared/widgets/app_snackbar.dart';
import 'package:banalyze/shared/utils/image_crop_helper.dart';

class ImageReviewPage extends StatefulWidget {
  final String imagePath;

  const ImageReviewPage({super.key, required this.imagePath});

  @override
  State<ImageReviewPage> createState() => _ImageReviewPageState();
}

class _ImageReviewPageState extends State<ImageReviewPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClassificationProvider>().setImage(File(widget.imagePath));
    });
  }

  Future<void> _retakeImage() async {
    final provider = context.read<ClassificationProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.darkCard : Colors.white;
    final textColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.textPrimary;
    final subtextColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.textSecondary;

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: subtextColor.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Retake Photo',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Choose a new image source',
                style: GoogleFonts.poppins(fontSize: 13, color: subtextColor),
              ),
              const SizedBox(height: 24),
              _SourceOption(
                icon: Icons.camera_alt_rounded,
                label: 'Take Photo',
                subtitle: 'Use camera to capture',
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
                isDark: isDark,
              ),
              const SizedBox(height: 12),
              _SourceOption(
                icon: Icons.photo_library_rounded,
                label: 'Choose from Gallery',
                subtitle: 'Select existing photo',
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
                isDark: isDark,
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );

    if (source == null || !mounted) return;

    final picked = await provider.pickImage(source);
    if (!picked || !mounted) return;

    final currentImage = provider.selectedImage;
    if (currentImage == null) return;

    if (source == ImageSource.gallery) {
      // Gallery: interactive crop
      final cropped = await cropImageInteractive(
        currentImage,
        context: context,
      );
      if (cropped != null && mounted) {
        provider.setImage(cropped);
      }
    } else {
      // Camera: auto center-crop
      final cropped = await centerCropSquare(currentImage);
      if (mounted) {
        provider.setImage(cropped);
      }
    }
  }

  Future<void> _cropCurrentImage() async {
    final provider = context.read<ClassificationProvider>();
    final currentImage = provider.selectedImage;
    if (currentImage == null) return;

    final cropped = await cropImageInteractive(currentImage, context: context);
    if (cropped != null && mounted) {
      provider.setImage(cropped);
    }
  }

  Future<void> _classifyImage() async {
    final provider = context.read<ClassificationProvider>();
    await provider.classify();

    if (!mounted) return;

    if (provider.status == ClassificationStatus.error) {
      AppSnackBar.error(provider.errorMessage ?? 'Classification failed');
      return;
    }

    Navigator.pushReplacementNamed(
      context,
      AppRouter.classificationResult,
      arguments: provider.toResultData(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBackground : AppColors.background;
    final textColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.textPrimary;
    final subtextColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.textSecondary;

    return Consumer<ClassificationProvider>(
      builder: (context, provider, _) {
        final image = provider.selectedImage ?? File(widget.imagePath);
        final isClassifying = provider.isLoading;

        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            backgroundColor: bgColor,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_rounded, color: textColor),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Review Photo',
              style: GoogleFonts.poppins(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            centerTitle: true,
          ),
          body: Column(
            children: [
              // Image preview
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: SizedBox(
                      width: double.infinity,
                      child: Image.file(image, fit: BoxFit.cover),
                    ),
                  ),
                ),
              ),

              // Quality check info
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.primary.withValues(alpha: 0.1)
                        : AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Check Quality',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: textColor,
                              ),
                            ),
                            Text(
                              'Ensure one banana is dominant in the frame',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: subtextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Buttons
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Column(
                  children: [
                    // Classify Now button
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: isClassifying ? null : _classifyImage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.accent,
                          disabledBackgroundColor: AppColors.primary.withValues(
                            alpha: 0.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: isClassifying
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: AppColors.accent,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Classifying...',
                                    style: GoogleFonts.poppins(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.accent,
                                    ),
                                  ),
                                ],
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Classify Now',
                                    style: GoogleFonts.poppins(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 20,
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Crop & Retake buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: isClassifying ? null : _cropCurrentImage,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.crop_rounded,
                                size: 18,
                                color: subtextColor,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Crop',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: subtextColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 32),
                        GestureDetector(
                          onTap: isClassifying ? null : _retakeImage,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.refresh_rounded,
                                size: 18,
                                color: subtextColor,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Retake',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: subtextColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
            ],
          ),
        );
      },
    );
  }
}

class _SourceOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final bool isDark;

  const _SourceOption({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.textPrimary;
    final subtextColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.textSecondary;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: subtextColor,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: subtextColor, size: 22),
          ],
        ),
      ),
    );
  }
}
