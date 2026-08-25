import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

/// Composant générique unifié pour toutes les modales d'alerte, de confirmation et d'information de Glift.
class GliftModal extends StatelessWidget {
  final String? iconAsset;
  final Widget? customIcon;
  final double iconHeight;
  final double iconWidth;
  final String title;
  final String? description;
  final Widget? content;

  // Bouton principal
  final String primaryButtonText;
  final VoidCallback? onPrimaryPressed;
  final Color? primaryButtonColor;
  final Color? primaryTextColor;
  final bool isPrimaryOutlined;

  // Bouton secondaire (optionnel, pour les confirmations à 2 boutons)
  final String? secondaryButtonText;
  final VoidCallback? onSecondaryPressed;
  final Color? secondaryButtonColor;
  final Color? secondaryTextColor;

  final VoidCallback? onClose;
  final bool showCloseButton;

  const GliftModal({
    super.key,
    this.iconAsset,
    this.customIcon,
    this.iconHeight = 35,
    this.iconWidth = 35,
    required this.title,
    this.description,
    this.content,
    this.primaryButtonText = 'Fermer',
    this.onPrimaryPressed,
    this.primaryButtonColor,
    this.primaryTextColor,
    this.isPrimaryOutlined = true,
    this.secondaryButtonText,
    this.onSecondaryPressed,
    this.secondaryButtonColor,
    this.secondaryTextColor,
    this.onClose,
    this.showCloseButton = true,
  });

  /// Affiche une modale générique
  static Future<T?> show<T>({
    required BuildContext context,
    String? iconAsset,
    Widget? customIcon,
    double iconHeight = 35,
    double iconWidth = 35,
    required String title,
    String? description,
    Widget? content,
    String primaryButtonText = 'Fermer',
    VoidCallback? onPrimaryPressed,
    Color? primaryButtonColor,
    Color? primaryTextColor,
    bool isPrimaryOutlined = true,
    String? secondaryButtonText,
    VoidCallback? onSecondaryPressed,
    Color? secondaryButtonColor,
    Color? secondaryTextColor,
    VoidCallback? onClose,
    bool showCloseButton = true,
    bool barrierDismissible = true,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (dialogContext) => GliftModal(
        iconAsset: iconAsset,
        customIcon: customIcon,
        iconHeight: iconHeight,
        iconWidth: iconWidth,
        title: title,
        description: description,
        content: content,
        primaryButtonText: primaryButtonText,
        onPrimaryPressed: onPrimaryPressed ?? () => Navigator.of(dialogContext).pop(true),
        primaryButtonColor: primaryButtonColor,
        primaryTextColor: primaryTextColor,
        isPrimaryOutlined: isPrimaryOutlined,
        secondaryButtonText: secondaryButtonText,
        onSecondaryPressed: onSecondaryPressed ?? () => Navigator.of(dialogContext).pop(false),
        secondaryButtonColor: secondaryButtonColor,
        secondaryTextColor: secondaryTextColor,
        onClose: onClose ?? () => Navigator.of(dialogContext).pop(false),
        showCloseButton: showCloseButton,
      ),
    );
  }

  /// Modale d'erreur type (icône message_erreur.svg + 1 bouton Fermer)
  static Future<void> showError({
    required BuildContext context,
    required String title,
    required String description,
    String buttonText = 'Fermer',
    VoidCallback? onPressed,
  }) {
    return show<void>(
      context: context,
      iconAsset: 'assets/icons/message_erreur.svg',
      title: title,
      description: description,
      primaryButtonText: buttonText,
      isPrimaryOutlined: true,
      onPrimaryPressed: onPressed,
    );
  }

