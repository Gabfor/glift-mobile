import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';

abstract class TimerAlertService {
  Future<void> playSound();

  Future<void> showTimerCompletedNotification();
}

class NotificationService implements TimerAlertService {
  NotificationService._internal();

  static final NotificationService instance = NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _androidChannel =
      AndroidNotificationChannel(
    'timer_completion_channel',
    'Timer Completion',
    description: 'Notifications envoyées lorsque le timer est terminé.',
    importance: Importance.high,
  );

  bool _initialized = false;

  Future<void> initialize() async {
    const androidInitializationSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInitializationSettings = DarwinInitializationSettings();

    const initializationSettings = InitializationSettings(
      android: androidInitializationSettings,
      iOS: iosInitializationSettings,
    );

    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);

    if (Platform.isAndroid) {
      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_androidChannel);
    } else if (Platform.isIOS) {
      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    }

    _initialized = true;
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

  @override
  Future<void> showTimerCompletedNotification() async {
    if (!_initialized) return;

    await _flutterLocalNotificationsPlugin.show(
      0,
      'Timer terminé',
      'Votre minuterie est arrivée à échéance.',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          playSound: false,
        ),
        iOS: const DarwinNotificationDetails(
          presentSound: false,
        ),
      ),
    );
  }
}
