import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ExitTrainingModal extends StatelessWidget {
  const ExitTrainingModal({super.key});

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
              // Removed crossAxisAlignment: CrossAxisAlignment.start to default to center
              children: [
                // Image
                Center(
                  child: SvgPicture.asset(
                    'assets/images/Attention.svg',
                    height: 35,
                    width: 39,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 8),
                
                // Title
                Center(
                  child: Text(
                    'Attention !',
                    style: GoogleFonts.quicksand(
                      fontSize: 18,
                      fontWeight: FontWeight.w700, // Bold
                      color: const Color(0xFF3A416F),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Warning Text 1
                Text(
                  'Si vous quittez cet entraînement, votre progression ne sera pas sauvegardée.',
                  style: GoogleFonts.quicksand(
                    fontSize: 14,
                    fontWeight: FontWeight.w700, // Bold
                    color: const Color(0xFF3A416F),
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                
                // Description Text 2 (RichText)
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: GoogleFonts.quicksand(
                      fontSize: 14,
                      fontWeight: FontWeight.w600, // SemiBold base
                      color: const Color(0xFF3A416F),
                      height: 1.4,
                    ),
                    children: [
                      const TextSpan(text: 'En cliquant sur “'),
                      TextSpan(
                        text: 'Confirmer',
                        style: GoogleFonts.quicksand(
                          fontWeight: FontWeight.w700, // Bold
                        ),
                      ),
                      const TextSpan(text: '” vous perdrez toute progression. En cliquant sur “'),
                      TextSpan(
                        text: 'Annuler',
                        style: GoogleFonts.quicksand(
                          fontWeight: FontWeight.w700, // Bold
                        ),
                      ),
                      const TextSpan(text: '” vous pourrez reprendre votre entraînement.'),
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
                    
                    // Confirm Button
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEF4F4E),
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
              icon: const Icon(Icons.close),
              color: const Color(0xFF3A416F),
              iconSize: 24, // Explicitly set to match Shop modal
              onPressed: () => Navigator.of(context).pop(false),
              padding: const EdgeInsets.all(8), // Ensure touch target is decent
              constraints: const BoxConstraints(), // Minimizes extra constraints
              style: IconButton.styleFrom(tapTargetSize: MaterialTapTargetSize.shrinkWrap),
            ),
          ),
        ],
      ),
    );
  }
}
