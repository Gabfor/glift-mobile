import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
    final textColor = isInteractive ? Colors.white : const Color(0xFFC2BFC6);

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
                return const Color(0xFFECE9F1);
              }
              return const Color(0xFFF2F1F6);
            }
            if (states.contains(WidgetState.hovered)) {
              return const Color(0xFF6660E4);
            }
            return const Color(0xFF7069FA);
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (!isInteractive) {
              return const Color(0xFFC2BFC6);
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
                      color: const Color(0xFFC2BFC6),
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
