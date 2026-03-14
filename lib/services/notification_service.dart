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
  final AudioPlayer _player = AudioPlayer();
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

  @override
  Future<void> scheduleTimerNotification({required DateTime scheduledTime}) async {
    if (!SettingsService.instance.getSoundEnabled()) return;
    final soundEffect = SettingsService.instance.getSoundEffect();
    
    // Default system sound or specific raw resource
    // For iOS, sound names normally need to be bundled and specified. Default is often fine.
    // For Android, we can specify raw sound if we have them in res/raw (bip, radar, etc.)
    // If not, we just use the default system notification sound.
    String androidSoundName = 'radar';
    if (['bip', 'radar', 'gong', 'bell'].contains(soundEffect)) {
       // androidSoundName = soundEffect;
    }
    
    // Using default notification sound for simplicity if custom ones are not registered in Android resources
    // In a real scenario, you'd place bip.mp3 -> bip.mp3 in android/app/src/main/res/raw/
    // Let's rely on the default sound for now to ensure it plays, since we don't have the raw files set up
    // in Android/iOS native assets.

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
            'glift_timer_channel', 'Glift Timer Notifications',
            channelDescription: 'Notifications for completed rest timers',
            importance: Importance.max,
            priority: Priority.high,
            // playSound: true,
            // sound: RawResourceAndroidNotificationSound(androidSoundName), // Requires files in raw/
            );
            
    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
            // sound: '$soundEffect.mp3', // Requires copy bundle resources
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
    _player.dispose();
  }
}
