import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase/supabase.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/training.dart';
import '../models/training_row.dart';
import '../repositories/program_repository.dart';
import 'widgets/glift_page_layout.dart';
import 'widgets/numeric_keypad.dart';
import '../theme/glift_theme.dart';

class ActiveTrainingPage extends StatefulWidget {
  const ActiveTrainingPage({
    super.key,
    required this.training,
    required this.supabase,
  });

  final Training training;
  final SupabaseClient supabase;

  @override
  State<ActiveTrainingPage> createState() => _ActiveTrainingPageState();
}

class _ActiveTrainingPageState extends State<ActiveTrainingPage> {
  late final ProgramRepository _programRepository;
  List<TrainingRow>? _rows;
  bool _isLoading = true;
  String? _error;

  // Keypad state
  ValueChanged<String>? _currentInputHandler;
  VoidCallback? _currentBackspaceHandler;
  VoidCallback? _currentDecimalHandler;
  VoidCallback? _currentCloseHandler;

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

  void _handleFocus({
    required ValueChanged<String> onInput,
    required VoidCallback onBackspace,
    required VoidCallback onDecimal,
    required VoidCallback onClose,
  }) {
    setState(() {
      _currentInputHandler = onInput;
      _currentBackspaceHandler = onBackspace;
      _currentDecimalHandler = onDecimal;
      _currentCloseHandler = onClose;
    });
  }

  void _closeKeypad() {
    if (_currentCloseHandler != null) {
      _currentCloseHandler!();
    }
    setState(() {
      _currentInputHandler = null;
      _currentBackspaceHandler = null;
      _currentDecimalHandler = null;
      _currentCloseHandler = null;
    });
  }

  // Interaction handlers
  void _moveRowDown(int index) {
    if (_rows == null || index >= _rows!.length - 1) return;
    
    setState(() {
      final item = _rows!.removeAt(index);
      _rows!.insert(index + 1, item);
    });
  }

  void _handleRowUpdate(int index, List<String> repetitions, List<String> weights) {
    if (_rows == null) return;
    
    setState(() {
      final oldRow = _rows![index];
      _rows![index] = TrainingRow(
        id: oldRow.id,
        trainingId: oldRow.trainingId,
        exercise: oldRow.exercise,
        series: oldRow.series,
        repetitions: repetitions,
        weights: weights,
        rest: oldRow.rest,
        note: oldRow.note,
        videoUrl: oldRow.videoUrl,
        order: oldRow.order,
      );
    });
  }

