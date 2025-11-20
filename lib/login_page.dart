import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase/supabase.dart';

import 'auth/auth_repository.dart';
import 'forgot_password_page.dart';
import 'home_page.dart';
import 'signup_page.dart';
import 'theme/glift_theme.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.authRepository});

  final AuthRepository authRepository;

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

  bool get _isFormValid =>
      _validateEmail(_emailController.text) == null &&
      _validatePassword(_passwordController.text) == null;

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

  String? _validatePassword(String value) {
    if (value.trim().isEmpty) {
      return 'Veuillez saisir votre mot de passe.';
    }

    if (value.trim().length < 6) {
      return 'Votre mot de passe doit contenir au moins 6 caractères.';
    }

    return null;
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
    final emailError = _validateEmail(_emailController.text);
    final passwordError = _validatePassword(_passwordController.text);

    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      _focusFirstError(emailError: emailError, passwordError: passwordError);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await widget.authRepository.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } on AuthException catch (error) {
      setState(() {
        _errorMessage = error.message.isNotEmpty
            ? error.message
            : 'Identifiants invalides. Vérifiez votre email et votre mot de passe.';
      });
      _focusFirstError(
        emailError: emailError ?? _validateEmail(_emailController.text),
        passwordError:
            passwordError ?? _validatePassword(_passwordController.text),
      );
    } catch (_) {
      setState(() {
        _errorMessage =
            'Service temporairement indisponible. Réessayez plus tard.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
    final textTheme = GoogleFonts.interTextTheme(Theme.of(context).textTheme);

    return Scaffold(
      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF6C5CE7), Color(0xFF7B6CFC)],
              stops: [0, 0.8],
            ),
          ),
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bonjour,',
                            style: textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Bienvenue sur Glift',
                            style: textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 26,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x1A000000),
                            blurRadius: 18,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 28,
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Connexion',
                                style: textTheme.titleLarge?.copyWith(
                                  color: GliftTheme.title,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 22,
                                ),
                              ),
                              const SizedBox(height: 24),
                              _LabeledTextField(
                                key: const Key('emailField'),
                                inputKey: const Key('emailInput'),
                                label: 'Email',
                                controller: _emailController,
                                focusNode: _emailFocusNode,
                                hintText: 'john.doe@email.com',
                                keyboardType: TextInputType.emailAddress,
                                validator: _validateEmail,
                                onChanged: (_) {
                                  setState(() {
                                    _errorMessage = null;
                                  });
                                },
                              ),
                              const SizedBox(height: 20),
                              _LabeledTextField(
                                key: const Key('passwordField'),
                                inputKey: const Key('passwordInput'),
                                label: 'Mot de passe',
                                controller: _passwordController,
                                focusNode: _passwordFocusNode,
                                hintText: '••••••••',
                                obscureText: _obscurePassword,
                                validator: _validatePassword,
                                onChanged: (_) {
                                  setState(() {
                                    _errorMessage = null;
                                  });
                                },
                                suffixIcon: Semantics(
                                  button: true,
                                  toggled: !_obscurePassword,
                                  label: _obscurePassword
                                      ? 'Afficher le mot de passe'
                                      : 'Masquer le mot de passe',
                                  child: IconButton(
                                    key: const Key('passwordToggle'),
                                    onPressed: _togglePasswordVisibility,
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      color: GliftTheme.body,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Center(
                                child: TextButton(
                                  onPressed: _openForgotPassword,
                                  style: TextButton.styleFrom(
                                    foregroundColor: const Color(0xFF6C5CE7),
                                    textStyle: GoogleFonts.inter(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  child: const Text('Mot de passe oublié'),
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (_errorMessage != null) ...[
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Text(
                                    _errorMessage!,
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: const Color(0xFFE74C3C),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton(
                                  key: const Key('loginButton'),
                                  onPressed:
                                      _isFormValid && !_isLoading ? _submit : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF6C5CE7),
                                    foregroundColor: Colors.white,
                                    disabledBackgroundColor:
                                        const Color(0xFFEAEAEA),
                                    disabledForegroundColor: GliftTheme.body,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    textStyle: GoogleFonts.inter(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                  child: _isLoading
                                      ? Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: const [
                                            SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation(
                                                  Colors.white,
                                                ),
                                              ),
                                            ),
                                            SizedBox(width: 12),
                                            Text('Chargement…'),
                                          ],
                                        )
                                      : const Text('Se connecter'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _SignupPrompt(onTap: _openSignup, textTheme: textTheme),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LabeledTextField extends StatelessWidget {
  const _LabeledTextField({
    super.key,
    required this.label,
    required this.controller,
    required this.focusNode,
    this.hintText,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType,
    this.validator,
    this.onChanged,
    this.inputKey,
  });

  final String label;
  final TextEditingController controller;
  final FocusNode focusNode;
  final String? hintText;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final String? Function(String value)? validator;
  final ValueChanged<String>? onChanged;
  final Key? inputKey;

  @override
  Widget build(BuildContext context) {
    final labelStyle = GoogleFonts.inter(
      fontWeight: FontWeight.w500,
      color: GliftTheme.title,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: labelStyle),
        const SizedBox(height: 12),
        TextFormField(
          key: inputKey,
          controller: controller,
          focusNode: focusNode,
          keyboardType: keyboardType,
          obscureText: obscureText,
          validator: validator,
          decoration: InputDecoration(
            hintText: hintText,
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF6C5CE7)),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE74C3C)),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE74C3C)),
            ),
            suffixIcon: suffixIcon,
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _SignupPrompt extends StatelessWidget {
  const _SignupPrompt({
    required this.onTap,
    required this.textTheme,
  });

  final VoidCallback onTap;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 4,
      children: [
        Text(
          'Pas encore inscrit ? ',
          style: textTheme.bodyMedium?.copyWith(color: Colors.white),
        ),
        TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF6C5CE7),
            textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
          ),
          child: const Text('Créer un compte'),
        ),
      ],
    );
  }
}
