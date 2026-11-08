import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'models/program.dart';
import 'repositories/program_repository.dart';
import 'visibility_program_detail_page.dart';
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

class VisibilityProgramsPage extends StatefulWidget {
  final SupabaseClient supabase;

  const VisibilityProgramsPage({
    super.key,
    required this.supabase,
  });

  @override
  State<VisibilityProgramsPage> createState() => _VisibilityProgramsPageState();
}

class _VisibilityProgramsPageState extends State<VisibilityProgramsPage> {
  late final ProgramRepository _repository;
  List<Program>? _programs;
  bool _isLoading = true;
  final ValueNotifier<double> _shadowOpacity = ValueNotifier<double>(0.0);

  @override
  void initState() {
    super.initState();
    _repository = ProgramRepository(widget.supabase);
    _loadPrograms();
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

  Future<void> _loadPrograms() async {
    try {
      final programs = await _repository.getAllProgramsRaw();
      // On affiche que les programmes avec des modifications :
      // pas le programme par défaut "Nom du programme" et aucun programme sans entraînement créé
      final filtered = programs.where((p) {
        if (p.trainings.isEmpty) return false;
        if (p.name.trim() == 'Nom du programme') return false;
        return true;
      }).toList();

      if (mounted) {
        setState(() {
          _programs = filtered;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading all programs for visibility: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
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
            // Scrollable content with pull-to-refresh
            Positioned.fill(
              top: headerHeight,
              child: _isLoading
                  ? const Center(child: GliftLoader())
                  : GliftPullToRefresh(
                      onRefresh: _loadPrograms,
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
                              // Section: PROGRAMMES
                              Text(
                                'PROGRAMMES',
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
                                child: (_programs == null || _programs!.isEmpty)
                                    ? Padding(
                                        padding: const EdgeInsets.all(20.0),
                                        child: Center(
                                          child: Text(
                                            'Aucun programme pour le moment',
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
                                        children: _programs!.map((program) {
                                          return InkWell(
                                            borderRadius: BorderRadius.circular(12),
                                            onTap: () async {
                                              await Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (context) => VisibilityProgramDetailPage(
                                                    program: program,
                                                    supabase: widget.supabase,
                                                  ),
                                                ),
                                              );
                                              _loadPrograms();
                                            },
                                            child: Container(
                                              height: 56,
                                              padding: const EdgeInsets.only(left: 15, right: 15),
                                              child: Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      program.name,
                                                      style: GoogleFonts.quicksand(
                                                        color: const Color(0xFF3A416F),
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.w700,
                                                      ),
                                                      overflow: TextOverflow.ellipsis,
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
                                'Réglages',
                                style: GoogleFonts.quicksand(
                                  color: const Color(0xFF3A416F),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Régler la visibilité',
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
