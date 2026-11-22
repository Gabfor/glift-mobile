import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:glift_mobile/auth/biometric_auth_service.dart';
import 'package:glift_mobile/services/settings_service.dart';
import 'package:glift_mobile/theme/glift_colors.dart';
import 'package:glift_mobile/widgets/glift_modal.dart';

class BiometricOptInModal {
  const BiometricOptInModal._();

  static Future<void> showIfNeeded({
    required BuildContext context,
    required BiometricAuthService biometricAuthService,
    required SupabaseClient supabase,
  }) async {
    if (SettingsService.instance.getBiometricPromptShown()) return;
    if (SettingsService.instance.getBiometricEnabled()) return;

    final available = await biometricAuthService.isBiometricAvailable();
    if (!available || !context.mounted) return;

    final label = await biometricAuthService.getBiometricLabel();
    final iconAsset = await biometricAuthService.getBiometricIconAsset();
    if (!context.mounted) return;

    await SettingsService.instance.saveBiometricPromptShown(true);
    if (!context.mounted) return;

    final (title, boldLead) = _copyForLabel(label);

    final confirmed = await GliftModal.show<bool>(
      context: context,
      iconAsset: iconAsset,
      iconWidth: 40,
      iconHeight: 40,
      title: title,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            boldLead,
            style: GoogleFonts.quicksand(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: GliftColors.brandStrong,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          Text(
            'Glift ne pourra en aucun cas accéder à tes données biométriques. Elles restent uniquement stockées sur ton téléphone. À tout moment, la fonctionnalité peut être désactivée dans tes Réglages.',
            style: GoogleFonts.quicksand(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: GliftColors.brandStrong,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      primaryButtonText: 'Activer',
      isPrimaryOutlined: false,
      primaryButtonColor: GliftColors.brandPrimary,
      primaryTextColor: Colors.white,
      secondaryButtonText: 'Plus tard',
      showCloseButton: true,
    );

    if (confirmed == true) {
      await SettingsService.instance.saveBiometricEnabled(true);
      final session = supabase.auth.currentSession;
      if (session != null) {
        await biometricAuthService.persistSession(session);
      }
    }
  }

  static (String, String) _copyForLabel(String label) {
    switch (label) {
      case 'Face ID':
        return (
          'Connexion par Face ID',
          'Active le Face ID pour te connecter encore plus facilement et en toute sécurité.',
        );
      case 'Touch ID':
        return (
          'Connexion par Touch ID',
          'Active le Touch ID pour te connecter encore plus facilement et en toute sécurité.',
        );
      case 'Reconnaissance faciale':
        return (
          'Connexion par reconnaissance faciale',
          'Active la reconnaissance faciale pour te connecter encore plus facilement et en toute sécurité.',
        );
      case 'Empreinte digitale':
        return (
          'Connexion par empreinte digitale',
          'Active l’empreinte digitale pour te connecter encore plus facilement et en toute sécurité.',
        );
      default:
        return (
          'Connexion par biométrie',
          'Active la biométrie pour te connecter encore plus facilement et en toute sécurité.',
        );
    }
  }
}
