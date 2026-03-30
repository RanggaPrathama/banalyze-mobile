import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:banalyze/core/constants/app_colors.dart';

class RipenessCard extends StatelessWidget {
  final String label;
  final String subtitle;
  final String stageLabel;
  final Color stageColor;
  final String? thumbnailUrl;
  final VoidCallback? onTap;
  final bool isLoading;

  const RipenessCard({
    super.key,
    required this.label,
    required this.subtitle,
    required this.stageLabel,
    required this.stageColor,
    this.thumbnailUrl,
    this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkCard : AppColors.white;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;
    final imageBg = isDark ? AppColors.darkSurface : AppColors.cardBackground;
    final textColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.textPrimary;
    final hintColor = isDark ? AppColors.darkTextHint : AppColors.textHint;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 165,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: isLoading
            ? _buildSkeleton(imageBg, borderColor)
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image area with stage badge
                  Expanded(
                    child: Stack(
                      children: [
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: imageBg,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child:
                                thumbnailUrl != null && thumbnailUrl!.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: thumbnailUrl!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                    placeholder: (_, __) => Center(
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: stageColor,
                                        ),
                                      ),
                                    ),
                                    errorWidget: (_, __, ___) => const Center(
                                      child: Text(
                                        '🍌',
                                        style: TextStyle(fontSize: 44),
                                      ),
                                    ),
                                  )
                                : const Center(
                                    child: Text(
                                      '🍌',
                                      style: TextStyle(fontSize: 44),
                                    ),
                                  ),
                          ),
                        ),
                        if (stageLabel.isNotEmpty)
                          Positioned(
                            bottom: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: stageColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                stageLabel,
                                style: GoogleFonts.poppins(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.white,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(fontSize: 11, color: hintColor),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSkeleton(Color imageBg, Color borderColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: imageBg,
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          height: 14,
          width: 100,
          decoration: BoxDecoration(
            color: imageBg,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 11,
          width: 130,
          decoration: BoxDecoration(
            color: imageBg,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ],
    );
  }
}
