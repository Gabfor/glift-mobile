import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class EmptyProgramsWidget extends StatefulWidget {
  const EmptyProgramsWidget({
    super.key,
    required this.onGoToStore,
    this.onManageTrainings,
    this.onManageVisibility,
    this.isAllMasked = false,
    this.isDashboard = false,
  });

  final VoidCallback onGoToStore;
  final VoidCallback? onManageTrainings;
  final VoidCallback? onManageVisibility;
  final bool isAllMasked;
  final bool isDashboard;

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
    if (widget.isAllMasked) {
      if (widget.isDashboard) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Oups ! Aucun programme\nà afficher...',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.quicksand(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF3A416F),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Tu as masqué l’ensemble de tes programmes dans ton tableau de bord. Règle leur visibilité pour voir les statistiques.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.quicksand(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF5D6494),
                    height: 1.4,
                  ),
                ),
                if (widget.onManageVisibility != null || widget.onManageTrainings != null) ...[
                  const SizedBox(height: 30),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      if (widget.onManageVisibility != null) {
                        widget.onManageVisibility!();
                      } else {
                        widget.onManageTrainings?.call();
                      }
                    },
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7069FA),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Régler la visibilité',
                            style: GoogleFonts.quicksand(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      }

      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Tous tes programmes\nsont masqués',
                textAlign: TextAlign.center,
                style: GoogleFonts.quicksand(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF3A416F),
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Tu as masqué l’ensemble de tes programmes dans l’application. Modifie leur visibilité depuis tes réglages pour les faire réapparaître ici.',
                textAlign: TextAlign.center,
                style: GoogleFonts.quicksand(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF5D6494),
                  height: 1.4,
                ),
              ),
              if (widget.onManageVisibility != null) ...[
                const SizedBox(height: 30),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    widget.onManageVisibility!();
                  },
                  child: Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7069FA),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Régler la visibilité',
                          style: GoogleFonts.quicksand(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

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
                  const TextSpan(text: 'Rends-toi sur le '),
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
                      text: ' pour trouver ton prochain programme !'),
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
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Aller sur le Store',
                      style: GoogleFonts.quicksand(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
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
