import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase/supabase.dart';
import 'package:url_launcher/url_launcher.dart';

import 'auth/biometric_auth_service.dart';
import 'auth/auth_repository.dart';
import 'widgets/forgot_password_modal.dart';
import 'main_page.dart';
import 'signup_page.dart';
import 'supabase_credentials.dart';
import 'widgets/auth_error_modal.dart';
import 'widgets/connect_button.dart';
import 'widgets/glift_page_layout.dart';
class LoginPage extends StatefulWidget {
  const LoginPage({
    super.key,
    this.authRepository,
    this.supabase,
    this.biometricAuthService,
  });

  final AuthRepository? authRepository;
  final SupabaseClient? supabase;
  final BiometricAuthService? biometricAuthService;

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

  String get _emailMessage {
    final trimmed = _emailController.text.trim();
    if (trimmed.isEmpty) return '';
    return _isEmailValid ? '' : 'Veuillez saisir un email valide.';
  }

  String get _passwordMessage => '';

  bool get _showEmailSuccess =>
      _isEmailValid && (_hasSubmitted || (_emailTouched && !_emailFocused));

  bool get _showEmailError {
    final hasText = _emailController.text.trim().isNotEmpty;
    if (!hasText) return false;
    return !_emailFocused && !_isEmailValid && (_hasSubmitted || _emailTouched);
  }

  bool get _showPasswordSuccess =>
      _isPasswordValid && (_hasSubmitted || (_passwordTouched && !_passwordFocused));

  bool get _showPasswordError =>
      _passwordController.text.trim().isNotEmpty &&
      ((_hasSubmitted && !_isPasswordValid) ||
          (_passwordTouched && !_passwordFocused && !_isPasswordValid));

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
    HapticFeedback.lightImpact();
    setState(() {
      _hasSubmitted = true;
      _emailTouched = true;
      _passwordTouched = true;
      _isLoading = true;
    });

    if (!_isFormValid) {
      setState(() {
        _isLoading = false;
      });
      _focusFirstError(
        emailError: _isEmailValid ? null : 'Format d’adresse invalide',
        passwordError: _isPasswordValid ? null : 'Mot de passe invalide',
      );
      return;
    }

