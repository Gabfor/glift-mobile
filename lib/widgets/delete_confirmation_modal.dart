import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:glift_mobile/theme/glift_colors.dart';

class DeleteConfirmationModal extends StatelessWidget {
  final String? question;
  final String? subtitle;
  final String objectName;

  const DeleteConfirmationModal({
    super.key,
    this.question,
    this.subtitle,
    required this.objectName,
  });

  String get effectiveSubtitle => subtitle ?? question ?? '';

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
                    'assets/icons/message_erreur.svg',
                    colorMapper: GliftColors.iconColorMapper,
                    height: 35,
                    width: 39,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 8),
                
                // Static Title
                Center(
                  child: Text(
                    'Attention !',
                    style: GoogleFonts.quicksand(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: GliftColors.brandStrong,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 10),
                
                // Subtitle / Question Text
                Text(
                  effectiveSubtitle,
                  style: GoogleFonts.quicksand(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: GliftColors.brandStrong,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                
                // Contextual Description (RichText)
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: GoogleFonts.quicksand(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: GliftColors.textBody,
                      height: 1.4,
                    ),
                    children: [
                      const TextSpan(text: 'En cliquant sur “'),
                      TextSpan(
                        text: 'Confirmer',
                        style: GoogleFonts.quicksand(
                          fontWeight: FontWeight.w700,
                          color: GliftColors.brandStrong,
                        ),
                      ),
                      TextSpan(text: '” $objectName sera définitivement supprimé. En cliquant sur “'),
                      TextSpan(
                        text: 'Annuler',
                        style: GoogleFonts.quicksand(
                          fontWeight: FontWeight.w700,
                          color: GliftColors.brandStrong,
                        ),
                      ),
                      const TextSpan(text: '” rien ne se passera.'),
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
                          onPressed: () => Navigator.of(context).pop(false),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: GliftColors.brandStrong),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: Text(
                            'Annuler',
                            style: GoogleFonts.quicksand(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: GliftColors.brandStrong,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    
                    // Confirm Button
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: GliftColors.accentDanger,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: Text(
                            'Confirmer',
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
                colorMapper: GliftColors.iconColorMapper,
                width: 25,
                height: 25,
              ),
              onPressed: () => Navigator.of(context).pop(false),
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(),
              style: IconButton.styleFrom(tapTargetSize: MaterialTapTargetSize.shrinkWrap),
            ),
          ),
        ],
      ),
    );
  }
}
