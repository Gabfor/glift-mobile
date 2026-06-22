import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

abstract class VibrationService {
  const VibrationService();

  Future<bool> hasVibrator();

  Future<void> vibrate();

  Future<void> fallback();
}

class DeviceVibrationService extends VibrationService {
  const DeviceVibrationService();

  @override
  Future<bool> hasVibrator() async {
    // Most physical devices support haptic feedback/vibration.
    // Returning true ensures vibrate() is called. If not supported by hardware,
    // Flutter's HapticFeedback API handles it gracefully without throwing or crashing.
    return true;
  }

  @override
  Future<void> vibrate() async {
    try {
      await HapticFeedback.vibrate();
    } catch (e) {
      debugPrint('Error triggering vibration: $e');
    }
  }

  @override
  Future<void> fallback() async {
    try {
      await HapticFeedback.mediumImpact();
    } catch (e) {
      debugPrint('Error triggering haptic fallback: $e');
    }
  }
}
