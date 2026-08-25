import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase/supabase.dart';

import 'auth/auth_repository.dart';
import 'auth/biometric_auth_service.dart';
import 'login_page.dart';
import 'widgets/glift_modal.dart';
import 'widgets/glift_page_layout.dart';

class ResetPasswordPage extends StatefulWidget {
  final SupabaseClient supabase;
  final AuthRepository authRepository;
  final BiometricAuthService? biometricAuthService;

  const ResetPasswordPage({
    super.key,
    required this.supabase,
    required this.authRepository,
    this.biometricAuthService,
  });

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final FocusNode _passwordFocusNode = FocusNode();
  final FocusNode _confirmPasswordFocusNode = FocusNode();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  bool _passwordFocused = false;
  bool _confirmPasswordFocused = false;
  bool _passwordTouched = false;
  bool _confirmPasswordTouched = false;

  @override
  void initState() {
    super.initState();
    _passwordFocusNode.addListener(() {
      setState(() {
        _passwordFocused = _passwordFocusNode.hasFocus;
        if (_passwordFocused) _passwordTouched = true;
      });
    });
    _confirmPasswordFocusNode.addListener(() {
      setState(() {
        _confirmPasswordFocused = _confirmPasswordFocusNode.hasFocus;
        if (_confirmPasswordFocused) _confirmPasswordTouched = true;
      });
    });
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  bool get _hasMinLength => _passwordController.text.length >= 8;
  bool get _hasLetter => RegExp(r'[a-zA-Z]').hasMatch(_passwordController.text);
  bool get _hasNumber => RegExp(r'[0-9]').hasMatch(_passwordController.text);
  bool get _hasSymbol => RegExp(r'[!@#$%^&*(),.?":{}|<>_\-]').hasMatch(_passwordController.text);

  bool get _isPasswordValid =>
      _hasMinLength && _hasLetter && _hasNumber && _hasSymbol;

  bool get _doPasswordsMatch =>
      _confirmPasswordController.text.isNotEmpty &&
      _confirmPasswordController.text == _passwordController.text;

  bool get _isFormValid => _isPasswordValid && _doPasswordsMatch;

  Future<void> _submit() async {
    HapticFeedback.lightImpact();
    FocusScope.of(context).unfocus();

    if (!_isFormValid) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await widget.supabase.auth.updateUser(
        UserAttributes(password: _passwordController.text),
      );

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      await GliftModal.show(
        context: context,
        iconAsset: 'assets/icons/message_succes.svg',
        title: 'Mot de passe modifié !',
        description: 'Ton mot de passe a bien été mis à jour. Tu peux maintenant te connecter.',
        primaryButtonText: 'Se connecter',
        onPrimaryPressed: () {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (_) => LoginPage(
                supabase: widget.supabase,
                authRepository: widget.authRepository,
                biometricAuthService: widget.biometricAuthService,
              ),
            ),
            (route) => false,
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      GliftModal.showError(
        context: context,
        title: 'Erreur',
        description: 'Impossible de mettre à jour le mot de passe. Veuillez réessayer.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GliftPageLayout(
      title: 'Réinitialisation',
      subtitle: 'Nouveau mot de passe',
      resizeToAvoidBottomInset: true,
      fullPageScroll: false,
      scrollable: true,
      physics: const ClampingScrollPhysics(),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                'Choisis un nouveau mot de passe',
                style: GoogleFonts.quicksand(
                  color: const Color(0xFF3A416F),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Champ Nouveau Mot de passe
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
                  color: _passwordFocused
                      ? const Color(0xFF7069FA)
                      : (_passwordTouched && !_isPasswordValid && _passwordController.text.isNotEmpty)
                          ? const Color(0xFFEF4444)
                          : const Color(0xFFD7D4DC),
                  width: 1.0,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _passwordController,
                      focusNode: _passwordFocusNode,
                      obscureText: _obscurePassword,
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
                      _obscurePassword
                          ? 'assets/icons/masque_defaut.svg'
                          : 'assets/icons/visible_defaut.svg',
                      width: 20,
                      height: 20,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ],
              ),
            ),

            // Critères de mot de passe
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x0F000000),
                    blurRadius: 9,
                    offset: const Offset(1, 1),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _CriteriaItem(valid: _hasMinLength, text: 'Au moins 8 caractères'),
                  const SizedBox(height: 6),
                  _CriteriaItem(valid: _hasLetter, text: 'Au moins 1 lettre'),
                  const SizedBox(height: 6),
                  _CriteriaItem(valid: _hasNumber, text: 'Au moins 1 chiffre'),
                  const SizedBox(height: 6),
                  _CriteriaItem(valid: _hasSymbol, text: 'Au moins 1 symbole'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Champ Confirmer mot de passe
            Text(
              'Confirmer le mot de passe',
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
                  color: _confirmPasswordFocused
                      ? const Color(0xFF7069FA)
                      : (_confirmPasswordTouched && !_doPasswordsMatch && _confirmPasswordController.text.isNotEmpty)
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
                    onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Bouton Valider
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isFormValid && !_isLoading ? _submit : null,
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
                        'Valider mon nouveau mot de passe',
                        style: GoogleFonts.quicksand(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _isFormValid ? Colors.white : const Color(0xFFD7D4DC),
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

class _CriteriaItem extends StatelessWidget {
  final bool valid;
  final String text;

  const _CriteriaItem({required this.valid, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          text,
          style: GoogleFonts.quicksand(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: valid ? const Color(0xFF00D591) : const Color(0xFFD7D4DC),
          ),
        ),
        SvgPicture.asset(
          valid ? 'assets/icons/check_green.svg' : 'assets/icons/check_grey.svg',
          width: 16,
          height: 16,
        ),
      ],
    );
  }
}
