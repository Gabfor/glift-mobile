import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../auth/auth_repository.dart';
import '../auth/biometric_auth_service.dart';
import '../supabase_credentials.dart';
import 'glift_modal.dart';

enum _ForgotPasswordStep { email, otp, newPassword, success }

class ForgotPasswordModal extends StatefulWidget {
  final AuthRepository? authRepository;
  final SupabaseClient? supabase;
  final BiometricAuthService? biometricAuthService;
  final String? initialEmail;

  const ForgotPasswordModal({
    super.key,
    this.authRepository,
    this.supabase,
    this.biometricAuthService,
    this.initialEmail,
  });

  @override
  State<ForgotPasswordModal> createState() => _ForgotPasswordModalState();
}

class _ForgotPasswordModalState extends State<ForgotPasswordModal> {
  _ForgotPasswordStep _step = _ForgotPasswordStep.email;

  // Step 1 : Email
  late final TextEditingController _emailController;
  final FocusNode _emailFocusNode = FocusNode();
  bool _isEmailFocused = false;
  bool _isEmailTouched = false;
  bool _isLoading = false;
  String? _emailErrorMessage;

  // Step 2 : OTP
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());
  int _focusedOtpIndex = -1;
  bool _hasOtpError = false;

  // Step 3 : Nouveau mot de passe
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final FocusNode _newPasswordFocusNode = FocusNode();
  final FocusNode _confirmPasswordFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  bool _isNewPasswordFocused = false;
  bool _isConfirmPasswordFocused = false;
  bool _isNewPasswordTouched = false;
  bool _isConfirmPasswordTouched = false;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail ?? '');
    _emailFocusNode.addListener(() {
      setState(() {
        _isEmailFocused = _emailFocusNode.hasFocus;
      });
    });

    for (int i = 0; i < 6; i++) {
      final index = i;
      _otpFocusNodes[index].addListener(() {
        if (_otpFocusNodes[index].hasFocus) {
          setState(() {
            _focusedOtpIndex = index;
          });
        }
      });
    }

    _newPasswordFocusNode.addListener(() {
      setState(() {
        _isNewPasswordFocused = _newPasswordFocusNode.hasFocus;
        if (_isNewPasswordFocused) _isNewPasswordTouched = true;
      });
      if (_newPasswordFocusNode.hasFocus) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (!mounted) return;
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              120.0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    });

    _confirmPasswordFocusNode.addListener(() {
      setState(() {
        _isConfirmPasswordFocused = _confirmPasswordFocusNode.hasFocus;
        if (_isConfirmPasswordFocused) _isConfirmPasswordTouched = true;
      });
      if (_confirmPasswordFocusNode.hasFocus) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (!mounted) return;
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _emailController.dispose();
    _emailFocusNode.dispose();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _otpFocusNodes) {
      f.dispose();
    }
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _newPasswordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  SupabaseClient get _client =>
      widget.supabase ??
      (widget.authRepository is SupabaseAuthRepository
          ? (widget.authRepository as SupabaseAuthRepository).supabase
          : SupabaseClient(supabaseUrl, supabaseAnonKey));

  // Validation Email (Step 1)
  bool get _isEmailFormatValid =>
      RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(_emailController.text.trim());

  bool get _isEmailValid =>
      _emailController.text.trim().isNotEmpty && _isEmailFormatValid;

  Color _emailBorderColor() {
    if (_emailErrorMessage != null) {
      return const Color(0xFFEF4444);
    }
    if (_isEmailFocused) {
      return const Color(0xFF7069FA);
    }
    if (_isEmailTouched && _emailController.text.isNotEmpty && !_isEmailFormatValid) {
      return const Color(0xFFEF4444);
    }
    if (_isEmailTouched && _isEmailValid) {
      return const Color(0xFF00D591);
    }
    return const Color(0xFFD7D4DC);
  }

  Color _emailMessageColor() {
    if (_emailErrorMessage != null ||
        (_isEmailTouched &&
            !_isEmailFocused &&
            !_isEmailFormatValid &&
            _emailController.text.isNotEmpty)) {
      return const Color(0xFFEF4444);
    }
    if (_isEmailTouched && !_isEmailFocused && _isEmailValid) {
      return const Color(0xFF00D591);
    }
    return const Color(0xFF5D6494);
  }

  String get _emailDisplayMessage {
    if (_emailErrorMessage != null) return _emailErrorMessage!;
    if (_isEmailTouched &&
        !_isEmailFocused &&
        _emailController.text.isNotEmpty &&
        !_isEmailFormatValid) {
      return 'Format d’e-mail invalide.';
    }
    return '';
  }

  // Validation OTP (Step 2)
  String get _fullOtpCode => _otpControllers.map((c) => c.text).join();
  bool get _isOtpComplete => _fullOtpCode.length == 6 && RegExp(r'^\d{6}$').hasMatch(_fullOtpCode);

  void _onOtpDigitChanged(int index, String value) {
    setState(() {
      _hasOtpError = false;
    });

    final digitsOnly = value.replaceAll(RegExp(r'\D'), '');

    if (digitsOnly.length >= 6) {
      for (int i = 0; i < 6; i++) {
        _otpControllers[i].text = digitsOnly[i];
      }
      _otpFocusNodes[5].requestFocus();
      return;
    }

    if (value.length > 1) {
      final lastDigit = value.substring(value.length - 1);
      _otpControllers[index].text = lastDigit;
    }

    if (_otpControllers[index].text.isNotEmpty && index < 5) {
      _otpFocusNodes[index + 1].requestFocus();
    }
  }

  void _onOtpBackspace(int index) {
    setState(() {
      _hasOtpError = false;
    });
    if (_otpControllers[index].text.isEmpty && index > 0) {
      _otpFocusNodes[index - 1].requestFocus();
    }
  }

  // Validation Password (Step 3)
  bool get _isNewPasswordLengthValid => _newPasswordController.text.length >= 8;
  bool get _hasPasswordLetter => RegExp(r'[a-zA-Z]').hasMatch(_newPasswordController.text);
  bool get _hasPasswordNumber => RegExp(r'[0-9]').hasMatch(_newPasswordController.text);
  bool get _hasPasswordSymbol => RegExp(r'[!@#$%^&*(),.?":{}|<>_\-]').hasMatch(_newPasswordController.text);

  bool get _isNewPasswordValid =>
      _isNewPasswordLengthValid &&
      _hasPasswordLetter &&
      _hasPasswordNumber &&
      _hasPasswordSymbol;

  bool get _hasConfirmMinLength => _confirmPasswordController.text.length >= 8;
  bool get _hasConfirmLetter => RegExp(r'[a-zA-Z]').hasMatch(_confirmPasswordController.text);
  bool get _hasConfirmNumber => RegExp(r'[0-9]').hasMatch(_confirmPasswordController.text);
  bool get _hasConfirmSymbol => RegExp(r'[!@#$%^&*(),.?":{}|<>_\-]').hasMatch(_confirmPasswordController.text);

  bool get _doPasswordsMatch =>
      _confirmPasswordController.text.isNotEmpty &&
      _confirmPasswordController.text == _newPasswordController.text;

  bool get _isPasswordFormValid =>
      _isNewPasswordValid && _doPasswordsMatch;

  Widget _buildCriteriaBox({
    required bool hasMinLength,
    required bool hasLetter,
    required bool hasNumber,
    required bool hasSymbol,
  }) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F000000),
            blurRadius: 9,
            spreadRadius: 1,
            offset: Offset(1, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          _PasswordCriteriaItem(
            valid: hasMinLength,
            text: 'Au moins 8 caractères',
          ),
          const SizedBox(height: 8),
          _PasswordCriteriaItem(
            valid: hasLetter,
            text: 'Au moins 1 lettre',
          ),
          const SizedBox(height: 8),
          _PasswordCriteriaItem(
            valid: hasNumber,
            text: 'Au moins 1 chiffre',
          ),
          const SizedBox(height: 8),
          _PasswordCriteriaItem(
            valid: hasSymbol,
            text: 'Au moins 1 symbole',
          ),
        ],
      ),
    );
  }

  // --- ACTIONS ---

  // Étape 1 : Envoi de l'e-mail de récupération
  Future<void> _handleSendEmail() async {
    HapticFeedback.lightImpact();
    final email = _emailController.text.trim();

    setState(() {
      _isEmailTouched = true;
      _emailErrorMessage = null;
    });

    if (!_isEmailValid) {
      setState(() {
        _emailErrorMessage = 'Veuillez saisir une adresse e-mail valide.';
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
        _step = _ForgotPasswordStep.otp;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _otpFocusNodes[0].canRequestFocus) {
          _otpFocusNodes[0].requestFocus();
        }
      });
    } on AuthException catch (e) {
      debugPrint('❌ [ForgotPasswordModal] AuthException: ${e.message}');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        if (e.statusCode == '429' ||
            e.message.toLowerCase().contains('rate') ||
            e.message.toLowerCase().contains('wait')) {
          _emailErrorMessage = 'Veuillez patienter quelques instants avant de réessayer.';
        } else {
          _emailErrorMessage = e.message;
        }
      });
    } catch (e) {
      debugPrint('❌ [ForgotPasswordModal] Error: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _emailErrorMessage = 'Impossible d’envoyer l’e-mail. Veuillez réessayer.';
      });
    }
  }

  // Étape 2 : Vérification du code OTP
  Future<void> _handleVerifyOtp() async {
    HapticFeedback.lightImpact();
    FocusScope.of(context).unfocus();

    if (!_isOtpComplete || _isLoading) return;

    setState(() {
      _isLoading = true;
      _hasOtpError = false;
    });

    final email = _emailController.text.trim();
    final token = _fullOtpCode;

    try {
      debugPrint('⏳ [ForgotPasswordModal] Verifying OTP recovery code for: $email');
      final response = await _client.auth.verifyOTP(
        email: email,
        token: token,
        type: OtpType.recovery,
      );

      debugPrint('✅ [ForgotPasswordModal] OTP verified successfully: ${response.user?.id}');

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        // Bascule vers l'étape 3 : Modification de ton mot de passe
        _step = _ForgotPasswordStep.newPassword;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _newPasswordFocusNode.canRequestFocus) {
          _newPasswordFocusNode.requestFocus();
        }
      });
    } on AuthException catch (e) {
      debugPrint('❌ [ForgotPasswordModal] AuthException OTP: ${e.message}');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasOtpError = true;
      });
    } catch (e) {
      debugPrint('❌ [ForgotPasswordModal] Error OTP: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasOtpError = true;
      });
    }
  }

  // Étape 3 : Enregistrement du nouveau mot de passe
  Future<void> _handleSaveNewPassword() async {
    HapticFeedback.lightImpact();
    FocusScope.of(context).unfocus();

    if (!_isPasswordFormValid || _isLoading) return;

    setState(() {
      _isLoading = true;
    });

    final newPassword = _newPasswordController.text;

    try {
      debugPrint('⏳ [ForgotPasswordModal] Updating password via Supabase...');
      await _client.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      debugPrint('✅ [ForgotPasswordModal] Password updated successfully!');

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _step = _ForgotPasswordStep.success;
      });
    } on AuthException catch (e) {
      debugPrint('❌ [ForgotPasswordModal] AuthException update password: ${e.message}');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      final isSamePassword = e.message.toLowerCase().contains('different') ||
          e.message.toLowerCase().contains('same') ||
          e.message.toLowerCase().contains('ancien');
      await GliftModal.showError(
        context: context,
        title: 'Oups, on a un problème...',
        description: isSamePassword
            ? 'Le nouveau mot de passe doit être différent de l’ancien mot de passe.'
            : e.message,
        buttonText: 'Fermer',
      );
    } catch (e) {
      debugPrint('❌ [ForgotPasswordModal] Error update password: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      await GliftModal.showError(
        context: context,
        title: 'Oups, on a un problème...',
        description:
            'Le nouveau mot de passe doit être différent de l’ancien mot de passe.',
        buttonText: 'Fermer',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isEmailStep = _step == _ForgotPasswordStep.email;
    final bool isOtpStep = _step == _ForgotPasswordStep.otp;
    final bool isNewPasswordStep = _step == _ForgotPasswordStep.newPassword;
    final bool isSuccessStep = _step == _ForgotPasswordStep.success;

    // Détermination de l'icône
    final String iconAsset = () {
      if (isSuccessStep) return 'assets/icons/message_succes.svg';
      if (isOtpStep) {
        return _hasOtpError
            ? 'assets/icons/cadena_rouge.svg'
            : 'assets/icons/cadena_vert.svg';
      }
      return 'assets/icons/cadena_violet.svg';
    }();

    // Détermination du titre
    final String title = () {
      if (isSuccessStep) return 'Mot de passe modifié !';
      if (isNewPasswordStep) return 'Modification de ton mot de passe';
      if (isOtpStep) {
        return _hasOtpError
            ? 'Code de validation incorrect'
            : 'Merci pour ton email';
      }
      return 'Mot de passe oublié ?';
    }();

    // Détermination de la description
    final String description = () {
      if (isSuccessStep) {
        return 'Bonne nouvelle ! Ton mot de passe a bien été modifié. Tu peux dès à présent te connecter en utilisant ton nouveau mot de passe.';
      }
      if (isNewPasswordStep) {
        return 'Pour finaliser ta demande, saisis un nouveau mot de passe sécurisé, puis confirme-le avant de cliquer sur « Enregistrer »';
      }
      if (isOtpStep) {
        return _hasOtpError
            ? 'Nous sommes désolés mais le code est invalide ou expiré. Merci de vérifier ton code ou de relancer une demande depuis « Mot de passe oublié ? ».'
            : 'Si un compte y est associé, un email contenant un code à 6 chiffres t’a été envoyé. Ce code est valable 30 minutes.';
      }
      return 'Pas de problème, nous allons t’envoyer un lien pour réinitialiser ton mot de passe en toute sécurité.';
    }();

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Stack(
        children: [
          SingleChildScrollView(
            controller: _scrollController,
            physics: const ClampingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icône en-tête (35px de haut)
                  Center(
                    child: SvgPicture.asset(
                      iconAsset,
                      height: 35,
                      width: 35,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Titre
                  Text(
                    title,
                    style: GoogleFonts.quicksand(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF3A416F),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),

                  // Description
                  Text(
                    description,
                    style: GoogleFonts.quicksand(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF3A416F),
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),

                  // CONTENU SELON L'ÉTAPE
                  if (isEmailStep) ...[
                    // ÉTAPE 1 : CHAMP EMAIL
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
                              color: _emailBorderColor(),
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
                                  _isEmailTouched = true;
                                  _emailErrorMessage = null;
                                });
                              },
                              onSubmitted: (_) => _handleSendEmail(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        SizedBox(
                          height: 18,
                          child: Text(
                            _emailDisplayMessage,
                            style: GoogleFonts.quicksand(
                              color: _emailMessageColor(),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] else if (isOtpStep) ...[
                    // ÉTAPE 2 : 6 CASES OTP
                    AutofillGroup(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(6, (index) {
                          final isFocused = _focusedOtpIndex == index;
                          return Expanded(
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              height: 46,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(
                                  color: _hasOtpError
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
                                      _onOtpBackspace(index);
                                    }
                                  },
                                  child: TextField(
                                    controller: _otpControllers[index],
                                    focusNode: _otpFocusNodes[index],
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
                                    onChanged: (val) => _onOtpDigitChanged(index, val),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ] else if (isNewPasswordStep) ...[
                    // ÉTAPE 3 : MODIFICATION DE TON MOT DE PASSE (Conforme à la maquette)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Champ Nouveau mot de passe
                        Text(
                          'Nouveau mot de passe',
                          style: GoogleFonts.quicksand(
                            color: const Color(0xFF3A416F),
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(
                              color: _isNewPasswordFocused
                                  ? const Color(0xFF7069FA)
                                  : (_isNewPasswordTouched &&
                                          !_isNewPasswordValid &&
                                          _newPasswordController.text.isNotEmpty)
                                      ? const Color(0xFFEF4444)
                                      : const Color(0xFFD7D4DC),
                              width: 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _newPasswordController,
                                  focusNode: _newPasswordFocusNode,
                                  obscureText: _obscureNewPassword,
                                  scrollPadding: const EdgeInsets.only(bottom: 220),
                                  style: GoogleFonts.quicksand(
                                    color: const Color(0xFF5D6494),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    hintText: '••••••••',
                                    hintStyle: GoogleFonts.quicksand(
                                      color: const Color(0xFFD7D4DC),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                                  ),
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                              IconButton(
                                icon: SvgPicture.asset(
                                  _obscureNewPassword
                                      ? 'assets/icons/masque_defaut.svg'
                                      : 'assets/icons/visible_defaut.svg',
                                  width: 20,
                                  height: 20,
                                ),
                                onPressed: () => setState(
                                    () => _obscureNewPassword = !_obscureNewPassword),
                              ),
                            ],
                          ),
                        ),
                        if (_isNewPasswordFocused)
                          _buildCriteriaBox(
                            hasMinLength: _isNewPasswordLengthValid,
                            hasLetter: _hasPasswordLetter,
                            hasNumber: _hasPasswordNumber,
                            hasSymbol: _hasPasswordSymbol,
                          ),
                        const SizedBox(height: 14),

                        // Champ Répéter le nouveau mot de passe
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Répéter le nouveau mot de passe',
                              style: GoogleFonts.quicksand(
                                color: const Color(0xFF3A416F),
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Container(
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(
                                  color: _isConfirmPasswordFocused
                                      ? const Color(0xFF7069FA)
                                      : (_isConfirmPasswordTouched &&
                                              !_doPasswordsMatch &&
                                              _confirmPasswordController.text.isNotEmpty)
                                          ? const Color(0xFFEF4444)
                                          : const Color(0xFFD7D4DC),
                                  width: 1.0,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _confirmPasswordController,
                                      focusNode: _confirmPasswordFocusNode,
                                      obscureText: _obscureConfirmPassword,
                                      scrollPadding: const EdgeInsets.only(bottom: 220),
                                      style: GoogleFonts.quicksand(
                                        color: const Color(0xFF5D6494),
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      decoration: InputDecoration(
                                        border: InputBorder.none,
                                        hintText: '••••••••',
                                        hintStyle: GoogleFonts.quicksand(
                                          color: const Color(0xFFD7D4DC),
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                                      ),
                                      onChanged: (_) => setState(() {}),
                                    ),
                                  ),
                                  IconButton(
                                    icon: SvgPicture.asset(
                                      _obscureConfirmPassword
                                          ? 'assets/icons/masque_defaut.svg'
                                          : 'assets/icons/visible_defaut.svg',
                                      width: 20,
                                      height: 20,
                                    ),
                                    onPressed: () => setState(() =>
                                        _obscureConfirmPassword = !_obscureConfirmPassword),
                                  ),
                                ],
                              ),
                            ),
                            if (_isConfirmPasswordFocused)
                              _buildCriteriaBox(
                                hasMinLength: _hasConfirmMinLength,
                                hasLetter: _hasConfirmLetter,
                                hasNumber: _hasConfirmNumber,
                                hasSymbol: _hasConfirmSymbol,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 14),

                  // BOUTONS D'ACTION
                  if (isSuccessStep) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7069FA),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: Text(
                          'Se connecter',
                          style: GoogleFonts.quicksand(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
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

                        // Valider / Enregistrer
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: ElevatedButton(
                              onPressed: isEmailStep
                                  ? (_isEmailValid && !_isLoading ? _handleSendEmail : null)
                                  : isOtpStep
                                      ? (_isOtpComplete && !_isLoading ? _handleVerifyOtp : null)
                                      : (_isPasswordFormValid && !_isLoading
                                          ? _handleSaveNewPassword
                                          : null),
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
                                      isNewPasswordStep ? 'Enregistrer' : 'Valider',
                                      style: GoogleFonts.quicksand(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: ((isEmailStep && _isEmailValid) ||
                                                (isOtpStep && _isOtpComplete) ||
                                                (isNewPasswordStep && _isPasswordFormValid))
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
                ],
              ),
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

class _PasswordCriteriaItem extends StatelessWidget {
  final bool valid;
  final String text;

  const _PasswordCriteriaItem({
    required this.valid,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final iconPath = valid
        ? 'assets/icons/check-success.svg'
        : 'assets/icons/check-neutral.svg';
    final textColor =
        valid ? const Color(0xFF00D591) : const Color(0xFFD7D4DC);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          text,
          style: GoogleFonts.quicksand(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        SvgPicture.asset(
          iconPath,
          width: 16,
          height: 16,
        ),
      ],
    );
  }
}
