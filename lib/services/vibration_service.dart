import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

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
    return await Vibration.hasVibrator() ?? false;
  }

  @override
  Future<void> vibrate() {
    return Vibration.vibrate();
  }

  @override
  Future<void> fallback() {
    return HapticFeedback.mediumImpact();
  }
}
