import 'package:flutter/material.dart';

/// Tailwind-driven semantic palette extracted from the web theme.
/// Values are kept in HSL to match the Tailwind tokens exactly.
class TailwindLightColors {
  TailwindLightColors._();

  static final Color background = _hsl(0, 0, 100);
  static final Color foreground = _hsl(0, 0, 3.9);
  static final Color card = _hsl(0, 0, 100);
  static final Color cardForeground = _hsl(0, 0, 3.9);
  static final Color popover = _hsl(0, 0, 100);
  static final Color popoverForeground = _hsl(0, 0, 3.9);
  static final Color primary = _hsl(0, 0, 9);
  static final Color primaryForeground = _hsl(0, 0, 98);
  static final Color secondary = _hsl(0, 0, 96.1);
  static final Color secondaryForeground = _hsl(0, 0, 9);
  static final Color muted = _hsl(0, 0, 96.1);
  static final Color mutedForeground = _hsl(0, 0, 45.1);
  static final Color accent = _hsl(0, 0, 96.1);
  static final Color accentForeground = _hsl(0, 0, 9);
  static final Color destructive = _hsl(0, 84.2, 60.2);
  static final Color destructiveForeground = _hsl(0, 0, 98);
  static final Color border = _hsl(0, 0, 89.8);
  static final Color input = _hsl(0, 0, 89.8);
  static final Color ring = _hsl(0, 0, 3.9);
  static final Color chart1 = _hsl(12, 76, 61);
  static final Color chart2 = _hsl(173, 58, 39);
  static final Color chart3 = _hsl(197, 37, 24);
  static final Color chart4 = _hsl(43, 74, 66);
  static final Color chart5 = _hsl(27, 87, 67);
}

class TailwindDarkColors {
  TailwindDarkColors._();

  static final Color background = _hsl(0, 0, 3.9);
  static final Color foreground = _hsl(0, 0, 98);
  static final Color card = _hsl(0, 0, 3.9);
  static final Color cardForeground = _hsl(0, 0, 98);
  static final Color popover = _hsl(0, 0, 3.9);
  static final Color popoverForeground = _hsl(0, 0, 98);
  static final Color primary = _hsl(0, 0, 98);
  static final Color primaryForeground = _hsl(0, 0, 9);
  static final Color secondary = _hsl(0, 0, 14.9);
  static final Color secondaryForeground = _hsl(0, 0, 98);
  static final Color muted = _hsl(0, 0, 14.9);
  static final Color mutedForeground = _hsl(0, 0, 63.9);
  static final Color accent = _hsl(0, 0, 14.9);
  static final Color accentForeground = _hsl(0, 0, 98);
  static final Color destructive = _hsl(0, 62.8, 30.6);
  static final Color destructiveForeground = _hsl(0, 0, 98);
  static final Color border = _hsl(0, 0, 14.9);
  static final Color input = _hsl(0, 0, 14.9);
  static final Color ring = _hsl(0, 0, 83.1);
  static final Color chart1 = _hsl(220, 70, 50);
  static final Color chart2 = _hsl(160, 60, 45);
  static final Color chart3 = _hsl(30, 80, 55);
  static final Color chart4 = _hsl(280, 65, 60);
  static final Color chart5 = _hsl(340, 75, 55);
}

/// Brand-specific colors that appear in globals.css and component styles.
class BrandColors {
  BrandColors._();

  static const Color pageBackground = Color(0xFFFBFCFE);
  static const Color text = Color(0xFF202121);
  static const Color title = Color(0xFF3A416F);
  static const Color body = Color(0xFF5D6494);
  static const Color primary = Color(0xFF2E3271);
  static const Color primaryHover = Color(0xFF1F224E);
  static const Color accent = Color(0xFF7069FA);
  static const Color accentSoft = Color(0xFFA1A5FD);
  static const Color accentPale = Color(0xFFECE9F1);
  static const Color border = Color(0xFFD7D4DC);
  static const Color borderHover = Color(0xFFC2BFC6);
  static const Color placeholder = Color(0xFFD7D4DC);
  static const Color overlay = Color(0x992E3142);
}

class Shadows {
  Shadows._();

  static const BoxShadow glift = BoxShadow(
    color: Color.fromRGBO(93, 100, 148, 0.15),
    offset: Offset(0, 3),
    blurRadius: 6,
  );

  static const BoxShadow gliftHover = BoxShadow(
    color: Color.fromRGBO(93, 100, 148, 0.25),
    offset: Offset(0, 10),
    blurRadius: 20,
  );

  static const BoxShadow gliftHoverSoft = BoxShadow(
    color: Color.fromRGBO(93, 100, 148, 0.15),
    offset: Offset(0, 5),
    blurRadius: 21,
  );
}

Color _hsl(double hue, double saturationPercent, double lightnessPercent) {
  return HSLColor.fromAHSL(
    1,
    hue,
    saturationPercent / 100,
    lightnessPercent / 100,
  ).toColor();
}
