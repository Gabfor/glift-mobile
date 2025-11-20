import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'theme/glift_theme.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tableau de bord'),
        backgroundColor: Colors.white,
      ),
      body: Center(
        child: Text(
          'Connexion réussie !',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: GliftTheme.title,
          ),
        ),
      ),
    );
  }
}
