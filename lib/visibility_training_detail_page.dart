import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase/supabase.dart';

import 'models/program.dart';
import 'models/training.dart';
import 'models/training_row.dart';
import 'repositories/program_repository.dart';
import 'widgets/glift_loader.dart';

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

  @override
  void initState() {
    super.initState();
    _repository = ProgramRepository(widget.supabase);
    _isAppVisible = widget.training.app;
    _isDashboardVisible = widget.training.dashboard;
    _fetchRows();
  }

  Future<void> _fetchRows() async {
    try {
      final rows = await _repository.getTrainingDetails(widget.training.id);
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
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header
            Container(
              color: const Color(0xFFF9FAFB),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: () => Navigator.of(context).pop(),
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
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.program.name,
                          style: GoogleFonts.quicksand(
                            color: const Color(0xFF3A416F),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.training.name,
                          style: GoogleFonts.quicksand(
                            color: const Color(0xFF3A416F),
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  20,
                  0,
                  20,
                  MediaQuery.of(context).padding.bottom + 40,
                ),
                children: [
                  // SECTION 1: RÉGLAGE DE LA VISIBILITÉ
                  Text(
                    'RÉGLAGE DE LA VISIBILITÉ',
                    style: GoogleFonts.quicksand(
                      color: const Color(0xFFA09CA8),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFD7D4DC)),
                    ),
                    child: Column(
                      children: [
                        _buildSwitchRow(
                          title: 'Application mobile',
                          value: _isAppVisible,
                          onChanged: _updateAppVisibility,
                        ),
                        const Divider(height: 1, color: Color(0xFFECE9F1)),
                        _buildSwitchRow(
                          title: 'Tableau de bord',
                          value: _isDashboardVisible,
                          onChanged: _updateDashboardVisibility,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 25),

                  // SECTION 2: EXERCICES A AFFICHER DANS L'ENTRAINEMENT
                  Text(
                    'EXERCICES A AFFICHER DANS L’ENTRAINEMENT',
                    style: GoogleFonts.quicksand(
                      color: const Color(0xFFA09CA8),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFD7D4DC)),
                    ),
                    child: _isLoadingRows
                        ? const Padding(
                            padding: EdgeInsets.all(24.0),
                            child: GliftLoader(),
                          )
                        : (_rows == null || _rows!.isEmpty)
                            ? Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Text(
                                  'Aucun exercice dans cet entraînement',
                                  style: GoogleFonts.quicksand(
                                    color: const Color(0xFF5D6494),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              )
                            : Column(
                                children: List.generate(
                                  _rows!.length,
                                  (index) {
                                    final row = _rows![index];
                                    final exerciseName = row.exercise.trim().isEmpty
                                        ? 'Nom de l’exercice'
                                        : row.exercise.trim();
                                    final isVisibleInTraining = !row.isHidden;

                                    return Column(
                                      children: [
                                        if (index > 0)
                                          const Divider(height: 1, color: Color(0xFFECE9F1)),
                                        _buildSwitchRow(
                                          title: exerciseName,
                                          value: isVisibleInTraining,
                                          onChanged: (v) => _toggleExerciseVisibility(row, v),
                                        ),
                                      ],
                                    );
                                  },
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

  Widget _buildSwitchRow({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
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
            ),
          ),
          const SizedBox(width: 12),
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

