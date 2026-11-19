import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:glift_mobile/theme/glift_colors.dart';

class GliftTheme {
  const GliftTheme._();

  static Color get background => GliftColors.surfacePrimary;
  static Color get accent => GliftColors.brandPrimary;
  static Color get title => GliftColors.brandStrong;
  static Color get body => GliftColors.textBody;
  static Color get pageIndicatorActive => GliftColors.focusRing;
  static Color get pageIndicatorInactive => GliftColors.surfaceSubtle;
  static Color get barrierColor => GliftColors.navyDeep.withValues(alpha: 0.6); // 60% opacity of #2E3142

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
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              if (states.contains(WidgetState.hovered)) {
                return GliftColors.surfaceSubtle;
              }
              return GliftColors.surfaceMuted;
            }
            if (states.contains(WidgetState.hovered)) {
              return GliftColors.brandPrimaryHover;
            }
            return accent;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return GliftColors.greyMedium;
            }
            return Colors.white;
          }),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
          ),
          textStyle: WidgetStatePropertyAll(
            GoogleFonts.quicksand(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          mouseCursor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return SystemMouseCursors.forbidden;
            }
            return SystemMouseCursors.click;
          }),
          elevation: const WidgetStatePropertyAll(0),
          shadowColor: const WidgetStatePropertyAll(Colors.transparent),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
          splashFactory: NoSplash.splashFactory,
        ),
      ),
    );
  }
}
