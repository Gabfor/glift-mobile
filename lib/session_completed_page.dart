import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase/supabase.dart';
import 'package:glift_mobile/auth/auth_repository.dart';
import 'package:glift_mobile/auth/biometric_auth_service.dart';
import 'package:glift_mobile/main_page.dart';
import 'package:glift_mobile/services/vibration_service.dart';
import 'theme/glift_theme.dart';

class SessionCompletedPage extends StatefulWidget {
  const SessionCompletedPage({
    super.key,
    required this.sessionCount,
    required this.durationMinutes,
    this.programId,
    this.trainingId,
    required this.supabase,
    required this.authRepository,
    required this.biometricAuthService,
  });

  final int sessionCount;
  final int durationMinutes;
  final String? programId;
  final String? trainingId;
  final SupabaseClient supabase;
  final AuthRepository authRepository;
  final BiometricAuthService biometricAuthService;

  @override
  State<SessionCompletedPage> createState() => _SessionCompletedPageState();
}

class _SessionCompletedPageState extends State<SessionCompletedPage> {
  @override
  void initState() {
    super.initState();
    // Evict the image from cache to ensure the GIF restarts
    final imageProvider = AssetImage('assets/images/congrats.gif');
    imageProvider.evict();
    
    _triggerVibration();
  }

  Future<void> _triggerVibration() async {
    const vibrationService = DeviceVibrationService();
    final hasVibrator = await vibrationService.hasVibrator();
    if (hasVibrator) {
      await vibrationService.vibrate();
    } else {
      await vibrationService.fallback();
    }
  }

  void _close() {
    HapticFeedback.lightImpact();
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => MainPage(
          supabase: widget.supabase,
          authRepository: widget.authRepository,
          biometricAuthService: widget.biometricAuthService,
          initialProgramId: widget.programId,
          initialTrainingId: widget.trainingId,
        ),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Stack(
        children: [

          // Background Image (Top aligned)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.65,
            child: Image.asset(
              'assets/images/congrats.gif',
              fit: BoxFit.contain,
              alignment: Alignment.topCenter,
            ),
          ),
          
          // Content (Bottom aligned)
          Positioned.fill(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
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
                    const SizedBox(height: 14),
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
                                widget.sessionCount == 1 ? 'ʳᵉ' : 'ᵉ',
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
                            text: '${widget.durationMinutes} minute${widget.durationMinutes > 1 ? 's' : ''}',
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
          ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: SafeArea(
              child: GestureDetector(
                onTap: _close,
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
              onTap: _close,
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
