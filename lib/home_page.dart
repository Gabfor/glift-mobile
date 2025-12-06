import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase/supabase.dart';

import 'auth/auth_repository.dart';
import 'login_page.dart';
import 'models/program.dart';
import 'models/training.dart';
import 'repositories/program_repository.dart';
import 'theme/glift_theme.dart';
import 'training_details_page.dart';
import 'widgets/glift_loader.dart';
import 'widgets/glift_page_layout.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.supabase,
    this.onNavigateToDashboard,
  });

  final SupabaseClient supabase;
  final void Function(String?)? onNavigateToDashboard;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final ProgramRepository _programRepository;
  late final PageController _pageController;
  late final ScrollController _programScrollController;
  final List<GlobalKey> _programKeys = [];
  List<Program>? _programs;
  String? _selectedProgramId;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _programRepository = ProgramRepository(widget.supabase);
    _pageController = PageController();
    _programScrollController = ScrollController();
    _fetchPrograms();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _programScrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchPrograms() async {
    try {
      final programs = await _programRepository.getPrograms();
      if (mounted) {
        setState(() {
          _programs = programs;
          _programKeys
            ..clear()
            ..addAll(List.generate(programs.length, (_) => GlobalKey()));
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
    _scrollProgramIntoView(index);
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
    _scrollProgramIntoView(index);
  }

  void _scrollProgramIntoView(int index) {
    if (_programScrollController.hasClients && index < _programKeys.length) {
      final context = _programKeys[index].currentContext;

      if (context != null) {
        Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          alignment: 0.5,
        );
      } else {
        _programScrollController.animateTo(
          _programScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GliftPageLayout(
      header: _buildHeader(),
      scrollable: false,
      padding: EdgeInsets.zero,
      headerPadding: EdgeInsets.zero,
      child: _buildBody(),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 20, right: 20, top: 10),
          child: Text(
            'Programmes',
            style: GoogleFonts.quicksand(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (_programs != null && _programs!.isNotEmpty) ...[
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            controller: _programScrollController,
            child: Row(
              children: [
                const SizedBox(width: 20),
                ..._programs!.asMap().entries.map((entry) {
                  final index = entry.key;
                  final program = entry.value;
                  final isSelected = program.id == _selectedProgramId;
                  return GestureDetector(
                    onTap: () => _onProgramSelected(index),
                    child: Padding(
                      padding: const EdgeInsets.only(right: 20),
                      child: Container(
                        key: _programKeys[index],
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
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const GliftLoader();
    }

    if (_error != null) {
      return Center(child: Text('Erreur: $_error'));
    }

    if (_programs == null || _programs!.isEmpty) {
      return Center(
        child: Text(
          'Aucun programme disponible',
          style: GoogleFonts.quicksand(fontSize: 16, color: GliftTheme.body),
        ),
      );
    }

    return PageView.builder(
      controller: _pageController,
      onPageChanged: _onPageChanged,
      itemCount: _programs!.length,
      itemBuilder: (context, index) {
        final program = _programs![index];
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 30, 20, 20),
          itemCount: program.trainings.length + 1,
          separatorBuilder: (context, separatorIndex) =>
              SizedBox(height: separatorIndex == 0 ? 10 : 16),
          itemBuilder: (context, itemIndex) {
            if (itemIndex == 0) {
              return Text(
                'Entraînements',
                style: GoogleFonts.quicksand(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: GliftTheme.title,
                ),
              );
            }

            final training = program.trainings[itemIndex - 1];
            return _TrainingCard(
              training: training,
              onTap: () async {
                final result = await Navigator.of(context).push(
                  PageRouteBuilder(
                    pageBuilder: (_, __, ___) => TrainingDetailsPage(
                      training: training,
                      supabase: widget.supabase,
                    ),
                    transitionsBuilder:
                        (_, animation, secondaryAnimation, child) {
                          const begin = Offset(0, 1);
                          const end = Offset.zero;
                          const curve = Curves.ease;

                          final tween = Tween(
                            begin: begin,
                            end: end,
                          ).chain(CurveTween(curve: curve));

                          return SlideTransition(
                            position: animation.drive(tween),
                            child: child,
                          );
                        },
                  ),
                );

                if (result == true) {
                  // Reload programs to refresh stats (last session, average time)
                  _fetchPrograms();
                  widget.onNavigateToDashboard?.call(program.id);
                }
              },
            );
          },
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
    // Determine dynamic display info
    String lastSessionText = 'Jamais';
    String averageTimeText = '-';

    if (training.lastSessionDate != null) {
      lastSessionText = _formatRelativeTime(training.lastSessionDate!);
    }
    
    if (training.averageDurationMinutes != null) {
      final hours = training.averageDurationMinutes! ~/ 60;
      final minutes = training.averageDurationMinutes! % 60;
      
      if (hours > 0) {
        averageTimeText = '${hours}h${minutes.toString().padLeft(2, '0')} min';
      } else {
        averageTimeText = '$minutes min';
      }
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: const Color(0xFFD7D4DC)),
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.quicksand(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF3A416F),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Dernière séance : $lastSessionText',
                    style: GoogleFonts.quicksand(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFC2BFC6),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Temps moyen : $averageTimeText',
                    style: GoogleFonts.quicksand(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFC2BFC6),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            SvgPicture.asset('assets/icons/good.svg', width: 20, height: 20),
          ],
        ),
      ),
    );
  }

  String _formatRelativeTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return 'il y a ${difference.inDays} jours';
    } else if (difference.inHours > 0) {
      return 'il y a ${difference.inHours} heures';
    } else if (difference.inMinutes > 0) {
      return 'il y a ${difference.inMinutes} minutes';
    } else {
      return 'à l\'instant';
    }
  }
}