  /// Modale de confirmation type (icône Attention + 2 boutons Annuler / Confirmer)
  static Future<bool?> showConfirm({
    required BuildContext context,
    String iconAsset = 'assets/images/Attention.svg',
    double iconHeight = 35,
    double iconWidth = 39,
    required String title,
    String? description,
    Widget? content,
    String confirmText = 'Confirmer',
    String cancelText = 'Annuler',
    Color confirmColor = const Color(0xFFEF4F4E),
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
  }) {
    return show<bool>(
      context: context,
      iconAsset: iconAsset,
      iconHeight: iconHeight,
      iconWidth: iconWidth,
      title: title,
      description: description,
      content: content,
      secondaryButtonText: cancelText,
      onSecondaryPressed: onCancel,
      primaryButtonText: confirmText,
      primaryButtonColor: confirmColor,
      primaryTextColor: Colors.white,
      isPrimaryOutlined: false,
      onPrimaryPressed: onConfirm,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool hasTwoButtons = secondaryButtonText != null;

    Widget? headerIcon;
    if (customIcon != null) {
      headerIcon = customIcon;
    } else if (iconAsset != null) {
      headerIcon = SvgPicture.asset(
        iconAsset!,
        height: iconHeight,
        width: iconWidth,
        fit: BoxFit.contain,
      );
    }

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (headerIcon != null) ...[
                  Center(child: headerIcon),
                  const SizedBox(height: 12),
                ],

                // Titre
                Text(
                  title,
                  style: GoogleFonts.quicksand(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF3A416F),
                  ),
                  textAlign: TextAlign.center,
                ),

                if (description != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    description!,
                    style: GoogleFonts.quicksand(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF3A416F),
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],

                if (content != null) ...[
                  const SizedBox(height: 14),
                  content!,
                ],

                const SizedBox(height: 24),

                // Actions (1 ou 2 boutons)
                if (hasTwoButtons)
                  Row(
                    children: [
                      // Bouton Secondaire (Annuler)
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: OutlinedButton(
                            onPressed: onSecondaryPressed ?? () => Navigator.of(context).pop(false),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: secondaryButtonColor ?? const Color(0xFF3A416F),
                                width: 1.2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                            child: Text(
                              secondaryButtonText!,
                              style: GoogleFonts.quicksand(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: secondaryTextColor ?? const Color(0xFF3A416F),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Bouton Principal (Confirmer / Action)
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: isPrimaryOutlined
                              ? OutlinedButton(
                                  onPressed: onPrimaryPressed ?? () => Navigator.of(context).pop(true),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(
                                      color: primaryButtonColor ?? const Color(0xFF3A416F),
                                      width: 1.2,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                  ),
                                  child: Text(
                                    primaryButtonText,
                                    style: GoogleFonts.quicksand(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: primaryTextColor ?? const Color(0xFF3A416F),
                                    ),
                                  ),
                                )
                              : ElevatedButton(
                                  onPressed: onPrimaryPressed ?? () => Navigator.of(context).pop(true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryButtonColor ?? const Color(0xFF7069FA),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                  ),
                                  child: Text(
                                    primaryButtonText,
                                    style: GoogleFonts.quicksand(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: primaryTextColor ?? Colors.white,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                    ],
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: isPrimaryOutlined
                        ? OutlinedButton(
                            onPressed: onPrimaryPressed ?? () => Navigator.of(context).pop(true),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: primaryButtonColor ?? const Color(0xFF3A416F),
                                width: 1.2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                            child: Text(
                              primaryButtonText,
                              style: GoogleFonts.quicksand(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: primaryTextColor ?? const Color(0xFF3A416F),
                              ),
                            ),
                          )
                        : ElevatedButton(
                            onPressed: onPrimaryPressed ?? () => Navigator.of(context).pop(true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryButtonColor ?? const Color(0xFF7069FA),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                            child: Text(
                              primaryButtonText,
                              style: GoogleFonts.quicksand(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: primaryTextColor ?? Colors.white,
                              ),
                            ),
                          ),
                  ),
              ],
            ),
          ),

          // Bouton Croix en haut à droite
          if (showCloseButton)
            Positioned(
              top: 14,
              right: 14,
              child: GestureDetector(
                onTap: onClose ?? () => Navigator.of(context).pop(false),
                behavior: HitTestBehavior.opaque,
                child: const Padding(
                  padding: EdgeInsets.all(6.0),
                  child: Icon(
                    Icons.close,
                    size: 20,
                    color: Color(0xFF3A416F),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
