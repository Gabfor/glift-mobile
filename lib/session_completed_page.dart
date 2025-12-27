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
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(),
                  Expanded(
                    flex: 4,
                    child: Image.asset(
                      'assets/images/congrats.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 48),
                  Text(
                    'Félicitations,\nvous avez terminé une nouvelle\nséance d’entrainement !',
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
                        fontWeight: FontWeight.w600, // Semibold for base text
                        color: const Color(0xFF5D6494),
                        height: 1.5,
                      ),
                      children: [
                        const TextSpan(text: 'C’était votre '),
                        TextSpan(
                          text: '${widget.sessionCount}',
                          style: GoogleFonts.quicksand(
                            fontWeight: FontWeight.w700, // Bold
                            color: const Color(0xFF3A416F),
                          ),
                        ),
                        WidgetSpan(
                          child: Transform.translate(
                            offset: const Offset(0, -6.0),
                            child: Text(
                              'ème',
                              style: GoogleFonts.quicksand(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF3A416F),
                              ),
                            ),
                          ),
                        ),
                        TextSpan(
                          text: ' séance',
                          style: GoogleFonts.quicksand(
                            fontWeight: FontWeight.w700, // Bold
                            color: const Color(0xFF3A416F),
                          ),
                        ),
                        const TextSpan(text: ' et vous vous êtes entraîné pendant '),
                        TextSpan(
                          text: '${widget.durationMinutes} minutes',
                          style: GoogleFonts.quicksand(
                            fontWeight: FontWeight.w700, // Bold
                            color: const Color(0xFF3A416F),
                          ),
                        ),
                        const TextSpan(text: '.'),
                      ],
                    ),
                  ),
                  // Adjusted spacing to match mockup: Distance between text and button
                  const SizedBox(height: 100), // 30px (gap) + 50px (button) + 20px (bottom padding)
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: SafeArea(
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.of(context).pop(true);
                },
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFF7069FA), // Active color from TimerPage
                    borderRadius: BorderRadius.circular(25),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Voir le tableau de bord',
                    style: GoogleFonts.quicksand(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 20,
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.of(context).pop(true);
              },
              child: SvgPicture.asset(
                'assets/icons/close.svg',
                width: 30,
                height: 30,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
