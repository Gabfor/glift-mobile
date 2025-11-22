import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'colors.dart';

class AppTypography {
  AppTypography._();

  static const String fontFamily = 'Quicksand';

  static TextTheme textTheme = TextTheme(
    titleLarge: GoogleFonts.quicksand(
      fontSize: 22,
      fontWeight: FontWeight.w700,
      color: BrandColors.title,
      height: 1.3,
    ),
    bodyLarge: GoogleFonts.quicksand(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: BrandColors.body,
      height: 1.5,
    ),
    bodyMedium: GoogleFonts.quicksand(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: BrandColors.body,
    ),
    labelSmall: GoogleFonts.quicksand(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.2,
      color: BrandColors.accent,
    ),
  );

  static TextStyle inputText = GoogleFonts.quicksand(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: BrandColors.body,
  );

  static TextStyle inputPlaceholder = GoogleFonts.quicksand(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: BrandColors.placeholder,
  );
}
