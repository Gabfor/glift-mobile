import 'package:supabase/supabase.dart';

import '../supabase_credentials.dart';

abstract class AuthRepository {
  Future<Session> signInWithPassword({
    required String email,
    required String password,
  });

  Future<void> sendPasswordReset({required String email});
}

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this.supabase);

  final SupabaseClient supabase;

  @override
  Future<Session> signInWithPassword({
    required String email,
    required String password,
  }) async {
    try {
      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final session = response.session;

      if (session == null) {
        throw const AuthException(
          'Identifiants invalides. Vérifiez votre email et votre mot de passe.',
        );
      }

      return session;
    } on AuthException catch (error) {
      if (error.message == 'Invalid login credentials') {
        throw const AuthException('Email ou mot de passe incorrect.');
      }

      throw AuthException(
        error.message.isNotEmpty
            ? error.message
            : 'Identifiants invalides. Vérifiez votre email et votre mot de passe.',
      );
    } catch (_) {
      throw const AuthException(
        'Service temporairement indisponible. Réessayez plus tard.',
      );
    }
  }

  @override
  Future<void> sendPasswordReset({required String email}) async {
    try {
      await supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: '$supabaseUrl/auth-callback',
      );
    } on AuthException catch (error) {
      throw AuthException(
        error.message.isNotEmpty
            ? error.message
            : 'Impossible d’envoyer l’email de réinitialisation pour le moment.',
      );
    } catch (_) {
      throw const AuthException(
        'Impossible d’envoyer l’email de réinitialisation pour le moment.',
      );
    }
  }
}
