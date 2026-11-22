import 'package:flutter/material.dart';
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
    if (!context.mounted) return;

    await SettingsService.instance.saveBiometricPromptShown(true);
    if (!context.mounted) return;

    final isFaceId = label == 'Face ID';
    final isTouchId = label == 'Touch ID';
    final labelText = isFaceId
        ? 'le Face ID'
        : (isTouchId ? 'le Touch ID' : 'la biométrie');
    final titleLabel = isFaceId || isTouchId ? label : 'biométrie';

    final confirmed = await GliftModal.show<bool>(
      context: context,
      customIcon: Icon(
        isFaceId ? Icons.face_rounded : Icons.fingerprint_rounded,
        size: 40,
        color: GliftColors.brandPrimary,
      ),
      title: 'Connexion par $titleLabel',
      description:
          'Active $labelText pour te connecter encore plus facilement et en toute sécurité.\n\nGlift ne pourra en aucun cas accéder à tes données biométriques. Elles restent uniquement stockées sur ton téléphone. À tout moment, la fonctionnalité peut être désactivée dans tes Réglages.',
      primaryButtonText:
          isFaceId || isTouchId ? 'Activer $label' : 'Activer la biométrie',
      isPrimaryOutlined: false,
      primaryButtonColor: GliftColors.brandPrimary,
      primaryTextColor: Colors.white,
      secondaryButtonText: 'Plus tard',
      showCloseButton: false,
    );

    if (confirmed == true) {
      await SettingsService.instance.saveBiometricEnabled(true);
      final session = supabase.auth.currentSession;
      if (session != null) {
        await biometricAuthService.persistSession(session);
      }
    }
  }
}
