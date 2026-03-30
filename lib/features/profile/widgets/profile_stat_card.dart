import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfileStatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color cardColor;
  final Color textColor;
  final Color subtextColor;
  final Color borderColor;

  const ProfileStatCard({
    super.key,
    required this.value,
    required this.label,
    required this.cardColor,
    required this.textColor,
    required this.subtextColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: subtextColor,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
