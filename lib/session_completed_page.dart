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
    required this.totalVolume,
    required this.totalReps,
    this.programId,
    this.trainingId,
    required this.supabase,
    required this.authRepository,
    required this.biometricAuthService,
  });

  final int sessionCount;
  final int durationMinutes;
  final double totalVolume;
  final int totalReps;
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
    // No longer using gif, but good to trigger vibration
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

  void _goToDashboard() {
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

  void _dismiss() {
    HapticFeedback.lightImpact();
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => MainPage(
          supabase: widget.supabase,
          authRepository: widget.authRepository,
          biometricAuthService: widget.biometricAuthService,
          // No initialProgramId/TrainingId -> Defaults to Sessions (Index 1)
        ),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
      (route) => false,
    );
  }

  String _formatVolume(double volume) {
    // Format volume with space as thousand separator e.g. "3 577"
    // Remove decimal if zero
    String text = volume % 1 == 0 ? volume.toInt().toString() : volume.toStringAsFixed(1);
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      if (i > 0 && (text.length - i) % 3 == 0) {
        buffer.write(' ');
      }
      buffer.write(text[i]);
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Let the stack handle opacity for tap detection
      body: Stack(
        children: [
          // Background dismiss layer
          Positioned.fill(
            child: GestureDetector(
              onTap: _dismiss,
              child: Container(
                color: Colors.black.withOpacity(0.5),
              ),
            ),
          ),
          
          Dialog(
             insetPadding: const EdgeInsets.symmetric(horizontal: 20),
             backgroundColor: Colors.transparent, // Using transparent to control the Container directly
             shadowColor: Colors.transparent,
             elevation: 0,
             child: Center(
               child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Top Icon
                        SvgPicture.asset(
                          'assets/icons/check_green.svg', // User requested check_green.svg
                          width: 35,
                          height: 35,
                        ),
                        const SizedBox(height: 16),
                        
                        // Title
                        Text(
                          'Félicitations !',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.quicksand(
                            fontSize: 18, 
                            fontWeight: FontWeight.w700, // Bold
                            color: const Color(0xFF3A416F),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Subtitle
                        Text(
                          'Vous avez terminé une nouvelle séance d’entraînement.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.quicksand(
                            fontSize: 14,
                            fontWeight: FontWeight.w700, // Bold matching mockup look
                            color: const Color(0xFF3A416F),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Stats Grid
                        Row(
                          children: [
                            Expanded(child: _buildStatItem(
                              icon: 'assets/icons/training_dumbell.svg', // Fallback if specific one not found, or use 'dumbbell.svg'
                              value: '${widget.sessionCount}${widget.sessionCount == 1 ? 'ʳᵉ' : 'ᵉ'} séance',
                              label: 'Effectuées',
                            )),
                            const SizedBox(width: 16),
                            Expanded(child: _buildStatItem(
                              icon: 'assets/icons/training_clock.svg', // Or 'assets/icons/stopwatch.svg' or check_green etc. mockup has clock
                              value: '${widget.durationMinutes} min', // Mockup says '42 min'
                              label: 'Durée de la séance',
                            )),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(child: _buildStatItem(
                              icon: 'assets/icons/Poids.svg', // User requested Poids.svg
                              value: '${_formatVolume(widget.totalVolume)} kg',
                              label: 'Soulevés',
                            )),
                            const SizedBox(width: 16),
                            Expanded(child: _buildStatItem(
                              icon: 'assets/icons/Rép.svg', // User requested Rép.svg
                              value: '${widget.totalReps} rép.', // Text changed to "rép."
                              label: 'Effectuées',
                            )),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // CTA Button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _goToDashboard,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF7069FA), // Purple
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
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
                      ],
                    ),

                    // Close Button (Top right of the card)
                    Positioned(
                      right: -12, 
                      top: -28, // Adjust to match mockup visual
                      child: IconButton(
                        icon: const Icon(Icons.close),
                        color: const Color(0xFF3A416F),
                        iconSize: 24,
                        onPressed: _dismiss,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ),
                  ],
                ),
               ),
             ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String icon,
    required String value,
    required String label,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center, // Align to center
      children: [
        SvgPicture.asset(
          icon,
          width: 24,
          height: 24,
          // Removed colorFilter to use original SVG colors
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.quicksand(
                  fontSize: 14,
                  fontWeight: FontWeight.w700, // Bold
                  color: const Color(0xFF3A416F),
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: GoogleFonts.quicksand(
                  fontSize: 10, // Small label
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF5D6494), // Greyish text
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
