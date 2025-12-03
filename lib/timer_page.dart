import 'dart:async';
import 'package:flutter/material.dart';
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
    TimerAlertService? alertService,
    VibrationService? vibrationService,
  })  : alertService = alertService ?? NotificationService.instance,
        vibrationService = vibrationService ?? const DeviceVibrationService();

  final int durationInSeconds;
  final bool enableVibration;
  final bool enableSound;
  final TimerAlertService alertService;
  final VibrationService vibrationService;

  @override
  State<TimerPage> createState() => _TimerPageState();
}

class _TimerPageState extends State<TimerPage> {
  late int _initialDurationSeconds;
  late int _remainingSeconds;
  Timer? _timer;
  bool _isRunning = false;

  @override
  void initState() {
    super.initState();
    _initialDurationSeconds = widget.durationInSeconds;
    _remainingSeconds = widget.durationInSeconds;
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
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
      _remainingSeconds = _initialDurationSeconds;
    });
  }

  void _updateDuration(int seconds, {bool restart = false}) {
    _pauseTimer();
    setState(() {
      _initialDurationSeconds = seconds;
      _remainingSeconds = seconds;
      _isRunning = false;
    });

    if (restart) {
      _startTimer();
    }
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

  Future<void> _editDuration() async {
    final wasRunning = _isRunning;
    _pauseTimer();

    final minutesController = TextEditingController(
      text: (_remainingSeconds ~/ 60).toString(),
    );
    final secondsController = TextEditingController(
      text: (_remainingSeconds % 60).toString(),
    );

    final newDuration = await showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Modifier la durée'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: minutesController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Minutes',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: secondsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Secondes',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                final minutes = int.tryParse(minutesController.text) ?? 0;
                final seconds = int.tryParse(secondsController.text) ?? 0;
                final clampedSeconds = seconds.clamp(0, 59).toInt();
                final newDurationSeconds = minutes * 60 + clampedSeconds;

                Navigator.of(context).pop(newDurationSeconds > 0
                    ? newDurationSeconds
                    : _initialDurationSeconds);
              },
              child: const Text('Enregistrer'),
            ),
          ],
        );
      },
    );

    if (newDuration != null) {
      _updateDuration(newDuration, restart: wasRunning);
    } else if (wasRunning) {
      _startTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
    final minutes = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_remainingSeconds % 60).toString().padLeft(2, '0');

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Stack(
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
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    SizedBox(
                      width: 100,
                      child: _TimeDigit(value: minutes, label: 'Minutes'),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 0),
                      child: SizedBox(
                        width: 20,
                        child: Text(
                          ':',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.redHatText(
                            fontSize: 80,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF3A416F),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 100,
                      child: _TimeDigit(value: seconds, label: 'Secondes'),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: _editDuration,
                  icon: const Icon(Icons.edit_outlined, color: Color(0xFF3A416F)),
                  label: Text(
                    'Modifier',
                    style: GoogleFonts.quicksand(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF3A416F),
                    ),
                  ),
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
        ],
      ),
    );
  }
}

class _TimeDigit extends StatelessWidget {
  const _TimeDigit({
    required this.value,
    required this.label,
  });

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 90,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              for (final digit in value.split(''))
                SizedBox(
                  width: 45,
                  child: _SlidingDigit(digit: digit),
                ),
            ],
          ),
        ),
        const SizedBox(height: 5), // Reduced spacing from 10px to 5px
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

class _SlidingDigit extends StatelessWidget {
  const _SlidingDigit({required this.digit});

  final String digit;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) {
        final incomingSlide = Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(animation);

        final outgoingSlide = Tween<Offset>(
          begin: Offset.zero,
          end: const Offset(0, -1),
        ).animate(ReverseAnimation(animation));

        final slideAnimation = animation.status == AnimationStatus.forward ||
                animation.status == AnimationStatus.completed
            ? incomingSlide
            : outgoingSlide;

        return ClipRect(
          child: SlideTransition(
            position: slideAnimation,
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          ),
        );
      },
      child: Text(
        digit,
        key: ValueKey(digit),
        textAlign: TextAlign.center,
        style: GoogleFonts.quicksand(
          fontSize: 80,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF3A416F),
          height: 1.0, // Reduce line height to minimize default padding
        ),
      ),
    );
  }
}
