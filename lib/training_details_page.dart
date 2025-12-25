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
import 'widgets/glift_pull_to_refresh.dart';
import 'widgets/note_modal.dart';
import 'widgets/superset_group_card.dart';
import 'widgets/numeric_keypad.dart';
import 'active_training_page.dart';
import '../theme/glift_theme.dart';
import '../timer_page.dart';
import '../services/settings_service.dart';

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

  ValueChanged<String>? _currentInputHandler;
  VoidCallback? _currentBackspaceHandler;
  VoidCallback? _currentDecimalHandler;
  VoidCallback? _currentCloseHandler;

  void _handleFocus({
    required ValueChanged<String> onInput,
    required VoidCallback onBackspace,
    required VoidCallback onDecimal,
    required VoidCallback onClose,
    required BuildContext focusContext,
  }) {
    setState(() {
      _currentInputHandler = onInput;
      _currentBackspaceHandler = onBackspace;
      _currentDecimalHandler = onDecimal;
      _currentCloseHandler = onClose;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollIntoView(focusContext);
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
                  'Entraînement',
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

    final items = <Widget>[];
    int i = 0;
    while (i < _rows!.length) {
      final row = _rows![i];
      if (row.supersetId != null) {
        final group = <TrainingRow>[row];
        int j = i + 1;
        while (j < _rows!.length && _rows![j].supersetId == row.supersetId) {
          group.add(_rows![j]);
          j++;
        }

        items.add(_SupersetGroupContainer(
          children: group.map((r) {
            final rIndex = _rows!.indexOf(r);
            return _ExerciseCard(
              key: ValueKey(r.id), // Add key for efficient updates
              row: r,
              onFocus: _handleFocus,
              onUpdate: (reps, weights, efforts) =>
                  _handleRowUpdate(rIndex, reps, weights, efforts),
              onRestUpdate: (newDuration) => _handleRestUpdate(rIndex, newDuration),
              onNoteUpdate: (note) => _handleNoteUpdate(rIndex, note),
              onMaterialUpdate: (material) => _handleMaterialUpdate(rIndex, material),
              showDecoration: false,
              showTimer: group.indexOf(r) == 0,
            );
          }).toList(),
        ));
        i = j;
      } else {
        final rowIndex = i;
        items.add(_ExerciseCard(
          key: ValueKey(row.id),
          row: row,
          onFocus: _handleFocus,
          onUpdate: (reps, weights, efforts) =>
              _handleRowUpdate(rowIndex, reps, weights, efforts),
          onRestUpdate: (newDuration) =>
              _handleRestUpdate(rowIndex, newDuration),
          onNoteUpdate: (note) => _handleNoteUpdate(rowIndex, note),
          onMaterialUpdate: (material) =>
              _handleMaterialUpdate(rowIndex, material),
          showDecoration: true,
          showTimer: true,
        ));
        i++;
      }
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
      child: GliftPullToRefresh(
        onRefresh: _fetchDetails,
        child: ListView.separated(
          padding: EdgeInsets.fromLTRB(
              20, 20, 20, _currentInputHandler != null ? 360 : 100),
          itemCount: items.length,
          separatorBuilder: (context, index) => const SizedBox(height: 20),
          itemBuilder: (context, index) => items[index],
        ),
      ),
    );
  }

  void _scrollIntoView(BuildContext focusContext) {
    final controller = PrimaryScrollController.of(context);
    if (controller == null || !controller.hasClients) return;

    final renderObject = focusContext.findRenderObject();
    if (renderObject is! RenderBox) return;

    final objectOffset = renderObject.localToGlobal(Offset.zero);
    final objectHeight = renderObject.size.height;
    const keypadHeight = 320.0; // Approximate height of the custom numeric keypad

    final screenHeight = MediaQuery.of(context).size.height;
    final availableHeight = screenHeight - keypadHeight - 40; // Extra space for safety
    final objectBottom = objectOffset.dy + objectHeight;

    if (objectBottom > availableHeight) {
      final scrollAmount = objectBottom - availableHeight;
      final targetOffset = (controller.offset + scrollAmount)
          .clamp(controller.position.minScrollExtent, controller.position.maxScrollExtent)
          as double;

      controller.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    }
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
        material: oldRow.material,
        videoUrl: oldRow.videoUrl,
        order: oldRow.order,
        supersetId: oldRow.supersetId,
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
    if (_rows == null || index < 0 || index >= _rows!.length) return;

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
        material: oldRow.material,
        videoUrl: oldRow.videoUrl,
        order: oldRow.order,
        supersetId: oldRow.supersetId,
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
      debugPrint('Error updating rest: $e');
    }
  }

  Future<void> _handleMaterialUpdate(int index, String material) async {
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
        note: oldRow.note,
        material: material,
        videoUrl: oldRow.videoUrl,
        order: oldRow.order,
        supersetId: oldRow.supersetId,
      );
    });

    try {
      await _programRepository.updateTrainingRow(
        _rows![index].id,
        material: material,
      );
    } catch (e) {
      debugPrint('Error updating material: $e');
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
        material: oldRow.material,
        videoUrl: oldRow.videoUrl,
        order: oldRow.order,
        supersetId: oldRow.supersetId,
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
    super.key,
    required this.row,
    required this.onFocus,
    required this.onUpdate,
    required this.onRestUpdate,
    required this.onNoteUpdate,
    required this.onMaterialUpdate,
    this.showDecoration = true,
    this.showTimer = true,
  });

  final TrainingRow row;
  final Function({
    required ValueChanged<String> onInput,
    required VoidCallback onBackspace,
    required VoidCallback onDecimal,
    required VoidCallback onClose,
    required BuildContext focusContext,
  }) onFocus;
  final Future<void> Function(List<String>, List<String>, List<String>) onUpdate;
  final Future<void> Function(int) onRestUpdate;
  final Future<void> Function(String) onNoteUpdate;
  final Future<void> Function(String) onMaterialUpdate;
  final bool showDecoration;
  final bool showTimer;

  @override
  State<_ExerciseCard> createState() => _ExerciseCardState();
}

