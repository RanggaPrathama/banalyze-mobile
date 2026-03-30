import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfileSectionLabel extends StatelessWidget {
  final String label;
  final Color color;

  const ProfileSectionLabel({
    super.key,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 1,
        ),
      ),
    );
  }
}
