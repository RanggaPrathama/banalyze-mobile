import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:banalyze/core/constants/app_colors.dart';

class ProfileMenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color cardColor;
  final Color textColor;
  final Color borderColor;
  final VoidCallback? onTap;

  const ProfileMenuTile({
    super.key,
    required this.icon,
    required this.label,
    required this.cardColor,
    required this.textColor,
    required this.borderColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: AppColors.primary),
        ),
        title: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: textColor,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: Colors.grey.shade400,
          size: 22,
        ),
      ),
    );
  }
}
