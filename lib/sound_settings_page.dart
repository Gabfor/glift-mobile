import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

import 'widgets/settings_option_page.dart';

class SoundSettingsPage extends StatefulWidget {
  const SoundSettingsPage({
    super.key,
    required this.initialValue,
    required this.onChanged,
  });

  final String initialValue;
  final ValueChanged<String> onChanged;

  @override
  State<SoundSettingsPage> createState() => _SoundSettingsPageState();
}

class _SoundSettingsPageState extends State<SoundSettingsPage> {
  final AudioPlayer _player = AudioPlayer();

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _playSound(String value) async {
    if (value == 'none') return;
    
    try {
      await _player.stop();
      
      String assetSource = 'sounds/bip.mp3';
      if (value == 'radar') {
        assetSource = 'sounds/radar.mp3';
      } else if (value == 'gong') {
        assetSource = 'sounds/gong.mp3';
      } else if (value == 'bell') {
        assetSource = 'sounds/bell.mp3';
      }

      await _player.setSource(AssetSource(assetSource));
      // No explicit volume set means it uses system media volume
      await _player.resume();
      
    } catch (e) {
      debugPrint('Error playing sound: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SettingsOptionPage(
      headerTitle: 'Réglages',
      headerSubtitle: 'Effet sonore',
      options: const [
        SettingsOptionItem(value: 'none', label: 'Aucun'),
        SettingsOptionItem(value: 'bip', label: 'Bip'),
        SettingsOptionItem(value: 'radar', label: 'Radar'),
        SettingsOptionItem(value: 'gong', label: 'Gong'),
        SettingsOptionItem(value: 'bell', label: 'Cloche'),
      ],
      initialValue: widget.initialValue,
      onChanged: (value) {
        widget.onChanged(value);
        _playSound(value);
      },
    );
  }
}
