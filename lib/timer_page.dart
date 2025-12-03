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
    this.onSave,
    TimerAlertService? alertService,
    VibrationService? vibrationService,
  })  : alertService = alertService ?? NotificationService.instance,
        vibrationService = vibrationService ?? const DeviceVibrationService();

  final int durationInSeconds;
  final bool enableVibration;
  final bool enableSound;
  final bool autoStart;
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
    _minutesController = TextEditingController();
    _secondsController = TextEditingController();
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

  void _finishMinutesEdit() {
    final newMinutes = (int.tryParse(_minutesController.text) ?? 0).clamp(0, 99);
    final seconds = _remainingSeconds % 60;
    setState(() {
      _remainingSeconds = newMinutes * 60 + seconds;
      _isEditingMinutes = false;
      _isModified = true;
      _lastEditedDuration = _remainingSeconds;
    });
    _restartIfNeeded();
  }

  void _finishSecondsEdit() {
    final newSeconds = (int.tryParse(_secondsController.text) ?? 0).clamp(0, 59);
    final minutes = _remainingSeconds ~/ 60;
    setState(() {
      _remainingSeconds = minutes * 60 + newSeconds;
      _isEditingSeconds = false;
      _isModified = true;
      _lastEditedDuration = _remainingSeconds;
    });
    _restartIfNeeded();
  }

  void _restartIfNeeded() {
    if (_wasRunningBeforeEdit) {
      _startTimer();
    }
    _wasRunningBeforeEdit = false;
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
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(8),
                    child: SvgPicture.asset(
                      'assets/icons/croix_small.svg',
                      colorFilter: const ColorFilter.mode(
                        Color(0xFFC2BFC6),
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
              ),

          
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
