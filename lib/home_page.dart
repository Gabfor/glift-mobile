import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase/supabase.dart';

import 'auth/auth_repository.dart';
import 'login_page.dart';
import 'models/program.dart';
import 'models/training.dart';
import 'repositories/program_repository.dart';
import 'theme/glift_theme.dart';
import 'training_details_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.supabase});

  final SupabaseClient supabase;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final ProgramRepository _programRepository;
  List<Program>? _programs;
  String? _selectedProgramId;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _programRepository = ProgramRepository(widget.supabase);
    _fetchPrograms();
  }

  Future<void> _fetchPrograms() async {
    try {
      final programs = await _programRepository.getPrograms();
      if (mounted) {
        setState(() {
          _programs = programs;
          if (programs.isNotEmpty) {
            _selectedProgramId = programs.first.id;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              color: const Color(0xFF7069FA),
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Programmes',
                    style: GoogleFonts.quicksand(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_programs != null)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _programs!.map((program) {
                          final isSelected = program.id == _selectedProgramId;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedProgramId = program.id;
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.only(right: 20, bottom: 15),
                              child: Text(
                                program.name,
                                style: GoogleFonts.quicksand(
                                  fontSize: isSelected ? 20 : 16,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.white.withOpacity(0.5),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ),
            ),
            
            // Content Section
            Expanded(
              child: Transform.translate(
                offset: const Offset(0, -20),
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                    child: _buildBody(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(child: Text('Erreur: $_error'));
    }

    if (_programs == null || _programs!.isEmpty) {
      return Center(
        child: Text(
          'Aucun programme disponible',
          style: GoogleFonts.quicksand(
            fontSize: 16,
            color: GliftTheme.body,
          ),
        ),
      );
    }

    final selectedProgram = _programs!.firstWhere(
      (p) => p.id == _selectedProgramId,
      orElse: () => _programs!.first,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 30, 20, 10),
          child: Text(
            'Entraînements',
            style: GoogleFonts.quicksand(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: GliftTheme.title,
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            itemCount: selectedProgram.trainings.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final training = selectedProgram.trainings[index];
              return _TrainingCard(
                training: training,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => TrainingDetailsPage(
                        training: training,
                        supabase: widget.supabase,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _TrainingCard extends StatelessWidget {
  const _TrainingCard({required this.training, required this.onTap});

  final Training training;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    training.name,
                    style: GoogleFonts.quicksand(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: GliftTheme.title,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Dernière séance : il y a 6 jours', // Placeholder
                    style: GoogleFonts.quicksand(
                      fontSize: 12,
                      color: const Color(0xFFD1D5DB),
                    ),
                  ),
                  Text(
                    'Temps moyen : 45min', // Placeholder
                    style: GoogleFonts.quicksand(
                      fontSize: 12,
                      color: const Color(0xFFD1D5DB),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Color(0xFF00D591), // Green color from screenshot
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_downward, // Looks like a download/arrow icon
                color: Colors.white,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
