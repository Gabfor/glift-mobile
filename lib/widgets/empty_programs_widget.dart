import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

class EmptyProgramsWidget extends StatefulWidget {
  const EmptyProgramsWidget({
    super.key,
    required this.onGoToStore,
  });

  final VoidCallback onGoToStore;

  @override
  State<EmptyProgramsWidget> createState() => _EmptyProgramsWidgetState();
}

class _EmptyProgramsWidgetState extends State<EmptyProgramsWidget> {
  late final TapGestureRecognizer _storeRecognizer;

  @override
  void initState() {
    super.initState();
    _storeRecognizer = TapGestureRecognizer()..onTap = widget.onGoToStore;
  }

  @override
  void dispose() {
    _storeRecognizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Oups ! Aucun programme\npour le moment....',
              textAlign: TextAlign.center,
              style: GoogleFonts.quicksand(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF3A416F),
                height: 1.3,
              ),
            ),
            const SizedBox(height: 12),
            Text.rich(
              TextSpan(
                style: GoogleFonts.quicksand(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF5D6494),
                  height: 1.4,
                ),
                children: [
                  const TextSpan(text: 'Rendez-vous sur le '),
                  TextSpan(
                    text: 'Store',
                    style: GoogleFonts.quicksand(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF7069FA),
                    ),
                    recognizer: _storeRecognizer,
                  ),
                  const TextSpan(
                      text: ' pour trouver votre prochain programme !'),
                ],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                widget.onGoToStore();
              },
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFF7069FA),
                  borderRadius: BorderRadius.circular(30),
                  // No boxShadow
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Accéder au Store',
                      style: GoogleFonts.quicksand(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    SvgPicture.asset(
                      'assets/icons/arrow.svg',
                      width: 26,
                      height: 26,
                      colorFilter: const ColorFilter.mode(
                        Colors.white,
                        BlendMode.srcIn,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
