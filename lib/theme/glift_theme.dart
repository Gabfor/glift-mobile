import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GliftTheme {
  const GliftTheme._();

  static const Color background = Color(0xFFF9FAFB);
  static const Color accent = Color(0xFF7069FA);
  static const Color title = Color(0xFF3A416F);
  static const Color body = Color(0xFF5D6494);
  static const Color pageIndicatorActive = Color(0xFFA1A5FD);
  static const Color pageIndicatorInactive = Color(0xFFECE9F1);
  static const Color barrierColor = Color(0x992E3142); // 60% opacity of #2E3142

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
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
      splashFactory: NoSplash.splashFactory,
    );

    final textTheme = GoogleFonts.quicksandTextTheme(baseTheme.textTheme).copyWith(
      headlineSmall: GoogleFonts.quicksand(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: title,
        height: 1.3,
      ),
      bodyLarge: GoogleFonts.quicksand(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: body,
        height: 1.5,
      ),
      bodyMedium: GoogleFonts.quicksand(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: body,
      ),
      labelSmall: GoogleFonts.quicksand(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: accent,
      ),
    );

    return baseTheme.copyWith(
      textTheme: textTheme,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFFF2F1F6),
          disabledForegroundColor: const Color(0xFFD7D4DC),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          textStyle: GoogleFonts.quicksand(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
          elevation: 0,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          overlayColor: Colors.transparent,
          splashFactory: NoSplash.splashFactory,
        ),
      ),
    );
  }
}
