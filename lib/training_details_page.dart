import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase/supabase.dart';
import '../models/training.dart';
import '../models/training_row.dart';
import '../repositories/program_repository.dart';
import 'widgets/glift_page_layout.dart';

import 'widgets/numeric_keypad.dart';
import 'active_training_page.dart';
import '../theme/glift_theme.dart';

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
      if (delta > 0) {
        _scrollEndTimer?.cancel();
        if (!_isScrolling) {
          setState(() {
            _isScrolling = true;
          });
        }

        _scrollEndTimer = Timer(const Duration(milliseconds: 200), () {
          if (mounted) {
            setState(() {
              _isScrolling = false;
            });
          }
        });
      } else if (delta < 0 && _isScrolling) {
        _scrollEndTimer?.cancel();
        setState(() {
          _isScrolling = false;
        });
      }
    } else if (notification is OverscrollNotification) {
      _scrollEndTimer?.cancel();
      if (notification.overscroll > 0) {
        if (!_isScrolling) {
          setState(() {
            _isScrolling = true;
          });
        }

        _scrollEndTimer = Timer(const Duration(milliseconds: 200), () {
          if (mounted) {
            setState(() {
              _isScrolling = false;
            });
          }
        });
      } else if (notification.overscroll < 0 && _isScrolling) {
        setState(() {
          _isScrolling = false;
        });
      }
    }

    if (notification is ScrollEndNotification ||
        (notification is UserScrollNotification &&
            notification.direction == ScrollDirection.idle)) {
      _scrollEndTimer?.cancel();
      if (_isScrolling) {
        setState(() {
          _isScrolling = false;
        });
      }
    }
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
            child: Center(
              child: _StartButton(
                onTap: _openActiveTraining,
                isCollapsed: _isScrolling,
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
            repository: _programRepository,
            onFocus: _handleFocus,
          );
        },
      ),
    );
  }
}

class _ExerciseCard extends StatefulWidget {
  const _ExerciseCard({
    required this.row,
    required this.repository,
    required this.onFocus,
  });

  final TrainingRow row;
  final ProgramRepository repository;
  final Function({
    required ValueChanged<String> onInput,
    required VoidCallback onBackspace,
    required VoidCallback onDecimal,
    required VoidCallback onClose,
  }) onFocus;

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
    _effortStates = List<_EffortState>.filled(widget.row.series, _EffortState.neutral);
    _repetitions = List<String>.from(widget.row.repetitions);
    _weights = List<String>.from(widget.row.weights);
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
  }

  Future<void> _handleClose(int index, String type) async {
    setState(() {
      _activeRepsIndex = null;
      _activeWeightIndex = null;
    });

    // Save to DB
    if (type == 'reps') {
      await widget.repository.updateTrainingRow(
        widget.row.id,
        repetitions: _repetitions,
      );
    } else {
      await widget.repository.updateTrainingRow(
        widget.row.id,
        weights: _weights,
      );
    }
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
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SizeTransition(
                  sizeFactor: animation,
                  axis: Axis.horizontal,
                  child: child,
                ),
              ),
              child: isCollapsed
                  ? const Icon(
                      Icons.arrow_forward,
                      key: ValueKey('collapsed_arrow'),
                      color: Colors.white,
                      size: 16,
                    )
                  : Center(
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
                          const Icon(Icons.arrow_forward,
                              color: Colors.white, size: 16),
                        ],
                      ),
                    ),
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
