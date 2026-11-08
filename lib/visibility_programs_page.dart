import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase/supabase.dart';

import 'models/program.dart';
import 'repositories/program_repository.dart';
import 'visibility_program_detail_page.dart';
import 'widgets/glift_loader.dart';
import 'widgets/glift_pull_to_refresh.dart';

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

  @override
  void initState() {
    super.initState();
    _repository = ProgramRepository(widget.supabase);
    _loadPrograms();
  }

  Future<void> _loadPrograms() async {
    try {
      final programs = await _repository.getAllProgramsRaw();
      if (mounted) {
        setState(() {
          _programs = programs;
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

            // Content
            Expanded(
              child: _isLoading
                  ? const Center(child: GliftLoader())
                  : GliftPullToRefresh(
                      onRefresh: _loadPrograms,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        padding: EdgeInsets.fromLTRB(
                          20,
                          0,
                          20,
                          MediaQuery.of(context).padding.bottom + 40,
                        ),
                        children: [
                          // Section: PROGRAMMES
                          Text(
                            'PROGRAMMES',
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
                            child: (_programs == null || _programs!.isEmpty)
                                ? Padding(
                                    padding: const EdgeInsets.all(20.0),
                                    child: Text(
                                      'Aucun programme pour le moment',
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
                                      _programs!.length,
                                      (index) {
                                        final program = _programs![index];
                                        return Column(
                                          children: [
                                            if (index > 0)
                                              const Divider(height: 1, color: Color(0xFFECE9F1)),
                                            InkWell(
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
                                                padding: const EdgeInsets.symmetric(horizontal: 16),
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
            ),
          ],
        ),
      ),
    );
  }
}

