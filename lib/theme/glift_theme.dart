import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GliftTheme {
  const GliftTheme._();

  static const Color background = Color(0xFFF9FAFB);
  static const Color accent = Color(0xFF7069FA);
  static const Color title = Color(0xFF3A416F);
  static const Color body = Color(0xFF5D6494);
  static const Color pageIndicatorActive = Color(0xFF7D72FF);
  static const Color pageIndicatorInactive = Color(0xFFE5E4ED);
  static const Color backgroundTop = Color(0xFFF4F3FF);
  static const Color cardShadow = Color(0x1A1A0F4D);

  static const LinearGradient onboardingBackground = LinearGradient(
    colors: [backgroundTop, background],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF7D6CFF), Color(0xFF5D4AE8)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static ThemeData buildTheme() {
    final quicksandFontFamily = GoogleFonts.quicksand().fontFamily;

    final baseTheme = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: accent,
        surface: background,
      ),
      scaffoldBackgroundColor: background,
      useMaterial3: true,
      fontFamily: quicksandFontFamily,
    );

    final textTheme = GoogleFonts.quicksandTextTheme(baseTheme.textTheme).copyWith(
      headlineSmall: GoogleFonts.quicksand(
        fontSize: 26,
        fontWeight: FontWeight.w800,
        color: title,
        height: 1.35,
      ),
      titleMedium: GoogleFonts.quicksand(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
      bodyLarge: GoogleFonts.quicksand(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: body,
        height: 1.6,
      ),
      bodyMedium: GoogleFonts.quicksand(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: body,
      ),
      labelSmall: GoogleFonts.quicksand(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 2,
        color: accent,
      ),
    );

    return baseTheme.copyWith(
      textTheme: textTheme,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          textStyle: GoogleFonts.quicksand(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
