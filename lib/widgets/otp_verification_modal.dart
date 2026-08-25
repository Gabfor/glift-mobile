import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase/supabase.dart';

import '../auth/auth_repository.dart';
import '../auth/biometric_auth_service.dart';
import '../main_page.dart';
import '../services/auth_code_service.dart';

class OtpVerificationModal extends StatefulWidget {
  final String email;
  final String password;
  final String name;
  final String initialToken;
  final SupabaseClient? supabase;
  final AuthRepository? authRepository;
  final BiometricAuthService? biometricAuthService;

  const OtpVerificationModal({
    super.key,
    required this.email,
    required this.password,
    required this.name,
    required this.initialToken,
    this.supabase,
    this.authRepository,
    this.biometricAuthService,
  });

  @override
  State<OtpVerificationModal> createState() => _OtpVerificationModalState();
}

class _OtpVerificationModalState extends State<OtpVerificationModal> {
  late String _token;
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;

  bool _isValidating = false;
  bool _isResending = false;
  bool _hasError = false;
  bool _hasResent = false;
  int _focusedIndex = -1;

  @override
  void initState() {
    super.initState();
    _token = widget.initialToken;
    _controllers = List.generate(6, (_) => TextEditingController());
    _focusNodes = List.generate(6, (index) => FocusNode());

    for (int i = 0; i < 6; i++) {
      _focusNodes[i].addListener(() {
        if (_focusNodes[i].hasFocus) {
          setState(() {
            _focusedIndex = i;
          });
        } else if (_focusedIndex == i) {
          setState(() {
            _focusedIndex = -1;
          });
        }
      });
    }

    // Auto-focus first input after modal opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNodes[0].requestFocus();
      }
    });
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  bool get _isComplete =>
      _controllers.every((controller) => controller.text.trim().isNotEmpty);

  String get _fullCode =>
      _controllers.map((c) => c.text.trim()).join();

  void _onDigitChanged(int index, String value) {
    if (_hasError) {
      setState(() {
        _hasError = false;
      });
    }

    // Gérer le copier-coller éventuel d'un code complet ou l'autofill iOS
    final cleanDigits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanDigits.length > 1) {
      for (int i = 0; i < 6; i++) {
        _controllers[i].text =
            i < cleanDigits.length ? cleanDigits[i] : '';
      }
      final nextIndex = cleanDigits.length < 6 ? cleanDigits.length : 5;
      _focusNodes[nextIndex].requestFocus();
      setState(() {});
      return;
    }

    if (cleanDigits.isNotEmpty) {
      _controllers[index].text = cleanDigits.substring(cleanDigits.length - 1);
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      }
    } else {
      _controllers[index].text = '';
    }

    setState(() {});
  }

  void _handleBackspace(int index) {
    if (_controllers[index].text.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
      _controllers[index - 1].text = '';
      setState(() {});
    }
  }

  Future<void> _handleResend() async {
    if (_isResending || _isValidating) return;

    HapticFeedback.lightImpact();
    setState(() {
      _isResending = true;
      _hasError = false;
      _hasResent = false;
    });

    try {
      final res = await AuthCodeService.sendCode(
        email: widget.email,
        password: widget.password,
        name: widget.name,
      );

      _token = res['token'] as String;
      for (final controller in _controllers) {
        controller.clear();
      }

      if (!mounted) return;
      setState(() {
        _hasResent = true;
        _isResending = false;
      });
      _focusNodes[0].requestFocus();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isResending = false;
      });
    }
  }

  Future<void> _handleValidate() async {
    if (!_isComplete || _isValidating) return;

    HapticFeedback.lightImpact();
    setState(() {
      _isValidating = true;
      _hasError = false;
    });

    try {
      final res = await AuthCodeService.verifyCode(
        code: _fullCode,
        token: _token,
      );

      final client = widget.supabase;
      if (client != null) {
        final sessionPayload = res['session'] as Map<String, dynamic>?;
        if (sessionPayload != null && sessionPayload['refresh_token'] != null) {
          try {
            final authRes = await client.auth.refreshSession(
              sessionPayload['refresh_token'] as String,
            );
            if (authRes.session != null && widget.biometricAuthService != null) {
              await widget.biometricAuthService!.persistSession(authRes.session!);
            }
          } catch (_) {
            // Fallback de connexion directe avec mot de passe
            final authRes = await client.auth.signInWithPassword(
              email: widget.email,
              password: widget.password,
            );
            if (authRes.session != null && widget.biometricAuthService != null) {
              await widget.biometricAuthService!.persistSession(authRes.session!);
            }
          }
        }
      }

      if (!mounted) return;

      // Fermer la modale
      Navigator.of(context).pop(true);

      // Rediriger vers l'application principale
      if (client != null &&
          widget.authRepository != null &&
          widget.biometricAuthService != null) {
        await Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => MainPage(
              supabase: client,
              authRepository: widget.authRepository!,
              biometricAuthService: widget.biometricAuthService!,
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _isValidating = false;
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
                // Icône Cadenas (Violet ou Rouge selon l'état d'erreur)
                Center(
                  child: SvgPicture.asset(
                    _hasError
                        ? 'assets/icons/cadena_rouge.svg'
                        : 'assets/icons/cadena_violet.svg',
                    height: 35,
                    width: 35,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 12),

                // Titre
                Text(
                  'Code de validation',
                  style: GoogleFonts.quicksand(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF3A416F),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                // Description contextualisée
                Text(
                  _hasError
                      ? 'Nous sommes désolés mais le code est invalide ou expiré. Merci de vérifier ton code ou de demander à recevoir un nouveau code.'
                      : _hasResent
                          ? 'Un nouveau code a été envoyé par e-mail.'
                          : 'Pour finaliser la création de ton compte, saisis le code de validation à 6 chiffres que nous venons de t’envoyer par email.',
                  style: GoogleFonts.quicksand(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _hasError
                        ? const Color(0xFFE34A4A)
                        : _hasResent
                            ? const Color(0xFF00D591)
                            : const Color(0xFF5D6494),
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),

                // Les 6 cases pour le code OTP
                AutofillGroup(
                  child: Row(
                    children: List.generate(6, (index) {
                      final isFocused = _focusedIndex == index;
                      return Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          height: 46,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(
                              color: _hasError
                                  ? const Color(0xFFEF4444)
                                  : isFocused
                                      ? const Color(0xFF7069FA)
                                      : const Color(0xFFD7D4DC),
                              width: 1.0,
                            ),
                          ),
                          child: Center(
                            child: KeyboardListener(
                              focusNode: FocusNode(),
                              onKeyEvent: (event) {
                                if (event is KeyDownEvent &&
                                    event.logicalKey ==
                                        LogicalKeyboardKey.backspace) {
                                  _handleBackspace(index);
                                }
                              },
                              child: TextField(
                                controller: _controllers[index],
                                focusNode: _focusNodes[index],
                                textAlign: TextAlign.center,
                                keyboardType: TextInputType.number,
                                autofillHints: const [AutofillHints.oneTimeCode],
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(6),
                                ],
                                style: GoogleFonts.quicksand(
                                  color: const Color(0xFF5D6494),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintText: '0',
                                  hintStyle: GoogleFonts.quicksand(
                                    color: const Color(0xFFD7D4DC),
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  contentPadding: EdgeInsets.zero,
                                ),
                                onChanged: (val) => _onDigitChanged(index, val),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 14),

                // Bouton "Renvoyer le code"
                GestureDetector(
                  onTap: _isResending || _isValidating ? null : _handleResend,
                  child: _isResending
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF7069FA),
                          ),
                        )
                      : Text(
                          'Renvoyer le code',
                          style: GoogleFonts.quicksand(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF7069FA),
                          ),
                        ),
                ),
                const SizedBox(height: 22),

                // Boutons d'action : Annuler & Valider
                Row(
                  children: [
                    // Annuler
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          onPressed: _isValidating
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
                          onPressed: _isComplete && !_isValidating
                              ? _handleValidate
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7069FA),
                            disabledBackgroundColor: const Color(0xFFF2F1F6),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: _isValidating
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
                                    color: _isComplete
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

          // Bouton Fermer (Croix en haut à droite)
          Positioned(
            right: 8,
            top: 8,
            child: IconButton(
              icon: const Icon(Icons.close),
              color: const Color(0xFF5D6494),
              iconSize: 22,
              onPressed: _isValidating
                  ? null
                  : () => Navigator.of(context).pop(false),
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(),
              style: IconButton.styleFrom(
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
