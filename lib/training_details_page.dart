import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase/supabase.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/training.dart';
import '../models/training_row.dart';
import '../repositories/program_repository.dart';
import 'widgets/glift_loader.dart';
import 'widgets/glift_page_layout.dart';
import 'widgets/note_modal.dart';

import 'widgets/numeric_keypad.dart';
import 'active_training_page.dart';
import '../theme/glift_theme.dart';
import '../timer_page.dart';

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
  bool _isScrolling = false;
  Timer? _scrollEndTimer;

  // Keypad state
  int? _activeRowIndex;
  int? _activeSeriesIndex;
  String? _activeFieldType; // 'reps' or 'weight'

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

  void _onKeypadInput(String value) {
    if (_activeRowIndex == null || _activeSeriesIndex == null || _activeFieldType == null) return;
    // This will be handled by the _ExerciseCard via a callback or by lifting state up.
    // Given the structure, it's better to lift the active state to the page level 
    // OR pass the keypad events down to the active card.
    // Actually, since the keypad is at page level (in the Stack), the page needs to know which card is active.
    // But the data is inside _ExerciseCard (local state).
    // We need to refactor so _ExerciseCard exposes its state or accepts updates.
    // EASIER APPROACH: The Page holds the keypad, but the _ExerciseCard handles the tap and "registers" itself as the listener.
    // But the keypad is in the Page's build method.
    // Let's make the Page manage the active state and pass a callback to _ExerciseCard to "request focus".
    // When "focused", the Page shows the keypad. When keypad emits, Page calls a callback provided by the Card.
  }
  
  // New approach:
  // The Page manages the visibility of the keypad.
  // We pass a `onFocus` callback to `_ExerciseCard`.
  // When a cell is tapped, `_ExerciseCard` calls `onFocus` with a callback to handle input.
  
  ValueChanged<String>? _currentInputHandler;
  VoidCallback? _currentBackspaceHandler;
  VoidCallback? _currentDecimalHandler;
  VoidCallback? _currentCloseHandler;

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

  void _handleScrollNotification(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification) {
      final delta = notification.scrollDelta ?? 0;
      if (delta > 0 &&
          notification.metrics.extentBefore > 0 &&
          notification.metrics.extentAfter > 0) {
        if (!_isScrolling) {
          setState(() {
            _isScrolling = true;
          });
        }
      } else if (delta < 0 && _isScrolling) {
        setState(() {
          _isScrolling = false;
        });
      }
      _startInactivityTimer();
    } else if (notification is OverscrollNotification) {
      _startInactivityTimer();
      if (notification.overscroll < 0 && _isScrolling) {
        setState(() {
          _isScrolling = false;
        });
      }
    }

    if (notification is ScrollEndNotification ||
        (notification is UserScrollNotification &&
            notification.direction == ScrollDirection.idle)) {
      _startInactivityTimer();
    }
  }

  void _startInactivityTimer() {
    _scrollEndTimer?.cancel();
    _scrollEndTimer = Timer(const Duration(seconds: 2), () {
      if (mounted && _isScrolling) {
        setState(() {
          _isScrolling = false;
        });
      }
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

  Future<void> _openActiveTraining() async {
    final result = await Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => ActiveTrainingPage(
          training: widget.training,
          supabase: widget.supabase,
        ),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
        transitionsBuilder: (_, __, ___, child) => child,
      ),
    );

    if (result == true && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GliftPageLayout(
      resizeToAvoidBottomInset: false, // Prevent resize
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
          Expanded(
            child: Column(
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
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
      scrollable: false,
      padding: EdgeInsets.zero,
      child: Stack(
        children: [
          GestureDetector(
            onTap: _closeKeypad, // Close keypad on outside tap
            behavior: HitTestBehavior.translucent,
            child: _buildBody(),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 30, // Adjust as needed for safe area/padding
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                alignment:
                    _isScrolling ? Alignment.centerRight : Alignment.center,
                child: _StartButton(
                  onTap: _openActiveTraining,
                  isCollapsed: _isScrolling,
                ),
              ),
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

  @override
  void dispose() {
    _scrollEndTimer?.cancel();
    super.dispose();
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const GliftLoader();
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

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollUpdateNotification ||
            notification is OverscrollNotification ||
            notification is ScrollEndNotification ||
            notification is UserScrollNotification) {
          _handleScrollNotification(notification);
        }
        return false;
      },
      child: ListView.separated(
        padding:
            const EdgeInsets.fromLTRB(20, 20, 20, 100), // Bottom padding for button
        itemCount: _rows!.length,
        separatorBuilder: (context, index) => const SizedBox(height: 20),
        itemBuilder: (context, index) {
          final row = _rows![index];
          return _ExerciseCard(
            row: row,
            onFocus: _handleFocus,
            onUpdate: (reps, weights, efforts) =>
                _handleRowUpdate(index, reps, weights, efforts),
            onRestUpdate: (newDuration) => _handleRestUpdate(index, newDuration),
            onNoteUpdate: (note) => _handleNoteUpdate(index, note),
          );
        },
      ),
    );
  }

  Future<void> _handleRestUpdate(int index, int newDuration) async {
    if (_rows == null) return;

    setState(() {
      final oldRow = _rows![index];
      _rows![index] = TrainingRow(
        id: oldRow.id,
        trainingId: oldRow.trainingId,
        exercise: oldRow.exercise,
        series: oldRow.series,
        repetitions: oldRow.repetitions,
        weights: oldRow.weights,
        efforts: oldRow.efforts,
        rest: newDuration.toString(),
        note: oldRow.note,
        videoUrl: oldRow.videoUrl,
        order: oldRow.order,
      );
    });

    try {
      await _programRepository.updateRestDuration(_rows![index].id, newDuration);
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    }
  }

  Future<void> _handleRowUpdate(
    int index,
    List<String> repetitions,
    List<String> weights,
    List<String> efforts,
  ) async {
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
        efforts: efforts,
        rest: oldRow.rest,
        note: oldRow.note,
        videoUrl: oldRow.videoUrl,
        order: oldRow.order,
      );
    });

    try {
      await _programRepository.updateTrainingRow(
        _rows![index].id,
        repetitions: repetitions,
        weights: weights,
        efforts: efforts,
      );
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    }
  }

  Future<void> _handleNoteUpdate(int index, String note) async {
    if (_rows == null) return;

    setState(() {
      final oldRow = _rows![index];
      _rows![index] = TrainingRow(
        id: oldRow.id,
        trainingId: oldRow.trainingId,
        exercise: oldRow.exercise,
        series: oldRow.series,
        repetitions: oldRow.repetitions,
        weights: oldRow.weights,
        efforts: oldRow.efforts,
        rest: oldRow.rest,
        note: note,
        videoUrl: oldRow.videoUrl,
        order: oldRow.order,
      );
    });

    try {
      await _programRepository.updateTrainingRow(_rows![index].id, note: note);
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    }
  }
}

class _ExerciseCard extends StatefulWidget {
  const _ExerciseCard({
    required this.row,
    required this.onFocus,
    required this.onUpdate,
    required this.onRestUpdate,
    required this.onNoteUpdate,
  });

  final TrainingRow row;
  final Function({
    required ValueChanged<String> onInput,
    required VoidCallback onBackspace,
    required VoidCallback onDecimal,
    required VoidCallback onClose,
  }) onFocus;
  final Future<void> Function(List<String>, List<String>, List<String>) onUpdate;
  final Future<void> Function(int) onRestUpdate;
  final Future<void> Function(String) onNoteUpdate;

  @override
  State<_ExerciseCard> createState() => _ExerciseCardState();
}

class _ExerciseCardState extends State<_ExerciseCard> {
  late final List<_EffortState> _effortStates;
  late List<String> _repetitions;
  late List<String> _weights;
  
  // Track active cell for highlighting
  int? _activeRepsIndex;
  int? _activeWeightIndex;
  bool _isFirstInput = true;

  @override
  void initState() {
    super.initState();
    _effortStates = List<_EffortState>.generate(
      widget.row.series,
      (index) => index < widget.row.efforts.length
          ? _effortValueToState(widget.row.efforts[index])
          : _EffortState.neutral,
    );
    _repetitions = List<String>.from(widget.row.repetitions);
    _weights = List<String>.from(widget.row.weights);
  }

  _EffortState _effortValueToState(String? value) {
    switch (value) {
      case 'trop facile':
      case 'positive':
        return _EffortState.positive;
      case 'trop dur':
      case 'negative':
        return _EffortState.negative;
      default:
        return _EffortState.neutral;
    }
  }

  String _effortStateToValue(_EffortState state) {
    return switch (state) {
      _EffortState.neutral => 'parfait',
      _EffortState.positive => 'trop facile',
      _EffortState.negative => 'trop dur',
    };
  }

  List<String> _effortsAsStrings() =>
      _effortStates.map((state) => _effortStateToValue(state)).toList();

  void _activateCell(int index, String type) {
    setState(() {
      if (type == 'reps') {
        _activeRepsIndex = index;
        _activeWeightIndex = null;
      } else {
        _activeRepsIndex = null;
        _activeWeightIndex = index;
      }
      _isFirstInput = true; // Reset flag when activating a cell
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
        current = ''; // Clear on first input
        _isFirstInput = false;
      } else if (current == '-') {
        current = '';
      }
      
      // Prevent multiple decimals
      if (value == '.' && current.contains('.')) return;
      
      list[index] = current + value;
      
      // Reset smiley
      if (index < _effortStates.length) {
        _effortStates[index] = _EffortState.neutral;
      }
    });

    widget.onUpdate(_repetitions, _weights, _effortsAsStrings());
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
      
      // Reset smiley
      if (index < _effortStates.length) {
        _effortStates[index] = _EffortState.neutral;
      }
    });

    widget.onUpdate(_repetitions, _weights, _effortsAsStrings());
  }

  Future<void> _handleClose(int index, String type) async {
    setState(() {
      _activeRepsIndex = null;
      _activeWeightIndex = null;
    });

    await widget.onUpdate(_repetitions, _weights, _effortsAsStrings());
  }

  Future<void> _launchVideoUrl() async {
    if (widget.row.videoUrl == null || widget.row.videoUrl!.isEmpty) return;

    final uri = Uri.parse(widget.row.videoUrl!);

    final launchedInApp =
        await launchUrl(uri, mode: LaunchMode.inAppBrowserView);

    if (!launchedInApp) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showNoteModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => NoteModal(
        initialNote: widget.row.note,
        onSave: widget.onNoteUpdate,
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    final hasRest = widget.row.rest.isNotEmpty && widget.row.rest != '0';
    final hasNote = widget.row.note != null && widget.row.note!.isNotEmpty;
    final hasLink =
        widget.row.videoUrl != null && widget.row.videoUrl!.isNotEmpty;

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
                  GestureDetector(
                    onTap: () {
                      if (hasRest) {
                        final duration = int.tryParse(widget.row.rest) ?? 0;
                        if (duration > 0) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => TimerPage(
                                durationInSeconds: duration,
                                autoStart: false,
                                onSave: widget.onRestUpdate,
                              ),
                            ),
                          );
                        }
                      }
                    },
                    child: SvgPicture.asset(
                      hasRest
                          ? 'assets/icons/timer_on.svg'
                          : 'assets/icons/timer_off.svg',
                      width: 24,
                      height: 24,
                    ),
                  ),
                  const SizedBox(width: 20),
                  GestureDetector(
                    onTap: _showNoteModal,
                    child: SvgPicture.asset(
                      hasNote
                          ? 'assets/icons/note_on.svg'
                          : 'assets/icons/note_off.svg',
                      width: 24,
                      height: 24,
                    ),
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
            ],
          ),
          const SizedBox(height: 10),

          // Sets Rows
          ...List.generate(widget.row.series, (index) {
            final reps = index < _repetitions.length ? _repetitions[index] : '-';
            final weight = index < _weights.length ? _weights[index] : '-';
            final visuals = _visualsForState(_effortStates[index]);

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
                            color: _activeRepsIndex == index
                                ? const Color(0xFFA1A5FD)
                                : const Color(0xFFECE9F1),
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
                            color: _activeWeightIndex == index
                                ? const Color(0xFFA1A5FD)
                                : const Color(0xFFECE9F1),
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
                          color: Colors.white,
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
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Future<void> _cycleEffortState(int index) async {
    setState(() {
      _effortStates[index] = switch (_effortStates[index]) {
        _EffortState.neutral => _EffortState.positive,
        _EffortState.positive => _EffortState.negative,
        _EffortState.negative => _EffortState.neutral,
      };
    });

    await widget.onUpdate(_repetitions, _weights, _effortsAsStrings());
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

class _StartButton extends StatelessWidget {
  const _StartButton({
    required this.onTap,
    required this.isCollapsed,
  });

  final VoidCallback onTap;
  final bool isCollapsed;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: isCollapsed ? 48 : 200,
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFF00D591),
        borderRadius: BorderRadius.circular(isCollapsed ? 24 : 25),
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
          borderRadius: BorderRadius.circular(isCollapsed ? 24 : 25),
          child: ClipRect(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final showExpandedContent =
                    !isCollapsed && constraints.maxWidth >= 120;

                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: child,
                  ),
                  layoutBuilder: (currentChild, previousChildren) =>
                      currentChild ?? const SizedBox.shrink(),
                  child: showExpandedContent
                      ? Center(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              key: const ValueKey('expanded_button'),
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
                                SvgPicture.asset(
                                  'assets/icons/arrow.svg',
                                  width: 26,
                                  height: 26,
                                ),
                              ],
                            ),
                          ),
                        )
                      : Center(
                          child: SvgPicture.asset(
                            'assets/icons/arrow.svg',
                            key: const ValueKey('collapsed_arrow'),
                            width: 26,
                            height: 26,
                          ),
                        ),
                );
              },
            ),
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
