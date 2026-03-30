import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:banalyze/core/constants/app_colors.dart';

class EditProfileFieldLabel extends StatelessWidget {
  final String text;
  final Color color;

  const EditProfileFieldLabel({
    super.key,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: color,
      ),
    );
  }
}

class EditProfileStyledTextField extends StatelessWidget {
  final TextEditingController controller;
  final IconData icon;
  final TextInputType? keyboardType;
  final Color textColor;
  final Color hintColor;
  final Color fillColor;
  final Color borderColor;

  const EditProfileStyledTextField({
    super.key,
    required this.controller,
    required this.icon,
    this.keyboardType,
    required this.textColor,
    required this.hintColor,
    required this.fillColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: GoogleFonts.poppins(fontSize: 14, color: textColor),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: hintColor, size: 20),
        filled: true,
        fillColor: fillColor,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }
}
