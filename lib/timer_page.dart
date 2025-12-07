import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:glift_mobile/services/notification_service.dart';
import 'package:glift_mobile/services/vibration_service.dart';

class TimerPage extends StatefulWidget {
  TimerPage({
    super.key,
    required this.durationInSeconds,
    this.enableVibration = true,
    this.enableSound = true,
    this.autoStart = true,
    this.isActiveTraining = false,
    this.onSave,
    TimerAlertService? alertService,
    VibrationService? vibrationService,
  })  : alertService = alertService ?? NotificationService.instance,
        vibrationService = vibrationService ?? const DeviceVibrationService();

  final int durationInSeconds;
  final bool enableVibration;
  final bool enableSound;
  final bool autoStart;
  final bool isActiveTraining;
  final Future<void> Function(int)? onSave;
  final TimerAlertService alertService;
  final VibrationService vibrationService;

  @override
  State<TimerPage> createState() => _TimerPageState();
}

class _TimerPageState extends State<TimerPage> {
  late int _remainingSeconds;
  Timer? _timer;
  bool _isRunning = false;
  bool _wasRunningBeforeEdit = false;
  bool _isModified = false;
  bool _isSaving = false;
  late int _lastEditedDuration;
  late int _savedDuration;
  bool _isInlineMode = false;
  Offset? _inlinePosition;

  late final TextEditingController _minutesController;
  late final TextEditingController _secondsController;
  late final FocusNode _minutesFocusNode;
  late final FocusNode _secondsFocusNode;
  bool _isEditingMinutes = false;
  bool _isEditingSeconds = false;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.durationInSeconds;
    _lastEditedDuration = widget.durationInSeconds;
    _savedDuration = widget.durationInSeconds;
    _minutesController = TextEditingController();
    _secondsController = TextEditingController();
    _minutesController.addListener(_handleMinutesTextChange);
    _secondsController.addListener(_handleSecondsTextChange);
    _minutesFocusNode = FocusNode();
    _secondsFocusNode = FocusNode();
    _minutesFocusNode.addListener(_handleMinutesFocusChange);
    _secondsFocusNode.addListener(_handleSecondsFocusChange);
    if (widget.autoStart) {
      _startTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _minutesController.removeListener(_handleMinutesTextChange);
    _secondsController.removeListener(_handleSecondsTextChange);
    _minutesController.dispose();
    _secondsController.dispose();
    _minutesFocusNode.dispose();
    _secondsFocusNode.dispose();
    super.dispose();
  }

