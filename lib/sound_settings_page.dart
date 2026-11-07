import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

import 'services/settings_service.dart';
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
  late List<RingtoneInfo> _activeRingtones;

  @override
  void initState() {
    super.initState();
    _activeRingtones = SettingsService.instance.getActiveRingtones();
    _syncLatestRingtones();
  }

  Future<void> _syncLatestRingtones() async {
    await SettingsService.instance.syncRingtones();
    if (mounted) {
      setState(() {
        _activeRingtones = SettingsService.instance.getActiveRingtones();
      });
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _playSound(String value) async {
    if (value == 'none') return;
    
    try {
      await _player.stop();
      
      final ringtone = SettingsService.instance.findRingtone(value);
      if (ringtone != null && ringtone.url.startsWith('http')) {
        await _player.setSource(UrlSource(ringtone.url));
      } else {
        final filename = ringtone?.filename ??
            (value == 'radar'
                ? 'radar.mp3'
                : value == 'bell'
                    ? 'bell.mp3'
                    : value == 'gong'
                        ? 'gong.mp3'
                        : 'bip.mp3');
        await _player.setSource(AssetSource('sounds/$filename'));
      }

      await _player.resume();
    } catch (e) {
      debugPrint('Error playing sound: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final options = [
      const SettingsOptionItem(value: 'none', label: 'Aucun'),
      ..._activeRingtones.map(
        (r) => SettingsOptionItem(value: r.soundKey, label: r.name, iconPath: r.iconUrl),
      ),
    ];

    // If current selected value is not among active options, fallback to default
    String safeInitialValue = widget.initialValue;
    final exists = options.any((opt) => opt.value == safeInitialValue);
    if (!exists) {
      safeInitialValue = SettingsService.instance.getDefaultRingtone().soundKey;
    }

    return SettingsOptionPage(
      headerTitle: 'Réglages',
      headerSubtitle: 'Sonnerie',
      options: options,
      initialValue: safeInitialValue,
      onChanged: (value) {
        widget.onChanged(value);
        _playSound(value);
      },
    );
  }
}
