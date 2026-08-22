import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

class AuthCodeService {
  static List<String> get candidateBaseUrls {
    const envUrl = String.fromEnvironment('GLIFT_API_BASE_URL', defaultValue: '');
    final candidates = <String>[];
    if (envUrl.isNotEmpty) candidates.add(envUrl);
    candidates.add('http://192.168.1.181:3000');
    candidates.add('http://127.0.0.1:3000');
    candidates.add('http://localhost:3000');
    candidates.add('https://glift.io');
    return candidates;
  }

  static Future<Map<String, dynamic>> sendCode({
    required String email,
    required String password,
    required String name,
    String plan = 'starter',
  }) async {
    Object? lastError;
    for (final baseUrl in candidateBaseUrls) {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 4);
      try {
        debugPrint('🔍 [AuthCodeService] Attempting sendCode via $baseUrl/api/auth/send-code');
        final uri = Uri.parse('$baseUrl/api/auth/send-code');
        final request = await client.postUrl(uri);
        request.headers.contentType = ContentType.json;
        request.write(jsonEncode({
          'email': email,
          'password': password,
          'name': name,
          'plan': plan,
        }));
        final response = await request.close();
        final body = await response.transform(utf8.decoder).join();

        Map<String, dynamic> data;
        try {
          data = jsonDecode(body) as Map<String, dynamic>;
        } catch (_) {
          debugPrint('⚠️ [AuthCodeService] Non-JSON response from $baseUrl: status ${response.statusCode}');
          continue;
        }

        if (response.statusCode >= 200 && response.statusCode < 300 && data['success'] == true) {
          debugPrint('✅ [AuthCodeService] sendCode success from $baseUrl');
          return data;
        } else if (response.statusCode >= 400 && data.containsKey('error')) {
          debugPrint('❌ [AuthCodeService] API error from $baseUrl: ${data['error']}');
          throw Exception(data['error']);
        }
      } catch (e) {
        if (e is Exception && e.toString().startsWith('Exception: ')) {
          rethrow;
        }
        debugPrint('⚠️ [AuthCodeService] Error from $baseUrl: $e');
        lastError = e;
      } finally {
        client.close();
      }
    }
    throw Exception(
      lastError?.toString().replaceAll('Exception: ', '') ??
          'Impossible de contacter le serveur d’authentification.',
    );
  }

  static Future<Map<String, dynamic>> verifyCode({
    required String code,
    required String token,
  }) async {
    Object? lastError;
    for (final baseUrl in candidateBaseUrls) {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 4);
      try {
        final uri = Uri.parse('$baseUrl/api/auth/verify-code');
        final request = await client.postUrl(uri);
        request.headers.contentType = ContentType.json;
        request.write(jsonEncode({
          'code': code,
          'token': token,
        }));
        final response = await request.close();
        final body = await response.transform(utf8.decoder).join();

        Map<String, dynamic> data;
        try {
          data = jsonDecode(body) as Map<String, dynamic>;
        } catch (_) {
          continue;
        }

        if (response.statusCode >= 200 && response.statusCode < 300 && data['success'] == true) {
          return data;
        } else if (response.statusCode >= 400 && data.containsKey('error')) {
          throw Exception(data['error']);
        }
      } catch (e) {
        if (e is Exception && e.toString().startsWith('Exception: ')) {
          rethrow;
        }
        lastError = e;
      } finally {
        client.close();
      }
    }
    throw Exception(
      lastError?.toString().replaceAll('Exception: ', '') ??
          'Code invalide ou expiré.',
    );
  }
}