  void _startTimer() {
    if (_timer != null) return;
    
    setState(() {
      _isRunning = true;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        timer.cancel();
        _timer = null;
        _onTimerCompleted();
      }
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    _timer = null;
    setState(() {
      _isRunning = false;
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
    setState(() {
      _isRunning = false;
      _remainingSeconds = widget.durationInSeconds;
    });
  }

  Future<void> _onTimerCompleted() async {
    if (widget.enableVibration) {
      final hasVibrator = await widget.vibrationService.hasVibrator();
      if (hasVibrator) {
        await widget.vibrationService.vibrate();
      } else {
        await widget.vibrationService.fallback();
      }
    }

    if (widget.enableSound) {
      await widget.alertService.playSound();
    }

    _stopTimer();
  }

  String _formatTime(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes : $seconds';
  }

  void _enterMinutesEdit() {
    // Save any pending seconds changes first
    if (_isEditingSeconds) {
      _finishSecondsEdit();
    }
    _pauseTimerForEdit();
    _minutesController.text = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    setState(() {
      _isEditingMinutes = true;
      _isEditingSeconds = false;
    });
    _minutesFocusNode.requestFocus();
  }

  void _enterSecondsEdit() {
    // Save any pending minutes changes first
    if (_isEditingMinutes) {
      _finishMinutesEdit();
    }
    _pauseTimerForEdit();
    _secondsController.text = (_remainingSeconds % 60).toString().padLeft(2, '0');
    setState(() {
      _isEditingSeconds = true;
      _isEditingMinutes = false;
    });
    _secondsFocusNode.requestFocus();
  }

  void _pauseTimerForEdit() {
    _wasRunningBeforeEdit = _isRunning;
    _pauseTimer();
  }

  void _handleMinutesFocusChange() {
    if (!_minutesFocusNode.hasFocus && _isEditingMinutes) {
      _finishMinutesEdit();
    }
  }

  void _handleSecondsFocusChange() {
    if (!_secondsFocusNode.hasFocus && _isEditingSeconds) {
      _finishSecondsEdit();
    }
  }

  int _clampInt(int value, int min, int max) {
    if (value < min) return min;
    if (value > max) return max;
    return value;
  }

  int _computePendingDuration({int? minutesOverride, int? secondsOverride}) {
    final minutes = _clampInt(minutesOverride ?? (_remainingSeconds ~/ 60), 0, 99);
    final seconds = _clampInt(secondsOverride ?? (_remainingSeconds % 60), 0, 59);
    return minutes * 60 + seconds;
  }

  void _handleMinutesTextChange() {
    if (!_isEditingMinutes) return;

    final pendingMinutes = int.tryParse(_minutesController.text) ?? 0;
    final pendingDuration = _computePendingDuration(minutesOverride: pendingMinutes);

    setState(() {
      _lastEditedDuration = pendingDuration;
      _isModified = _lastEditedDuration != _savedDuration;
    });
  }

  void _handleSecondsTextChange() {
    if (!_isEditingSeconds) return;

    final pendingSeconds = int.tryParse(_secondsController.text) ?? 0;
    final pendingDuration = _computePendingDuration(secondsOverride: pendingSeconds);

    setState(() {
      _lastEditedDuration = pendingDuration;
      _isModified = _lastEditedDuration != _savedDuration;
    });
  }

  void _finishMinutesEdit() {
    final pendingDuration =
        _computePendingDuration(minutesOverride: int.tryParse(_minutesController.text) ?? 0);
    setState(() {
      _remainingSeconds = pendingDuration;
      _isEditingMinutes = false;
      _lastEditedDuration = pendingDuration;
      _isModified = _lastEditedDuration != _savedDuration;
    });
    _restartIfNeeded();
  }

  void _finishSecondsEdit() {
    final pendingDuration =
        _computePendingDuration(secondsOverride: int.tryParse(_secondsController.text) ?? 0);
    setState(() {
      _remainingSeconds = pendingDuration;
      _isEditingSeconds = false;
      _lastEditedDuration = pendingDuration;
      _isModified = _lastEditedDuration != _savedDuration;
    });
    _restartIfNeeded();
  }

  void _restartIfNeeded() {
    if (_wasRunningBeforeEdit) {
      _startTimer();
    }
    _wasRunningBeforeEdit = false;
  }

  void _enterInlineMode() {
    final mediaQuery = MediaQuery.of(context);
    const inlineSize = Size(353, 142);
    final left = (mediaQuery.size.width - inlineSize.width) / 2;
    final top = (mediaQuery.size.height - inlineSize.height - mediaQuery.padding.bottom) - 40;

    if (_isEditingMinutes) {
      _finishMinutesEdit();
    } else if (_isEditingSeconds) {
      _finishSecondsEdit();
    } else {
      _handleOutsideTap();
    }

    setState(() {
      _inlinePosition = Offset(left, top.clamp(mediaQuery.padding.top, mediaQuery.size.height));
      _isInlineMode = true;
    });
  }

  void _exitInlineMode() {
    setState(() {
      _isInlineMode = false;
    });
  }

  void _updateInlinePosition(Offset delta) {
    final mediaQuery = MediaQuery.of(context);
    const inlineSize = Size(353, 142);

    final current = _inlinePosition ?? Offset.zero;
    final tentative = current + delta;

    final minX = 0.0;
    final maxX = mediaQuery.size.width - inlineSize.width;
    final minY = mediaQuery.padding.top;
    final maxY = mediaQuery.size.height - inlineSize.height - mediaQuery.padding.bottom;

    setState(() {
      _inlinePosition = Offset(
        tentative.dx.clamp(minX, maxX),
        tentative.dy.clamp(minY, maxY),
      );
    });
  }

  void _handleOutsideTap() {
    if (_isEditingMinutes || _isEditingSeconds) {
      FocusScope.of(context).unfocus();
    }
  }

  Future<void> _handleSave() async {
    if (widget.onSave == null) return;
    
    // Finish any pending edits before saving
    if (_isEditingMinutes) {
      _finishMinutesEdit();
    }
    if (_isEditingSeconds) {
      _finishSecondsEdit();
    }
    
    // Unfocus to close keyboard
    FocusScope.of(context).unfocus();
    
    setState(() => _isSaving = true);
    try {
      await widget.onSave!(_lastEditedDuration);
      if (mounted) {
        setState(() {
          _isSaving = false;
          _savedDuration = _lastEditedDuration;
          _isModified = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final minutes = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_remainingSeconds % 60).toString().padLeft(2, '0');

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _handleOutsideTap,
        child: Stack(
          children: [
            // Close Button
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              right: 20,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: SvgPicture.asset(
                  'assets/icons/close.svg',
                  width: 30,
                  height: 30,
                ),
              ),
            ),

            // Screen Icon (Active Training Only)
            if (widget.isActiveTraining)
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                left: 20,
                child: GestureDetector(
                  onTap: _isInlineMode ? _exitInlineMode : _enterInlineMode,
                  child: SvgPicture.asset(
                    _isInlineMode
                        ? 'assets/icons/screen_big.svg'
                        : 'assets/icons/screen_small.svg',
                    width: 30,
                    height: 30,
                    colorFilter: const ColorFilter.mode(
                      Color(0xFF7069FA),
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),

            if (!_isInlineMode) ...[
              // Main Content
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Timer Display
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 140,
                          child: _EditableTimeValue(
                            value: minutes,
                            label: 'Minutes',
                            isEditing: _isEditingMinutes,
                            controller: _minutesController,
                            focusNode: _minutesFocusNode,
                            onTap: _enterMinutesEdit,
                            maxLength: 2,
                          ),
                        ),
                        Container(
                          width: 20,
                          height: 90,
                          alignment: Alignment.center,
                          child: Text(
                            ':',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.redHatText(
                              fontSize: 80,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF3A416F),
                              height: 1.0,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 140,
                          child: _EditableTimeValue(
                            value: seconds,
                            label: 'Secondes',
                            isEditing: _isEditingSeconds,
                            controller: _secondsController,
                            focusNode: _secondsFocusNode,
                            onTap: _enterSecondsEdit,
                            maxLength: 2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 25),

                    // Controls
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Pause Button (Left)
                        GestureDetector(
                          onTap: _isRunning ? _pauseTimer : null,
                          child: SizedBox(
                            width: 50,
                            height: 50,
                            child: SvgPicture.asset(
                              'assets/icons/pause.svg',
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),

                        // Play/Stop Button (Right)
                        GestureDetector(
                          onTap: _isRunning ? _stopTimer : _startTimer,
                          child: SizedBox(
                            width: 50,
                            height: 50,
                            child: SvgPicture.asset(
                              _isRunning ? 'assets/icons/stop.svg' : 'assets/icons/play.svg',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Save Button
              if (widget.onSave != null)
                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: SafeArea(
                    child: GestureDetector(
                      onTap: _isModified && !_isSaving ? _handleSave : null,
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: _isModified
                              ? const Color(0xFF7069FA)
                              : const Color(0xFFECE9F1),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        alignment: Alignment.center,
                        child: _isSaving
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                'Sauvegarder ce temps de repos',
                                style: GoogleFonts.quicksand(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: _isModified
                                      ? Colors.white
                                      : const Color(0xFFC2BFC6),
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
            ] else if (_inlinePosition != null) ...[
              Positioned(
                left: _inlinePosition!.dx,
                top: _inlinePosition!.dy,
                child: GestureDetector(
                  onPanUpdate: (details) => _updateInlinePosition(details.delta),
                  child: _InlineTimer(
                    minutes: minutes,
                    seconds: seconds,
                    isRunning: _isRunning,
                    onToggleScreen: _exitInlineMode,
                    onPause: _isRunning ? _pauseTimer : null,
                    onPlayOrStop: _isRunning ? _stopTimer : _startTimer,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EditableTimeValue extends StatelessWidget {
  const _EditableTimeValue({
    required this.value,
    required this.label,
    required this.isEditing,
    required this.controller,
    required this.focusNode,
    required this.onTap,
    required this.maxLength,
  });

  final String value;
  final String label;
  final bool isEditing;
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onTap;
  final int maxLength;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: SizedBox(
            height: 90,
            child: isEditing
                ? Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFA1A5FD),
                        width: 2,
                      ),
                    ),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: TextField(
                      controller: controller,
                      focusNode: focusNode,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(maxLength),
                      ],
                      textAlign: TextAlign.center,
                      style: GoogleFonts.quicksand(
                        fontSize: 80,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF3A416F),
                        height: 1.0,
                      ),
                      decoration: const InputDecoration(
                        isCollapsed: true,
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  )
                : Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.transparent,
                        width: 2,
                      ),
                    ),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      value,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.quicksand(
                        fontSize: 80,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF3A416F),
                        height: 1.0,
                      ),
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.quicksand(
            fontSize: 16,
            color: const Color(0xFFC2BFC6),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _InlineTimer extends StatelessWidget {
  const _InlineTimer({
    required this.minutes,
    required this.seconds,
    required this.isRunning,
    required this.onToggleScreen,
    required this.onPause,
    required this.onPlayOrStop,
  });

  final String minutes;
  final String seconds;
  final bool isRunning;
  final VoidCallback onToggleScreen;
  final VoidCallback? onPause;
  final VoidCallback onPlayOrStop;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 353,
      height: 142,
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          side: const BorderSide(
            width: 1,
            color: Color(0xFFECE9F1),
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        shadows: const [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Row(
          children: [
            GestureDetector(
              onTap: onToggleScreen,
              child: SvgPicture.asset(
                'assets/icons/screen_big.svg',
                width: 30,
                height: 30,
                colorFilter: const ColorFilter.mode(
                  Color(0xFF7069FA),
                  BlendMode.srcIn,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    minutes,
                    style: GoogleFonts.quicksand(
                      color: const Color(0xFF3A416F),
                      fontSize: 60,
                      fontWeight: FontWeight.w600,
                      height: 1.0,
                    ),
                  ),
                  Text(
                    ':',
                    style: GoogleFonts.redHatText(
                      color: const Color(0xFF3A416F),
                      fontSize: 60,
                      fontWeight: FontWeight.w500,
                      height: 1.0,
                    ),
                  ),
                  Text(
                    seconds,
                    style: GoogleFonts.quicksand(
                      color: const Color(0xFF3A416F),
                      fontSize: 60,
                      fontWeight: FontWeight.w600,
                      height: 1.0,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            GestureDetector(
              onTap: onPause,
              child: Container(
                width: 38,
                height: 38,
                decoration: const ShapeDecoration(
                  color: Color(0xFFECE9F1),
                  shape: OvalBorder(),
                ),
                child: Center(
                  child: _PauseGlyph(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: onPlayOrStop,
              child: Container(
                width: 38,
                height: 38,
                decoration: ShapeDecoration(
                  color: _playColor,
                  shape: const OvalBorder(),
                ),
                child: Center(
                  child: _InlinePlayIcon(isRunning: isRunning),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color get _playColor => const Color(0xFF00D591);
}

class _PauseGlyph extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 3.12,
          height: 12.16,
          decoration: BoxDecoration(
            color: const Color(0xFFD7D4DC),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Container(
          width: 3.12,
          height: 12.16,
          decoration: BoxDecoration(
            color: const Color(0xFFD7D4DC),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }
}

class _InlinePlayIcon extends StatelessWidget {
  const _InlinePlayIcon({required this.isRunning});

  final bool isRunning;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: SvgPicture.asset(
        isRunning ? 'assets/icons/stop.svg' : 'assets/icons/play.svg',
        colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
      ),
    );
  }
}
