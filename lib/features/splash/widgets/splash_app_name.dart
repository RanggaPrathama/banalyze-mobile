import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:banalyze/core/constants/app_colors.dart';
import 'package:banalyze/core/constants/app_strings.dart';

class SplashAppName extends StatelessWidget {
  final Color textColorHeader;
  final Color textColorTagline;
  const SplashAppName({super.key, this.textColorHeader = AppColors.textPrimary, this.textColorTagline = AppColors.textSecondary});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Banana Ripeness\nClassifier',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: textColorHeader,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          AppStrings.appTagline,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: textColorTagline,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
