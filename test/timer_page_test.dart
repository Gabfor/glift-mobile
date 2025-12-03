import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glift_mobile/services/notification_service.dart';
import 'package:glift_mobile/services/vibration_service.dart';
import 'package:glift_mobile/timer_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('plays alerts when timer completes with sound and vibration',
      (tester) async {
    final alertService = _FakeAlertService();
    final vibrationService = _FakeVibrationService(hasVibrator: true);

    await tester.pumpWidget(
      MaterialApp(
        home: TimerPage(
          durationInSeconds: 1,
          alertService: alertService,
          vibrationService: vibrationService,
        ),
      ),
    );

    await tester.pump(const Duration(seconds: 1));
    await tester.pump();

    expect(vibrationService.vibrateCount, 1);
    expect(vibrationService.fallbackCount, 0);
    expect(alertService.playSoundCount, 1);
  });

  testWidgets('uses fallback vibration when the device lacks a motor',
      (tester) async {
    final alertService = _FakeAlertService();
    final vibrationService = _FakeVibrationService(hasVibrator: false);

    await tester.pumpWidget(
      MaterialApp(
        home: TimerPage(
          durationInSeconds: 1,
          alertService: alertService,
          vibrationService: vibrationService,
        ),
      ),
    );

    await tester.pump(const Duration(seconds: 1));
    await tester.pump();

    expect(vibrationService.vibrateCount, 0);
    expect(vibrationService.fallbackCount, 1);
    expect(alertService.playSoundCount, 1);
  });
}

class _FakeAlertService implements TimerAlertService {
  int playSoundCount = 0;

  @override
  Future<void> playSound() async {
    playSoundCount++;
  }
}

class _FakeVibrationService implements VibrationService {
  _FakeVibrationService({required this.hasVibrator});

  final bool hasVibrator;
  int vibrateCount = 0;
  int fallbackCount = 0;

  @override
  Future<void> fallback() async {
    fallbackCount++;
  }

  @override
  Future<bool> hasVibrator() async {
    return hasVibrator;
  }

  @override
  Future<void> vibrate() async {
    vibrateCount++;
  }
}
