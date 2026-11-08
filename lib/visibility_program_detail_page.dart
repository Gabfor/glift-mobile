import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase/supabase.dart';

import 'models/program.dart';
import 'models/training.dart';
import 'repositories/program_repository.dart';
import 'visibility_training_detail_page.dart';

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

  @override
  void initState() {
    super.initState();
    _repository = ProgramRepository(widget.supabase);
    _program = widget.program;
    _isAppVisible = widget.program.app;
    _isDashboardVisible = widget.program.dashboard;
  }

  Future<void> _refreshProgram() async {
    try {
      final allPrograms = await _repository.getAllProgramsRaw();
      final updated = allPrograms.firstWhere(
        (p) => p.id == _program.id,
        orElse: () => _program,
      );
      if (mounted) {
        setState(() {
          _program = updated;
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
                          'Régler la visibilité',
                          style: GoogleFonts.quicksand(
                            color: const Color(0xFF3A416F),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _program.name,
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

                  // SECTION 2: ENTRAÎNEMENTS
                  Text(
                    'ENTRAÎNEMENTS',
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
                    child: (_program.trainings.isEmpty)
                        ? Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Text(
                              'Aucun entraînement dans ce programme',
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
                              _program.trainings.length,
                              (index) {
                                final training = _program.trainings[index];
                                return Column(
                                  children: [
                                    if (index > 0)
                                      const Divider(height: 1, color: Color(0xFFECE9F1)),
                                    _buildTrainingTile(training),
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

  Widget _buildTrainingTile(Training training) {
    return InkWell(
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
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                training.name,
                style: GoogleFonts.quicksand(
                  color: const Color(0xFF3A416F),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF5D6494)),
          ],
        ),
      ),
    );
  }
}

