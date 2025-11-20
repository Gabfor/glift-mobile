import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase/supabase.dart';

import 'auth/auth_repository.dart';
import 'theme/glift_theme.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key, required this.authRepository});

  final AuthRepository authRepository;

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();

  bool _isLoading = false;
  String? _feedback;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  String? _validateEmail(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return 'Veuillez saisir un email valide.';
    }
    final emailRegex = RegExp(r"^[\\w-.]+@([\\w-]+\\.)+[\\w-]{2,4}\\$");
    if (!emailRegex.hasMatch(trimmed)) {
      return 'Format d’email invalide.';
    }
    return null;
  }

  Future<void> _submit() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    setState(() {
      _isLoading = true;
      _feedback = null;
    });

    try {
      await widget.authRepository
          .sendPasswordReset(email: _emailController.text.trim());
      setState(() {
        _feedback =
            'Email envoyé ! Vérifiez votre boîte de réception pour réinitialiser votre mot de passe.';
      });
    } on AuthException catch (error) {
      setState(() {
        _feedback = error.message;
      });
    } catch (_) {
      setState(() {
        _feedback =
            'Service temporairement indisponible. Réessayez plus tard.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Mot de passe oublié'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Recevez un lien de réinitialisation par email.',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: GliftTheme.title,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                ),
                validator: _validateEmail,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Envoyer'),
                ),
              ),
              if (_feedback != null) ...[
                const SizedBox(height: 16),
                Text(
                  _feedback!,
                  style: GoogleFonts.inter(
                    color: _feedback!.startsWith('Email envoyé')
                        ? Colors.green
                        : const Color(0xFFE74C3C),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