    try {
      if (widget.authRepository != null && widget.supabase != null) {
        final session = await widget.authRepository!.signInWithPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        if (widget.biometricAuthService != null) {
          await widget.biometricAuthService!.persistSession(session);
        }
        if (!mounted) return;
        if (widget.biometricAuthService != null) {
          await Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => MainPage(
                supabase: widget.supabase!,
                authRepository: widget.authRepository!,
                biometricAuthService: widget.biometricAuthService!,
              ),
            ),
          );
        }
      }
    } on AuthException catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      _focusFirstError(
        emailError: _isEmailValid ? null : 'Format d’adresse invalide',
        passwordError: _isPasswordValid ? null : 'Mot de passe invalide',
      );
      AuthErrorModal.show(
        context,
        title: 'Email ou mot de passe incorrect',
        description:
            'Nous n’arrivons pas à te connecter. Vérifie qu’il s’agit bien de l’email utilisé lors de ton inscription ou qu’il n’y a pas d’erreur dans le mot de passe.',
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      AuthErrorModal.show(
        context,
        title: 'Erreur de connexion',
        description:
            'Une erreur inattendue est survenue. Veuillez vérifier votre connexion et réessayer.',
      );
    }
  }

  Future<void> _signInWithOAuth(OAuthProvider provider) async {
    HapticFeedback.lightImpact();
    setState(() {
      _isLoading = true;
    });

    try {
      if (widget.supabase != null) {
        final redirectUrl = '$supabaseUrl/auth-callback';
        final response = await widget.supabase!.auth.getOAuthSignInUrl(
          provider: provider,
          redirectTo: redirectUrl,
        );
        final uri = Uri.parse(response.url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      }
    } catch (e) {
      if (!mounted) return;
      AuthErrorModal.show(
        context,
        title: 'Erreur de connexion',
        description: 'Impossible de se connecter avec ce service.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _openForgotPassword() {
    showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) => ForgotPasswordModal(
        authRepository: widget.authRepository,
        supabase: widget.supabase,
        biometricAuthService: widget.biometricAuthService,
        initialEmail: _emailController.text.trim(),
      ),
    );
  }

  void _openSignup() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => SignupPage(
          authRepository: widget.authRepository,
          supabase: widget.supabase,
          biometricAuthService: widget.biometricAuthService,
        ),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final now = DateTime.now();
    final greeting = (now.hour >= 18 && now.hour <= 23) ? 'Bonsoir,' : 'Bonjour,';

    return GliftPageLayout(
      title: greeting,
      subtitle: 'Prêt pour ta séance ?',
      resizeToAvoidBottomInset: false,
      fullPageScroll: false,
      scrollable: true,
      physics: const ClampingScrollPhysics(),
      footerIgnoresViewInsets: true,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
      footerPadding: EdgeInsets.fromLTRB(24, 0, 24, bottomPadding),
      footer: _SignupPrompt(onTap: _openSignup),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                'Connexion',
                style: GoogleFonts.quicksand(
                  color: const Color(0xFF3A416F),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 8),
            _InputField(
              label: 'Adresse e-mail',
              hintText: 'john.doe@email.com',
              controller: _emailController,
              focusNode: _emailFocusNode,
              isFocused: _emailFocused,
              isError: _showEmailError,
              message: _emailMessage,
              fieldKey: const Key('emailInput'),
              onChanged: (_) {
                setState(() {
                  _emailTouched = true;
                });
              },
            ),
            const SizedBox(height: 5),
            _PasswordField(
              controller: _passwordController,
              focusNode: _passwordFocusNode,
              obscureText: _obscurePassword,
              isFocused: _passwordFocused,
              onChanged: (_) {
                setState(() {
                  _passwordTouched = true;
                });
              },
              onToggleVisibility: _togglePasswordVisibility,
              isError: _showPasswordError,
              onSubmitted: (_) => _submit(),
              message: _passwordMessage,
              textFieldKey: const Key('passwordInput'),
              toggleKey: const Key('passwordToggle'),
            ),
            const SizedBox(height: 24),
            ConnectButton(
              key: const Key('loginButton'),
              isEnabled: _isFormValid,
              isLoading: _isLoading,
              onPressed: _submit,
            ),
            const SizedBox(height: 14),
            Center(
              child: TextButton(
                onPressed: _openForgotPassword,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Mot de passe oublié ?',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.quicksand(
                    color: const Color(0xFF7069FA),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
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
                    'ou continue avec',
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
  final Key? fieldKey;

  const _InputField({
    super.key,
    required this.label,
    required this.controller,
    required this.focusNode,
    required this.isFocused,
    required this.isError,
    required this.message,
    this.fieldKey,
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
            height: 48, // Fixed total height to prevent layout jump
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                color: _borderColor(),
                width: 1.0,
              ),
              borderRadius: BorderRadius.circular(5),
              boxShadow: (widget.isFocused || widget.isError)
                  ? [
                      BoxShadow(
                        color: _borderColor(),
                        offset: Offset.zero,
                        blurRadius: 0,
                        spreadRadius: 0.5,
                      ),
                    ]
                  : [],
            ),
            child: Center(
              child: TextField(
                key: widget.fieldKey,
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
                  contentPadding: const EdgeInsets.only(
                    left: 14.5,
                    right: 14.5,
                  ),
                ),
                onChanged: widget.onChanged,
              ),
            ),
          ),
        ),
        const SizedBox(height: 5),
        SizedBox(
          height: 18,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 150),
            opacity: widget.isError && widget.message.isNotEmpty ? 1 : 0,
            child: Text(
              widget.message,
              style: GoogleFonts.quicksand(
                color: _messageColor(),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
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
  final ValueChanged<String> onChanged;
  final VoidCallback onToggleVisibility;
  final bool isError;
  final ValueChanged<String> onSubmitted;
  final String message;
  final bool isFocused;
  final Key? textFieldKey;
  final Key? toggleKey;

  const _PasswordField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.obscureText,
    required this.onChanged,
    required this.onToggleVisibility,
    required this.isError,
    required this.onSubmitted,
    required this.message,
    required this.isFocused,
    this.textFieldKey,
    this.toggleKey,
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
          height: 48, // Fixed total height
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(
              color: _borderColor(),
              width: 1.0,
            ),
            borderRadius: BorderRadius.circular(5),
            boxShadow: (isFocused || isError)
                ? [
                    BoxShadow(
                      color: _borderColor(),
                      offset: Offset.zero,
                      blurRadius: 0,
                      spreadRadius: 0.5,
                    ),
                  ]
                : [],
          ),
          child: Stack(
            children: [
              Center(
                child: TextField(
                  key: textFieldKey,
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
                      right: 54.5, // 40 + 14.5
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
                    key: toggleKey,
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
        if (isError && message.isNotEmpty) ...[
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

