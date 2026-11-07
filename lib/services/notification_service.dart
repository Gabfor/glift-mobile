import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'settings_service.dart';

abstract class TimerAlertService {
  Future<void> playSound();
  Future<void> scheduleTimerNotification({required DateTime scheduledTime});
  Future<void> cancelTimerNotification();
}

class NotificationService implements TimerAlertService {
  NotificationService._internal();

  static final NotificationService instance = NotificationService._internal();
  AudioPlayer? _player;
  AudioPlayer get _audioPlayer => _player ??= AudioPlayer();
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    tz.initializeTimeZones();
    
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
        
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: false,
            requestSoundPermission: true);
            
    const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsDarwin,
        macOS: initializationSettingsDarwin);
        
    await flutterLocalNotificationsPlugin.initialize(
        settings: initializationSettings);
  }

  @override
  Future<void> playSound() async {
    try {
      if (!SettingsService.instance.getSoundEnabled()) return;
      final soundEffect = SettingsService.instance.getSoundEffect();
      
      if (soundEffect == 'none') return;
      
      final ringtone = SettingsService.instance.findRingtone(soundEffect);

      // Explicitly stop any previous sound
      await _audioPlayer.stop();

      if (ringtone != null && ringtone.url.startsWith('http')) {
        await _audioPlayer.setSource(UrlSource(ringtone.url));
      } else {
        final filename = ringtone?.filename ??
            (soundEffect == 'radar'
                ? 'radar.mp3'
                : soundEffect == 'bell'
                    ? 'bell.mp3'
                    : soundEffect == 'gong'
                        ? 'gong.mp3'
                        : 'bip.mp3');
        await _audioPlayer.setSource(AssetSource('sounds/$filename'));
      }

      // Use system volume (no setVolume call)
      await _audioPlayer.resume();
      
    } catch (e) {
      debugPrint('Error playing notification sound: $e');
    }
  }

  @override
  Future<void> scheduleTimerNotification({required DateTime scheduledTime}) async {
    if (!SettingsService.instance.getSoundEnabled()) return;

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
            'glift_timer_channel', 'Glift Timer Notifications',
            channelDescription: 'Notifications for completed rest timers',
            importance: Importance.max,
            priority: Priority.high,
            );
            
    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
            presentSound: true,
            presentAlert: true,
        );
        
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics, iOS: iOSPlatformChannelSpecifics);

    final delay = scheduledTime.difference(DateTime.now());
    if (delay.isNegative) return;

    await flutterLocalNotificationsPlugin.zonedSchedule(
        id: 0, // Notification ID
        title: 'Temps de repos terminé !',
        body: 'Il est temps de reprendre l\'entraînement 💪',
        scheduledDate: tz.TZDateTime.now(tz.local).add(delay),
        notificationDetails: platformChannelSpecifics,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle);
  }

  @override
  Future<void> cancelTimerNotification() async {
    await flutterLocalNotificationsPlugin.cancel(id: 0);
  }
  
  void dispose() {
    _player?.dispose();
  }
}
