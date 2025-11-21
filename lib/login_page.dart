import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 70, left: 24, right: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Bonjour,', style: bonjourStyle),
                    const SizedBox(height: 4),
                    Text('Bienvenue sur Glift', style: bienvenueStyle),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(40),
                    ),
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final viewInsets = MediaQuery.of(context).viewInsets.bottom;
                      final verticalPadding = 50 + 24;

                      return SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(
                          24,
                          50,
                          24,
                          24 + viewInsets,
                        ),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: 420,
                            minHeight:
                                constraints.maxHeight - (verticalPadding + viewInsets),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Connexion',
                                      style: GoogleFonts.quicksand(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                        color: GliftTheme.title,
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    Align(
                                      alignment: Alignment.center,
                                      child: ConstrainedBox(
                                        constraints:
                                            const BoxConstraints(maxWidth: 368),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            _InputField(
                                              key: const Key('emailField'),
                                              inputKey: const Key('emailInput'),
                                              label: 'Email',
                                              focusNode: _emailFocusNode,
                                              controller: _emailController,
                                              hintText: 'john.doe@email.com',
                                              keyboardType:
                                                  TextInputType.emailAddress,
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
                                            const SizedBox(height: 16),
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
                                              onToggleVisibility:
                                                  _togglePasswordVisibility,
                                              isSuccess: _showPasswordSuccess,
                                              isError: _showPasswordError,
                                              onSubmitted: (_) => _submit(),
                                              onForgotPassword: _openForgotPassword,
                                              message: _passwordMessage,
                                            ),
                                          ],
                                        ),
                                      ),
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
                                    Center(
                                      child: SizedBox(
                                        width: 160,
                                        height: 44,
                                        child: Stack(
                                          children: [
                                            if (!_isFormValid && !_isLoading)
                                              Positioned.fill(
                                                child: GestureDetector(
                                                  behavior: HitTestBehavior.translucent,
                                                  onTap: _submit,
                                                ),
                                              ),
                                            ElevatedButton(
                                              key: const Key('loginButton'),
                                              onPressed: _isFormValid && !_isLoading
                                                  ? _submit
                                                  : null,
                                              style: ButtonStyle(
                                                backgroundColor:
                                                    WidgetStateProperty.resolveWith(
                                                  (states) {
                                                    if (states.contains(
                                                        WidgetState.disabled)) {
                                                      return const Color(0xFFF2F1F6);
                                                    }
                                                    if (states.contains(
                                                        WidgetState.pressed)) {
                                                      return const Color(0xFF6660E4);
                                                    }
                                                    if (states.contains(
                                                        WidgetState.hovered)) {
                                                      return const Color(0xFF6660E4);
                                                    }
                                                    return const Color(0xFF7069FA);
                                                  },
                                                ),
                                                foregroundColor:
                                                    WidgetStateProperty.resolveWith(
                                                  (states) {
                                                    if (states.contains(
                                                        WidgetState.disabled)) {
                                                      return const Color(0xFFD7D4DC);
                                                    }
                                                    return Colors.white;
                                                  },
                                                ),
                                                overlayColor:
                                                    WidgetStateProperty.resolveWith(
                                                  (states) {
                                                    if (states.contains(
                                                        WidgetState.pressed)) {
                                                      return const Color(0x1A13027B);
                                                    }
                                                    return null;
                                                  },
                                                ),
                                                elevation:
                                                    WidgetStateProperty.all<double>(0),
                                                shape: WidgetStateProperty.all<
                                                    RoundedRectangleBorder>(
                                                  RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(14),
                                                  ),
                                                ),
                                              ),
                                              child: _isLoading
                                                  ? const SizedBox(
                                                      height: 20,
                                                      width: 20,
                                                      child: CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        valueColor:
                                                            AlwaysStoppedAnimation<
                                                                Color>(Colors.white),
                                                      ),
                                                    )
                                                  : Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment.center,
                                                      children: [
                                                        SvgPicture.asset(
                                                          'assets/icons/login-button.svg',
                                                          height: 20,
                                                          width: 20,
                                                          colorFilter:
                                                              ColorFilter.mode(
                                                            _isFormValid &&
                                                                    !_isLoading
                                                                ? Colors.white
                                                                : const Color(
                                                                    0xFFD7D4DC),
                                                            BlendMode.srcIn,
                                                          ),
                                                        ),
                                                        const SizedBox(width: 8),
                                                        const Text('Se connecter'),
                                                      ],
                                                    ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Center(
                                      child: TextButton(
                                        onPressed: _openForgotPassword,
                                        style: TextButton.styleFrom(
                                          foregroundColor:
                                              const Color(0xFF7069FA),
                                          textStyle: GoogleFonts.inter(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ).copyWith(
                                          overlayColor:
                                              WidgetStateProperty.all(
                                            const Color(0x1A7069FA),
                                          ),
                                        ),
                                        child: const Text('Mot de passe oublié'),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 32),
                                child: _SignupPrompt(
                                  onTap: _openSignup,
                                  textTheme: textTheme,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
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
    final labelStyle = GoogleFonts.inter(
      fontWeight: FontWeight.w700,
      fontSize: 16,
      color: const Color(0xFF3A416F),
    );

    final inputStyle = GoogleFonts.inter(
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
                        color: const Color(0x73A1A5FD),
                        blurRadius: 0,
                        spreadRadius: 2,
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
                  hintStyle: GoogleFonts.inter(
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
              style: GoogleFonts.inter(
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
    required this.onForgotPassword,
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
  final VoidCallback onForgotPassword;
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
    final labelStyle = GoogleFonts.inter(
      fontWeight: FontWeight.w700,
      fontSize: 16,
      color: const Color(0xFF3A416F),
    );

    final inputStyle = GoogleFonts.inter(
      fontWeight: FontWeight.w700,
      fontSize: 16,
      color: const Color(0xFF5D6494),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Mot de passe', style: labelStyle),
              TextButton(
                onPressed: widget.onForgotPassword,
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF7069FA),
                  textStyle: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ).copyWith(
                  overlayColor: WidgetStateProperty.all(
                    const Color(0x1F6660E4),
                  ),
                ),
                child: const Text('Mot de passe oublié ?'),
              ),
            ],
          ),
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
                        color: const Color(0x73A1A5FD),
                        blurRadius: 0,
                        spreadRadius: 2,
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
                      onFieldSubmitted: widget.onSubmitted,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: '••••••••',
                        hintStyle: GoogleFonts.inter(
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
              style: GoogleFonts.inter(
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
