import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/glift_theme.dart';
import 'colors.dart';
import 'spacing.dart';
import 'typography.dart';

class DesignTheme {
  const DesignTheme._();

  static ThemeData light() {
    final textTheme = GoogleFonts.quicksandTextTheme().copyWith(
      titleLarge: AppTypography.textTheme.titleLarge,
      bodyLarge: AppTypography.textTheme.bodyLarge,
      bodyMedium: AppTypography.textTheme.bodyMedium,
      labelSmall: AppTypography.textTheme.labelSmall,
    );

    final colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: BrandColors.primary,
      onPrimary: TailwindLightColors.primaryForeground,
      secondary: TailwindLightColors.secondary,
      onSecondary: TailwindLightColors.secondaryForeground,
      error: TailwindLightColors.destructive,
      onError: TailwindLightColors.destructiveForeground,
      background: TailwindLightColors.background,
      onBackground: TailwindLightColors.foreground,
      surface: BrandColors.pageBackground,
      onSurface: BrandColors.text,
    );

    return ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      scaffoldBackgroundColor: BrandColors.pageBackground,
      colorScheme: colorScheme,
      textTheme: textTheme,
      inputDecorationTheme: _buildInputDecorationTheme(),
      elevatedButtonTheme: _buildElevatedButtonTheme(textTheme),
      outlinedButtonTheme: _buildOutlinedButtonTheme(textTheme),
      chipTheme: _chipTheme(textTheme, colorScheme),
    );
  }

  /// Keeps backward compatibility with existing usages.
  static ThemeData legacyGliftTheme() => GliftTheme.buildTheme();
}

InputDecorationTheme _buildInputDecorationTheme() {
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
    borderSide: const BorderSide(color: BrandColors.border),
  );

  return InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.inputPaddingX,
      vertical: 0,
    ),
    constraints: const BoxConstraints(
      minHeight: AppSpacing.inputHeight,
    ),
    border: border,
    enabledBorder: border,
    focusedBorder: border.copyWith(
      borderSide: const BorderSide(color: BrandColors.accentSoft, width: 2),
    ),
    hintStyle: AppTypography.inputPlaceholder,
    labelStyle: AppTypography.inputText,
  );
}

ElevatedButtonThemeData _buildElevatedButtonTheme(TextTheme textTheme) {
  return ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: BrandColors.primary,
      foregroundColor: Colors.white,
      minimumSize: const Size.fromHeight(AppSpacing.buttonHeight),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.buttonPaddingX),
      textStyle: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
      ),
      shadowColor: Shadows.glift.color,
      elevation: 3,
    ),
  );
}

OutlinedButtonThemeData _buildOutlinedButtonTheme(TextTheme textTheme) {
  return OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: BrandColors.primary,
      side: const BorderSide(color: BrandColors.primary, width: 2),
      minimumSize: const Size.fromHeight(AppSpacing.buttonHeight),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.buttonPaddingX),
      textStyle: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
      ),
    ).copyWith(
      overlayColor: MaterialStateProperty.all(
        BrandColors.primary.withOpacity(0.08),
      ),
    ),
  );
}

ChipThemeData _chipTheme(TextTheme textTheme, ColorScheme colorScheme) {
  return ChipThemeData(
    backgroundColor: TailwindLightColors.secondary,
    selectedColor: BrandColors.primary,
    labelStyle: textTheme.bodyMedium,
    secondaryLabelStyle: textTheme.bodyMedium?.copyWith(
      color: TailwindLightColors.primaryForeground,
    ),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      side: const BorderSide(color: BrandColors.border),
    ),
    iconTheme: IconThemeData(color: colorScheme.primary),
  );
}
