import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'services/settings_service.dart';
import 'widgets/glift_loader.dart';

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
  bool _isLoading = true;
  bool _isProcessing = false;
  String _subscriptionPlan = 'starter';
  bool _hasUsedTrial = false;
  bool _isInTrial = false;
  bool _isCancelled = false;
  DateTime? _periodEndDate;

  @override
  void initState() {
    super.initState();
    _loadSubscriptionData();
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
          .select('subscription_plan, premium_trial_started_at, premium_trial_end_at, premium_end_at, trial, cancellation')
          .eq('id', user.id)
          .maybeSingle();

      if (response != null && mounted) {
        final plan = (response['subscription_plan'] as String?)?.toLowerCase();
        final trialStarted = response['premium_trial_started_at'] != null;
        final isTrial = response['trial'] == true;
        final hasUsedTrial = trialStarted || isTrial;
        final isCancelled = response['cancellation'] == true;

        final rawPremiumEnd = response['premium_end_at'];
        final rawTrialEnd = response['premium_trial_end_at'];
        final rawTrialStarted = response['premium_trial_started_at'];

        DateTime? endDt;
        DateTime? trialEndDt;
        if (rawTrialEnd != null) {
          trialEndDt = DateTime.tryParse(rawTrialEnd as String);
        } else if (rawTrialStarted != null) {
          final started = DateTime.tryParse(rawTrialStarted as String);
          if (started != null) {
            trialEndDt = started.add(const Duration(days: 30));
          }
        }

        if (rawPremiumEnd != null) {
          endDt = DateTime.tryParse(rawPremiumEnd as String);
        } else {
          endDt = trialEndDt;
        }

        final now = DateTime.now();
        final isInTrial = isTrial || (trialEndDt != null && trialEndDt.isAfter(now) && rawPremiumEnd == null);

        setState(() {
          _subscriptionPlan = (plan == 'premium') ? 'premium' : 'starter';
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

      final Map<String, dynamic> updateData = {
        'cancellation': true,
      };
      if (_periodEndDate == null) {
        updateData['premium_end_at'] = endAt.toIso8601String();
      }

      await widget.supabase.from('profiles').update(updateData).eq('id', user.id);

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
      if (targetPlan == 'premium') {
        final now = DateTime.now();
        final trialEnd = now.add(const Duration(days: 30));
        
        final Map<String, dynamic> updateData = {
          'subscription_plan': 'premium',
          'cancellation': false,
          'premium_end_at': null,
        };

        if (!_hasUsedTrial) {
          updateData['premium_trial_started_at'] = now.toIso8601String();
          updateData['premium_trial_end_at'] = trialEnd.toIso8601String();
          updateData['trial'] = true;
        }

        await widget.supabase.from('profiles').update(updateData).eq('id', user.id);

        try {
          await widget.supabase.from('user_subscriptions').upsert({
            'user_id': user.id,
            'plan': 'premium',
          });
        } catch (_) {}
      } else {
        await widget.supabase.from('profiles').update({
          'subscription_plan': 'starter',
          'cancellation': false,
        }).eq('id', user.id);

        try {
          await widget.supabase.from('user_subscriptions').upsert({
            'user_id': user.id,
            'plan': 'starter',
          });
        } catch (_) {}
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

  void _showCancelConfirmationDialog() {
    showDialog(
      context: context,
      barrierColor: const Color(0xFF1E2238).withValues(alpha: 0.5),
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
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Red Exclamation Badge
                    SvgPicture.asset(
                      'assets/icons/message_erreur.svg',
                      width: 44,
                      height: 44,
                    ),
                    const SizedBox(height: 16),

                    // Title
                    Text(
                      'Annulation de ton abonnement',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.quicksand(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF3A416F),
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
                        color: const Color(0xFF3A416F),
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
                              color: const Color(0xFF3A416F),
                            ),
                          ),
                          const TextSpan(
                            text: '”, tu confirmes l’annulation de ton abonnement. En cliquant sur “',
                          ),
                          TextSpan(
                            text: 'Annuler',
                            style: GoogleFonts.quicksand(
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF3A416F),
                            ),
                          ),
                          const TextSpan(text: '” on annule tout !'),
                        ],
                      ),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.quicksand(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF5D6494),
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
                                side: const BorderSide(
                                  color: Color(0xFF3A416F),
                                  width: 1.2,
                                ),
                                shape: const StadiumBorder(),
                                elevation: 0,
                                padding: EdgeInsets.zero,
                              ),
                              child: Text(
                                'Annuler',
                                style: GoogleFonts.quicksand(
                                  color: const Color(0xFF3A416F),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.of(dialogContext).pop();
                                _cancelPremium();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFEF4F4E),
                                elevation: 0,
                                shape: const StadiumBorder(),
                                padding: EdgeInsets.zero,
                              ),
                              child: Text(
                                'Confirmer',
                                style: GoogleFonts.quicksand(
                                  color: Colors.white,
                                  fontSize: 15,
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
                top: 16,
                right: 16,
                child: GestureDetector(
                  onTap: () => Navigator.of(dialogContext).pop(),
                  behavior: HitTestBehavior.opaque,
                  child: const Padding(
                    padding: EdgeInsets.all(4.0),
                    child: Icon(
                      Icons.close,
                      size: 20,
                      color: Color(0xFF5D6494),
                    ),
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
      barrierColor: const Color(0xFF1E2238).withValues(alpha: 0.5),
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
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Purple Exclamation Badge
                    Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: Color(0xFF7069FA),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '!',
                        style: GoogleFonts.quicksand(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          height: 1.0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Title
                    Text(
                      'Annulation prise en compte',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.quicksand(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF3A416F),
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
                        color: const Color(0xFF3A416F),
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
                          side: const BorderSide(
                            color: Color(0xFF3A416F),
                            width: 1.2,
                          ),
                          shape: const StadiumBorder(),
                          elevation: 0,
                          padding: EdgeInsets.zero,
                        ),
                        child: Text(
                          'Fermer',
                          style: GoogleFonts.quicksand(
                            color: const Color(0xFF3A416F),
                            fontSize: 15,
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
                top: 16,
                right: 16,
                child: GestureDetector(
                  onTap: () => Navigator.of(dialogContext).pop(),
                  behavior: HitTestBehavior.opaque,
                  child: const Padding(
                    padding: EdgeInsets.all(4.0),
                    child: Icon(
                      Icons.close,
                      size: 20,
                      color: Color(0xFF5D6494),
                    ),
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
    final bool isEffectivelyPremium = _subscriptionPlan == 'premium' &&
        (_periodEndDate == null || _periodEndDate!.isAfter(DateTime.now()));

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
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
                          color: const Color(0xFF3A416F),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Mon abonnement',
                        style: GoogleFonts.quicksand(
                          color: const Color(0xFF3A416F),
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Subscription Cards List
            Expanded(
              child: _isLoading
                  ? const GliftLoader(size: 32)
                  : SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                        20,
                        0,
                        20,
                        MediaQuery.of(context).padding.bottom + 40,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ─── SECTION 1 : ABONNEMENT ACTIF ───
                          Text(
                            'ABONNEMENT ACTIF',
                            style: GoogleFonts.quicksand(
                              color: const Color(0xFFC2BFC6),
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
                                      backgroundColor: const Color(0xFF7069FA),
                                      textColor: Colors.white,
                                      isLoading: _isProcessing,
                                      onPressed: _isProcessing ? null : () => _changePlan('premium'),
                                    )
                                  : _ActionButton(
                                      text: 'Annuler mon abonnement',
                                      backgroundColor: const Color(0xFFF15454),
                                      textColor: Colors.white,
                                      isLoading: _isProcessing,
                                      onPressed: _isProcessing ? null : _showCancelConfirmationDialog,
                                    ),
                            )
                          else
                            _buildStarterCard(
                              button: const _ActionButton(
                                text: 'Annuler mon abonnement',
                                backgroundColor: Color(0xFFF2F1F6),
                                textColor: Color(0xFFD7D4DC),
                                onPressed: null,
                              ),
                            ),

                          const SizedBox(height: 24),

                          // ─── SECTION 2 : ABONNEMENT INACTIF ───
                          Text(
                            'ABONNEMENT INACTIF',
                            style: GoogleFonts.quicksand(
                              color: const Color(0xFFC2BFC6),
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
                                      backgroundColor: const Color(0xFFF2F1F6),
                                      textColor: const Color(0xFFD7D4DC),
                                      onPressed: _showCancellationInfoDialog,
                                    )
                                  : _ActionButton(
                                      text: 'Choisir cet abonnement',
                                      backgroundColor: Colors.white,
                                      textColor: const Color(0xFF3A416F),
                                      borderColor: const Color(0xFF3A416F),
                                      isLoading: _isProcessing,
                                      onPressed: _isProcessing ? null : _showCancelConfirmationDialog,
                                    ),
                            )
                          else
                            _buildPremiumCard(
                              button: _ActionButton(
                                text: 'Choisir cet abonnement',
                                backgroundColor: const Color(0xFF7069FA),
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
                                          '30 jours pour tester, puis 2,49 € /mois',
                                          style: GoogleFonts.quicksand(
                                            color: const Color(0xFF5D6494),
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
    return _SubscriptionCardContainer(
      iconAsset: 'assets/icons/diamant_gold.svg',
      title: 'Abonnement Premium',
      price: '2,49 €',
      period: '/mois',
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
    return _SubscriptionCardContainer(
      iconAsset: 'assets/icons/diamant_purple.svg',
      title: 'Abonnement Starter',
      price: '0,00 €',
      period: '/mois',
      features: const [
        _SubscriptionFeature(
          boldText: 'Un seul',
          normalText: ' entraînement',
        ),
        _SubscriptionFeature(
          prefixText: 'Un maximum de ',
          boldText: '10 exercices',
        ),
        _SubscriptionFeature(
          normalText: 'Un tableau de bord personnalisé',
        ),
        _SubscriptionFeature(
          boldText: 'Accès aux bons plans de la Glift Shop',
        ),
        _SubscriptionFeature(
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
          color: const Color(0xFFD7D4DC),
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
      padding: const EdgeInsets.fromLTRB(20, 26, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Diamond Icon
          SvgPicture.asset(
            iconAsset,
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
              color: const Color(0xFF3A416F),
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
                  color: const Color(0xFF3A416F),
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                ' $period',
                style: GoogleFonts.quicksand(
                  color: const Color(0xFF3A416F),
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
                  ? const Color(0xFF5D6494)
                  : const Color(0xFFB1BACC);
              final boldColor = feature.isEnabled
                  ? const Color(0xFF3A416F)
                  : const Color(0xFFB1BACC);
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
    final effectiveBgColor = isLoading ? const Color(0xFFF2F1F6) : backgroundColor;
    final effectiveBorder = (isLoading || borderColor == null)
        ? null
        : Border.all(color: borderColor!, width: 1.2);
    final effectiveTextColor = isLoading ? const Color(0xFFD7D4DC) : textColor;

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
        decoration: const BoxDecoration(
          color: Color(0xFF3A416F),
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
