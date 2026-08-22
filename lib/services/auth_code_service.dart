import 'dart:convert';
import 'dart:io';

class AuthCodeService {
  static const String baseUrl = String.fromEnvironment(
    'GLIFT_API_BASE_URL',
    defaultValue: 'https://glift.io',
  );

  static Future<Map<String, dynamic>> sendCode({
    required String email,
    required String password,
    required String name,
    String plan = 'starter',
  }) async {
    final client = HttpClient();
    try {
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
      final data = jsonDecode(body) as Map<String, dynamic>;

      if (response.statusCode >= 200 && response.statusCode < 300 && data['success'] == true) {
        return data;
      } else {
        throw Exception(data['error'] ?? 'Une erreur est survenue.');
      }
    } finally {
      client.close();
    }
  }

  static Future<Map<String, dynamic>> verifyCode({
    required String code,
    required String token,
  }) async {
    final client = HttpClient();
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
      final data = jsonDecode(body) as Map<String, dynamic>;

      if (response.statusCode >= 200 && response.statusCode < 300 && data['success'] == true) {
        return data;
      } else {
        throw Exception(data['error'] ?? 'Code invalide ou expiré.');
      }
    } finally {
      client.close();
    }
  }
}
