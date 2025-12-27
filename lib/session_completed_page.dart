import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme/glift_theme.dart';

class SessionCompletedPage extends StatefulWidget {
  const SessionCompletedPage({
    super.key,
    required this.sessionCount,
    required this.durationMinutes,
  });

  final int sessionCount;
  final int durationMinutes;

  @override
  State<SessionCompletedPage> createState() => _SessionCompletedPageState();
}

class _SessionCompletedPageState extends State<SessionCompletedPage> {
  @override
  void initState() {
    super.initState();
    // Play success sound or haptic here if desired
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Center(
                child: SizedBox(
                  width: 280,
                  height: 280,
                  child: SvgPicture.asset(
                    'assets/images/congrats.svg',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 48),
              Text(
                'Félicitations,',
                textAlign: TextAlign.center,
                style: GoogleFonts.quicksand(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF3A416F),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'vous avez terminé une nouvelle\nséance d’entrainement !',
                textAlign: TextAlign.center,
                style: GoogleFonts.quicksand(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF3A416F),
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 24),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: GoogleFonts.quicksand(
                    fontSize: 16,
                    fontWeight: FontWeight.w600, // Semibold
                    color: const Color(0xFF5D6494), // Default body color
                    height: 1.5,
                  ),
                  children: [
                    const TextSpan(text: 'C’était votre '),
                    TextSpan(
                      text: '${widget.sessionCount}ème séance',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold, // Bold
                        color: Color(0xFF3A416F),
                      ),
                    ),
                    const TextSpan(text: ' et vous vous êtes\nentraîné pendant '),
                    TextSpan(
                      text: '${widget.durationMinutes} minutes',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold, // Bold
                        color: Color(0xFF3A416F),
                      ),
                    ),
                    const TextSpan(text: '.'),
                  ],
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.of(context).pop(true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: GliftTheme.accent,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Voir le tableau de bord',
                  style: GoogleFonts.quicksand(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
