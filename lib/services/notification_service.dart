import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';

abstract class TimerAlertService {
  Future<void> playSound();
}

class NotificationService implements TimerAlertService {
  NotificationService._internal();

  static final NotificationService instance = NotificationService._internal();

  Future<void> initialize() async {
    // No initialization required when notifications are disabled.
  }

  @override
  Future<void> playSound() async {
    await FlutterRingtonePlayer.play(
      android: AndroidSounds.notification,
      ios: IosSounds.glass,
      looping: false,
      volume: 1.0,
      asAlarm: false,
    );
  }
}
