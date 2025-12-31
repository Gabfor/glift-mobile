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
    this.averageDuration,
    this.previousTotalVolume,
    this.previousTotalReps,
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
  final int? averageDuration;
  final double? previousTotalVolume;
  final int? previousTotalReps;
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
          initialProgramId: widget.programId,
          initialIndex: 1, // Go to 'Séances' tab explicitly
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

  String? _getDurationIcon() {
    debugPrint('DEBUG: Duration: ${widget.durationMinutes}, Avg: ${widget.averageDuration}');
    if (widget.averageDuration == null) return null;
    if (widget.durationMinutes > widget.averageDuration!) {
      return 'assets/icons/Arrow_red_up.svg';
    } else if (widget.durationMinutes < widget.averageDuration!) {
      return 'assets/icons/Arrow_green_down.svg';
    }
    return null;
  }

  String? _getVolumeIcon() {
    debugPrint('DEBUG: Volume: ${widget.totalVolume}, Prev: ${widget.previousTotalVolume}');
    if (widget.previousTotalVolume == null) return null;
    // Compare with epsilon for double equality if needed, but strict > / < is fine
    if (widget.totalVolume > widget.previousTotalVolume!) {
      return 'assets/icons/Arrow_green_up.svg';
    } else if (widget.totalVolume < widget.previousTotalVolume!) {
      return 'assets/icons/Arrow_red_down.svg';
    }
    return null;
  }

  String? _getRepsIcon() {
    debugPrint('DEBUG: Reps: ${widget.totalReps}, Prev: ${widget.previousTotalReps}');
    if (widget.previousTotalReps == null) return null;
    if (widget.totalReps > widget.previousTotalReps!) {
      return 'assets/icons/Arrow_green_up.svg';
    } else if (widget.totalReps < widget.previousTotalReps!) {
      return 'assets/icons/Arrow_red_down.svg';
    }
    return null;
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
              behavior: HitTestBehavior.opaque, // Ensure clicks are caught even if transparent parts exist
              child: Container(
                color: Colors.black.withOpacity(0.5),
              ),
            ),
          ),
          
          Center(
             child: Padding(
               padding: const EdgeInsets.symmetric(horizontal: 20),
               child: Container(
                 decoration: BoxDecoration(
                   color: Colors.white,
                   borderRadius: BorderRadius.circular(20),
                 ),
                 // Remove padding allow Stack to position elements freely
                 clipBehavior: Clip.hardEdge, // Ensure ripple/content stays inside bounds
                 child: Stack(
                   children: [
                     // Content
                     Padding(
                       // Top padding 44 matches ExitTrainingModal to clear the close button area effectively
                       padding: const EdgeInsets.fromLTRB(24, 44, 24, 24),
                       child: Column(
                         mainAxisSize: MainAxisSize.min,
                         children: [
                           // Top Icon (Check)
                           SvgPicture.asset(
                             'assets/icons/check_green.svg',
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
                               fontWeight: FontWeight.w700, 
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
                               fontWeight: FontWeight.w700,
                               color: const Color(0xFF3A416F),
                               height: 1.4,
                             ),
                           ),
                           const SizedBox(height: 32),

                           // Stats Grid
                           Row(
                             children: [
                               Expanded(child: _buildStatItem(
                                 icon: 'assets/icons/training_dumbell.svg',
                                 value: '${widget.sessionCount}${widget.sessionCount == 1 ? 'ʳᵉ' : 'ᵉ'} séance',
                                 label: 'Effectuées',
                               )),
                               const SizedBox(width: 16),
                               Expanded(child: _buildStatItem(
                                 icon: 'assets/icons/training_clock.svg',
                                 value: '${widget.durationMinutes} min',
                                 label: 'Durée de la séance',
                                 comparisonIconPath: _getDurationIcon(),
                               )),
                             ],
                           ),
                           const SizedBox(height: 24),
                           Row(
                             children: [
                               Expanded(child: _buildStatItem(
                                 icon: 'assets/icons/Poids.svg',
                                 value: '${_formatVolume(widget.totalVolume)} kg',
                                 label: 'Soulevés',
                                 comparisonIconPath: _getVolumeIcon(),
                               )),
                               const SizedBox(width: 16),
                               Expanded(child: _buildStatItem(
                                 icon: 'assets/icons/Rép.svg',
                                 value: '${widget.totalReps} rép.',
                                 label: 'Effectuées',
                                 comparisonIconPath: _getRepsIcon(),
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
                                 backgroundColor: const Color(0xFF7069FA),
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
                     ),

                     // Close Button (Positioned top-right)
                     Positioned(
                       top: 8, 
                       right: 8, 
                       child: GestureDetector(
                         onTap: _dismiss,
                         behavior: HitTestBehavior.opaque,
                         child: Container(
                           width: 48, 
                           height: 48,
                           alignment: Alignment.center,
                           child: const Icon(
                             Icons.close,
                             color: Color(0xFF3A416F),
                             size: 24,
                           ),
                         ),
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
    String? comparisonIconPath,
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
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible( // Use Flexible to prevent overflow if value is long
                    child: Text(
                      value,
                      style: GoogleFonts.quicksand(
                        fontSize: 14,
                        fontWeight: FontWeight.w700, // Bold
                        color: const Color(0xFF3A416F),
                        height: 1.2,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                   if (comparisonIconPath != null) ...[
                    const SizedBox(width: 4),
                    SvgPicture.asset(
                      comparisonIconPath,
                      width: 12,
                      height: 12,
                    ),
                  ],
                ],
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
