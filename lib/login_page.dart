import 'package:flutter/material.dart';
import 'package:supabase/supabase.dart';

import 'auth/auth_repository.dart';
import 'design/colors.dart';
import 'design/spacing.dart';
import 'design/theme.dart';
import 'design/typography.dart';
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
        emailError: _isEmailValid ? null : 'Format d'adresse invalide',
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
        emailError: _isEmailValid ? null : 'Format d'adresse invalide',
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
    final mediaQuery = MediaQuery.of(context);
    final viewInsets = mediaQuery.viewInsets.bottom;

    return Theme(
      data: DesignTheme.light(),
      child: Scaffold(
        backgroundColor: BrandColors.pageBackground,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final minHeight = constraints.maxHeight - viewInsets;

              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(20, 24, 20, 16 + viewInsets),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: minHeight),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _PageHeader(),
                      const SizedBox(height: 20),
                      _LoginCard(
                        formKey: _formKey,
                        emailController: _emailController,
                        passwordController: _passwordController,
                        emailFocusNode: _emailFocusNode,
                        passwordFocusNode: _passwordFocusNode,
                        isLoading: _isLoading,
                        isFormValid: _isFormValid,
                        showEmailSuccess: _showEmailSuccess,
                        showEmailError: _showEmailError,
                        showPasswordSuccess: _showPasswordSuccess,
                        showPasswordError: _showPasswordError,
                        emailMessage: _emailMessage,
                        passwordMessage: _passwordMessage,
                        errorMessage: _errorMessage,
                        obscurePassword: _obscurePassword,
                        onEmailChanged: (_) {
                          setState(() {
                            _emailTouched = true;
                            _errorMessage = null;
                          });
                        },
                        onPasswordChanged: (_) {
                          setState(() {
                            _passwordTouched = true;
                            _errorMessage = null;
                          });
                        },
                        onSubmit: _submit,
                        onTogglePassword: _togglePasswordVisibility,
                        onForgotPassword: _openForgotPassword,
                        onSignup: _openSignup,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PageHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: BrandColors.accentPale,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Text(
            'Heureux de te revoir',
            style: textTheme.labelSmall?.copyWith(color: BrandColors.primary),
          ),
        ),
        const SizedBox(height: 12),
        Text('Connexion', style: textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(
          'Accède à ton suivi et reprends ton entraînement où tu t'es arrêté.',
          style: textTheme.bodyLarge,
        ),
      ],
    );
  }
}

class _LoginCard extends StatelessWidget {
  const _LoginCard({
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.emailFocusNode,
    required this.passwordFocusNode,
    required this.isLoading,
    required this.isFormValid,
    required this.showEmailSuccess,
    required this.showEmailError,
    required this.showPasswordSuccess,
    required this.showPasswordError,
    required this.emailMessage,
    required this.passwordMessage,
    required this.errorMessage,
    required this.obscurePassword,
    required this.onEmailChanged,
    required this.onPasswordChanged,
    required this.onSubmit,
    required this.onTogglePassword,
    required this.onForgotPassword,
    required this.onSignup,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final FocusNode emailFocusNode;
  final FocusNode passwordFocusNode;
  final bool isLoading;
  final bool isFormValid;
  final bool showEmailSuccess;
  final bool showEmailError;
  final bool showPasswordSuccess;
  final bool showPasswordError;
  final String emailMessage;
  final String passwordMessage;
  final String? errorMessage;
  final bool obscurePassword;
  final ValueChanged<String> onEmailChanged;
  final ValueChanged<String> onPasswordChanged;
  final VoidCallback onSubmit;
  final VoidCallback onTogglePassword;
  final VoidCallback onForgotPassword;
  final VoidCallback onSignup;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radius),
        boxShadow: const [Shadows.glift],
      ),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _InputField(
              key: const Key('emailField'),
              inputKey: const Key('emailInput'),
              label: 'Email',
              focusNode: emailFocusNode,
              controller: emailController,
              hintText: 'john.doe@email.com',
              keyboardType: TextInputType.emailAddress,
              onChanged: onEmailChanged,
              isSuccess: showEmailSuccess,
              isError: showEmailError,
              message: emailMessage,
            ),
            const SizedBox(height: 14),
            _PasswordField(
              controller: passwordController,
              focusNode: passwordFocusNode,
              obscureText: obscurePassword,
              onChanged: onPasswordChanged,
              onToggleVisibility: onTogglePassword,
              isSuccess: showPasswordSuccess,
              isError: showPasswordError,
              onSubmitted: (_) => onSubmit(),
              onForgotPassword: onForgotPassword,
              message: passwordMessage,
            ),
            if (errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                errorMessage!,
                style: textTheme.bodyMedium?.copyWith(
                  color: TailwindLightColors.destructive,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: AppSpacing.buttonHeight,
              child: ElevatedButton(
                key: const Key('loginButton'),
                onPressed: isFormValid && !isLoading ? onSubmit : null,
                child: isLoading
                    ? const SizedBox(
                        height: AppSpacing.spinnerMd,
                        width: AppSpacing.spinnerMd,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Se connecter'),
              ),
            ),
            const SizedBox(height: 16),
            const Divider(color: BrandColors.border),
            const SizedBox(height: 12),
            _SignupPrompt(
              onTap: onSignup,
              textTheme: textTheme,
            ),
          ],
        ),
      ),
    );
  }
}

