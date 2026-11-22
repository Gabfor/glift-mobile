import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:glift_mobile/auth/auth_repository.dart';
import 'package:glift_mobile/auth/biometric_auth_service.dart';
import 'package:glift_mobile/login_page.dart';
import 'package:glift_mobile/services/settings_service.dart';

class _FakeAuthRepository implements AuthRepository {
  @override
  Future<Session> signInWithPassword({
    required String email,
    required String password,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> sendPasswordReset({required String email}) async {}
}

class _FakeBiometricAuthService extends BiometricAuthService {
  _FakeBiometricAuthService({
    required super.supabase,
    this.available = true,
    this.hasCredentials = true,
    this.label = 'Face ID',
  });

  bool available;
  bool hasCredentials;
  String label;
  int signInCalls = 0;

  @override
  Future<bool> isBiometricAvailable() async => available;

  @override
  Future<bool> hasStoredCredentials() async => hasCredentials;

  @override
  Future<String> getBiometricLabel() async => label;

  @override
  Future<void> clearStoredCredentials() async {
    hasCredentials = false;
  }

  @override
  Future<AuthResponse> signInWithBiometrics() async {
    signInCalls++;
    return AuthResponse();
  }
}

void main() {
  final supabase = SupabaseClient(
    'https://test.supabase.co',
    'public-anon-key',
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SettingsService.instance.init();
    await SettingsService.instance.saveBiometricEnabled(true);
  });

  testWidgets('Shows biometric login button when available and credentials exist',
      (tester) async {
    final biometricService = _FakeBiometricAuthService(
      supabase: supabase,
      available: true,
      hasCredentials: true,
      label: 'Face ID',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: LoginPage(
          authRepository: _FakeAuthRepository(),
          supabase: supabase,
          biometricAuthService: biometricService,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('biometricLoginButton')), findsOneWidget);
    expect(find.text('Se connecter avec Face ID'), findsOneWidget);

    await tester.tap(find.byKey(const Key('biometricLoginButton')));
    await tester.pumpAndSettle();

    expect(biometricService.signInCalls, 1);
  });

  testWidgets('Hides biometric login button when no stored credentials',
      (tester) async {
    final biometricService = _FakeBiometricAuthService(
      supabase: supabase,
      available: true,
      hasCredentials: false,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: LoginPage(
          authRepository: _FakeAuthRepository(),
          supabase: supabase,
          biometricAuthService: biometricService,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('biometricLoginButton')), findsNothing);
  });

  testWidgets('Hides biometric login button when disabled in settings',
      (tester) async {
    await SettingsService.instance.saveBiometricEnabled(false);

    final biometricService = _FakeBiometricAuthService(
      supabase: supabase,
      available: true,
      hasCredentials: true,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: LoginPage(
          authRepository: _FakeAuthRepository(),
          supabase: supabase,
          biometricAuthService: biometricService,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('biometricLoginButton')), findsNothing);
  });
}
