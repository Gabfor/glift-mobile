import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BiometricAuthException implements Exception {
  const BiometricAuthException(this.message, {this.isCancelled = false});

  final String message;
  final bool isCancelled;
}

class BiometricAuthService {
  BiometricAuthService({
    required SupabaseClient supabase,
    LocalAuthentication? localAuth,
    FlutterSecureStorage? secureStorage,
  })  : _supabase = supabase,
        _localAuth = localAuth ?? LocalAuthentication(),
        _secureStorage = secureStorage ?? const FlutterSecureStorage();

  final SupabaseClient _supabase;
  final LocalAuthentication _localAuth;
  final FlutterSecureStorage _secureStorage;

  static const _refreshTokenKey = 'biometric_refresh_token';

  Future<bool> isBiometricAvailable() async {
    try {
      final isSupported = await _localAuth.isDeviceSupported();
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;

      return isSupported && canCheckBiometrics;
    } on PlatformException {
      return false;
    }
  }

  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } on PlatformException {
      return const [];
    }
  }

  Future<String> getBiometricLabel() async {
    final biometrics = await getAvailableBiometrics();
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      if (biometrics.contains(BiometricType.face)) {
        return 'Face ID';
      }
      if (biometrics.contains(BiometricType.fingerprint)) {
        return 'Touch ID';
      }
      return 'Biométrie';
    }
    final hasFace = biometrics.contains(BiometricType.face);
    final hasFingerprint = biometrics.contains(BiometricType.fingerprint);
    if (hasFace && !hasFingerprint) {
      return 'Reconnaissance faciale';
    }
    if (hasFingerprint && !hasFace) {
      return 'Empreinte digitale';
    }
    return 'Biométrie';
  }

  Future<String> getBiometricIconAsset() async {
    final biometrics = await getAvailableBiometrics();
    final hasFace = biometrics.contains(BiometricType.face);
    final hasFingerprint = biometrics.contains(BiometricType.fingerprint);
    if (hasFace && !hasFingerprint) {
      return 'assets/icons/biometrie_face.svg';
    }
    if (defaultTargetPlatform == TargetPlatform.iOS && hasFace) {
      return 'assets/icons/biometrie_face.svg';
    }
    return 'assets/icons/biometrie_empreinte.svg';
  }

  Future<bool> hasStoredCredentials() async {
    final storedToken = await _secureStorage.read(key: _refreshTokenKey);
    return storedToken != null && storedToken.isNotEmpty;
  }

  Future<void> clearStoredCredentials() async {
    await _secureStorage.delete(key: _refreshTokenKey);
  }

  Future<void> persistSession(Session session) async {
    final refreshToken = session.refreshToken;

    if (refreshToken != null && refreshToken.isNotEmpty) {
      await _secureStorage.write(
        key: _refreshTokenKey,
        value: refreshToken,
      );
    }
  }

  Future<AuthResponse> signInWithBiometrics() async {
    final refreshToken = await _secureStorage.read(key: _refreshTokenKey);

    if (refreshToken == null || refreshToken.isEmpty) {
      throw const BiometricAuthException(
        'Aucune session biométrique enregistrée.',
      );
    }

    try {
      final reason = defaultTargetPlatform == TargetPlatform.iOS
          ? 'Déverrouille Glift avec Face ID ou Touch ID'
          : 'Déverrouille Glift avec la biométrie';

      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (!didAuthenticate) {
        throw const BiometricAuthException(
          'Authentification biométrique annulée.',
          isCancelled: true,
        );
      }

      final response = await _supabase.auth.refreshSession(refreshToken);

      final newRefreshToken = response.session?.refreshToken;
      if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
        await _secureStorage.write(
          key: _refreshTokenKey,
          value: newRefreshToken,
        );
      }

      return response;
    } on PlatformException catch (_) {
      throw const BiometricAuthException(
        'La biométrie n’est pas disponible sur cet appareil.',
      );
    } on AuthException catch (error) {
      await _secureStorage.delete(key: _refreshTokenKey);
      throw AuthException(
        error.message.isNotEmpty
            ? error.message
            : 'Impossible de rafraîchir la session biométrique.',
      );
    }
  }
}
