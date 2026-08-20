import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase/supabase.dart';
import 'package:url_launcher/url_launcher.dart';

import 'auth/auth_repository.dart';
import 'auth/biometric_auth_service.dart';
import 'main_page.dart';
import 'supabase_credentials.dart';
import 'widgets/glift_page_layout.dart';

class SignupPage extends StatefulWidget {
  final AuthRepository? authRepository;
  final SupabaseClient? supabase;
  final BiometricAuthService? biometricAuthService;

  const SignupPage({
    super.key,
    this.authRepository,
    this.supabase,
    this.biometricAuthService,
  });

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final FocusNode _firstNameFocusNode = FocusNode();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  final GlobalKey _passwordKey = GlobalKey();
  final ScrollController _scrollController = ScrollController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  String? _errorTitle;
  String? _errorDescription;
  String? _externalEmailError;

  bool _firstNameTouched = false;
  bool _emailTouched = false;
  bool _passwordTouched = false;
  bool _firstNameFocused = false;
  bool _emailFocused = false;
  bool _passwordFocused = false;

  bool get _isFirstNameFormatValid =>
      RegExp(r'^[a-zA-ZÀ-ÿ\s-]+$').hasMatch(_firstNameController.text.trim());

  bool get _isFirstNameValid =>
      _firstNameController.text.trim().isNotEmpty && _isFirstNameFormatValid;

  bool get _isEmailValid =>
      RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
          .hasMatch(_emailController.text.trim());

  bool get _hasMinLength => _passwordController.text.length >= 8;
  bool get _hasLetter => RegExp(r'[a-zA-Z]').hasMatch(_passwordController.text);
  bool get _hasNumber => RegExp(r'\d').hasMatch(_passwordController.text);
  bool get _hasSymbol =>
      RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(_passwordController.text);

  bool get _isPasswordValid =>
      _hasMinLength && _hasLetter && _hasNumber && _hasSymbol;

  bool get _isFormValid =>
      _isFirstNameValid && _isEmailValid && _isPasswordValid && !_isLoading;

  bool get _showFirstNameSuccess =>
      _firstNameTouched && !_firstNameFocused && _isFirstNameValid;

  bool get _showFirstNameFormatError =>
      _firstNameTouched &&
      !_firstNameFocused &&
      _firstNameController.text.isNotEmpty &&
      !_isFirstNameFormatValid;

  String get _firstNameMessage {
    if (_showFirstNameSuccess) {
      return 'Enchanté ${_firstNameController.text.trim()} !';
    }
    if (_showFirstNameFormatError) {
      return 'Le prénom ne doit contenir que des lettres';
    }
    return '';
  }

  bool get _showEmailSuccess =>
      _emailTouched &&
      !_emailFocused &&
      _isEmailValid &&
      _externalEmailError == null;

  bool get _showEmailFormatError =>
      _emailTouched &&
      !_emailFocused &&
      _emailController.text.trim().isNotEmpty &&
      !_isEmailValid;

  bool get _showEmailExternalError =>
      _externalEmailError != null && !_emailFocused;

  String get _emailMessage {
    if (_showEmailExternalError) {
      return _externalEmailError!;
    }
    if (_showEmailSuccess) {
      return 'Merci, cet email sera ton identifiant de connexion';
    }
    if (_showEmailFormatError) {
      return 'Format d’adresse invalide';
    }
    return '';
  }

  bool get _showPasswordSuccess =>
      _passwordTouched && !_passwordFocused && _isPasswordValid;

  bool get _showPasswordError =>
      _passwordTouched &&
      !_passwordFocused &&
      _passwordController.text.isNotEmpty &&
      !_isPasswordValid;

  String get _passwordMessage {
    if (_showPasswordSuccess) {
      return 'Mot de passe valide';
    }
    if (_showPasswordError) {
      return 'Mot de passe invalide';
    }
    return '';
  }

