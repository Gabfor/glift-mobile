import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'models/program.dart';
import 'models/training.dart';
import 'repositories/program_repository.dart';
import 'visibility_training_detail_page.dart';
import 'widgets/glift_pull_to_refresh.dart';

class _ClampedBottomScrollPhysics extends ScrollPhysics {
  const _ClampedBottomScrollPhysics({super.parent});

  @override
  _ClampedBottomScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return _ClampedBottomScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  double applyBoundaryConditions(ScrollMetrics position, double value) {
    if (value > position.maxScrollExtent) {
      return value - position.maxScrollExtent;
    }
    return super.applyBoundaryConditions(position, value);
  }
}

class VisibilityProgramDetailPage extends StatefulWidget {
  final Program program;
  final SupabaseClient supabase;

  const VisibilityProgramDetailPage({
    super.key,
    required this.program,
    required this.supabase,
  });

  @override
  State<VisibilityProgramDetailPage> createState() => _VisibilityProgramDetailPageState();
}

class _VisibilityProgramDetailPageState extends State<VisibilityProgramDetailPage> {
  late final ProgramRepository _repository;
  late Program _program;
  late bool _isAppVisible;
  late bool _isDashboardVisible;
  final ValueNotifier<double> _shadowOpacity = ValueNotifier<double>(0.0);

  @override
  void initState() {
    super.initState();
    _repository = ProgramRepository(widget.supabase);
    final sortedTrainings = List<Training>.from(widget.program.trainings)
      ..sort((a, b) => a.position.compareTo(b.position));
    _program = widget.program.copyWith(trainings: sortedTrainings);
    _isAppVisible = widget.program.app;
    _isDashboardVisible = widget.program.dashboard;
  }

  @override
  void dispose() {
    _shadowOpacity.dispose();
    super.dispose();
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification.metrics.axis == Axis.vertical) {
      final double offset = notification.metrics.pixels;
      final double target = (offset / 15.0).clamp(0.0, 1.0);
      if (_shadowOpacity.value != target) {
        _shadowOpacity.value = target;
      }
    }
    return false;
  }

  Future<void> _refreshProgram() async {
    try {
      final allPrograms = await _repository.getAllProgramsRaw();
      final updated = allPrograms.firstWhere(
        (p) => p.id == _program.id,
        orElse: () => _program,
      );
      final sortedTrainings = List<Training>.from(updated.trainings)
        ..sort((a, b) => a.position.compareTo(b.position));
      final programWithSortedTrainings = updated.copyWith(trainings: sortedTrainings);
      if (mounted) {
        setState(() {
          _program = programWithSortedTrainings;
          _isAppVisible = updated.app;
          _isDashboardVisible = updated.dashboard;
        });
      }
    } catch (e) {
      debugPrint('Error refreshing program: $e');
    }
  }

  Future<void> _updateAppVisibility(bool value) async {
    HapticFeedback.lightImpact();
    setState(() {
      _isAppVisible = value;
      // Cascade to local training objects
      _program = _program.copyWith(
        app: value,
        trainings: _program.trainings.map((t) => t.copyWith(app: value)).toList(),
      );
    });
    try {
      await _repository.updateProgramVisibility(_program.id, value);
    } catch (e) {
      debugPrint('Error updating program app visibility: $e');
      if (mounted) {
        setState(() {
          _isAppVisible = !value;
        });
      }
    }
  }

  Future<void> _updateDashboardVisibility(bool value) async {
    HapticFeedback.lightImpact();
    setState(() {
      _isDashboardVisible = value;
      _program = _program.copyWith(dashboard: value);
    });
    try {
      await _repository.updateProgramDashboardVisibility(_program.id, value);
    } catch (e) {
      debugPrint('Error updating program dashboard visibility: $e');
      if (mounted) {
        setState(() {
          _isDashboardVisible = !value;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const double headerHeight = 84.0;
    const double gapBelowHeader = 10.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // Scrollable Content
            Positioned.fill(
              top: headerHeight,
              child: GliftPullToRefresh(
                onRefresh: _refreshProgram,
                child: NotificationListener<ScrollNotification>(
                  onNotification: _handleScrollNotification,
                  child: SingleChildScrollView(
                    physics: const _ClampedBottomScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                    ),
                    padding: EdgeInsets.fromLTRB(
                      20,
                      gapBelowHeader,
                      20,
                      MediaQuery.of(context).padding.bottom + 40,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // SECTION 1: RÉGLAGE DE LA VISIBILITÉ
                        Text(
                          'RÉGLAGE DE LA VISIBILITÉ',
                          style: GoogleFonts.quicksand(
                            color: const Color(0xFFC2BFC6),
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFECE9F1)),
                          ),
                          child: Column(
                            children: [
                              _buildSwitchRow(
                                title: 'Application mobile',
                                value: _isAppVisible,
                                onChanged: _updateAppVisibility,
                              ),
                              _buildSwitchRow(
                                title: 'Tableau de bord',
                                value: _isDashboardVisible,
                                onChanged: _updateDashboardVisibility,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 25),

                        // SECTION 2: ENTRAÎNEMENT(S)
                        Text(
                          _program.trainings.length > 1
                              ? 'ENTRAÎNEMENTS'
                              : 'ENTRAÎNEMENT',
                          style: GoogleFonts.quicksand(
                            color: const Color(0xFFC2BFC6),
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFECE9F1)),
                          ),
                          child: (_program.trainings.isEmpty)
                              ? Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: Center(
                                    child: Text(
                                      'Aucun entraînement dans ce programme',
                                      style: GoogleFonts.quicksand(
                                        color: const Color(0xFF5D6494),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                )
                              : Column(
                                  children: _program.trainings.map((training) {
                                    return _buildTrainingTile(training);
                                  }).toList(),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Pinned Header with scroll shadow
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    color: const Color(0xFFF9FAFB),
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _SettingsBackButton(onTap: () => Navigator.of(context).pop()),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Régler la visibilité',
                                style: GoogleFonts.quicksand(
                                  color: const Color(0xFF3A416F),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _program.name.trim().isEmpty
                                    ? 'Programme sans nom'
                                    : _program.name.trim(),
                                style: GoogleFonts.quicksand(
                                  color: const Color(0xFF3A416F),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  ValueListenableBuilder<double>(
                    valueListenable: _shadowOpacity,
                    builder: (context, opacity, _) {
                      return IgnorePointer(
                        child: Opacity(
                          opacity: opacity,
                          child: Container(
                            height: 16,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  const Color(0xFF1E1742).withValues(alpha: 0.12),
                                  const Color(0xFF1E1742).withValues(alpha: 0.04),
                                  Colors.transparent,
                                ],
                                stops: const [0.0, 0.45, 1.0],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchRow({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.quicksand(
                color: const Color(0xFF3A416F),
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          const SizedBox(width: 15),
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

  Widget _buildTrainingTile(Training training) {
    final trainingName = training.name.trim().isEmpty
        ? 'Entraînement sans nom'
        : training.name.trim();

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => VisibilityTrainingDetailPage(
              program: _program,
              training: training,
              supabase: widget.supabase,
            ),
          ),
        );
        _refreshProgram();
      },
      child: Container(
        height: 56,
        padding: const EdgeInsets.only(left: 15, right: 15),
        child: Row(
          children: [
            Expanded(
              child: Text(
                trainingName,
                style: GoogleFonts.quicksand(
                  color: const Color(0xFF3A416F),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Color(0xFF5D6494),
            ),
          ],
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
