import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:glift_mobile/theme/glift_colors.dart';

class ConnectButton extends StatelessWidget {
  final bool isEnabled;
  final bool isLoading;
  final VoidCallback onPressed;

  const ConnectButton({
    super.key,
    required this.isEnabled,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isInteractive = isEnabled && !isLoading;
    final textColor = isInteractive ? Colors.white : GliftColors.greyMedium;

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: isInteractive ? onPressed : null,
        style: ButtonStyle(
          elevation: const WidgetStatePropertyAll(0),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (!isInteractive) {
              if (states.contains(WidgetState.hovered)) {
                return GliftColors.surfaceSubtle;
              }
              return GliftColors.surfaceMuted;
            }
            if (states.contains(WidgetState.hovered)) {
              return GliftColors.brandPrimaryHover;
            }
            return GliftColors.brandPrimary;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (!isInteractive) {
              return GliftColors.greyMedium;
            }
            return Colors.white;
          }),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          ),
          textStyle: WidgetStatePropertyAll(
            GoogleFonts.quicksand(
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          mouseCursor: WidgetStateProperty.resolveWith((states) {
            if (!isInteractive) {
              return SystemMouseCursors.forbidden;
            }
            return SystemMouseCursors.click;
          }),
        ),
        child: isLoading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(textColor),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'En cours...',
                    style: GoogleFonts.quicksand(
                      color: GliftColors.greyMedium,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              )
            : const Text('Se connecter'),
      ),
    );
  }
}
