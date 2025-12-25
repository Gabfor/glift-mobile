import 'package:flutter/material.dart';

import 'widgets/settings_option_page.dart';

class DisplaySettingsPage extends StatelessWidget {
  const DisplaySettingsPage({
    super.key,
    required this.initialValue,
    required this.onChanged,
  });

  final String initialValue;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SettingsOptionPage(
      headerTitle: 'Réglages',
      headerSubtitle: 'Type d\'affichage',
      options: const [
        SettingsOptionItem(value: 'Miniature', label: 'Miniature'),
        SettingsOptionItem(value: 'Plein écran', label: 'Plein écran'),
      ],
      initialValue: initialValue,
      onChanged: onChanged,
    );
  }
}
