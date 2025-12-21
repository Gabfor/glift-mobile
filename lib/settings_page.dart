import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase/supabase.dart';

import 'widgets/glift_page_layout.dart';
import 'login_page.dart';
import 'auth/auth_repository.dart';
import 'auth/biometric_auth_service.dart';

class SettingsPage extends StatefulWidget {
  final SupabaseClient supabase;
  final AuthRepository authRepository;
  final BiometricAuthService biometricAuthService;

  const SettingsPage({
    super.key,
    required this.supabase,
    required this.authRepository,
    required this.biometricAuthService,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // Local state for toggles (mocked for now as per requirements)
  final bool _weightMetric = true;
  bool _effort = true;
  bool _links = true;
  bool _notes = true;
  bool _rest = true;
  bool _tracking = true;
  bool _superset = true;
  bool _vibrations = true;
  bool _sound = true;
  bool _isLoggingOut = false;

  Future<void> _signOut() async {
    if (_isLoggingOut) return;
    
    HapticFeedback.lightImpact();
    setState(() => _isLoggingOut = true);

    try {
      await widget.supabase.auth.signOut();
      if (mounted) {
        // Navigate to login page with instant transition and clear the navigation stack
        Navigator.of(context).pushAndRemoveUntil(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => LoginPage(
              supabase: widget.supabase,
              authRepository: widget.authRepository,
              biometricAuthService: widget.biometricAuthService,
            ),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          ),
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint('Error signing out: $e');
      if (mounted) {
        setState(() => _isLoggingOut = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de la déconnexion')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GliftPageLayout(
      title: 'Réglages',
      subtitle: 'Personnaliser l’application',
      scrollable: false,
      padding: EdgeInsets.zero,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
        children: [
          // App Settings
          const _SettingsSectionHeader(title: 'RÉGLAGES DE L’APPLICATION'),
          const SizedBox(height: 10),
          _SettingsContainer(
            children: [
              _SettingsTile(
                title: 'Unités de poids',
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Métrique (kg)',
                      style: GoogleFonts.quicksand(
                        color: const Color(0xFF5D6494),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.chevron_right, color: Color(0xFF5D6494)),
                  ],
                ),
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Exercise Settings
          const _SettingsSectionHeader(title: 'RÉGLAGES DES EXERCICES'),
          const SizedBox(height: 10),
          _SettingsContainer(
            children: [
              _SettingsSwitchTile(
                title: 'Activer Effort',
                value: _effort,
                onChanged: (v) => setState(() => _effort = v),
              ),
              _SettingsSwitchTile(
                title: 'Activer Liens',
                value: _links,
                onChanged: (v) => setState(() => _links = v),
              ),
              _SettingsSwitchTile(
                title: 'Activer Notes',
                value: _notes,
                onChanged: (v) => setState(() => _notes = v),
              ),
              _SettingsSwitchTile(
                title: 'Activer Repos',
                value: _rest,
                onChanged: (v) => setState(() => _rest = v),
              ),
              _SettingsSwitchTile(
                title: 'Activer Suivi',
                value: _tracking,
                onChanged: (v) => setState(() => _tracking = v),
              ),
              _SettingsSwitchTile(
                title: 'Activer Superset',
                value: _superset,
                onChanged: (v) => setState(() => _superset = v),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Rest Time Settings
          const _SettingsSectionHeader(title: 'RÉGLAGES DU TEMPS DE REPOS'),
          const SizedBox(height: 10),
          _SettingsContainer(
            children: [
              _SettingsSwitchTile(
                title: 'Activer les vibrations',
                value: _vibrations,
                onChanged: (v) => setState(() => _vibrations = v),
              ),
              _SettingsSwitchTile(
                title: 'Activer la sonnerie',
                value: _sound,
                onChanged: (v) => setState(() => _sound = v),
              ),
              _SettingsTile(
                title: 'Effet sonore',
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Radar',
                      style: GoogleFonts.quicksand(
                        color: const Color(0xFF5D6494),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.chevron_right, color: Color(0xFF5D6494)),
                  ],
                ),
                onTap: () {},
              ),
              _SettingsTile(
                title: 'Valeur par défaut',
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '0 secondes',
                      style: GoogleFonts.quicksand(
                        color: const Color(0xFF5D6494),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.chevron_right, color: Color(0xFF5D6494)),
                  ],
                ),
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Others
          const _SettingsSectionHeader(title: 'AUTRES'),
          const SizedBox(height: 10),
          _SettingsContainer(
            children: [
              _SettingsTile(
                title: 'Vous aimez Glift ?',
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Evaluez-nous',
                      style: GoogleFonts.quicksand(
                        color: const Color(0xFF5D6494),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.chevron_right, color: Color(0xFF5D6494)),
                  ],
                ),
                onTap: () {},
              ),
              _SettingsTile(
                title: 'Du feedback ?',
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Contactez-nous',
                      style: GoogleFonts.quicksand(
                        color: const Color(0xFF5D6494),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.chevron_right, color: Color(0xFF5D6494)),
                  ],
                ),
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 30),

          // Logout Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoggingOut ? null : _signOut,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isLoggingOut 
                    ? const Color(0xFFF2F1F6) 
                    : const Color(0xFFEF4F4E),
                disabledBackgroundColor: const Color(0xFFF2F1F6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                elevation: 0,
              ),
              child: _isLoggingOut
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD7D4DC)),
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
                  : Text(
                      'Se déconnecter',
                      style: GoogleFonts.quicksand(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsSectionHeader extends StatelessWidget {
  final String title;

  const _SettingsSectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.quicksand(
        color: const Color(0xFFC2BFC6),
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _SettingsContainer extends StatelessWidget {
  final List<Widget> children;

  const _SettingsContainer({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD7D4DC)),
      ),
      child: Column(
        children: children,
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final String title;
  final Widget trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.title,
    required this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: Row(
          children: [
            Text(
              title,
              style: GoogleFonts.quicksand(
                color: const Color(0xFF3A416F),
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            trailing,
          ],
        ),
      ),
    );
  }
}

class _SettingsSwitchTile extends StatelessWidget {
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsSwitchTile({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Row(
        children: [
          Text(
            title,
            style: GoogleFonts.quicksand(
              color: const Color(0xFF3A416F),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          SizedBox(
            width: 44,
            height: 26,
            child: Switch.adaptive(
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              value: value,
              onChanged: onChanged,
              activeColor: const Color(0xFFA1A5FD),
            ),
          ),
        ],
      ),
    );
  }
}
