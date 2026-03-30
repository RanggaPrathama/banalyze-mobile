import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:banalyze/core/constants/app_colors.dart';

class AboutSectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color cardColor;
  final Color borderColor;
  final Color textColor;
  final List<Widget> children;

  const AboutSectionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.cardColor,
    required this.borderColor,
    required this.textColor,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}