  @override
  void initState() {
    super.initState();
    _firstNameFocusNode.addListener(() {
      setState(() {
        _firstNameFocused = _firstNameFocusNode.hasFocus;
        _firstNameTouched = _firstNameTouched || _firstNameFocused;
      });
    });
    _emailFocusNode.addListener(() {
      setState(() {
        _emailFocused = _emailFocusNode.hasFocus;
        _emailTouched = _emailTouched || _emailFocused;
      });
    });
    _passwordFocusNode.addListener(() {
      setState(() {
        _passwordFocused = _passwordFocusNode.hasFocus;
        _passwordTouched = _passwordTouched || _passwordFocused;
      });

      if (_passwordFocusNode.hasFocus) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (!mounted) return;
          if (_passwordKey.currentContext != null) {
            Scrollable.ensureVisible(
              _passwordKey.currentContext!,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              alignment: 1.0,
            );
          } else if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _firstNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _firstNameFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  Future<void> _openPrivacyPolicy() async {
    final uri = Uri.parse('https://glift.io/politique-de-confidentialite/');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openCGU() async {
    final uri = Uri.parse('https://glift.io/cgu/');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _handleError(String? message) {
    if (message == null || message.trim().isEmpty) {
      _errorTitle = 'Mince, il y a un problème...';
      _errorDescription =
          'Nous sommes désolés mais nous rencontrons actuellement une erreur. Merci de réessayer dans un instant.';
      _externalEmailError = null;
      return;
    }

    final normalized = message.trim().toLowerCase();
    final emailAlreadyUsed = normalized.contains('already registered') ||
        normalized.contains('already in use') ||
        normalized.contains('already exists') ||
        normalized.contains('email registered') ||
        normalized.contains('deja utilise') ||
        normalized.contains('deja associe') ||
        normalized.contains('email deja');

    if (emailAlreadyUsed) {
      _errorTitle = 'Inscription impossible';
      _errorDescription =
          'Vous ne pouvez pas utiliser cet email car il est déjà associé à un compte actif sur la plateforme.';
      _externalEmailError = 'Mince, cet email est déjà utilisé';
    } else {
      _errorTitle = message;
      _errorDescription = null;
      _externalEmailError = null;
    }
  }

  Future<void> _submit() async {
    HapticFeedback.lightImpact();
    setState(() {
      _firstNameTouched = true;
      _emailTouched = true;
      _passwordTouched = true;
      _errorTitle = null;
      _errorDescription = null;
      _externalEmailError = null;
      _isLoading = true;
    });

    if (!_isFormValid) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final client = widget.supabase;
    if (client == null) {
      setState(() {
        _isLoading = false;
        _handleError('Supabase client non initialisé.');
      });
      return;
    }

    try {
      final res = await client.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        data: {'first_name': _firstNameController.text.trim()},
      );

      if (res.session != null) {
        if (widget.biometricAuthService != null) {
          await widget.biometricAuthService!.persistSession(res.session!);
        }
        if (!mounted) return;
        if (widget.authRepository != null && widget.biometricAuthService != null) {
          await Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => MainPage(
                supabase: client,
                authRepository: widget.authRepository!,
                biometricAuthService: widget.biometricAuthService!,
              ),
            ),
          );
        } else {
          Navigator.of(context).pop();
        }
      } else {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Un email de confirmation vous a été envoyé. Veuillez vérifier votre boîte de réception.',
            ),
          ),
        );
      }
    } on AuthException catch (error) {
      if (!mounted) return;
      setState(() {
        _handleError(error.message);
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _handleError(null);
        _isLoading = false;
      });
    }
  }

  Future<void> _signInWithOAuth(OAuthProvider provider) async {
    final client = widget.supabase;
    if (client == null) return;

    HapticFeedback.lightImpact();
    setState(() {
      _isLoading = true;
      _errorTitle = null;
      _errorDescription = null;
      _externalEmailError = null;
    });

    try {
      final redirectUrl = '$supabaseUrl/auth-callback';
      final response = await client.auth.getOAuthSignInUrl(
        provider: provider,
        redirectTo: redirectUrl,
      );
      final uri = Uri.parse(response.url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _handleError('Impossible de se connecter avec ce service.');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final now = DateTime.now();
    final greeting = (now.hour >= 18 && now.hour <= 23) ? 'Bonsoir,' : 'Bonjour,';

    return GliftPageLayout(
      title: greeting,
      subtitle: 'Bienvenue sur Glift !',
      controller: _scrollController,
      resizeToAvoidBottomInset: true,
      fullPageScroll: true,
      scrollable: true,
      footerIgnoresViewInsets: true,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
      footerPadding: EdgeInsets.fromLTRB(24, 0, 24, bottomPadding),
      footer: _LoginPrompt(
        onTap: () => Navigator.of(context).pop(),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                'Inscription',
                style: GoogleFonts.quicksand(
                  color: const Color(0xFF3A416F),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (_errorTitle != null) ...[
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1F1),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      child: Container(
                        width: 3,
                        decoration: const BoxDecoration(
                          color: Color(0xFFE34A4A),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(5),
                            bottomLeft: Radius.circular(5),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _errorTitle!,
                            style: GoogleFonts.quicksand(
                              color: const Color(0xFFE34A4A),
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (_errorDescription != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              _errorDescription!,
                              style: GoogleFonts.quicksand(
                                color: const Color(0xFFE34A4A),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            const SizedBox(height: 8),
            _InputField(
              label: 'Prénom',
              hintText: 'John',
              controller: _firstNameController,
              focusNode: _firstNameFocusNode,
              isFocused: _firstNameFocused,
              isSuccess: _showFirstNameSuccess,
              isError: _showFirstNameFormatError,
              message: _firstNameMessage,
              onChanged: (_) {
                setState(() {
                  _firstNameTouched = true;
                  _errorTitle = null;
                  _errorDescription = null;
                });
              },
            ),
            const SizedBox(height: 5),
            _InputField(
              label: 'Email',
              hintText: 'john.doe@email.com',
              controller: _emailController,
              focusNode: _emailFocusNode,
              isFocused: _emailFocused,
              isSuccess: _showEmailSuccess,
              isError: _showEmailFormatError || _showEmailExternalError,
              message: _emailMessage,
              onChanged: (_) {
                setState(() {
                  _emailTouched = true;
                  _errorTitle = null;
                  _errorDescription = null;
                  _externalEmailError = null;
                });
              },
            ),
            const SizedBox(height: 5),
            _PasswordField(
              key: _passwordKey,
              controller: _passwordController,
              focusNode: _passwordFocusNode,
              obscureText: _obscurePassword,
              isFocused: _passwordFocused,
              isSuccess: _showPasswordSuccess,
              isError: _showPasswordError,
              message: _passwordMessage,
              hasMinLength: _hasMinLength,
              hasLetter: _hasLetter,
              hasNumber: _hasNumber,
              hasSymbol: _hasSymbol,
              onChanged: (_) {
                setState(() {
                  _passwordTouched = true;
                  _errorTitle = null;
                  _errorDescription = null;
                });
              },
              onToggleVisibility: _togglePasswordVisibility,
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 5),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text.rich(
                  TextSpan(
                    style: GoogleFonts.quicksand(
                      color: const Color(0xFF5D6494),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                    children: [
                      const TextSpan(text: 'En créant mon compte, j’accepte la '),
                      TextSpan(
                        text: 'Politique de confidentialité',
                        style: GoogleFonts.quicksand(
                          color: const Color(0xFF7069FA),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        recognizer: TapGestureRecognizer()..onTap = _openPrivacyPolicy,
                      ),
                      const TextSpan(text: ' et les '),
                      TextSpan(
                        text: 'CGU',
                        style: GoogleFonts.quicksand(
                          color: const Color(0xFF7069FA),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        recognizer: TapGestureRecognizer()..onTap = _openCGU,
                      ),
                      const TextSpan(text: ' de Glift.'),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 20),
            _CreateAccountButton(
              isEnabled: _isFormValid,
              isLoading: _isLoading,
              onPressed: _submit,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                const Expanded(
                  child: Divider(
                    color: Color(0xFFECE9F1),
                    thickness: 1,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'ou',
                    style: GoogleFonts.quicksand(
                      color: const Color(0xFFD7D4DC),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Expanded(
                  child: Divider(
                    color: Color(0xFFECE9F1),
                    thickness: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _SocialLoginButton(
                  iconPath: 'assets/icons/apple.svg',
                  label: 'Apple',
                  iconSize: 22,
                  onTap: () => _signInWithOAuth(OAuthProvider.apple),
                ),
                const SizedBox(width: 24),
                _SocialLoginButton(
                  iconPath: 'assets/icons/google.svg',
                  label: 'Google',
                  iconSize: 20,
                  onTap: () => _signInWithOAuth(OAuthProvider.google),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateAccountButton extends StatelessWidget {
  final bool isEnabled;
  final bool isLoading;
  final VoidCallback onPressed;

  const _CreateAccountButton({
    required this.isEnabled,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isInteractive = isEnabled && !isLoading;
    final color = isInteractive ? const Color(0xFF7069FA) : const Color(0xFFF2F1F6);
    final textColor = isInteractive ? Colors.white : const Color(0xFFD7D4DC);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: double.infinity,
      height: 48,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(25),
      ),
      child: ElevatedButton(
        onPressed: isInteractive ? onPressed : null,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: color,
          foregroundColor: textColor,
          disabledBackgroundColor: color,
          disabledForegroundColor: textColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          textStyle: GoogleFonts.quicksand(
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        child: isLoading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(textColor),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'En cours...',
                    style: GoogleFonts.quicksand(
                      color: const Color(0xFFD7D4DC),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!isInteractive) ...[
                    SvgPicture.asset(
                      'assets/icons/locked.svg',
                      width: 16,
                      height: 16,
                      colorFilter: const ColorFilter.mode(
                        Color(0xFFD7D4DC),
                        BlendMode.srcIn,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  const Text('Créer mon compte'),
                ],
              ),
      ),
    );
  }
}

class _LoginPrompt extends StatelessWidget {
  final VoidCallback onTap;
  const _LoginPrompt({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 4,
        runSpacing: 4,
        children: [
          Text(
            'Déjà inscrit ? ',
            style: GoogleFonts.quicksand(
              color: const Color(0xFF5D6494),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          GestureDetector(
            onTap: onTap,
            child: Text(
              'Se connecter',
              style: GoogleFonts.quicksand(
                color: const Color(0xFF7069FA),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final String label;
  final String? hintText;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isFocused;
  final bool isSuccess;
  final bool isError;
  final String message;
  final ValueChanged<String>? onChanged;

  const _InputField({
    required this.label,
    required this.controller,
    required this.focusNode,
    required this.isFocused,
    required this.isSuccess,
    required this.isError,
    required this.message,
    this.hintText,
    this.onChanged,
  });

  Color _borderColor() {
    if (isError) return const Color(0xFFEF4444);
    if (isSuccess) return const Color(0xFF00D591);
    if (isFocused) return const Color(0xFF7069FA);
    return const Color(0xFFD7D4DC);
  }

  Color _messageColor() {
    if (isError) return const Color(0xFFEF4444);
    if (isSuccess) return const Color(0xFF00D591);
    return const Color(0xFF5D6494);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
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
              controller: controller,
              focusNode: focusNode,
              style: GoogleFonts.quicksand(
                color: const Color(0xFF5D6494),
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: hintText,
                hintStyle: GoogleFonts.quicksand(
                  color: const Color(0xFFD7D4DC),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14.5),
              ),
              onChanged: onChanged,
            ),
          ),
        ),
        const SizedBox(height: 5),
        SizedBox(
          height: 18,
          child: Text(
            message,
            style: GoogleFonts.quicksand(
              color: _messageColor(),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool obscureText;
  final bool isFocused;
  final bool isSuccess;
  final bool isError;
  final String message;
  final bool hasMinLength;
  final bool hasLetter;
  final bool hasNumber;
  final bool hasSymbol;
  final ValueChanged<String>? onChanged;
  final VoidCallback onToggleVisibility;
  final ValueChanged<String>? onSubmitted;

  const _PasswordField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.obscureText,
    required this.isFocused,
    required this.isSuccess,
    required this.isError,
    required this.message,
    required this.hasMinLength,
    required this.hasLetter,
    required this.hasNumber,
    required this.hasSymbol,
    required this.onToggleVisibility,
    this.onChanged,
    this.onSubmitted,
  });

  Color _borderColor() {
    if (isError) return const Color(0xFFEF4444);
    if (isSuccess) return const Color(0xFF00D591);
    if (isFocused) return const Color(0xFF7069FA);
    return const Color(0xFFD7D4DC);
  }

  Color _messageColor() {
    if (isError) return const Color(0xFFEF4444);
    if (isSuccess) return const Color(0xFF00D591);
    return const Color(0xFF5D6494);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mot de passe',
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
          child: Stack(
            children: [
              Center(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  obscureText: obscureText,
                  obscuringCharacter: '●',
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
                    contentPadding: const EdgeInsets.only(
                      left: 14.5,
                      right: 54.5,
                    ),
                  ),
                  onChanged: onChanged,
                  onSubmitted: onSubmitted,
                ),
              ),
              Positioned(
                right: 10,
                top: 0,
                bottom: 0,
                child: Center(
                  child: GestureDetector(
                    onTapDown: (_) => focusNode.requestFocus(),
                    onTap: onToggleVisibility,
                    child: SvgPicture.asset(
                      obscureText
                          ? 'assets/icons/visible_defaut.svg'
                          : 'assets/icons/masque_defaut.svg',
                      width: 25,
                      height: 25,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (isFocused) ...[
          const SizedBox(height: 8),
          Container(
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
          ),
        ],
        const SizedBox(height: 5),
        SizedBox(
          height: 18,
          child: Text(
            message,
            style: GoogleFonts.quicksand(
              color: _messageColor(),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
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
            color: textColor,
            fontSize: 12,
            fontWeight: FontWeight.w600,
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

class _SocialLoginButton extends StatefulWidget {
  final String iconPath;
  final String label;
  final double iconSize;
  final VoidCallback onTap;

  const _SocialLoginButton({
    required this.iconPath,
    required this.label,
    required this.iconSize,
    required this.onTap,
  });

  @override
  State<_SocialLoginButton> createState() => _SocialLoginButtonState();
}

class _SocialLoginButtonState extends State<_SocialLoginButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: _isHovered
                      ? const Color(0xFFC2BFC6)
                      : const Color(0xFFD7D4DC),
                  width: 1.0,
                ),
              ),
              alignment: Alignment.center,
              child: SvgPicture.asset(
                widget.iconPath,
                width: widget.iconSize,
                height: widget.iconSize,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.label,
              style: GoogleFonts.quicksand(
                color: const Color(0xFFD7D4DC),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
