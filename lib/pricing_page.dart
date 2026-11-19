import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth/auth_repository.dart';
import 'auth/biometric_auth_service.dart';
import 'main_page.dart';
import 'services/auth_code_service.dart';
import 'services/settings_service.dart';
import 'widgets/glift_page_layout.dart';
import 'package:glift_mobile/theme/glift_colors.dart';

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
  bool _isYearly = false;

  @override
  void initState() {
    super.initState();
    final monthlyEnabled = SettingsService.instance.isPremiumMonthlyEnabled();
    final yearlyEnabled = SettingsService.instance.isPremiumYearlyEnabled();
    if (!monthlyEnabled && yearlyEnabled) {
      _isYearly = true;
    }
  }

  Future<void> _selectPlan(String plan) async {
    if (_isLoading) return;
    HapticFeedback.lightImpact();

    setState(() {
      _isLoading = true;
      _loadingPlan = plan;
    });

    try {
      final session = widget.supabase.auth.currentSession;

      if (session != null) {
        await AuthCodeService.postAuthenticated(
          path: '/api/user/select-plan',
          accessToken: session.accessToken,
          body: {
            'plan': plan,
            'interval': _isYearly ? 'yearly' : 'monthly',
          },
        );

        await SettingsService.instance.syncFromSupabase();
      }

      if (!mounted) return;
      _navigateToMainPage();
    } catch (e) {
      debugPrint('Error selecting plan: $e');
      if (!mounted) return;
      _navigateToMainPage();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadingPlan = null;
        });
      }
    }
  }

  void _navigateToMainPage() {
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => MainPage(
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

    final maxTrainings = SettingsService.instance.getStarterMaxTrainings();
    final maxExercises = SettingsService.instance.getStarterMaxExercises();
    final monthlyPrice = SettingsService.instance.getPremiumMonthlyPrice();
    final yearlyPrice = SettingsService.instance.getPremiumYearlyPrice();
    final showToggle = SettingsService.instance.isPremiumMonthlyEnabled() &&
        SettingsService.instance.isPremiumYearlyEnabled();

    double parsePrice(String p) => double.tryParse(p.replaceAll(',', '.')) ?? 0.0;
    final mVal = parsePrice(monthlyPrice);
    final yVal = parsePrice(yearlyPrice);
    final discountPercent = (mVal > 0 && yVal > 0 && 12 * mVal > yVal)
        ? (((12 * mVal - yVal) / (12 * mVal)) * 100).round()
        : 0;

    final currentPrice = _isYearly ? yearlyPrice : monthlyPrice;
    final currentPeriod = _isYearly ? '/an' : '/mois';

    return GliftPageLayout(
      title: greetingTitle,
      subtitle: 'Choisis ta formule d’abonnement',
      scrollable: true,
      fullPageScroll: false,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      child: Column(
        children: [
          if (showToggle) ...[
            _IntervalToggle(
              isYearly: _isYearly,
              onChanged: (val) {
                HapticFeedback.lightImpact();
                setState(() => _isYearly = val);
              },
              discountPercent: discountPercent,
            ),
            const SizedBox(height: 20),
          ],

          // ─── CARTE 1 : ABONNEMENT PREMIUM ──────────────────────────────
          _PlanCard(
            iconAsset: 'assets/icons/diamant_gold.svg',
            title: 'Abonnement Premium',
            price: '$currentPrice €',
            period: currentPeriod,
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
                boldText: 'Accès aux bons plans de la Glift Shop',
                isEnabled: true,
              ),
              _FeatureItem(
                boldText: 'Accès aux programmes du Glift Store',
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
                  '30 jours pour tester, puis $currentPrice € $currentPeriod',
                  style: GoogleFonts.quicksand(
                    color: GliftColors.textBody,
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
            price: 'Gratuit',
            period: '',
            features: [
              _FeatureItem(
                boldText: maxTrainings == 1 ? 'Un seul' : '$maxTrainings',
                regularText: ' entraînement${maxTrainings > 1 ? "s" : ""}',
                isEnabled: true,
              ),
              _FeatureItem(
                prefixText: 'Un maximum de ',
                boldText: '$maxExercises exercices',
                isEnabled: true,
              ),
              const _FeatureItem(
                regularText: 'Un tableau de bord personnalisé',
                isEnabled: true,
              ),
              const _FeatureItem(
                boldText: 'Accès aux bons plans de la Glift Shop',
                isEnabled: true,
              ),
              const _FeatureItem(
                regularText: 'Accès aux programmes du Glift Store',
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
          color: GliftColors.surfaceSubtle,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: GliftColors.textBody.withValues(alpha: 0.05),
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
                  colorMapper: GliftColors.svgColorMapperFor(iconAsset),
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
                    color: GliftColors.brandStrong,
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
                        color: GliftColors.brandStrong,
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (period.isNotEmpty)
                      Text(
                        ' $period',
                        style: GoogleFonts.quicksand(
                          color: GliftColors.textBody,
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
                            colorMapper: GliftColors.svgColorMapperFor(feature.isEnabled
                                ? 'assets/icons/plan_check_green.svg'
                                : 'assets/icons/plan_check_grey.svg'),
                            width: 18,
                            height: 18,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  if (feature.prefixText.isNotEmpty)
                                    TextSpan(
                                      text: feature.prefixText,
                                      style: GoogleFonts.quicksand(
                                        fontWeight: FontWeight.w600,
                                        color: feature.isEnabled
                                            ? GliftColors.textBody
                                            : GliftColors.greyBlue,
                                        decoration: feature.isEnabled
                                            ? TextDecoration.none
                                            : TextDecoration.lineThrough,
                                        decorationColor: GliftColors.greyBlue,
                                      ),
                                    ),
                                  if (feature.boldText.isNotEmpty)
                                    TextSpan(
                                      text: feature.boldText,
                                      style: GoogleFonts.quicksand(
                                        fontWeight: FontWeight.w700,
                                        color: feature.isEnabled
                                            ? GliftColors.brandStrong
                                            : GliftColors.greyBlue,
                                        decoration: feature.isEnabled
                                            ? TextDecoration.none
                                            : TextDecoration.lineThrough,
                                        decorationColor: GliftColors.greyBlue,
                                      ),
                                    ),
                                  if (feature.regularText.isNotEmpty)
                                    TextSpan(
                                      text: feature.regularText,
                                      style: GoogleFonts.quicksand(
                                        fontWeight: FontWeight.w600,
                                        color: feature.isEnabled
                                            ? GliftColors.textBody
                                            : GliftColors.greyBlue,
                                        decoration: feature.isEnabled
                                            ? TextDecoration.none
                                            : TextDecoration.lineThrough,
                                        decorationColor: GliftColors.greyBlue,
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
  final String prefixText;
  final String boldText;
  final String regularText;
  final bool isEnabled;

  const _FeatureItem({
    this.prefixText = '',
    this.boldText = '',
    this.regularText = '',
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
    final textColor = isLoading ? GliftColors.greyMedium : Colors.white;

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ButtonStyle(
          elevation: const WidgetStatePropertyAll(0),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (isLoading) {
              if (states.contains(WidgetState.hovered)) {
                return GliftColors.surfaceSubtle;
              }
              return GliftColors.surfaceMuted;
            }
            if (states.contains(WidgetState.hovered)) {
              return GliftColors.brandPrimaryHover;
            }
            return GliftColors.brandPrimary;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (isLoading) {
              return GliftColors.greyMedium;
            }
            return Colors.white;
          }),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
          ),
          textStyle: WidgetStatePropertyAll(
            GoogleFonts.quicksand(
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
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
          color: GliftColors.surfaceMuted,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(GliftColors.greyMedium),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'En cours...',
              style: GoogleFonts.quicksand(
                color: GliftColors.greyMedium,
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
          side: BorderSide(
            color: GliftColors.textBody,
            width: 1.2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
        child: Text(
          'Choisir cet abonnement',
          style: GoogleFonts.quicksand(
            color: GliftColors.brandStrong,
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
                    color: GliftColors.accentSuccess.withValues(alpha: opacity),
                    shape: BoxShape.circle,
                  ),
                ),
              );
            },
          ),
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: GliftColors.accentSuccess,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}

class _IntervalToggle extends StatelessWidget {
  final bool isYearly;
  final ValueChanged<bool> onChanged;
  final int discountPercent;

  const _IntervalToggle({
    required this.isYearly,
    required this.onChanged,
    required this.discountPercent,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () => onChanged(false),
          behavior: HitTestBehavior.opaque,
          child: Text(
            'Mensuel',
            style: GoogleFonts.quicksand(
              color: !isYearly ? GliftColors.brandStrong : GliftColors.textBody,
              fontSize: 16,
              fontWeight: !isYearly ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 44,
          height: 26,
          child: Switch.adaptive(
            value: isYearly,
            onChanged: onChanged,
            activeThumbColor: GliftColors.brandPrimary,
            activeTrackColor: GliftColors.focusRing,
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () => onChanged(true),
          behavior: HitTestBehavior.opaque,
          child: Text(
            'Annuel',
            style: GoogleFonts.quicksand(
              color: isYearly ? GliftColors.brandStrong : GliftColors.textBody,
              fontSize: 16,
              fontWeight: isYearly ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ),
        if (discountPercent > 0) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: GliftColors.successSurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Économise $discountPercent %',
              style: GoogleFonts.quicksand(
                color: GliftColors.accentSuccess,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
