import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase/supabase.dart';

import 'widgets/glift_page_layout.dart';
import 'widgets/glift_pull_to_refresh.dart';
import 'login_page.dart';
import 'auth/auth_repository.dart';
import 'auth/biometric_auth_service.dart';
import 'services/settings_service.dart';
import 'weight_unit_settings_page.dart';
import 'display_settings_page.dart';
import 'sound_settings_page.dart';
import 'default_timer_page.dart';
import 'user_informations_page.dart';
import 'user_subscription_page.dart';

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
  late final PageController _pageController;
  int _currentTab = 0;

  // Local state for toggles (mocked for now as per requirements)
  String _weightUnit = 'metric';
  bool _effort = true;
  bool _links = true;
  bool _notes = true;
  bool _suivi = true;
  bool _material = true;
  bool _rest = true;
  bool _superset = true;
  bool _showSummary = true;
  bool _showGoals = true;
  bool _autoTrigger = true;
  bool _vibrations = true;
  bool _sound = true;
  String _displayType = 'Miniature';
  String _soundEffect = 'radar';
  int _defaultRestTime = 60;
  bool _isLoggingOut = false;
  bool _newsletterGlift = false;
  bool _surveys = false;
  bool _newsletterShop = false;
  bool _newsletterStore = false;
  String _subscriptionPlan = 'basic';

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _applySettingsFromService();
    _loadSettings();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _applySettingsFromService() {
    if (!mounted) return;
    final settings = SettingsService.instance;
    setState(() {
      _material = settings.getMaterialEnabled();
      _effort = settings.getShowEffort();
      _autoTrigger = settings.getAutoTriggerEnabled();
      _displayType = settings.getDisplayType();
      _weightUnit = settings.getWeightUnit();
      _soundEffect = settings.getSoundEffect();
      _sound = settings.getSoundEnabled();
      _vibrations = settings.getVibrationEnabled();
      _links = settings.getShowLinks();
      _notes = settings.getShowNotes();
      _suivi = settings.getShowSuivi();
      _superset = settings.getShowSuperset();
      _showSummary = settings.getShowSummary();
      _showGoals = settings.getShowGoals();
      _newsletterGlift = settings.getNewsletterGlift();
      _surveys = settings.getSurveys();
      _newsletterShop = settings.getNewsletterShop();
      _newsletterStore = settings.getNewsletterStore();
      _subscriptionPlan = settings.getSubscriptionPlan();

      _rest = settings.getShowRepos();
      _defaultRestTime = settings.getDefaultRestTime(); 
    });
  }

  Future<void> _loadSettings() async {
    final settings = SettingsService.instance;
    await settings.init();
    await settings.initSupabase(widget.supabase);
    _applySettingsFromService();
  }

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

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 20, right: 20, top: 10),
          child: Text(
            'Réglages',
            style: GoogleFonts.quicksand(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 20, right: 20),
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  if (_currentTab != 0) {
                    _pageController.animateToPage(
                      0,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                },
                child: Text(
                  'Mon application',
                  style: GoogleFonts.quicksand(
                    color: _currentTab == 0
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.5),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              GestureDetector(
                onTap: () {
                  if (_currentTab != 1) {
                    _pageController.animateToPage(
                      1,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                },
                child: Text(
                  'Mon profil',
                  style: GoogleFonts.quicksand(
                    color: _currentTab == 1
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.5),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildApplicationTab() {
    return GliftPullToRefresh(
      onRefresh: () async {
        await SettingsService.instance.syncFromSupabase();
        _applySettingsFromService();
      },
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
                      _weightUnit == 'imperial' ? 'Lb' : 'Kg',
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
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => WeightUnitSettingsPage(
                        initialValue: _weightUnit,
                        onChanged: (value) {
                          setState(() => _weightUnit = value);
                          SettingsService.instance.saveWeightUnit(value);
                        },
                      ),
                    ),
                  );
                },
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
                onChanged: (v) {
                  setState(() => _effort = v);
                  SettingsService.instance.saveShowEffort(v);
                },
              ),
              _SettingsSwitchTile(
                title: 'Activer Liens',
                value: _links,
                onChanged: (v) {
                  setState(() => _links = v);
                  SettingsService.instance.saveShowLinks(v);
                },
              ),
              _SettingsSwitchTile(
                title: 'Activer Notes',
                value: _notes,
                onChanged: (v) {
                  setState(() {
                    _notes = v;
                    if (!v) _material = false;
                  });
                  SettingsService.instance.saveShowNotes(v);
                },
              ),
              _SettingsSwitchTile(
                title: 'Activer Matériel',
                value: _material,
                enabled: _notes, // Disabled if Notes is OFF
                onChanged: (v) {
                  setState(() => _material = v);
                  SettingsService.instance.saveMaterialEnabled(v);
                },
              ),
              _SettingsSwitchTile(
                title: 'Activer Repos',
                value: _rest,
                onChanged: (v) {
                  setState(() => _rest = v);
                  SettingsService.instance.saveShowRepos(v);
                },
              ),
              _SettingsSwitchTile(
                title: 'Activer Suivi',
                value: _suivi,
                onChanged: (v) {
                  setState(() => _suivi = v);
                  SettingsService.instance.saveShowSuivi(v);
                },
              ),
              _SettingsSwitchTile(
                title: 'Activer Superset',
                value: _superset,
                onChanged: (v) {
                  setState(() => _superset = v);
                  SettingsService.instance.saveShowSuperset(v);
                },
              ),
              _SettingsSwitchTile(
                title: 'Activer Récapitulatif',
                value: _showSummary,
                onChanged: (v) {
                  setState(() => _showSummary = v);
                  SettingsService.instance.saveShowSummary(v);
                },
              ),
              _SettingsSwitchTile(
                title: 'Activer Objectifs',
                value: _showGoals,
                onChanged: (v) {
                  setState(() => _showGoals = v);
                  SettingsService.instance.saveShowGoals(v);
                },
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
                title: 'Déclenchement automatique',
                value: _autoTrigger,
                onChanged: (v) {
                  setState(() => _autoTrigger = v);
                  SettingsService.instance.saveAutoTriggerEnabled(v);
                },
              ),
              _SettingsSwitchTile(
                title: 'Activer les vibrations',
                value: _vibrations,
                onChanged: (v) {
                  setState(() => _vibrations = v);
                  SettingsService.instance.saveVibrationEnabled(v);
                },
              ),
              _SettingsSwitchTile(
                title: 'Activer la sonnerie',
                value: _sound,
                onChanged: (v) {
                  setState(() => _sound = v);
                  SettingsService.instance.saveSoundEnabled(v);
                },
              ),
              _SettingsTile(
                title: 'Sonnerie',
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _getSoundEffectLabel(_soundEffect),
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
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => SoundSettingsPage(
                        initialValue: _soundEffect,
                        onChanged: (value) {
                          setState(() => _soundEffect = value);
                          SettingsService.instance.saveSoundEffect(value);
                        },
                      ),
                    ),
                  );
                },
              ),
              _SettingsTile(
                title: 'Type d\'affichage',
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _displayType,
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
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => DisplaySettingsPage(
                        initialValue: _displayType,
                        onChanged: (value) {
                          setState(() => _displayType = value);
                          SettingsService.instance.saveDisplayType(value);
                        },
                      ),
                    ),
                  );
                },
              ),
              _SettingsTile(
                title: 'Valeur par défaut',
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$_defaultRestTime secondes',
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
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => DefaultTimerPage(
                        initialDuration: _defaultRestTime,
                      ),
                    ),
                  ).then((_) {
                    // Update state when returning
                     setState(() {
                       _defaultRestTime = SettingsService.instance.getDefaultRestTime();
                     });
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 30),

          // Logout Button
          _buildLogoutButton(),
        ],
      ),
    );
  }

  Widget _buildProfileTab() {
    return GliftPullToRefresh(
      onRefresh: () async {
        await SettingsService.instance.syncFromSupabase();
        _applySettingsFromService();
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
        children: [
          // Profil Section
          const _SettingsSectionHeader(title: 'PROFIL'),
          const SizedBox(height: 10),
          _SettingsContainer(
            children: [
              _SettingsTile(
                title: 'Mes informations',
                trailing: const Icon(Icons.chevron_right, color: Color(0xFF5D6494)),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => UserInformationsPage(
                        supabase: widget.supabase,
                      ),
                    ),
                  );
                },
              ),
              _SettingsTile(
                title: 'Mon abonnement',
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _subscriptionPlan == 'premium' ? 'Premium' : 'Starter',
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
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => UserSubscriptionPage(
                        supabase: widget.supabase,
                      ),
                    ),
                  ).then((_) {
                    _applySettingsFromService();
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Communications Section
          const _SettingsSectionHeader(title: 'COMMUNICATIONS'),
          const SizedBox(height: 10),
          _SettingsContainer(
            children: [
              _SettingsSwitchTile(
                title: 'Newsletter Glift',
                value: _newsletterGlift,
                onChanged: (v) {
                  setState(() => _newsletterGlift = v);
                  SettingsService.instance.saveNewsletterGlift(v);
                },
              ),
              _SettingsSwitchTile(
                title: 'Enquêtes sondages',
                value: _surveys,
                onChanged: (v) {
                  setState(() => _surveys = v);
                  SettingsService.instance.saveSurveys(v);
                },
              ),
              _SettingsSwitchTile(
                title: 'Newsletter Glift Shop',
                value: _newsletterShop,
                onChanged: (v) {
                  setState(() => _newsletterShop = v);
                  SettingsService.instance.saveNewsletterShop(v);
                },
              ),
              _SettingsSwitchTile(
                title: 'Newsletter Glift Store',
                value: _newsletterStore,
                onChanged: (v) {
                  setState(() => _newsletterStore = v);
                  SettingsService.instance.saveNewsletterStore(v);
                },
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Autres Section
          const _SettingsSectionHeader(title: 'AUTRES'),
          const SizedBox(height: 10),
          _SettingsContainer(
            children: [
              _SettingsTile(
                title: 'Tu aimes Glift ?',
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Nous évaluer',
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
                      'Nous contacter',
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
                title: 'Besoin d\'aide ?',
                trailing: const Icon(Icons.chevron_right, color: Color(0xFF5D6494)),
                onTap: () {},
              ),
              _SettingsTile(
                title: 'Mentions légales',
                trailing: const Icon(Icons.chevron_right, color: Color(0xFF5D6494)),
                onTap: () {
                  // TODO: Add navigation to legal mentions
                },
              ),
            ],
          ),
          const SizedBox(height: 30),

          // Logout Button
          _buildLogoutButton(),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return GliftPageLayout(
      header: _buildHeader(),
      scrollable: false,
      padding: EdgeInsets.zero,
      headerPadding: EdgeInsets.zero,
      child: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentTab = index;
          });
        },
        children: [
          _buildApplicationTab(),
          _buildProfileTab(),
        ],
      ),
    );
  }
  String _getSoundEffectLabel(String value) {
    if (value == 'none') return 'Aucun';
    if (value == 'bip') return 'Bip';
    if (value == 'radar') return 'Radar';
    if (value == 'gong') return 'Gong';
    if (value == 'bell') return 'Cloche';
    return 'Radar';
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
        padding: const EdgeInsets.only(left: 15, right: 9),
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
  final bool enabled;

  const _SettingsSwitchTile({
    required this.title,
    required this.value,
    required this.onChanged,
    this.enabled = true,
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
              color: enabled ? const Color(0xFF3A416F) : const Color(0xFFD7D4DC),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          SizedBox(
            width: 44,
            height: 26,
            child: IgnorePointer(
              ignoring: !enabled,
              child: Switch.adaptive(
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                value: enabled ? value : false,
                onChanged: (v) {
                  if (enabled) {
                    HapticFeedback.lightImpact();
                    onChanged(v);
                  }
                },
                activeColor: const Color(0xFFA1A5FD),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
