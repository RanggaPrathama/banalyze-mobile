import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:banalyze/core/constants/app_colors.dart';

class AboutTechRow extends StatelessWidget {
  final String label;
  final String value;

  const AboutTechRow({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subtextColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.textSecondary;
    final textColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.textPrimary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(fontSize: 13, color: subtextColor),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
