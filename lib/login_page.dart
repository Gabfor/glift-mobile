import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase/supabase.dart';

import 'auth/biometric_auth_service.dart';
import 'auth/auth_repository.dart';
import 'forgot_password_page.dart';
import 'main_page.dart';
import 'signup_page.dart';
import 'widgets/glift_page_layout.dart';
class LoginPage extends StatefulWidget {
  const LoginPage({
    super.key,
    required this.authRepository,
    required this.supabase,
    required this.biometricAuthService,
  });

  final AuthRepository authRepository;
  final SupabaseClient supabase;
  final BiometricAuthService biometricAuthService;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();

  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;
  bool _emailTouched = false;
  bool _passwordTouched = false;
  bool _emailFocused = false;
  bool _passwordFocused = false;
  bool _hasSubmitted = false;

  bool get _isFormValid =>
      _isEmailValid && _passwordController.text.trim().isNotEmpty;

  bool get _isEmailValid {
    final trimmed = _emailController.text.trim();
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return emailRegex.hasMatch(trimmed);
  }

  bool get _isPasswordValid => _passwordController.text.trim().isNotEmpty;

  String get _emailMessage => _isEmailValid
      ? ''
      : 'Veuillez saisir un email valide.';

  String get _passwordMessage => _isPasswordValid
      ? 'Mot de passe valide'
      : 'Veuillez saisir votre mot de passe.';

  bool get _showEmailSuccess =>
      _isEmailValid && (_hasSubmitted || (_emailTouched && !_emailFocused));

  bool get _showEmailError =>
      (_hasSubmitted && !_isEmailValid) ||
      (_emailTouched &&
          !_emailFocused &&
          !_isEmailValid &&
          _emailController.text.trim().isNotEmpty);

  bool get _showPasswordSuccess =>
      _isPasswordValid && (_hasSubmitted || (_passwordTouched && !_passwordFocused));

  bool get _showPasswordError =>
      (_hasSubmitted && !_isPasswordValid) ||
      (_passwordTouched && !_passwordFocused && !_isPasswordValid);