class _InputField extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    Color? suffixColor() {
      if (isError) return TailwindLightColors.destructive;
      if (isSuccess) return BrandColors.primary;
      return null;
    }

    final suffixIcon = suffixColor() != null
        ? Icon(
            isError ? Icons.error_outline : Icons.check_circle,
            color: suffixColor(),
          )
        : null;

    final messageColor = isError
        ? TailwindLightColors.destructive
        : isSuccess
            ? BrandColors.primary
            : BrandColors.body;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: textTheme.bodyMedium?.copyWith(color: BrandColors.title),
        ),
        const SizedBox(height: 6),
        TextFormField(
          key: inputKey,
          controller: controller,
          focusNode: focusNode,
          keyboardType: keyboardType,
          style: AppTypography.inputText,
          decoration: InputDecoration(
            hintText: hintText,
            suffixIcon: suffixIcon,
          ),
          onChanged: onChanged,
        ),
        const SizedBox(height: 6),
        Text(
          isError || isSuccess ? message : '',
          style: textTheme.bodySmall?.copyWith(
            color: messageColor,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _PasswordField extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    Color? suffixColor() {
      if (isError) return TailwindLightColors.destructive;
      if (isSuccess) return BrandColors.primary;
      return BrandColors.body;
    }

    final messageColor = isError
        ? TailwindLightColors.destructive
        : isSuccess
            ? BrandColors.primary
            : BrandColors.body;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Mot de passe',
                style: textTheme.bodyMedium?.copyWith(color: BrandColors.title),
              ),
            ),
            TextButton(
              onPressed: onForgotPassword,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Oublié ?',
                style: textTheme.bodySmall?.copyWith(color: BrandColors.primary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          key: const Key('passwordInput'),
          controller: controller,
          focusNode: focusNode,
          obscureText: obscureText,
          style: AppTypography.inputText,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          decoration: InputDecoration(
            hintText: '••••••••',
            suffixIcon: IconButton(
              key: const Key('passwordToggle'),
              splashRadius: 20,
              onPressed: onToggleVisibility,
              icon: Icon(
                obscureText
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: suffixColor(),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          isError || isSuccess ? message : '',
          style: textTheme.bodySmall?.copyWith(
            color: messageColor,
            fontWeight: FontWeight.w700,
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
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 4,
      children: [
        Text(
          'Pas encore inscrit ? ',
          style: textTheme.bodyMedium?.copyWith(color: BrandColors.body),
        ),
        TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            foregroundColor: BrandColors.primary,
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
          ),
          child: Text(
            'Créer un compte',
            style: textTheme.bodyMedium?.copyWith(
              color: BrandColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