class _ExerciseCardState extends State<_ExerciseCard>
    with AutomaticKeepAliveClientMixin<_ExerciseCard> {
  @override
  bool get wantKeepAlive => true;

  late List<_EffortState> _effortStates;
  late List<String> _repetitions;
  late List<String> _weights;
  
  // Track active cell for highlighting
  int? _activeRepsIndex;
  int? _activeWeightIndex;
  bool _isFirstInput = true;

  @override
  void initState() {
    super.initState();
    _initializeState();
  }

  @override
  void didUpdateWidget(covariant _ExerciseCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.row != oldWidget.row) {
      _initializeState();
    }
  }

  void _initializeState() {
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

  void _activateCell(BuildContext focusContext, int index, String type) {
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
      focusContext: focusContext,
    );
  }

  void _handleInput(int index, String type, String value) async {
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

    try {
      await widget.onUpdate(_repetitions, _weights, _effortsAsStrings());
    } catch (e) {
      debugPrint('Error saving input: $e');
    }
  }

  void _handleBackspace(int index, String type) async {
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

    try {
      await widget.onUpdate(_repetitions, _weights, _effortsAsStrings());
    } catch (e) {
      debugPrint('Error saving backspace: $e');
    }
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
      barrierColor: GliftTheme.barrierColor,
      builder: (context) => NoteModal(
        initialNote: widget.row.note,
        initialMaterial: widget.row.material,
        onSave: widget.onNoteUpdate,
        onSaveMaterial: widget.onMaterialUpdate,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final hasRest = widget.row.rest.isNotEmpty && widget.row.rest != '0';
    final hasNote = widget.row.note != null && widget.row.note!.isNotEmpty;
    final hasLink =
        widget.row.videoUrl != null && widget.row.videoUrl!.isNotEmpty;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: hasLink
                  ? GestureDetector(
                      onTap: _launchVideoUrl,
                      child: Text(
                        widget.row.exercise,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.quicksand(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF3A416F),
                      ),
                    ),
            ),
            const SizedBox(width: 20),
            Row(
              children: [
                if (widget.showTimer) ...[
                  GestureDetector(
                    onTap: () {
                      final duration = int.tryParse(widget.row.rest) ?? 0;
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => TimerPage(
                            durationInSeconds: duration,
                            autoStart: false,
                            enableVibration: SettingsService.instance.getVibrationEnabled(),
                            enableSound: SettingsService.instance.getSoundEnabled(),
                            onSave: widget.onRestUpdate,
                          ),
                        ),
                      );
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
                ],
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
        Row(
          children: [
            const _GridHeader('Sets', flex: 40),
            const SizedBox(width: 10),
            const _GridHeader('Reps.', flex: 86),
            const SizedBox(width: 10),
            const _GridHeader('Poids', flex: 86),
            const SizedBox(width: 10),
            const _GridHeader('Effort', flex: 68),
          ],
        ),
        const SizedBox(height: 10),
        ...List.generate(widget.row.series, (index) {
          final reps = index < _repetitions.length ? _repetitions[index] : '-';
          final weight = index < _weights.length ? _weights[index] : '-';
          final visuals = _visualsForState(_effortStates[index]);

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
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
                Expanded(
                  flex: 86,
                  child: GestureDetector(
                    onTap: () => _activateCell(context, index, 'reps'),
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
                Expanded(
                  flex: 86,
                  child: GestureDetector(
                    onTap: () => _activateCell(context, index, 'weight'),
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
                Expanded(
                  flex: 68,
                  child: GestureDetector(
                    onTap: () => _cycleEffortState(index),
                    child: Container(
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: visuals.backgroundColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFFECE9F1),
                          width: 1,
                        ),
                      ),
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
    );

    if (widget.showDecoration) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: const Color(0xFFD7D4DC), width: 1),
        ),
        child: content,
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: content,
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

class _SupersetGroupContainer extends StatelessWidget {
  final List<Widget> children;

  const _SupersetGroupContainer({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: CustomPaint(
        foregroundPainter: DashedBorderPainter(color: const Color(0xFF7069FA)),
        child: Column(
          children: children,
        ),
      ),
    );
  }
}
