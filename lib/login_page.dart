import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase/supabase.dart';

import 'auth/auth_repository.dart';
import 'forgot_password_page.dart';
import 'home_page.dart';
import 'signup_page.dart';

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
      ? 'Merci, cet email sera ton identifiant de connexion'
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
        emailError: _isEmailValid ? null : 'Format d’adresse invalide',
        passwordError: _isPasswordValid ? null : 'Mot de passe invalide',
      );
    } catch (error) {
      setState(() {
        _errorMessage =
            'Une erreur est survenue. Veuillez réessayer plus tard.';
      });
    } finally {
      setState(() {
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
    final textTheme = GoogleFonts.interTextTheme(Theme.of(context).textTheme);
    final bonjourStyle = GoogleFonts.quicksand(
      fontWeight: FontWeight.w600,
      fontSize: 14,
      color: Colors.white,
    );
    final bienvenueStyle = GoogleFonts.quicksand(
      fontWeight: FontWeight.w700,
      fontSize: 16,
      color: Colors.white,
    );

    final viewPadding = MediaQuery.of(context).padding;

    return Scaffold(
      backgroundColor: const Color(0xFF7069FA),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final viewInsets = MediaQuery.of(context).viewInsets.bottom;
            final availableHeight = (constraints.maxHeight - viewInsets)
                .clamp(0.0, double.infinity)
                .toDouble();

            return Stack(
              children: [
                Positioned.fill(
                  child: Container(color: const Color(0xFF7069FA)),
                ),
                SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    24 + viewPadding.top,
                    20,
                    24 + (viewInsets > 0 ? viewInsets : viewPadding.bottom),
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: (availableHeight - 48)
                          .clamp(0.0, double.infinity),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Bonjour,', style: bonjourStyle),
                        const SizedBox(height: 6),
                        Text('Bienvenue sur Glift', style: bienvenueStyle),
                        const SizedBox(height: 32),
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F9FA),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Connexion',
                                    style: GoogleFonts.quicksand(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                      color: const Color(0xFF3A416F),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  _InputField(
                                    key: const Key('emailField'),
                                    inputKey: const Key('emailInput'),
                                    label: 'Email',
                                    focusNode: _emailFocusNode,
                                    controller: _emailController,
                                    hintText: 'john.doe@email.com',
                                    keyboardType: TextInputType.emailAddress,
                                    onChanged: (_) {
                                      setState(() {
                                        _emailTouched = true;
                                        _errorMessage = null;
                                      });
                                    },
                                    isSuccess: _showEmailSuccess,
                                    isError: _showEmailError,
                                    message: _emailMessage,
                                  ),
                                  const SizedBox(height: 18),
                                  _PasswordField(
                                    controller: _passwordController,
                                    focusNode: _passwordFocusNode,
                                    obscureText: _obscurePassword,
                                    onChanged: (_) {
                                      setState(() {
                                        _passwordTouched = true;
                                        _errorMessage = null;
                                      });
                                    },
                                    onToggleVisibility: _togglePasswordVisibility,
                                    isSuccess: _showPasswordSuccess,
                                    isError: _showPasswordError,
                                    onSubmitted: (_) => _submit(),
                                    message: _passwordMessage,
                                  ),
                                  const SizedBox(height: 12),
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
                                  _SubmitButton(
                                    isLoading: _isLoading,
                                    isEnabled: _isFormValid,
                                    onSubmit: _submit,
                                  ),
                                  const SizedBox(height: 14),
                                  Center(
                                    child: TextButton(
                                      onPressed: _openForgotPassword,
                                      style: TextButton.styleFrom(
                                        foregroundColor: const Color(0xFF7069FA),
                                        textStyle: GoogleFonts.quicksand(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                        padding: EdgeInsets.zero,
                                      ),
                                      child: const Text('Mot de passe oublié'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        _SignupPrompt(
                          onTap: _openSignup,
                          textTheme: textTheme,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  const _SubmitButton({
    required this.isLoading,
    required this.isEnabled,
    required this.onSubmit,
  });

  final bool isLoading;
  final bool isEnabled;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isEnabled && !isLoading
        ? const Color(0xFF7069FA)
        : const Color(0xFFF2F1F6);

    final textColor = isEnabled && !isLoading
        ? Colors.white
        : const Color(0xFFD7D4DC);

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        key: const Key('loginButton'),
        onPressed: isEnabled && !isLoading ? onSubmit : null,
        style: ButtonStyle(
          elevation: WidgetStateProperty.all(0),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return backgroundColor;
            }
            return backgroundColor;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return textColor;
            }
            return textColor;
          }),
          overlayColor: WidgetStateProperty.all(const Color(0x147069FA)),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          ),
          textStyle: WidgetStateProperty.all(
            GoogleFonts.quicksand(
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text('Se connecter'),
      ),
    );
  }
}

class _InputField extends StatefulWidget {
  const _InputField({
    super.key,
    required this.label,
    required this.controller,
    required this.focusNode,
    required this.isSuccess,
    required this.isError,
    required this.message,
    this.hintText,
    this.keyboardType,
    this.onChanged,
    this.inputKey,
  });

  final String label;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isSuccess;
  final bool isError;
  final String message;
  final String? hintText;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final Key? inputKey;

  @override
  State<_InputField> createState() => _InputFieldState();
}

class _InputFieldState extends State<_InputField> {
  bool _isHovered = false;

  Color _borderColor() {
    if (widget.isError) {
      return const Color(0xFFEF4444);
    }
    if (widget.isSuccess) {
      return const Color(0xFF00D591);
    }
    return _isHovered ? const Color(0xFFC2BFC6) : const Color(0xFFD7D4DC);
  }

  Color _messageColor() {
    if (widget.isError) {
      return const Color(0xFFEF4444);
    }
    if (widget.isSuccess) {
      return const Color(0xFF00D591);
    }
    return const Color(0xFF5D6494);
  }

  @override
  Widget build(BuildContext context) {
    final labelStyle = GoogleFonts.quicksand(
      fontWeight: FontWeight.w700,
      fontSize: 16,
      color: const Color(0xFF3A416F),
    );

    final inputStyle = GoogleFonts.quicksand(
      fontWeight: FontWeight.w700,
      fontSize: 16,
      color: const Color(0xFF5D6494),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 5),
          child: Text(widget.label, style: labelStyle),
        ),
        MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: _borderColor()),
              boxShadow: widget.focusNode.hasFocus
                  ? [
                      BoxShadow(
                        color: const Color(0x266069FA),
                        blurRadius: 10,
                        spreadRadius: 0,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: SizedBox(
              height: 45,
              child: TextFormField(
                key: widget.inputKey,
                controller: widget.controller,
                focusNode: widget.focusNode,
                keyboardType: widget.keyboardType,
                style: inputStyle,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: widget.hintText,
                  hintStyle: GoogleFonts.quicksand(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: const Color(0xFFD7D4DC),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                ),
                onChanged: widget.onChanged,
              ),
            ),
          ),
        ),
        const SizedBox(height: 5),
        SizedBox(
          height: 20,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              widget.isError || widget.isSuccess ? widget.message : '',
              style: GoogleFonts.quicksand(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: _messageColor(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PasswordField extends StatefulWidget {
  const _PasswordField({
    required this.controller,
    required this.focusNode,
    required this.obscureText,
    required this.onChanged,
    required this.onToggleVisibility,
    required this.isSuccess,
    required this.isError,
    required this.onSubmitted,
    required this.message,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool obscureText;
  final ValueChanged<String> onChanged;
  final VoidCallback onToggleVisibility;
  final bool isSuccess;
  final bool isError;
  final ValueChanged<String> onSubmitted;
  final String message;

  @override
  State<_PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<_PasswordField> {
  bool _isHovered = false;

  Color _borderColor() {
    if (widget.isError) {
      return const Color(0xFFEF4444);
    }
    if (widget.isSuccess) {
      return const Color(0xFF00D591);
    }
    return _isHovered ? const Color(0xFFC2BFC6) : const Color(0xFFD7D4DC);
  }

  Color _messageColor() {
    if (widget.isError) {
      return const Color(0xFFEF4444);
    }
    if (widget.isSuccess) {
      return const Color(0xFF00D591);
    }
    return const Color(0xFF5D6494);
  }

  @override
  Widget build(BuildContext context) {
    final labelStyle = GoogleFonts.quicksand(
      fontWeight: FontWeight.w700,
      fontSize: 16,
      color: const Color(0xFF3A416F),
    );

    final inputStyle = GoogleFonts.quicksand(
      fontWeight: FontWeight.w700,
      fontSize: 16,
      color: const Color(0xFF5D6494),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Text('Mot de passe', style: labelStyle),
          ),
          MouseRegion(
            onEnter: (_) => setState(() => _isHovered = true),
            onExit: (_) => setState(() => _isHovered = false),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: _borderColor()),
                boxShadow: widget.focusNode.hasFocus
                    ? [
                        BoxShadow(
                          color: const Color(0x266069FA),
                          blurRadius: 10,
                          spreadRadius: 0,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
            ),
            child: SizedBox(
              height: 45,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: TextField(
                      key: const Key('passwordInput'),
                      controller: widget.controller,
                      focusNode: widget.focusNode,
                      obscureText: widget.obscureText,
                      style: inputStyle,
                      onChanged: widget.onChanged,
                      onSubmitted: widget.onSubmitted,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: '••••••••',
                        hintStyle: GoogleFonts.quicksand(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: const Color(0xFFD7D4DC),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 10,
                    top: 10,
                    bottom: 10,
                    child: Semantics(
                      button: true,
                      toggled: !widget.obscureText,
                      label: widget.obscureText
                          ? 'Afficher le mot de passe'
                          : 'Masquer le mot de passe',
                      child: GestureDetector(
                        key: const Key('passwordToggle'),
                        behavior: HitTestBehavior.translucent,
                        onTapDown: (_) => widget.focusNode.requestFocus(),
                        onTap: widget.onToggleVisibility,
                        child: SvgPicture.asset(
                          widget.obscureText
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
          ),
        ),
        const SizedBox(height: 5),
          SizedBox(
            height: 20,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                widget.isError || widget.isSuccess ? widget.message : '',
                style: GoogleFonts.quicksand(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: _messageColor(),
              ),
            ),
          ),
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
    final promptTextStyle = GoogleFonts.quicksand(
      fontWeight: FontWeight.w600,
      fontSize: 16,
      color: const Color(0xFF5D6494),
    );

    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 4,
      children: [
        Text(
          'Pas encore inscrit ? ',
          style: promptTextStyle,
        ),
        TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF6C5CE7),
            textStyle: promptTextStyle,
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
          ),
          child: const Text('Créer un compte'),
        ),
      ],
    );
  }
}