  @override
  void initState() {
    super.initState();
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
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  void _focusFirstError({String? emailError, String? passwordError}) {
    if (emailError != null) {
      _emailFocusNode.requestFocus();
      return;
    }
    if (passwordError != null) {
      _passwordFocusNode.requestFocus();
    }
  }

  Future<void> _submit() async {
    setState(() {
      _hasSubmitted = true;
      _emailTouched = true;
      _passwordTouched = true;
      _errorMessage = null;
    });

    if (!_isFormValid) {
      _focusFirstError(
        emailError: _isEmailValid ? null : 'Format d’adresse invalide',
        passwordError: _isPasswordValid ? null : 'Mot de passe invalide',
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final session = await widget.authRepository.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      await widget.biometricAuthService.persistSession(session);
      if (!mounted) return;
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => MainPage(supabase: widget.supabase),
        ),
      );
    } on AuthException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.message.isNotEmpty
            ? error.message
            : 'Identifiants invalides. Vérifiez votre email et votre mot de passe.';
        _isLoading = false;
      });
      _focusFirstError(
        emailError: _isEmailValid ? null : 'Format d’adresse invalide',
        passwordError: _isPasswordValid ? null : 'Mot de passe invalide',
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage =
            'Une erreur est survenue. Veuillez réessayer plus tard.';
        _isLoading = false;
      });
    }
  }

  void _openForgotPassword() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ForgotPasswordPage(authRepository: widget.authRepository),
      ),
    );
  }

  void _openSignup() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SignupPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    final now = DateTime.now();
    final greeting = (now.hour >= 18 && now.hour <= 23) ? 'Bonsoir,' : 'Bonjour,';

    return GliftPageLayout(
      title: greeting,
      subtitle: 'Bienvenue sur Glift',
      resizeToAvoidBottomInset: false,
      fullPageScroll: false,
      scrollable: false,
      footerIgnoresViewInsets: true,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
      footerPadding: EdgeInsets.fromLTRB(24, 0, 24, bottomPadding),
      footer: _SignupPrompt(onTap: _openSignup),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Connexion',
              style: GoogleFonts.quicksand(
                color: const Color(0xFF3A416F),
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            const SizedBox(height: 8),
            _InputField(
              label: 'Adresse e-mail',
              hintText: 'prenom.nom@email.fr',
              controller: _emailController,
              focusNode: _emailFocusNode,
              isFocused: _emailFocused,
              isError: _showEmailError,
              message: _emailMessage,
              onChanged: (_) {
                setState(() {
                  _emailTouched = true;
                  _errorMessage = null;
                });
              },
            ),
            const SizedBox(height: 30),
            _PasswordField(
              controller: _passwordController,
              focusNode: _passwordFocusNode,
              obscureText: _obscurePassword,
              isFocused: _passwordFocused,
              onChanged: (_) {
                setState(() {
                  _passwordTouched = true;
                  _errorMessage = null;
                });
              },
              onToggleVisibility: _togglePasswordVisibility,
              isError: _showPasswordError,
              onSubmitted: (_) => _submit(),
              message: _passwordMessage,
            ),
            const SizedBox(height: 30),
            if (_errorMessage != null) ...[
              Text(
                _errorMessage!,
                style: GoogleFonts.quicksand(
                  color: const Color(0xFFE74C3C),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
            ],
            _AnimatedButton(
              isEnabled: _isFormValid,
              isLoading: _isLoading,
              onPressed: _submit,
            ),
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: _openForgotPassword,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Mot de passe oublié',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.quicksand(
                    color: const Color(0xFF7069FA),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedButton extends StatelessWidget {
  final bool isEnabled;
  final bool isLoading;
  final VoidCallback onPressed;

  const _AnimatedButton({
    required this.isEnabled,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final color = isEnabled ? const Color(0xFF7069FA) : const Color(0xFFF2F1F6);
    final textColor = isEnabled ? Colors.white : const Color(0xFFD7D4DC);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: double.infinity,
      height: 48,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(25),
      ),
      child: ElevatedButton(
        onPressed: isEnabled && !isLoading ? onPressed : null,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: color,
          foregroundColor: textColor,
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
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFFD7D4DC)),
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
            : const Text('Se connecter'),
      ),
    );
  }
}

class _SignupPrompt extends StatelessWidget {
  final VoidCallback onTap;
  const _SignupPrompt({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 4,
        runSpacing: 4,
        children: [
          Text(
            'Pas encore inscrit ? ',
            style: GoogleFonts.quicksand(
              color: const Color(0xFF5D6494),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          GestureDetector(
            onTap: onTap,
            child: Text(
              'Créer un compte',
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

class _InputField extends StatefulWidget {
  final String label;
  final String? hintText;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isFocused;
  final bool isError;
  final String message;
  final ValueChanged<String>? onChanged;

  const _InputField({
    required this.label,
    required this.controller,
    required this.focusNode,
    required this.isFocused,
    required this.isError,
    required this.message,
    this.hintText,
    this.onChanged,
  });

  @override
  State<_InputField> createState() => _InputFieldState();
}

class _InputFieldState extends State<_InputField> {
  bool _isHovered = false;

  Color _borderColor() {
    if (widget.isError) return const Color(0xFFEF4444);
    if (widget.isFocused) return const Color(0xFFA1A5FD);
    return _isHovered ? const Color(0xFFC2BFC6) : const Color(0xFFD7D4DC);
  }

  Color _messageColor() {
    if (widget.isError) return const Color(0xFFEF4444);
    return const Color(0xFF5D6494);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: GoogleFonts.quicksand(
            color: const Color(0xFF3A416F),
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 5),
        MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                color: _borderColor(),
                width: widget.isFocused ? 1.5 : 1,
              ),
              borderRadius: BorderRadius.circular(5),
            ),
            child: SizedBox(
              height: 45,
              child: TextField(
                controller: widget.controller,
                focusNode: widget.focusNode,
                keyboardType: TextInputType.emailAddress,
                style: GoogleFonts.quicksand(
                  color: const Color(0xFF5D6494),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: widget.hintText,
                  hintStyle: GoogleFonts.quicksand(
                    color: const Color(0xFFD7D4DC),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 15),
                ),
                onChanged: widget.onChanged,
              ),
            ),
          ),
        ),
        if (widget.isError) ...[
          const SizedBox(height: 5),
          Text(
            widget.message,
            style: GoogleFonts.quicksand(
              color: _messageColor(),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

class _PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool obscureText;
  final ValueChanged<String> onChanged;
  final VoidCallback onToggleVisibility;
  final bool isError;
  final ValueChanged<String> onSubmitted;
  final String message;
  final bool isFocused;

  const _PasswordField({
    required this.controller,
    required this.focusNode,
    required this.obscureText,
    required this.onChanged,
    required this.onToggleVisibility,
    required this.isError,
    required this.onSubmitted,
    required this.message,
    required this.isFocused,
  });

  Color _borderColor() {
    if (isError) return const Color(0xFFEF4444);
    if (isFocused) return const Color(0xFFA1A5FD);
    return const Color(0xFFD7D4DC);
  }

  Color _messageColor() {
    if (isError) return const Color(0xFFEF4444);
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
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(
              color: _borderColor(),
              width: isFocused ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(5),
          ),
          child: SizedBox(
            height: 45,
            child: Stack(
              children: [
                Positioned.fill(
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
                      contentPadding: const EdgeInsets.symmetric(horizontal: 15),
                    ),
                    onChanged: onChanged,
                    onSubmitted: onSubmitted,
                  ),
                ),
                Positioned(
                  right: 10,
                  top: 10,
                  bottom: 10,
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
              ],
            ),
          ),
        ),
        if (isError) ...[
          const SizedBox(height: 5),
          Text(
            message,
            style: GoogleFonts.quicksand(
              color: _messageColor(),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}
