import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:banalyze/core/constants/app_colors.dart';

class ScanErrorPage extends StatelessWidget {
  const ScanErrorPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBackground : Colors.white;
    final textColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.textPrimary;
    final subtextColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.textSecondary;
    final cardColor = isDark ? AppColors.darkCard : AppColors.cardBackground;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Error State - Not Rec...',
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.code_rounded, color: subtextColor, size: 20),
            onPressed: () {},
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          children: [
            const Spacer(flex: 2),

            // Error illustration
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: borderColor),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('🍌❓', style: const TextStyle(fontSize: 60)),
                    const SizedBox(height: 8),
                    Icon(
                      Icons.image_not_supported_outlined,
                      size: 32,
                      color: subtextColor,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Title
            Text(
              'Image not recognized',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: textColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Description
            Text(
              'We couldn\'t detect a banana in that photo. Please ensure the fruit is centered, clear, and well-lit.',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: subtextColor,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Try Again button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.accent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Try Again',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // View photo tips
            TextButton(
              onPressed: () {},
              child: Text(
                'View photo tips',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: subtextColor,
                ),
              ),
            ),

            const Spacer(flex: 3),
          ],
        ),
      ),
    );
  }
}
