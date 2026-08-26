import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth/auth_repository.dart';
import 'auth/biometric_auth_service.dart';
import 'main_page.dart';
import 'services/settings_service.dart';
import 'widgets/glift_page_layout.dart';

class PricingPage extends StatefulWidget {
  final String userName;
  final SupabaseClient supabase;
  final AuthRepository authRepository;
  final BiometricAuthService biometricAuthService;

  const PricingPage({
    super.key,
    required this.userName,
    required this.supabase,
    required this.authRepository,
    required this.biometricAuthService,
  });

  @override
  State<PricingPage> createState() => _PricingPageState();
}

class _PricingPageState extends State<PricingPage> {
  bool _isLoading = false;
  String? _loadingPlan;

  Future<void> _selectPlan(String plan) async {
    if (_isLoading) return;
    HapticFeedback.lightImpact();

    setState(() {
      _isLoading = true;
      _loadingPlan = plan;
    });

    try {
      final user = widget.supabase.auth.currentUser;

      if (user != null) {
        if (plan == 'premium') {
          final now = DateTime.now();
          final trialEnd = now.add(const Duration(days: 30));
          await widget.supabase.from('profiles').update({
            'subscription_plan': 'premium',
            'premium_trial_started_at': now.toIso8601String(),
            'premium_trial_end_at': trialEnd.toIso8601String(),
            'trial': true,
          }).eq('id', user.id);

          try {
            await widget.supabase.from('user_subscriptions').upsert({
              'user_id': user.id,
              'plan': 'premium',
            });
          } catch (_) {}
        } else {
          await widget.supabase.from('profiles').update({
            'subscription_plan': 'starter',
          }).eq('id', user.id);

          try {
            await widget.supabase.from('user_subscriptions').upsert({
              'user_id': user.id,
              'plan': 'starter',
            });
          } catch (_) {}
        }

        await SettingsService.instance.syncFromSupabase();
      }

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => MainPage(
            supabase: widget.supabase,
            authRepository: widget.authRepository,
            biometricAuthService: widget.biometricAuthService,
          ),
        ),
        (route) => false,
      );
    } catch (e) {
      debugPrint('Error selecting plan: $e');
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => MainPage(
            supabase: widget.supabase,
            authRepository: widget.authRepository,
            biometricAuthService: widget.biometricAuthService,
          ),
        ),
        (route) => false,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadingPlan = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String rawName = widget.userName.trim();
    if (rawName.isEmpty) {
      final user = widget.supabase.auth.currentUser;
      rawName = (user?.userMetadata?['name'] ??
              user?.userMetadata?['full_name'] ??
              (user?.email != null ? user!.email!.split('@').first : ''))
          .toString()
          .trim();
    }

    String firstName = rawName.isNotEmpty ? rawName.split(' ').first : '';
    if (firstName.isNotEmpty) {
      firstName = firstName[0].toUpperCase() + firstName.substring(1);
    }

    final greetingTitle =
        firstName.isNotEmpty ? 'Enchanté $firstName !' : 'Enchanté !';

    return GliftPageLayout(
      title: greetingTitle,
      subtitle: 'Choisissez votre formule d’abonnement',
      scrollable: true,
      fullPageScroll: false,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      child: Column(
        children: [
          // ─── CARTE 1 : ABONNEMENT PREMIUM ──────────────────────────────
          _PlanCard(
            iconAsset: 'assets/icons/diamant_gold.svg',
            title: 'Abonnement Premium',
            price: '2,49 €',
            period: '/mois',
            features: const [
              _FeatureItem(
                boldText: 'Un nombre illimité',
                regularText: ' d’entraînements',
                isEnabled: true,
              ),
              _FeatureItem(
                boldText: 'Un nombre illimité',
                regularText: ' d’exercices',
                isEnabled: true,
              ),
              _FeatureItem(
                regularText: 'Un tableau de bord personnalisé',
                isEnabled: true,
              ),
              _FeatureItem(
                boldText: 'Accès aux programmes',
                regularText: ' du Glift Store',
                isEnabled: true,
              ),
              _FeatureItem(
                boldText: 'Offres personnalisées',
                regularText: ' dans la Glift Shop',
                isEnabled: true,
              ),
              _FeatureItem(
                regularText: 'Annulation gratuite à tout moment',
                isEnabled: true,
              ),
            ],
            button: _PremiumButton(
              isLoading: _isLoading && _loadingPlan == 'premium',
              onPressed: _isLoading ? null : () => _selectPlan('premium'),
            ),
            footerNote: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const _PulsingGreenDot(),
                const SizedBox(width: 8),
                Text(
                  '30 jours pour tester, puis 2,49 € /mois',
                  style: GoogleFonts.quicksand(
                    color: const Color(0xFF5D6494),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ─── CARTE 2 : ABONNEMENT STARTER ──────────────────────────────
          _PlanCard(
            iconAsset: 'assets/icons/diamant_purple.svg',
            title: 'Abonnement Starter',
            price: '0,00 €',
            period: '/mois',
            features: const [
              _FeatureItem(
                regularText: 'Un seul entrainement',
                isEnabled: true,
              ),
              _FeatureItem(
                regularText: 'Un maximum de 10 exercices',
                isEnabled: true,
              ),
              _FeatureItem(
                regularText: 'Un tableau de bord personnalisé',
                isEnabled: true,
              ),
              _FeatureItem(
                regularText: 'Accès aux programmes du Glift Store',
                isEnabled: false,
              ),
              _FeatureItem(
                regularText: 'Offres personnalisées dans la Glift Shop',
                isEnabled: false,
              ),
            ],
            button: _StarterButton(
              isLoading: _isLoading && _loadingPlan == 'starter',
              onPressed: _isLoading ? null : () => _selectPlan('starter'),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final String iconAsset;
  final String title;
  final String price;
  final String period;
  final List<_FeatureItem> features;
  final Widget button;
  final Widget? footerNote;

  const _PlanCard({
    required this.iconAsset,
    required this.title,
    required this.price,
    required this.period,
    required this.features,
    required this.button,
    this.footerNote,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFECE9F1),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5D6494).withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Icone Diamant
                SvgPicture.asset(
                  iconAsset,
                  width: 44,
                  height: 36,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 14),

                // Titre Plan
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.quicksand(
                    color: const Color(0xFF3A416F),
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),

                // Prix & Période
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      price,
                      style: GoogleFonts.quicksand(
                        color: const Color(0xFF3A416F),
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      ' $period',
                      style: GoogleFonts.quicksand(
                        color: const Color(0xFF5D6494),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),

                // Liste des avantages
                Column(
                  children: features.map((feature) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SvgPicture.asset(
                            feature.isEnabled
                                ? 'assets/icons/plan_check_green.svg'
                                : 'assets/icons/plan_check_grey.svg',
                            width: 18,
                            height: 18,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  if (feature.boldText.isNotEmpty)
                                    TextSpan(
                                      text: feature.boldText,
                                      style: GoogleFonts.quicksand(
                                        fontWeight: FontWeight.w700,
                                        color: feature.isEnabled
                                            ? const Color(0xFF3A416F)
                                            : const Color(0xFFB1BACC),
                                        decoration: feature.isEnabled
                                            ? TextDecoration.none
                                            : TextDecoration.lineThrough,
                                        decorationColor: const Color(0xFFB1BACC),
                                      ),
                                    ),
                                  TextSpan(
                                    text: feature.regularText,
                                    style: GoogleFonts.quicksand(
                                      fontWeight: FontWeight.w600,
                                      color: feature.isEnabled
                                          ? const Color(0xFF5D6494)
                                          : const Color(0xFFB1BACC),
                                      decoration: feature.isEnabled
                                          ? TextDecoration.none
                                          : TextDecoration.lineThrough,
                                      decorationColor: const Color(0xFFB1BACC),
                                    ),
                                  ),
                                ],
                              ),
                              style: GoogleFonts.quicksand(
                                fontSize: 14,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 12),

                // Bouton d'action
                button,

                if (footerNote != null) ...[
                  const SizedBox(height: 12),
                  footerNote!,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureItem {
  final String boldText;
  final String regularText;
  final bool isEnabled;

  const _FeatureItem({
    this.boldText = '',
    required this.regularText,
    required this.isEnabled,
  });
}

class _PremiumButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onPressed;

  const _PremiumButton({
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final color = isLoading ? const Color(0xFFF2F1F6) : const Color(0xFF7069FA);
    final textColor = isLoading ? const Color(0xFFD7D4DC) : Colors.white;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: double.infinity,
      height: 48,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(25),
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          disabledBackgroundColor: color,
          foregroundColor: textColor,
          disabledForegroundColor: textColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
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
                      color: textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              )
            : Text(
                'Tester gratuitement',
                style: GoogleFonts.quicksand(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }
}

class _StarterButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onPressed;

  const _StarterButton({
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        width: double.infinity,
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFFF2F1F6),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
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
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(
            color: Color(0xFF5D6494),
            width: 1.2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
        child: Text(
          'Choisir cet abonnement',
          style: GoogleFonts.quicksand(
            color: const Color(0xFF3A416F),
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _PulsingGreenDot extends StatefulWidget {
  const _PulsingGreenDot();

  @override
  State<_PulsingGreenDot> createState() => _PulsingGreenDotState();
}

class _PulsingGreenDotState extends State<_PulsingGreenDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 14,
      height: 14,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final scale = 1.0 + (_controller.value * 1.5);
              final opacity = (1.0 - _controller.value) * 0.65;

              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00D591).withValues(alpha: opacity),
                    shape: BoxShape.circle,
                  ),
                ),
              );
            },
          ),
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Color(0xFF00D591),
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}
