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
import 'widgets/glift_page_layout.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.supabase});

  final SupabaseClient supabase;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final ProgramRepository _programRepository;
  late final PageController _pageController;
  List<Program>? _programs;
  String? _selectedProgramId;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _programRepository = ProgramRepository(widget.supabase);
    _pageController = PageController();
    _fetchPrograms();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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

  void _onProgramSelected(int index) {
    setState(() {
      _selectedProgramId = _programs![index].id;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _onPageChanged(int index) {
    setState(() {
      _selectedProgramId = _programs![index].id;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GliftPageLayout(
      header: _buildHeader(),
      scrollable: false,
      padding: EdgeInsets.zero,
      child: _buildBody(),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Programmes',
          style: GoogleFonts.quicksand(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (_programs != null && _programs!.isNotEmpty) ...[
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _programs!.asMap().entries.map((entry) {
                final index = entry.key;
                final program = entry.value;
                final isSelected = program.id == _selectedProgramId;
                return GestureDetector(
                  onTap: () => _onProgramSelected(index),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 20),
                    child: Text(
                      program.name,
                      style: GoogleFonts.quicksand(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
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
      ],
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

    return PageView.builder(
      controller: _pageController,
      onPageChanged: _onPageChanged,
      itemCount: _programs!.length,
      itemBuilder: (context, index) {
        final program = _programs![index];
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
                itemCount: program.trainings.length,
                separatorBuilder: (context, index) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final training = program.trainings[index];
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
      },
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
