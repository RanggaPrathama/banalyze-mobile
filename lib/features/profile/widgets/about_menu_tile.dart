import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AboutMenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color cardColor;
  final Color borderColor;
  final Color textColor;
  final Color subtextColor;
  final VoidCallback onTap;

  const AboutMenuTile({
    super.key,
    required this.icon,
    required this.label,
    required this.cardColor,
    required this.borderColor,
    required this.textColor,
    required this.subtextColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: subtextColor),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 20, color: subtextColor),
          ],
        ),
      ),
    );
  }
}
