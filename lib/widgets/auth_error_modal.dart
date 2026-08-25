import 'package:flutter/material.dart';
import 'glift_modal.dart';

class AuthErrorModal extends StatelessWidget {
  final String title;
  final String description;
  final String buttonText;

  const AuthErrorModal({
    super.key,
    this.title = 'Email ou mot de passe incorrect',
    this.description =
        'Nous n’arrivons pas à te connecter. Vérifie qu’il s’agit bien de l’email utilisé lors de ton inscription ou qu’il n’y a pas d’erreur dans le mot de passe.',
    this.buttonText = 'Fermer',
  });

  static Future<void> show(
    BuildContext context, {
    String title = 'Email ou mot de passe incorrect',
    String description =
        'Nous n’arrivons pas à te connecter. Vérifie qu’il s’agit bien de l’email utilisé lors de ton inscription ou qu’il n’y a pas d’erreur dans le mot de passe.',
    String buttonText = 'Fermer',
  }) {
    return GliftModal.showError(
      context: context,
      title: title,
      description: description,
      buttonText: buttonText,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GliftModal(
      iconAsset: 'assets/icons/message_erreur.svg',
      title: title,
      description: description,
      primaryButtonText: buttonText,
      isPrimaryOutlined: true,
    );
  }
}
