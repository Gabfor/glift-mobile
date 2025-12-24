import 'package:flutter/material.dart';

import 'widgets/settings_option_page.dart';

class WeightUnitSettingsPage extends StatelessWidget {
  const WeightUnitSettingsPage({
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
      headerSubtitle: 'Unités de poids',
      options: const [
        SettingsOptionItem(value: 'metric', label: 'Métrique (kg)'),
        SettingsOptionItem(value: 'imperial', label: 'Impérial (lb)'),
      ],
      initialValue: initialValue,
      onChanged: onChanged,
    );
  }
}
