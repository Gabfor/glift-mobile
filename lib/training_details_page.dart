import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase/supabase.dart';
import '../models/training.dart';
import '../models/training_row.dart';
import '../repositories/program_repository.dart';
import 'widgets/glift_page_layout.dart';

class TrainingDetailsPage extends StatefulWidget {
  const TrainingDetailsPage({
    super.key,
    required this.training,
    required this.supabase,
  });

  final Training training;
  final SupabaseClient supabase;

  @override
  State<TrainingDetailsPage> createState() => _TrainingDetailsPageState();
}

class _TrainingDetailsPageState extends State<TrainingDetailsPage> {
  late final ProgramRepository _programRepository;
  List<TrainingRow>? _rows;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _programRepository = ProgramRepository(widget.supabase);
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    try {
      final rows = await _programRepository.getTrainingDetails(widget.training.id);
      if (mounted) {
        setState(() {
          _rows = rows;
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
    return GliftPageLayout(
      header: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.chevron_left, color: Color(0xFF7069FA)),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Entraînements',
                style: GoogleFonts.quicksand(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  height: 1.86,
                ),
              ),
              Text(
                widget.training.name,
                style: GoogleFonts.quicksand(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  height: 1.62,
                ),
              ),
            ],
          ),
        ],
      ),
      scrollable: false,
      padding: EdgeInsets.zero,
      footer: _StartButton(onTap: () {
        // TODO: Start workout logic
      }),
      child: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }

    if (_error != null) {
      return Center(child: Text('Erreur: $_error', style: const TextStyle(color: Colors.white)));
    }

    if (_rows == null || _rows!.isEmpty) {
      return Center(
        child: Text(
          'Aucun exercice dans cet entraînement',
          style: GoogleFonts.quicksand(
            fontSize: 16,
            color: Colors.white,
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100), // Bottom padding for button
      itemCount: _rows!.length,
      separatorBuilder: (context, index) => const SizedBox(height: 20),
      itemBuilder: (context, index) {
        final row = _rows![index];
        return _ExerciseCard(row: row);
      },
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({required this.row});

  final TrainingRow row;

  @override
  State<_ExerciseCard> createState() => _ExerciseCardState();
}

class _ExerciseCardState extends State<_ExerciseCard> {
  late final List<_EffortState> _effortStates;

  @override
  void initState() {
    super.initState();
    _effortStates = List<_EffortState>.filled(widget.row.series, _EffortState.neutral);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFD7D4DC), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.row.exercise,
            style: GoogleFonts.quicksand(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF7069FA),
            ),
          ),
          const SizedBox(height: 20),

          // Header Row
          Row(
            children: [
              _GridHeader('Sets', flex: 40),
              const SizedBox(width: 10),
              _GridHeader('Reps.', flex: 86),
              const SizedBox(width: 10),
              _GridHeader('Poids', flex: 86),
              const SizedBox(width: 10),
              _GridHeader('Effort', flex: 68),
            ],
          ),
          const SizedBox(height: 10),

          // Sets Rows
          ...List.generate(widget.row.series, (index) {
            final reps = index < widget.row.repetitions.length ? widget.row.repetitions[index] : '-';
            final weight = index < widget.row.weights.length ? widget.row.weights[index] : '-';
            final state = _effortStates[index];
            final backgroundColor = _backgroundColorForState(state);
            final textColor = _textColorForState(state);

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  // Set Number
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${index + 1}',
                        style: GoogleFonts.quicksand(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF3A416F),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Reps
                  Expanded(
                    flex: 86,
                    child: Container(
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: backgroundColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFECE9F1)),
                      ),
                      child: Text(
                        reps,
                        style: GoogleFonts.quicksand(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Weight
                  Expanded(
                    flex: 86,
                    child: Container(
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: backgroundColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFECE9F1)),
                      ),
                      child: Text(
                        weight,
                        style: GoogleFonts.quicksand(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Effort toggle
                  Expanded(
                    flex: 68,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => _cycleEffortState(index),
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFECE9F1)),
                        ),
                        alignment: Alignment.center,
                        child: SvgPicture.asset(
                          _iconForState(state),
                          width: 24,
                          height: 24,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  void _cycleEffortState(int index) {
    setState(() {
      _effortStates[index] = switch (_effortStates[index]) {
        _EffortState.neutral => _EffortState.positive,
        _EffortState.positive => _EffortState.negative,
        _EffortState.negative => _EffortState.neutral,
      };
    });
  }

  Color _backgroundColorForState(_EffortState state) {
    switch (state) {
      case _EffortState.neutral:
        return Colors.white;
      case _EffortState.positive:
        return const Color(0xFFF6FDF7);
      case _EffortState.negative:
        return const Color(0xFFFFF1F1);
    }
  }

  Color _textColorForState(_EffortState state) {
    switch (state) {
      case _EffortState.neutral:
        return const Color(0xFF3A416F);
      case _EffortState.positive:
        return const Color(0xFF57AE5B);
      case _EffortState.negative:
        return const Color(0xFFEF4F4E);
    }
  }

  String _iconForState(_EffortState state) {
    switch (state) {
      case _EffortState.neutral:
        return 'assets/icons/smiley_jaune.svg';
      case _EffortState.positive:
        return 'assets/icons/smileys-vert.svg';
      case _EffortState.negative:
        return 'assets/icons/smiley_rouge.svg';
    }
  }
}

enum _EffortState { neutral, positive, negative }

class _StartButton extends StatelessWidget {
  const _StartButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFF00D591),
        borderRadius: BorderRadius.circular(25),
        boxShadow: const [
          BoxShadow(
            color: Color(0x3F00D591),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(25),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Commencer',
                style: GoogleFonts.quicksand(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward, color: Colors.white, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _GridHeader extends StatelessWidget {
  final String text;
  final int flex;

  const _GridHeader(this.text, {required this.flex});

  @override
  Widget build(BuildContext context) {
    if (flex > 0) {
       return Expanded(
        flex: flex,
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: GoogleFonts.redHatText(
            fontSize: 14,
            color: const Color(0xFFC2BFC6),
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    } else {
      return SizedBox(
        width: 40, // Fixed width for "Sets" if needed, but using flex is safer for responsiveness
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: GoogleFonts.redHatText(
            fontSize: 14,
            color: const Color(0xFFC2BFC6),
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }
  }
}
