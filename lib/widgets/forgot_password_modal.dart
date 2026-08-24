import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase/supabase.dart';

import '../auth/auth_repository.dart';
import '../supabase_credentials.dart';

class ForgotPasswordModal extends StatefulWidget {
  final AuthRepository? authRepository;
  final SupabaseClient? supabase;
  final String? initialEmail;

  const ForgotPasswordModal({
    super.key,
    this.authRepository,
    this.supabase,
    this.initialEmail,
  });

  @override
  State<ForgotPasswordModal> createState() => _ForgotPasswordModalState();
}

class _ForgotPasswordModalState extends State<ForgotPasswordModal> {
  late final TextEditingController _emailController;
  final FocusNode _emailFocusNode = FocusNode();

  bool _isFocused = false;
  bool _isTouched = false;
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail ?? '');
    _emailFocusNode.addListener(() {
      setState(() {
        _isFocused = _emailFocusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _emailFocusNode.dispose();
    super.dispose();
  }

  bool get _isEmailFormatValid =>
      RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(_emailController.text.trim());

  bool get _isEmailValid =>
      _emailController.text.trim().isNotEmpty && _isEmailFormatValid;

  Color _borderColor() {
    if (_errorMessage != null) {
      return const Color(0xFFEF4444);
    }
    if (_successMessage != null) {
      return const Color(0xFF00D591);
    }
    if (_isFocused) {
      return const Color(0xFF7069FA);
    }
    if (_isTouched && _emailController.text.isNotEmpty && !_isEmailFormatValid) {
      return const Color(0xFFEF4444);
    }
    if (_isTouched && _isEmailValid) {
      return const Color(0xFF00D591);
    }
    return const Color(0xFFD7D4DC);
  }

  Color _messageColor() {
    if (_errorMessage != null ||
        (_isTouched &&
            !_isFocused &&
            !_isEmailFormatValid &&
            _emailController.text.isNotEmpty)) {
      return const Color(0xFFEF4444);
    }
    if (_successMessage != null ||
        (_isTouched && !_isFocused && _isEmailValid)) {
      return const Color(0xFF00D591);
    }
    return const Color(0xFF5D6494);
  }

  String get _displayMessage {
    if (_errorMessage != null) return _errorMessage!;
    if (_successMessage != null) return _successMessage!;
    if (_isTouched &&
        !_isFocused &&
        _emailController.text.isNotEmpty &&
        !_isEmailFormatValid) {
      return 'Format d’e-mail invalide.';
    }
    return '';
  }

  Future<void> _submit() async {
    HapticFeedback.lightImpact();
    final email = _emailController.text.trim();

    setState(() {
      _isTouched = true;
      _errorMessage = null;
      _successMessage = null;
    });

    if (!_isEmailValid) {
      setState(() {
        _errorMessage = 'Veuillez saisir une adresse e-mail valide.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      debugPrint('⏳ [ForgotPasswordModal] Sending reset email to: $email');
      final httpClient = HttpClient();
      try {
        final request = await httpClient.postUrl(Uri.parse('$supabaseUrl/auth/v1/recover'));
        request.headers.set('apikey', supabaseAnonKey);
        request.headers.set('Authorization', 'Bearer $supabaseAnonKey');
        request.headers.set('Content-Type', 'application/json');
        request.write(jsonEncode({'email': email}));
        final response = await request.close();
        final responseBody = await response.transform(utf8.decoder).join();
        debugPrint('ℹ️ [ForgotPasswordModal] Status: ${response.statusCode}, Body: $responseBody');

        if (response.statusCode == 200) {
          debugPrint('✅ [ForgotPasswordModal] Reset email sent successfully to $email');
        } else if (response.statusCode == 429) {
          throw const AuthException(
            'Veuillez patienter quelques instants avant de réessayer.',
            statusCode: '429',
          );
        } else {
          String msg = 'Impossible d’envoyer l’e-mail. Veuillez réessayer.';
          try {
            final data = jsonDecode(responseBody);
            if (data is Map && data['msg'] != null) {
              msg = data['msg'].toString();
            } else if (data is Map && data['error_description'] != null) {
              msg = data['error_description'].toString();
            }
          } catch (_) {}
          throw AuthException(msg, statusCode: response.statusCode.toString());
        }
      } finally {
        httpClient.close();
      }

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _successMessage = 'Un e-mail de réinitialisation vous a été envoyé.';
      });

      await Future.delayed(const Duration(milliseconds: 1500));
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on AuthException catch (e) {
      debugPrint('❌ [ForgotPasswordModal] AuthException: ${e.message} (status: ${e.statusCode})');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        if (e.statusCode == '429' ||
            e.message.toLowerCase().contains('rate') ||
            e.message.toLowerCase().contains('wait')) {
          _errorMessage = 'Veuillez patienter quelques instants avant de réessayer.';
        } else {
          _errorMessage = e.message;
        }
      });
    } catch (e) {
      debugPrint('❌ [ForgotPasswordModal] Error: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Impossible d’envoyer l’e-mail. Veuillez réessayer.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icône Cadenas Violet
                Center(
                  child: SvgPicture.asset(
                    'assets/icons/cadena_violet.svg',
                    height: 44,
                    width: 44,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 12),

                // Titre
                Text(
                  'Mot de passe oublié ?',
                  style: GoogleFonts.quicksand(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF3A416F),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                // Description
                Text(
                  'Pas de problèmes, nous allons t’envoyer un lien pour que tu puisses choisir un nouveau mot de passe en toute sécurité.',
                  style: GoogleFonts.quicksand(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF5D6494),
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),

                // Champ Email
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Email',
                      style: GoogleFonts.quicksand(
                        color: const Color(0xFF3A416F),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(
                          color: _borderColor(),
                          width: 1.0,
                        ),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Center(
                        child: TextField(
                          controller: _emailController,
                          focusNode: _emailFocusNode,
                          keyboardType: TextInputType.emailAddress,
                          autocorrect: false,
                          style: GoogleFonts.quicksand(
                            color: const Color(0xFF5D6494),
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: 'john.doe@email.com',
                            hintStyle: GoogleFonts.quicksand(
                              color: const Color(0xFFD7D4DC),
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14.5),
                          ),
                          onChanged: (_) {
                            setState(() {
                              _isTouched = true;
                              _errorMessage = null;
                              _successMessage = null;
                            });
                          },
                          onSubmitted: (_) => _submit(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    SizedBox(
                      height: 18,
                      child: Text(
                        _displayMessage,
                        style: GoogleFonts.quicksand(
                          color: _messageColor(),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Boutons Annuler & Valider
                Row(
                  children: [
                    // Annuler
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          onPressed: _isLoading
                              ? null
                              : () => Navigator.of(context).pop(false),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: Color(0xFF3A416F),
                              width: 1.2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: Text(
                            'Annuler',
                            style: GoogleFonts.quicksand(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF3A416F),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Valider
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isEmailValid && !_isLoading
                              ? _submit
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7069FA),
                            disabledBackgroundColor: const Color(0xFFF2F1F6),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: _isLoading
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          Color(0xFFD7D4DC),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'En cours...',
                                      style: GoogleFonts.quicksand(
                                        color: const Color(0xFFD7D4DC),
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                )
                              : Text(
                                  'Valider',
                                  style: GoogleFonts.quicksand(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: _isEmailValid
                                        ? Colors.white
                                        : const Color(0xFFD7D4DC),
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Bouton Croix en haut à droite
          Positioned(
            top: 14,
            right: 14,
            child: GestureDetector(
              onTap: _isLoading ? null : () => Navigator.of(context).pop(false),
              behavior: HitTestBehavior.opaque,
              child: const Padding(
                padding: EdgeInsets.all(6.0),
                child: Icon(
                  Icons.close,
                  size: 20,
                  color: Color(0xFF3A416F),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
