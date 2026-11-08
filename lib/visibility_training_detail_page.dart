import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'models/program.dart';
import 'models/training.dart';
import 'models/training_row.dart';
import 'repositories/program_repository.dart';
import 'widgets/glift_loader.dart';
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

class VisibilityTrainingDetailPage extends StatefulWidget {
  final Program program;
  final Training training;
  final SupabaseClient supabase;

  const VisibilityTrainingDetailPage({
    super.key,
    required this.program,
    required this.training,
    required this.supabase,
  });

  @override
  State<VisibilityTrainingDetailPage> createState() => _VisibilityTrainingDetailPageState();
}

class _VisibilityTrainingDetailPageState extends State<VisibilityTrainingDetailPage> {
  late final ProgramRepository _repository;
  late bool _isAppVisible;
  late bool _isDashboardVisible;

  List<TrainingRow>? _rows;
  bool _isLoadingRows = true;
  final ValueNotifier<double> _shadowOpacity = ValueNotifier<double>(0.0);

  @override
  void initState() {
    super.initState();
    _repository = ProgramRepository(widget.supabase);
    _isAppVisible = widget.training.app;
    _isDashboardVisible = widget.training.dashboard;
    _fetchRows();
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

  Future<void> _fetchRows() async {
    try {
      final rows = await _repository.getTrainingDetails(widget.training.id);
      rows.sort((a, b) => a.order.compareTo(b.order));
      if (mounted) {
        setState(() {
          _rows = rows;
          _isLoadingRows = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading training rows: $e');
      if (mounted) {
        setState(() {
          _isLoadingRows = false;
        });
      }
    }
  }

  Future<void> _refreshData() async {
    try {
      final allPrograms = await _repository.getAllProgramsRaw();
      final prog = allPrograms.firstWhere(
        (p) => p.id == widget.program.id,
        orElse: () => widget.program,
      );
      final tr = prog.trainings.firstWhere(
        (t) => t.id == widget.training.id,
        orElse: () => widget.training,
      );
      final rows = await _repository.getTrainingDetails(widget.training.id);
      rows.sort((a, b) => a.order.compareTo(b.order));
      if (mounted) {
        setState(() {
          _isAppVisible = tr.app;
          _isDashboardVisible = tr.dashboard;
          _rows = rows;
          _isLoadingRows = false;
        });
      }
    } catch (e) {
      debugPrint('Error refreshing training visibility data: $e');
    }
  }

  Future<void> _updateAppVisibility(bool value) async {
    HapticFeedback.lightImpact();
    setState(() {
      _isAppVisible = value;
    });
    try {
      await _repository.updateTrainingVisibility(widget.training.id, value);
    } catch (e) {
      debugPrint('Error updating training app visibility: $e');
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
    });
    try {
      await _repository.updateTrainingDashboardVisibility(widget.training.id, value);
    } catch (e) {
      debugPrint('Error updating training dashboard visibility: $e');
      if (mounted) {
        setState(() {
          _isDashboardVisible = !value;
        });
      }
    }
  }

  Future<void> _toggleExerciseVisibility(TrainingRow row, bool isVisibleInTraining) async {
    HapticFeedback.lightImpact();
    final newIsHidden = !isVisibleInTraining;
    if (_rows == null) return;

    final index = _rows!.indexWhere((r) => r.id == row.id);
    if (index == -1) return;

    setState(() {
      _rows![index] = _rows![index].copyWith(isHidden: newIsHidden);
    });

    try {
      await _repository.updateTrainingRow(row.id, isHidden: newIsHidden);
    } catch (e) {
      debugPrint('Error updating exercise visibility: $e');
      if (mounted) {
        setState(() {
          _rows![index] = _rows![index].copyWith(isHidden: !newIsHidden);
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
                onRefresh: _refreshData,
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

                        // SECTION 2: EXERCICE(S) A AFFICHER DANS L'ENTRAINEMENT
                        Text(
                          (_rows != null && _rows!.length > 1)
                              ? 'EXERCICES A AFFICHER DANS L’ENTRAINEMENT'
                              : 'EXERCICE A AFFICHER DANS L’ENTRAINEMENT',
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
                          child: _isLoadingRows
                              ? const Padding(
                                  padding: EdgeInsets.all(24.0),
                                  child: Center(child: GliftLoader()),
                                )
                              : (_rows == null || _rows!.isEmpty)
                                  ? Padding(
                                      padding: const EdgeInsets.all(20.0),
                                      child: Center(
                                        child: Text(
                                          'Aucun exercice dans cet entraînement',
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
                                      children: _rows!.map((row) {
                                        final isVisibleInTraining = !row.isHidden;
                                        final rawName = row.exercise.trim();
                                        final exerciseName = rawName.isEmpty
                                            ? 'Exercice sans nom'
                                            : rawName;
                                        return _buildSwitchRow(
                                          title: exerciseName,
                                          value: isVisibleInTraining,
                                          onChanged: (visible) =>
                                              _toggleExerciseVisibility(row, visible),
                                        );
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
                                widget.program.name.trim().isEmpty
                                    ? 'Programme sans nom'
                                    : widget.program.name.trim(),
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
                                widget.training.name.trim().isEmpty
                                    ? 'Entraînement sans nom'
                                    : widget.training.name.trim(),
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
