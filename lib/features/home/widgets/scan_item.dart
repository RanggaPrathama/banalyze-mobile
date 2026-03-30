import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:banalyze/core/constants/app_colors.dart';

/// A row item showing a recent scan result.
class ScanItem extends StatelessWidget {
  final String label;
  final String subtitle;
  final Color statusColor;
  final IconData statusIcon;

  const ScanItem({
    super.key,
    required this.label,
    required this.subtitle,
    required this.statusColor,
    required this.statusIcon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkCard : AppColors.white;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;
    final thumbBg = isDark ? AppColors.darkSurface : AppColors.cardBackground;
    final textColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.textPrimary;
    final hintColor = isDark ? AppColors.darkTextHint : AppColors.textHint;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Thumbnail
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: thumbBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(
              child: Text('🍌', style: TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 12),
          // Info
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
                  style: GoogleFonts.poppins(fontSize: 11, color: hintColor),
                ),
              ],
            ),
          ),
          // Status
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(statusIcon, color: statusColor, size: 18),
          ),
        ],
      ),
    );
  }
}
