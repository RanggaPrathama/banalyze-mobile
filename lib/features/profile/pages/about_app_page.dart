import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:banalyze/core/constants/app_colors.dart';
import 'package:banalyze/features/profile/widgets/about_menu_tile.dart';
import 'package:banalyze/features/profile/widgets/about_section_card.dart';
import 'package:banalyze/features/profile/widgets/about_tech_row.dart';

class AboutAppPage extends StatelessWidget {
  const AboutAppPage({super.key});

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
    final hintColor = isDark ? AppColors.darkTextHint : AppColors.textHint;
    final cardColor = isDark ? AppColors.darkCard : Colors.grey.shade50;
    final borderColor = isDark ? AppColors.darkBorder : Colors.grey.shade200;

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
          'About App',
          style: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
        child: Column(
          children: [
            // App logo & version
            const SizedBox(height: 8),
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.eco_rounded,
                size: 36,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Banalyze',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Version 1.0.0',
              style: GoogleFonts.poppins(fontSize: 13, color: hintColor),
            ),
            const SizedBox(height: 28),

            // Our Technology card
            AboutSectionCard(
              title: 'Our Technology',
              icon: Icons.memory_rounded,
              cardColor: cardColor,
              borderColor: borderColor,
              textColor: textColor,
              children: const [
                AboutTechRow(
                  label: 'Klasifikasi Model',
                  value: 'EfficientNetV2',
                ),
                AboutTechRow(label: 'Optimized With', value: 'MobileNetV3'),
                AboutTechRow(label: 'Training Data', value: '50,000 samples'),
              ],
            ),
            const SizedBox(height: 16),

            // Developer Info card
            AboutSectionCard(
              title: 'Developer Info',
              icon: Icons.code_rounded,
              cardColor: cardColor,
              borderColor: borderColor,
              textColor: textColor,
              children: const [
                AboutTechRow(
                  label: 'University',
                  value: 'Universitas Banalyze',
                ),
                AboutTechRow(label: 'Developer', value: 'Rangga'),
                AboutTechRow(label: 'Supervisor', value: '-'),
              ],
            ),
            const SizedBox(height: 24),

            // Menu tiles
            AboutMenuTile(
              icon: Icons.description_outlined,
              label: 'Terms of Service',
              cardColor: cardColor,
              borderColor: borderColor,
              textColor: textColor,
              subtextColor: subtextColor,
              onTap: () {},
            ),
            const SizedBox(height: 10),
            AboutMenuTile(
              icon: Icons.shield_outlined,
              label: 'Privacy Policy',
              cardColor: cardColor,
              borderColor: borderColor,
              textColor: textColor,
              subtextColor: subtextColor,
              onTap: () {},
            ),
            const SizedBox(height: 10),
            AboutMenuTile(
              icon: Icons.headset_mic_outlined,
              label: 'Support Contact',
              cardColor: cardColor,
              borderColor: borderColor,
              textColor: textColor,
              subtextColor: subtextColor,
              onTap: () {},
            ),
            const SizedBox(height: 32),

            // Copyright
            Text(
              '© 2025 Banalyze. All rights reserved.',
              style: GoogleFonts.poppins(fontSize: 11, color: hintColor),
            ),
          ],
        ),
      ),
    );
  }
}
