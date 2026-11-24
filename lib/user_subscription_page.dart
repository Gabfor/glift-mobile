import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'services/auth_code_service.dart';
import 'services/settings_service.dart';
import 'widgets/glift_loader.dart';
import 'package:glift_mobile/theme/glift_colors.dart';

class UserSubscriptionPage extends StatefulWidget {
  final SupabaseClient supabase;

  const UserSubscriptionPage({
    super.key,
    required this.supabase,
  });

  @override
  State<UserSubscriptionPage> createState() => _UserSubscriptionPageState();
}

class _UserSubscriptionPageState extends State<UserSubscriptionPage> {
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;
  bool _isLoading = true;
  bool _isProcessing = false;
  String _subscriptionPlan = 'starter';
  bool _isYearly = false;
  bool _currentSubIsYearly = false;
  bool _hasUsedTrial = false;
  bool _isInTrial = false;
  bool _isCancelled = false;
  DateTime? _periodEndDate;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadSubscriptionData();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final scrolled = _scrollController.offset > 0;
    if (scrolled != _isScrolled) {
      setState(() {
        _isScrolled = scrolled;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  String _getFormattedPeriodEndDate() {
    if (_periodEndDate != null) {
      return DateFormat('dd/MM/yyyy').format(_periodEndDate!);
    }
    return DateFormat('dd/MM/yyyy').format(DateTime.now().add(const Duration(days: 30)));
  }

  Future<void> _loadSubscriptionData() async {
    final cached = SettingsService.instance.getSubscriptionPlan();
    _subscriptionPlan = (cached == 'premium') ? 'premium' : 'starter';
    _hasUsedTrial = SettingsService.instance.getHasUsedTrial();

    final user = widget.supabase.auth.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final response = await widget.supabase
          .from('profiles')
          .select('subscription_plan, subscription_interval, premium_trial_started_at, premium_trial_end_at, premium_end_at, trial, cancellation')
          .eq('id', user.id)
          .maybeSingle();

      if (response != null && mounted) {
        final plan = (response['subscription_plan'] as String?)?.toLowerCase();
        final rawInterval = (response['subscription_interval'] as String?)?.toLowerCase();
        final isYearly = rawInterval == 'yearly' ||
            (!SettingsService.instance.isPremiumMonthlyEnabled() &&
                SettingsService.instance.isPremiumYearlyEnabled());
        final trialStarted = response['premium_trial_started_at'] != null;
        final isTrial = response['trial'] == true;
        final hasUsedTrial = trialStarted || isTrial;
        final isCancelled = response['cancellation'] == true;

        final rawPremiumEnd = response['premium_end_at'];
        final rawTrialEnd = response['premium_trial_end_at'];
        final rawTrialStarted = response['premium_trial_started_at'];

        DateTime? premiumEndDt;
        if (rawPremiumEnd != null) {
          premiumEndDt = DateTime.tryParse(rawPremiumEnd as String);
        }

        DateTime? trialEndDt;
        if (rawTrialEnd != null) {
          trialEndDt = DateTime.tryParse(rawTrialEnd as String);
        } else if (rawTrialStarted != null) {
          final started = DateTime.tryParse(rawTrialStarted as String);
          if (started != null) {
            trialEndDt = started.add(const Duration(days: 30));
          }
        }

        final now = DateTime.now();

        // 1. Est-ce que l'utilisateur est effectivement Premium ?
        // Identique à glift-web : si le plan est "premium", il est actif sauf si une date de fin de période payante/résiliée (premium_end_at) est dépassée.
        bool isEffectivePremium = (plan == 'premium');
        if (isEffectivePremium && premiumEndDt != null && premiumEndDt.isBefore(now)) {
          isEffectivePremium = false;
        }

        // 2. Est-ce que l'utilisateur est actuellement en essai actif ?
        final isInTrial = isEffectivePremium &&
            trialEndDt != null &&
            trialEndDt.isAfter(now) &&
            rawPremiumEnd == null;

        // 3. Date de fin de période pour l'affichage en cas d'annulation
        DateTime? endDt = premiumEndDt ?? (isInTrial ? trialEndDt : null);

        setState(() {
          _subscriptionPlan = isEffectivePremium ? 'premium' : 'starter';
          _isYearly = isYearly;
          _currentSubIsYearly = isYearly;
          _hasUsedTrial = hasUsedTrial;
          _isInTrial = isInTrial;
          _isCancelled = isCancelled;
          _periodEndDate = endDt;
          _isLoading = false;
        });
      } else if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error loading subscription data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _cancelPremium() async {
    if (_isProcessing) return;
    HapticFeedback.lightImpact();

    final user = widget.supabase.auth.currentUser;
    if (user == null) return;

    setState(() => _isProcessing = true);

    try {
      final now = DateTime.now();
      final endAt = _periodEndDate ?? now.add(const Duration(days: 30));

      // Synchronisation Stripe ou annulation côté serveur
      final session = widget.supabase.auth.currentSession;
      if (session != null) {
        try {
          await AuthCodeService.postAuthenticated(
            path: '/api/user/update-subscription',
            accessToken: session.accessToken,
            body: {'plan': 'starter'},
          );
        } catch (_) {
          await AuthCodeService.postAuthenticated(
            path: '/api/user/select-plan',
            accessToken: session.accessToken,
            body: {'action': 'cancel'},
          );
        }
      }

      await SettingsService.instance.syncFromSupabase();

      if (mounted) {
        setState(() {
          _isCancelled = true;
          _periodEndDate = endAt;
          _isProcessing = false;
        });
      }
    } catch (e) {
      debugPrint('Error canceling subscription: $e');
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _changePlan(String targetPlan) async {
    if (_isProcessing) return;
    HapticFeedback.lightImpact();

    final user = widget.supabase.auth.currentUser;
    if (user == null) return;

    setState(() => _isProcessing = true);

    try {
      final wasTrial = !_hasUsedTrial;
      final session = widget.supabase.auth.currentSession;
      if (session != null) {
        await AuthCodeService.postAuthenticated(
          path: '/api/user/select-plan',
          accessToken: session.accessToken,
          body: {
            'plan': targetPlan,
            'interval': _isYearly ? 'yearly' : 'monthly',
          },
        );
      }

      await SettingsService.instance.syncFromSupabase();

      if (mounted) {
        final now = DateTime.now();
        setState(() {
          _subscriptionPlan = targetPlan;
          if (targetPlan == 'premium') {
            _hasUsedTrial = true;
            _isInTrial = wasTrial;
            _isCancelled = false;
            _currentSubIsYearly = _isYearly;
            if (_periodEndDate == null || _periodEndDate!.isBefore(now)) {
              _periodEndDate = now.add(const Duration(days: 30));
            }
          }
          _isProcessing = false;
        });
      }
    } catch (e) {
      debugPrint('Error updating subscription: $e');
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _updateSubscriptionInterval() async {
    if (_isProcessing) return;
    HapticFeedback.lightImpact();

    final user = widget.supabase.auth.currentUser;
    if (user == null) return;

    setState(() => _isProcessing = true);

    try {
      final wasDowngradeToMonthly = !_isInTrial && _currentSubIsYearly && !_isYearly;
      final newInterval = _isYearly ? 'yearly' : 'monthly';

      // Synchronisation Stripe ou mise à jour d'intervalle côté serveur
      final session = widget.supabase.auth.currentSession;
      if (session != null) {
        try {
          await AuthCodeService.postAuthenticated(
            path: '/api/user/update-subscription',
            accessToken: session.accessToken,
            body: {
              'plan': 'premium',
              'interval': newInterval,
            },
          );
        } catch (_) {
          await AuthCodeService.postAuthenticated(
            path: '/api/user/select-plan',
            accessToken: session.accessToken,
            body: {
              'action': 'update_interval',
              'interval': newInterval,
            },
          );
        }
      }

      await SettingsService.instance.syncFromSupabase();

      if (mounted) {
        setState(() {
          if (!wasDowngradeToMonthly) {
            _currentSubIsYearly = _isYearly;
          }
          _isProcessing = false;
        });
        _showIntervalUpdatedDialog(wasDowngradeToMonthly: wasDowngradeToMonthly);
      }
    } catch (e) {
      debugPrint('Error updating subscription interval: $e');
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showChangeIntervalConfirmationDialog() {
    final targetFormula = _isYearly ? 'annuelle' : 'mensuelle';
    final targetPrice = _isYearly
        ? '${SettingsService.instance.getPremiumYearlyPrice()} €/an'
        : '${SettingsService.instance.getPremiumMonthlyPrice()} €/mois';
    final isDowngradeToMonthly = !_isInTrial && _currentSubIsYearly && !_isYearly;

    showDialog(
      context: context,
      barrierColor: GliftColors.navyDeep.withValues(alpha: 0.6),
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 44, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Purple Message Badge
                    SvgPicture.asset(
                      'assets/icons/message.svg',
                      colorMapper: GliftColors.iconColorMapper,
                      width: 39,
                      height: 35,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 16),

                    // Title
                    Text(
                      'Changer de formule',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.quicksand(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: GliftColors.brandStrong,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Paragraph 1
                    Text(
                      _isInTrial
                          ? 'Tu profites actuellement de ton essai gratuit. Ta formule passera à l’abonnement $targetFormula ($targetPrice) dès la fin de ton essai le ${_getFormattedPeriodEndDate()}. Aucun débit n’aura lieu aujourd’hui.'
                          : isDowngradeToMonthly
                          ? 'Ton abonnement annuel reste actif jusqu’au ${_getFormattedPeriodEndDate()}. À cette date, ton abonnement basculera automatiquement sur la formule mensuelle à $targetPrice au lieu d’un renouvellement annuel. Aucun débit n’aura lieu aujourd’hui.'
                          : 'Tu es sur le point de passer à la formule annuelle à $targetPrice. Les jours non utilisés de ton mois en cours sont immédiatement déduits de ta facture et ta nouvelle année d’abonnement commence aujourd’hui.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.quicksand(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: GliftColors.brandStrong,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Paragraph 2
                    Text.rich(
                      TextSpan(
                        children: [
                          const TextSpan(text: 'En cliquant sur “'),
                          TextSpan(
                            text: 'Confirmer',
                            style: GoogleFonts.quicksand(
                              fontWeight: FontWeight.w700,
                              color: GliftColors.brandStrong,
                            ),
                          ),
                          TextSpan(
                            text: _isInTrial
                                ? '”, ta formule sera enregistrée pour la fin de ton essai. En cliquant sur “'
                                : isDowngradeToMonthly
                                ? '”, ton passage au mensuel sera programmé pour le ${_getFormattedPeriodEndDate()}. En cliquant sur “'
                                : '”, ta formule passera immédiatement en facturation annuelle. En cliquant sur “',
                          ),
                          TextSpan(
                            text: 'Annuler',
                            style: GoogleFonts.quicksand(
                              fontWeight: FontWeight.w700,
                              color: GliftColors.brandStrong,
                            ),
                          ),
                          const TextSpan(text: '” tu conserves ta formule actuelle.'),
                        ],
                      ),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.quicksand(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: GliftColors.textBody,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(dialogContext).pop(),
                              style: OutlinedButton.styleFrom(
                                backgroundColor: Colors.white,
                                side: BorderSide(
                                  color: GliftColors.brandStrong,
                                  width: 1.2,
                                ),
                                shape: const StadiumBorder(),
                                elevation: 0,
                                padding: EdgeInsets.zero,
                              ),
                              child: Text(
                                'Annuler',
                                style: GoogleFonts.quicksand(
                                  color: GliftColors.brandStrong,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.of(dialogContext).pop();
                                _updateSubscriptionInterval();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: GliftColors.brandPrimary,
                                elevation: 0,
                                shape: const StadiumBorder(),
                                padding: EdgeInsets.zero,
                              ),
                              child: Text(
                                'Confirmer',
                                style: GoogleFonts.quicksand(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Close Button (Top right)
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: SvgPicture.asset(
                    'assets/icons/close_modal.svg',
                    colorMapper: GliftColors.iconColorMapper,
                    width: 25,
                    height: 25,
                  ),
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                  style: IconButton.styleFrom(
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showIntervalUpdatedDialog({bool wasDowngradeToMonthly = false}) {
    final formula = _currentSubIsYearly ? 'annuelle' : 'mensuelle';

    showDialog(
      context: context,
      barrierColor: GliftColors.navyDeep.withValues(alpha: 0.6),
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 44, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Success Badge
                    SvgPicture.asset(
                      'assets/icons/message_succes.svg',
                      colorMapper: GliftColors.iconColorMapper,
                      width: 39,
                      height: 35,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 16),

                    // Title
                    Text(
                      wasDowngradeToMonthly
                          ? 'Changement de formule programmé'
                          : 'Formule modifiée avec succès',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.quicksand(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: GliftColors.brandStrong,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Body
                    Text(
                      _isInTrial
                          ? 'Ton abonnement passera sur la formule $formula à la fin de tes 30 jours d’essai offerts.'
                          : wasDowngradeToMonthly
                          ? 'Ton abonnement annuel reste actif jusqu’au ${_getFormattedPeriodEndDate()}. À cette date, il basculera automatiquement sur la formule mensuelle.'
                          : 'Félicitations ! Ton abonnement a bien été basculé sur la formule annuelle. Le montant au prorata a été pris en compte.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.quicksand(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: GliftColors.brandStrong,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Close Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          side: BorderSide(
                            color: GliftColors.brandStrong,
                            width: 1.2,
                          ),
                          shape: const StadiumBorder(),
                          elevation: 0,
                          padding: EdgeInsets.zero,
                        ),
                        child: Text(
                          'Fermer',
                          style: GoogleFonts.quicksand(
                            color: GliftColors.brandStrong,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Close Button (Top right)
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: SvgPicture.asset(
                    'assets/icons/close_modal.svg',
                    colorMapper: GliftColors.iconColorMapper,
                    width: 25,
                    height: 25,
                  ),
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                  style: IconButton.styleFrom(
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCancelConfirmationDialog() {
    showDialog(
      context: context,
      barrierColor: GliftColors.navyDeep.withValues(alpha: 0.6),
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 44, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Red Exclamation Badge
                    SvgPicture.asset(
                      'assets/icons/message_erreur.svg',
                      colorMapper: GliftColors.iconColorMapper,
                      width: 39,
                      height: 35,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 16),

                    // Title
                    Text(
                      'Annulation de ton abonnement',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.quicksand(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: GliftColors.brandStrong,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Paragraph 1
                    Text(
                      _isInTrial
                          ? 'Ton abonnement Premium se terminera à la fin des 30 jours d’essai offerts, soit le ${_getFormattedPeriodEndDate()}.'
                          : 'Ton abonnement Premium se terminera à la fin de la période de facturation actuelle, soit le ${_getFormattedPeriodEndDate()}.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.quicksand(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: GliftColors.brandStrong,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Paragraph 2: En cliquant sur “Confirmer”, tu confirmes l’annulation de ton abonnement. En cliquant sur “Annuler” on annule tout !
                    Text.rich(
                      TextSpan(
                        children: [
                          const TextSpan(text: 'En cliquant sur “'),
                          TextSpan(
                            text: 'Confirmer',
                            style: GoogleFonts.quicksand(
                              fontWeight: FontWeight.w700,
                              color: GliftColors.brandStrong,
                            ),
                          ),
                          const TextSpan(
                            text: '”, tu confirmes l’annulation de ton abonnement. En cliquant sur “',
                          ),
                          TextSpan(
                            text: 'Annuler',
                            style: GoogleFonts.quicksand(
                              fontWeight: FontWeight.w700,
                              color: GliftColors.brandStrong,
                            ),
                          ),
                          const TextSpan(text: '” on annule tout !'),
                        ],
                      ),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.quicksand(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: GliftColors.textBody,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(dialogContext).pop(),
                              style: OutlinedButton.styleFrom(
                                backgroundColor: Colors.white,
                                side: BorderSide(
                                  color: GliftColors.brandStrong,
                                  width: 1.2,
                                ),
                                shape: const StadiumBorder(),
                                elevation: 0,
                                padding: EdgeInsets.zero,
                              ),
                              child: Text(
                                'Annuler',
                                style: GoogleFonts.quicksand(
                                  color: GliftColors.brandStrong,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.of(dialogContext).pop();
                                _cancelPremium();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: GliftColors.accentDanger,
                                elevation: 0,
                                shape: const StadiumBorder(),
                                padding: EdgeInsets.zero,
                              ),
                              child: Text(
                                'Confirmer',
                                style: GoogleFonts.quicksand(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Close Button (Top right)
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: SvgPicture.asset(
                    'assets/icons/close_modal.svg',
                    colorMapper: GliftColors.iconColorMapper,
                    width: 25,
                    height: 25,
                  ),
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                  style: IconButton.styleFrom(
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCancellationInfoDialog() {
    showDialog(
      context: context,
      barrierColor: GliftColors.navyDeep.withValues(alpha: 0.6),
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 44, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Purple Exclamation Badge
                    SvgPicture.asset(
                      'assets/icons/message.svg',
                      colorMapper: GliftColors.iconColorMapper,
                      width: 39,
                      height: 35,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 16),

                    // Title
                    Text(
                      'Annulation prise en compte',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.quicksand(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: GliftColors.brandStrong,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Body
                    Text(
                      _isInTrial
                          ? 'Nous avons bien pris en compte ta demande d’annulation. Tu passeras à un abonnement Starter dès la fin des 30 jours offerts pour tester l’abonnement Premium, soit le ${_getFormattedPeriodEndDate()}.'
                          : 'Nous avons bien pris en compte ta demande d’annulation. Tu passeras à un abonnement Starter dès la fin de ta période d’abonnement Premium actuelle, soit le ${_getFormattedPeriodEndDate()}.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.quicksand(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: GliftColors.brandStrong,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Close Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          side: BorderSide(
                            color: GliftColors.brandStrong,
                            width: 1.2,
                          ),
                          shape: const StadiumBorder(),
                          elevation: 0,
                          padding: EdgeInsets.zero,
                        ),
                        child: Text(
                          'Fermer',
                          style: GoogleFonts.quicksand(
                            color: GliftColors.brandStrong,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Close Button (Top right)
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: SvgPicture.asset(
                    'assets/icons/close_modal.svg',
                    colorMapper: GliftColors.iconColorMapper,
                    width: 25,
                    height: 25,
                  ),
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                  style: IconButton.styleFrom(
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isEffectivelyPremium = _subscriptionPlan == 'premium';
    final bool hasIntervalChanged = isEffectivelyPremium && (_isYearly != _currentSubIsYearly);
    final showToggle = SettingsService.instance.isPremiumMonthlyEnabled() &&
        SettingsService.instance.isPremiumYearlyEnabled();

    double parsePrice(String p) => double.tryParse(p.replaceAll(',', '.')) ?? 0.0;
    final mVal = parsePrice(SettingsService.instance.getPremiumMonthlyPrice());
    final yVal = parsePrice(SettingsService.instance.getPremiumYearlyPrice());
    final discountPercent = (mVal > 0 && yVal > 0 && 12 * mVal > yVal)
        ? (((12 * mVal - yVal) / (12 * mVal)) * 100).round()
        : 0;

    return Scaffold(
      backgroundColor: GliftColors.surfacePrimary,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // Subscription Cards List
            _isLoading
                ? const Center(child: GliftLoader(size: 32))
                : SingleChildScrollView(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(
                      20,
                      108,
                      20,
                      MediaQuery.of(context).padding.bottom + 40,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (showToggle) ...[
                          Center(
                            child: _IntervalToggle(
                              isYearly: _isYearly,
                              onChanged: (val) {
                                HapticFeedback.lightImpact();
                                setState(() => _isYearly = val);
                              },
                              discountPercent: discountPercent,
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],

                        // ─── SECTION 1 : ABONNEMENT ACTIF ───
                        Text(
                          'ABONNEMENT ACTIF',
                          style: GoogleFonts.quicksand(
                            color: GliftColors.greyMedium,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 10),

                        if (isEffectivelyPremium)
                          _buildPremiumCard(
                            button: _isCancelled
                                ? _ActionButton(
                                    text: 'Réactiver mon abonnement',
                                    backgroundColor: GliftColors.brandPrimary,
                                    textColor: Colors.white,
                                    isLoading: _isProcessing,
                                    onPressed: _isProcessing ? null : () => _changePlan('premium'),
                                  )
                                : hasIntervalChanged
                                    ? _ActionButton(
                                        text: 'Mettre à jour la formule',
                                        backgroundColor: GliftColors.brandPrimary,
                                        textColor: Colors.white,
                                        isLoading: _isProcessing,
                                        onPressed: _isProcessing ? null : _showChangeIntervalConfirmationDialog,
                                      )
                                    : _ActionButton(
                                        text: 'Annuler mon abonnement',
                                        backgroundColor: GliftColors.accentDanger,
                                        textColor: Colors.white,
                                        isLoading: _isProcessing,
                                        onPressed: _isProcessing ? null : _showCancelConfirmationDialog,
                                      ),
                          )
                        else
                          _buildStarterCard(
                            button: _ActionButton(
                              text: 'Annuler mon abonnement',
                              backgroundColor: GliftColors.surfaceMuted,
                              textColor: GliftColors.greyMedium,
                              onPressed: null,
                            ),
                          ),

                        const SizedBox(height: 24),

                        // ─── SECTION 2 : ABONNEMENT INACTIF ───
                        Text(
                          'ABONNEMENT INACTIF',
                          style: GoogleFonts.quicksand(
                            color: GliftColors.greyMedium,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 10),

                        if (isEffectivelyPremium)
                          _buildStarterCard(
                            button: _isCancelled
                                ? _ActionButton(
                                    text: 'Choisir cet abonnement',
                                    backgroundColor: GliftColors.surfaceMuted,
                                    textColor: GliftColors.greyMedium,
                                    onPressed: _showCancellationInfoDialog,
                                  )
                                : _ActionButton(
                                    text: 'Choisir cet abonnement',
                                    backgroundColor: Colors.white,
                                    textColor: GliftColors.brandStrong,
                                    borderColor: GliftColors.brandStrong,
                                    isLoading: _isProcessing,
                                    onPressed: _isProcessing ? null : _showCancelConfirmationDialog,
                                  ),
                          )
                        else
                          _buildPremiumCard(
                            button: _ActionButton(
                              text: 'Choisir cet abonnement',
                              backgroundColor: GliftColors.brandPrimary,
                              textColor: Colors.white,
                              isLoading: _isProcessing,
                              onPressed: _isProcessing ? null : () => _changePlan('premium'),
                            ),
                            footerNote: !_hasUsedTrial
                                ? Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const _PulsingGreenDot(),
                                      const SizedBox(width: 8),
                                      Text(
                                        '30 jours pour tester, puis ${_isYearly ? SettingsService.instance.getPremiumYearlyPrice() : SettingsService.instance.getPremiumMonthlyPrice()} € ${_isYearly ? "/an" : "/mois"}',
                                        style: GoogleFonts.quicksand(
                                          color: GliftColors.textBody,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  )
                                : null,
                          ),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),

            // Header
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    color: GliftColors.surfacePrimary,
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _SettingsBackButton(onTap: () => Navigator.of(context).pop()),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Réglages',
                              style: GoogleFonts.quicksand(
                                color: GliftColors.brandStrong,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Mon abonnement',
                              style: GoogleFonts.quicksand(
                                color: GliftColors.brandStrong,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: _isScrolled ? 1.0 : 0.0,
                    child: Container(
                      height: 16,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            GliftColors.navyDeep.withValues(alpha: 0.12),
                            GliftColors.navyDeep.withValues(alpha: 0.04),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.45, 1.0],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumCard({
    required Widget button,
    Widget? footerNote,
  }) {
    final monthlyPrice = SettingsService.instance.getPremiumMonthlyPrice();
    final yearlyPrice = SettingsService.instance.getPremiumYearlyPrice();
    final currentPrice = _isYearly ? yearlyPrice : monthlyPrice;
    final currentPeriod = _isYearly ? '/an' : '/mois';

    return _SubscriptionCardContainer(
      iconAsset: 'assets/icons/diamant_gold.svg',
      title: 'Abonnement Premium',
      price: '$currentPrice €',
      period: currentPeriod,
      features: const [
        _SubscriptionFeature(
          boldText: 'Un nombre illimité',
          normalText: ' d’entraînements',
        ),
        _SubscriptionFeature(
          boldText: 'Un nombre illimité',
          normalText: ' d’exercices',
        ),
        _SubscriptionFeature(
          normalText: 'Un tableau de bord personnalisé',
        ),
        _SubscriptionFeature(
          boldText: 'Accès aux bons plans de la Glift Shop',
        ),
        _SubscriptionFeature(
          boldText: 'Accès aux programmes du Glift Store',
        ),
        _SubscriptionFeature(
          normalText: 'Annulation gratuite à tout moment',
        ),
      ],
      button: button,
      footerNote: footerNote,
    );
  }

  Widget _buildStarterCard({
    required Widget button,
  }) {
    final maxTrainings = SettingsService.instance.getStarterMaxTrainings();
    final maxExercises = SettingsService.instance.getStarterMaxExercises();

    return _SubscriptionCardContainer(
      iconAsset: 'assets/icons/diamant_purple.svg',
      title: 'Abonnement Starter',
      price: 'Gratuit',
      period: '',
      features: [
        _SubscriptionFeature(
          boldText: maxTrainings == 1 ? 'Un seul' : '$maxTrainings',
          normalText: ' entraînement${maxTrainings > 1 ? "s" : ""}',
        ),
        _SubscriptionFeature(
          prefixText: 'Un maximum de ',
          boldText: '$maxExercises exercices',
        ),
        const _SubscriptionFeature(
          normalText: 'Un tableau de bord personnalisé',
        ),
        const _SubscriptionFeature(
          boldText: 'Accès aux bons plans de la Glift Shop',
        ),
        const _SubscriptionFeature(
          normalText: 'Accès aux programmes du Glift Store',
          isEnabled: false,
        ),
      ],
      button: button,
    );
  }
}

class _SubscriptionCardContainer extends StatelessWidget {
  final String iconAsset;
  final String title;
  final String price;
  final String period;
  final List<_SubscriptionFeature> features;
  final Widget button;
  final Widget? footerNote;

  const _SubscriptionCardContainer({
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
          color: GliftColors.borderSoft,
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
      padding: const EdgeInsets.fromLTRB(20, 26, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Diamond Icon
          SvgPicture.asset(
            iconAsset,
            colorMapper: GliftColors.svgColorMapperFor(iconAsset),
            width: 44,
            height: 36,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 14),

          // Plan Title
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

          // Price & Period
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
                    color: GliftColors.brandStrong,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),

          // Features List
          Column(
            children: features.map((feature) {
              final checkIcon = feature.isEnabled
                  ? 'assets/icons/plan_check_green.svg'
                  : 'assets/icons/plan_check_grey.svg';
              final textColor = feature.isEnabled
                  ? GliftColors.textBody
                  : GliftColors.greyBlue;
              final boldColor = feature.isEnabled
                  ? GliftColors.brandStrong
                  : GliftColors.greyBlue;
              final decoration = feature.isEnabled
                  ? TextDecoration.none
                  : TextDecoration.lineThrough;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SvgPicture.asset(
                      checkIcon,
                      colorMapper: GliftColors.svgColorMapperFor(checkIcon),
                      width: 18,
                      height: 18,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            if (feature.prefixText != null)
                              TextSpan(
                                text: feature.prefixText,
                                style: GoogleFonts.quicksand(
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                  decoration: decoration,
                                  decorationColor: textColor,
                                ),
                              ),
                            if (feature.boldText != null)
                              TextSpan(
                                text: feature.boldText,
                                style: GoogleFonts.quicksand(
                                  fontWeight: FontWeight.w700,
                                  color: boldColor,
                                  decoration: decoration,
                                  decorationColor: boldColor,
                                ),
                              ),
                            if (feature.normalText != null)
                              TextSpan(
                                text: feature.normalText,
                                style: GoogleFonts.quicksand(
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                  decoration: decoration,
                                  decorationColor: textColor,
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

          const SizedBox(height: 8),

          // Action Button
          button,

          if (footerNote != null) ...[
            const SizedBox(height: 12),
            footerNote!,
          ],
        ],
      ),
    );
  }
}

class _SubscriptionFeature {
  final String? prefixText;
  final String? boldText;
  final String? normalText;
  final bool isEnabled;

  const _SubscriptionFeature({
    this.prefixText,
    this.boldText,
    this.normalText,
    this.isEnabled = true,
  });
}

class _ActionButton extends StatelessWidget {
  final String text;
  final Color backgroundColor;
  final Color textColor;
  final Color? borderColor;
  final bool isLoading;
  final VoidCallback? onPressed;

  const _ActionButton({
    required this.text,
    required this.backgroundColor,
    required this.textColor,
    this.borderColor,
    this.isLoading = false,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBgColor = isLoading ? GliftColors.surfaceMuted : backgroundColor;
    final effectiveBorder = (isLoading || borderColor == null)
        ? null
        : Border.all(color: borderColor!, width: 1.2);
    final effectiveTextColor = isLoading ? GliftColors.greyMedium : textColor;

    return Container(
      width: double.infinity,
      height: 48,
      decoration: BoxDecoration(
        color: effectiveBgColor,
        borderRadius: BorderRadius.circular(25),
        border: effectiveBorder,
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          disabledBackgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
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
              )
            : Text(
                text,
                style: GoogleFonts.quicksand(
                  color: effectiveTextColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }
}

class _SettingsBackButton extends StatelessWidget {
  const _SettingsBackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: GliftColors.brandStrong,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.chevron_left,
          color: Colors.white,
          size: 28,
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
