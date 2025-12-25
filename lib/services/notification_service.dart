import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'settings_service.dart';

abstract class TimerAlertService {
  Future<void> playSound();
}

class NotificationService implements TimerAlertService {
  NotificationService._internal();

  static final NotificationService instance = NotificationService._internal();
  final AudioPlayer _player = AudioPlayer();

  Future<void> initialize() async {
    // No initialization required when notifications are disabled.
  }

  @override
  Future<void> playSound() async {
    try {
      if (!SettingsService.instance.getSoundEnabled()) return;
      final soundEffect = SettingsService.instance.getSoundEffect();
      
      if (soundEffect == 'none') return;
      
      String assetSource = 'sounds/bip.mp3'; // Default fallback? Or match specific values
      
      if (soundEffect == 'bip') {
        assetSource = 'sounds/bip.mp3';
      } else if (soundEffect == 'radar') {
        assetSource = 'sounds/radar.mp3';
      } else if (soundEffect == 'gong') {
        assetSource = 'sounds/gong.mp3';
      } else if (soundEffect == 'bell') {
        assetSource = 'sounds/bell.mp3';
      } else {
         // Fallback if somehow value is unknown, strictly speaking we could default to 'radar' or return.
         // Let's assume 'radar' as default if unknown, or just keys match.
         // If "radar" was default in settings service, logic holds.
         if (soundEffect.isNotEmpty) {
            assetSource = 'sounds/$soundEffect.mp3'; 
         } else {
             assetSource = 'sounds/radar.mp3';
         }
      }

      // Explicitly stop any previous sound
      await _player.stop();
      
      await _player.setSource(AssetSource(assetSource));
      // Use system volume (no setVolume call)
      await _player.resume();
      
    } catch (e) {
      debugPrint('Error playing notification sound: $e');
    }
  }
  
  void dispose() {
    _player.dispose();
  }
}