  Future<void> _finishTraining() async {
    if (_rows == null) return;

    setState(() => _isLoading = true);

    try {
      // Filter only completed rows
      final completedRowsData = _rows!.where((row) => _completedRows.contains(row.id)).toList();

      if (completedRowsData.isNotEmpty) {
        final userId = widget.supabase.auth.currentUser?.id;
        if (userId != null) {
          // Save history
          await _programRepository.saveTrainingSession(
            userId: userId,
            trainingId: widget.training.id,
            completedRows: completedRowsData,
          );
        }

        // Update templates (last used weights)
        await Future.wait(completedRowsData.map((row) => _programRepository.updateTrainingRow(
          row.id,
          repetitions: row.repetitions,
          weights: row.weights,
        )));
      }

      if (mounted) {
        Navigator.of(context).pop(true);
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

  final Set<String> _completedRows = {};
  final Set<String> _ignoredRows = {};

  Future<void> _completeRow(int index) async {
    if (_rows == null) return;
    
    final row = _rows![index];
    
    setState(() {
      _completedRows.add(row.id);
      final item = _rows!.removeAt(index);
      _rows!.add(item);
    });
  }

  void _ignoreRow(int index) {
    if (_rows == null) return;
    
    final row = _rows![index];
    
    setState(() {
      _ignoredRows.add(row.id);
      final item = _rows!.removeAt(index);
      _rows!.add(item);
    });
  }

  @override
  Widget build(BuildContext context) {
    final allProcessed = _rows != null && 
        (_completedRows.length + _ignoredRows.length == _rows!.length);

    return GliftPageLayout(
      resizeToAvoidBottomInset: false,
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
      child: Stack(
        children: [
          GestureDetector(
            onTap: _closeKeypad,
            behavior: HitTestBehavior.translucent,
            child: _buildBody(allProcessed),
          ),
          if (allProcessed)
            Positioned(
              left: 0,
              right: 0,
              bottom: 30,
              child: Center(
                child: _FinishButton(onTap: _finishTraining),
              ),
            ),
          if (_currentInputHandler != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: NumericKeypad(
                onNumber: _currentInputHandler!,
                onBackspace: _currentBackspaceHandler!,
                onDecimal: _currentDecimalHandler!,
                onClose: _closeKeypad,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBody(bool allProcessed) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: GliftTheme.accent));
    }

    if (_error != null) {
      return Center(child: Text('Erreur: $_error', style: const TextStyle(color: Colors.red)));
    }

    if (_rows == null || _rows!.isEmpty) {
      return Center(
        child: Text(
          'Aucun exercice dans cet entraînement',
          style: GoogleFonts.quicksand(
            fontSize: 16,
            color: GliftTheme.title,
          ),
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.fromLTRB(20, 20, 20, allProcessed ? 100 : 20),
      itemCount: _rows!.length,
      separatorBuilder: (context, index) => const SizedBox(height: 20),
      itemBuilder: (context, index) {
        final row = _rows![index];
        final isLast = index == _rows!.length - 1;
        final isCompleted = _completedRows.contains(row.id);
        final isIgnored = _ignoredRows.contains(row.id);

        return _ActiveExerciseCard(
          key: ValueKey(row.id),
          row: row,
          onFocus: _handleFocus,
          isLast: isLast,
          isCompleted: isCompleted,
          isIgnored: isIgnored,
          onMoveDown: () => _moveRowDown(index),
          onComplete: () => _completeRow(index),
          onIgnore: () => _ignoreRow(index),
          onUpdate: (reps, weights) => _handleRowUpdate(index, reps, weights),
        );
      },
    );
  }
}

class _ActiveExerciseCard extends StatefulWidget {
  const _ActiveExerciseCard({
    super.key,
    required this.row,
    required this.onFocus,
    required this.isLast,
    required this.isCompleted,
    required this.isIgnored,
    required this.onMoveDown,
    required this.onComplete,
    required this.onIgnore,
    required this.onUpdate,
  });

  final TrainingRow row;
  final Function({
    required ValueChanged<String> onInput,
    required VoidCallback onBackspace,
    required VoidCallback onDecimal,
    required VoidCallback onClose,
  }) onFocus;
  final bool isLast;
  final bool isCompleted;
  final bool isIgnored;
  final VoidCallback onMoveDown;
  final VoidCallback onComplete;
  final VoidCallback onIgnore;
  final Function(List<String>, List<String>) onUpdate;

  @override
  State<_ActiveExerciseCard> createState() => _ActiveExerciseCardState();
}

class _ActiveExerciseCardState extends State<_ActiveExerciseCard> with AutomaticKeepAliveClientMixin {
  late final List<_EffortState> _effortStates;
  late List<String> _repetitions;
  late List<String> _weights;
  late List<bool> _completedSets;
  
  int? _activeRepsIndex;
  int? _activeWeightIndex;
  bool _isFirstInput = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _effortStates = List<_EffortState>.filled(widget.row.series, _EffortState.neutral);
    _repetitions = List<String>.from(widget.row.repetitions);
    _weights = List<String>.from(widget.row.weights);
    _completedSets = List<bool>.filled(widget.row.series, false);
  }

  void _activateCell(int index, String type) {
    setState(() {
      if (type == 'reps') {
        _activeRepsIndex = index;
        _activeWeightIndex = null;
      } else {
        _activeRepsIndex = null;
        _activeWeightIndex = index;
      }
      _isFirstInput = true;
    });

    widget.onFocus(
      onInput: (value) => _handleInput(index, type, value),
      onBackspace: () => _handleBackspace(index, type),
      onDecimal: () => _handleInput(index, type, '.'),
      onClose: () => _handleClose(index, type),
    );
  }

  void _handleInput(int index, String type, String value) {
    setState(() {
      List<String> list = type == 'reps' ? _repetitions : _weights;
      if (index >= list.length) {
        list.addAll(List.filled(index - list.length + 1, '-'));
      }
      
      String current = list[index];
      
      if (_isFirstInput) {
        current = '';
        _isFirstInput = false;
      } else if (current == '-') {
        current = '';
      }
      
      if (value == '.' && current.contains('.')) return;
      
      list[index] = current + value;
      
      if (index < _effortStates.length) {
        _effortStates[index] = _EffortState.neutral;
      }
    });
  }

  void _handleBackspace(int index, String type) {
    setState(() {
      List<String> list = type == 'reps' ? _repetitions : _weights;
      if (index < list.length) {
        String current = list[index];
        if (current != '-' && current.isNotEmpty) {
          list[index] = current.substring(0, current.length - 1);
          if (list[index].isEmpty) list[index] = '-';
        }
      }
      
      if (index < _effortStates.length) {
        _effortStates[index] = _EffortState.neutral;
      }
    });
  }

  Future<void> _handleClose(int index, String type) async {
    setState(() {
      _activeRepsIndex = null;
      _activeWeightIndex = null;
    });

    // Notify parent of updates instead of saving to repository
    widget.onUpdate(_repetitions, _weights);
  }

  void _toggleSetCompletion(int index) {
    setState(() {
      _completedSets[index] = !_completedSets[index];
    });
  }

  Future<void> _launchVideoUrl() async {
    if (widget.row.videoUrl != null) {
      final uri = Uri.parse(widget.row.videoUrl!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final hasRest = widget.row.rest.isNotEmpty && widget.row.rest != '0';
    final hasNote = widget.row.note != null && widget.row.note!.isNotEmpty;
    final hasLink = widget.row.videoUrl != null && widget.row.videoUrl!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFD7D4DC), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              hasLink
                  ? GestureDetector(
                      onTap: _launchVideoUrl,
                      child: Text(
                        widget.row.exercise,
                        style: GoogleFonts.quicksand(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF7069FA),
                          decoration: TextDecoration.underline,
                          decorationColor: const Color(0xFF7069FA),
                        ),
                      ),
                    )
                  : Text(
                      widget.row.exercise,
                      style: GoogleFonts.quicksand(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF3A416F),
                      ),
                    ),
              Row(
                children: [
                  SvgPicture.asset(
                    hasRest ? 'assets/icons/timer_on.svg' : 'assets/icons/timer_off.svg',
                    width: 24,
                    height: 24,
                  ),
                  const SizedBox(width: 20),
                  SvgPicture.asset(
                    hasNote ? 'assets/icons/note_on.svg' : 'assets/icons/note_off.svg',
                    width: 24,
                    height: 24,
                  ),
                ],
              ),
            ],
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
              const SizedBox(width: 10),
              _GridHeader('Suivi', flex: 40),
            ],
          ),
          const SizedBox(height: 10),

          // Sets Rows
          ...List.generate(widget.row.series, (index) {
            final reps = index < _repetitions.length ? _repetitions[index] : '-';
            final weight = index < _weights.length ? _weights[index] : '-';
            final visuals = _visualsForState(_effortStates[index]);
            final isCompleted = _completedSets[index];

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
                    child: GestureDetector(
                      onTap: () => _activateCell(index, 'reps'),
                      child: Container(
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: visuals.backgroundColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _activeRepsIndex == index ? const Color(0xFF7069FA) : const Color(0xFFECE9F1),
                            width: _activeRepsIndex == index ? 2 : 1,
                          ),
                        ),
                        child: Text(
                          reps,
                          style: GoogleFonts.quicksand(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: visuals.textColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Weight
                  Expanded(
                    flex: 86,
                    child: GestureDetector(
                      onTap: () => _activateCell(index, 'weight'),
                      child: Container(
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: visuals.backgroundColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _activeWeightIndex == index ? const Color(0xFF7069FA) : const Color(0xFFECE9F1),
                            width: _activeWeightIndex == index ? 2 : 1,
                          ),
                        ),
                        child: Text(
                          weight,
                          style: GoogleFonts.quicksand(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: visuals.textColor,
                          ),
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
                          color: visuals.backgroundColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFECE9F1)),
                        ),
                        alignment: Alignment.center,
                        child: Image.asset(
                          visuals.iconPath,
                          width: 24,
                          height: 24,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Suivi (Completion)
                  Expanded(
                    flex: 40,
                    child: GestureDetector(
                      onTap: () => _toggleSetCompletion(index),
                      child: SvgPicture.asset(
                        isCompleted ? 'assets/icons/Suivi_vert.svg' : 'assets/icons/Suivi_gris.svg',
                        width: 24,
                        height: 24,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 5),

          // Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _ActionButton(
                label: 'Ignorer',
                icon: 'assets/icons/croix_small.svg',
                iconWidth: 12,
                iconHeight: 12,
                color: widget.isIgnored ? Colors.white : const Color(0xFFC2BFC6),
                backgroundColor: widget.isIgnored ? const Color(0xFFC2BFC6) : Colors.white,
                onTap: widget.onIgnore,
              ),
              _ActionButton(
                label: 'Déplacer',
                icon: 'assets/icons/arrow_small.svg',
                iconWidth: 12,
                iconHeight: 12,
                color: widget.isLast ? const Color(0xFFECE9F1) : const Color(0xFFC2BFC6),
                onTap: widget.isLast ? () {} : widget.onMoveDown,
              ),
              _ActionButton(
                label: 'Terminé',
                icon: 'assets/icons/check_small.svg',
                iconWidth: 12,
                iconHeight: 12,
                color: widget.isCompleted ? Colors.white : const Color(0xFF00D591),
                backgroundColor: widget.isCompleted ? const Color(0xFF00D591) : Colors.white,
                isPrimary: true,
                onTap: widget.onComplete,
              ),
            ],
          ),
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

  _EffortVisuals _visualsForState(_EffortState state) {
    switch (state) {
      case _EffortState.neutral:
        return const _EffortVisuals(
          backgroundColor: Colors.white,
          textColor: Color(0xFF3A416F),
          iconPath: 'assets/icons/smiley_jaune.png',
        );
      case _EffortState.positive:
        return const _EffortVisuals(
          backgroundColor: Color(0xFFF6FDF7),
          textColor: Color(0xFF57AE5B),
          iconPath: 'assets/icons/smiley_vert.png',
        );
      case _EffortState.negative:
        return const _EffortVisuals(
          backgroundColor: Color(0xFFFFF1F1),
          textColor: Color(0xFFEF4F4E),
          iconPath: 'assets/icons/smiley_rouge.png',
        );
    }
  }
}

class _FinishButton extends StatelessWidget {
  const _FinishButton({required this.onTap});

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
              const Icon(Icons.check, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Text(
                'J\'ai terminé !',
                style: GoogleFonts.quicksand(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _EffortState { neutral, positive, negative }

class _EffortVisuals {
  const _EffortVisuals({
    required this.backgroundColor,
    required this.textColor,
    required this.iconPath,
  });

  final Color backgroundColor;
  final Color textColor;
  final String iconPath;
}

class _GridHeader extends StatelessWidget {
  final String text;
  final int flex;

  const _GridHeader(this.text, {required this.flex});

  @override
  Widget build(BuildContext context) {
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
  }
}

class _ActionButton extends StatefulWidget {
  final String label;
  final String icon;
  final Color color;
  final Color backgroundColor;
  final bool isPrimary;
  final double iconWidth;
  final double iconHeight;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    this.backgroundColor = Colors.white,
    this.isPrimary = false,
    this.iconWidth = 16,
    this.iconHeight = 16,
    required this.onTap,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _isPressed = false;

  Future<void> _handleTap() async {
    HapticFeedback.lightImpact();

    setState(() => _isPressed = true);

    await Future.delayed(const Duration(milliseconds: 140));

    if (!mounted) return;

    widget.onTap();

    if (!mounted) return;

    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final overlayColor = Colors.black.withOpacity(0.05);
    final usePrimaryPressedStyle =
        widget.isPrimary && widget.backgroundColor == Colors.white && _isPressed;

    final backgroundColor = usePrimaryPressedStyle
        ? widget.color
        : (_isPressed
            ? Color.lerp(widget.backgroundColor, overlayColor, 0.35)!
            : widget.backgroundColor);

    final contentColor = usePrimaryPressedStyle ? Colors.white : widget.color;

    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 140),
        scale: _isPressed ? 0.97 : 1,
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: widget.isPrimary && backgroundColor == Colors.white
                  ? widget.color
                  : (!widget.isPrimary && backgroundColor == Colors.white
                      ? const Color(0xFFECE9F1)
                      : Colors.transparent),
            ),
            boxShadow: _isPressed
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Row(
            children: [
              SvgPicture.asset(
                widget.icon,
                width: widget.iconWidth,
                height: widget.iconHeight,
                colorFilter: ColorFilter.mode(contentColor, BlendMode.srcIn),
              ),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: GoogleFonts.quicksand(
                  color: contentColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

