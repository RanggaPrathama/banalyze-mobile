import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:banalyze/core/constants/app_colors.dart';

class ScanSummaryCard extends StatelessWidget {
  final int ripeCount;
  final int partiallyRipeCount;
  final int overripeUnripeCount;
  final int totalCount;

  const ScanSummaryCard({
    super.key,
    required this.ripeCount,
    required this.partiallyRipeCount,
    required this.overripeUnripeCount,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.darkCard : Colors.white;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;
    final textColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.textPrimary;
    final subtextColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.textSecondary;

    final maxCount = [
      ripeCount,
      partiallyRipeCount,
      overripeUnripeCount,
    ].reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Scan Summary (This Week)',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          const SizedBox(height: 14),
          _SummaryRow(
            label: 'RIPE',
            count: ripeCount,
            color: AppColors.ripe,
            maxCount: maxCount,
            textColor: textColor,
            subtextColor: subtextColor,
            isDark: isDark,
          ),
          const SizedBox(height: 10),
          _SummaryRow(
            label: 'PARTIALLY RIPE',
            count: partiallyRipeCount,
            color: AppColors.primary,
            maxCount: maxCount,
            textColor: textColor,
            subtextColor: subtextColor,
            isDark: isDark,
          ),
          const SizedBox(height: 10),
          _SummaryRow(
            label: 'OVERRIPE',
            count: overripeUnripeCount,
            color: AppColors.overripe,
            maxCount: maxCount,
            textColor: textColor,
            subtextColor: subtextColor,
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final int maxCount;
  final Color textColor;
  final Color subtextColor;
  final bool isDark;

  const _SummaryRow({
    required this.label,
    required this.count,
    required this.color,
    required this.maxCount,
    required this.textColor,
    required this.subtextColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final fraction = maxCount > 0 ? count / maxCount : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: subtextColor,
                letterSpacing: 0.3,
              ),
            ),
            Text(
              '$count SCANS',
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: fraction,
            backgroundColor: isDark
                ? AppColors.darkBorder
                : Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}
