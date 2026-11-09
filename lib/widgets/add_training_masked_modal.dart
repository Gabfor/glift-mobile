import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../user_subscription_page.dart';
import '../visibility_programs_page.dart';

class AddTrainingMaskedModal extends StatefulWidget {
  const AddTrainingMaskedModal({super.key});

  @override
  State<AddTrainingMaskedModal> createState() => _AddTrainingMaskedModalState();
}

class _AddTrainingMaskedModalState extends State<AddTrainingMaskedModal> {
  late final TapGestureRecognizer _settingsRecognizer;
  bool _isSettingsHovered = false;

  @override
  void initState() {
    super.initState();
    _settingsRecognizer = TapGestureRecognizer()..onTap = _openVisibilitySettings;
  }

  @override
  void dispose() {
    _settingsRecognizer.dispose();
    super.dispose();
  }

  void _openVisibilitySettings() {
    HapticFeedback.lightImpact();
    final navigator = Navigator.of(context);
    navigator.pop();
    navigator.push(
      MaterialPageRoute(
        builder: (context) => VisibilityProgramsPage(
          supabase: Supabase.instance.client,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 44, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Image
                Center(
                  child: SvgPicture.asset(
                    'assets/icons/message.svg',
                    height: 35,
                    width: 39,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 16),

                // Title
                Center(
                  child: Text(
                    "Ajout d'entraînement impossible",
                    style: GoogleFonts.quicksand(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF3A416F),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),

                // Warning Text
                Text(
                  'Ta formule d’abonnement actuelle te limite à un seul entraînement utilisable mais il est masqué.',
                  style: GoogleFonts.quicksand(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF3A416F),
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Description Text
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: GoogleFonts.quicksand(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF5D6494),
                      height: 1.4,
                    ),
                    children: [
                      const TextSpan(
                        text: 'Rends-toi dans ',
                      ),
                      TextSpan(
                        text: 'tes réglages',
                        recognizer: _settingsRecognizer,
                        mouseCursor: SystemMouseCursors.click,
                        onEnter: (_) => setState(() => _isSettingsHovered = true),
                        onExit: (_) => setState(() => _isSettingsHovered = false),
                        style: GoogleFonts.quicksand(
                          fontWeight: FontWeight.w600,
                          color: _isSettingsHovered
                              ? const Color(0xFF6660E4)
                              : const Color(0xFF7069FA),
                        ),
                      ),
                      const TextSpan(
                        text: ' pour gérer sa visibilité ou clique sur ',
                      ),
                      TextSpan(
                        text: '“Débloquer”',
                        style: GoogleFonts.quicksand(
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF3A416F),
                        ),
                      ),
                      const TextSpan(
                        text: ' pour modifier ta formule d’abonnement.',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Buttons
                Row(
                  children: [
                    // Cancel Button
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF3A416F)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: Text(
                            'Annuler',
                            style: GoogleFonts.quicksand(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF3A416F),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Unlock Button
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () {
                            final navigator = Navigator.of(context);
                            navigator.pop();
                            navigator.push(
                              MaterialPageRoute(
                                builder: (context) => UserSubscriptionPage(
                                  supabase: Supabase.instance.client,
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7069FA),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: Text(
                            'Débloquer',
                            style: GoogleFonts.quicksand(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Close Button (Top Right)
          Positioned(
            right: 8,
            top: 8,
            child: IconButton(
              icon: SvgPicture.asset(
                'assets/icons/close_modal.svg',
                width: 25,
                height: 25,
              ),
              onPressed: () => Navigator.of(context).pop(),
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(),
              style: IconButton.styleFrom(
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
