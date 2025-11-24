import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import 'theme/glift_theme.dart';
import 'widgets/glift_page_layout.dart';

class SignupPage extends StatelessWidget {
  const SignupPage({super.key});

  Future<void> _openPricing() async {
    final uri = Uri.parse('https://glift.io/tarifs/');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return GliftPageLayout(
      title: 'Inscription',
      subtitle: 'Créer un compte',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rejoignez Glift en quelques clics.',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: GliftTheme.title,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Vous serez redirigé vers notre site pour finaliser votre inscription.',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: GliftTheme.body,
            ),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _openPricing,
              child: const Text('Continuer vers glift.io'),
            ),
          ),
        ],
      ),
    );
  }
}
