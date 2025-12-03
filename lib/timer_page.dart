import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

class TimerPage extends StatefulWidget {
  const TimerPage({
    super.key,
    required this.durationInSeconds,
  });

  final int durationInSeconds;

  @override
  State<TimerPage> createState() => _TimerPageState();
}

class _TimerPageState extends State<TimerPage> {
  late int _remainingSeconds;
  Timer? _timer;
  bool _isRunning = false;

  @override
  void initState() {
    super.initState();
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
        _stopTimer();
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

  String _formatTime(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes : $seconds';
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
                const SizedBox(height: 30),
                
                // Controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Pause Button (Left)
                    GestureDetector(
                      onTap: _isRunning ? _pauseTimer : null,
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: const BoxDecoration(
                          color: Color(0xFFECE9F1),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: SvgPicture.asset(
                            'assets/icons/pause.svg',
                            width: 24,
                            height: 24,
                            colorFilter: const ColorFilter.mode(
                              Color(0xFFC2BFC6),
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    
                    // Play/Stop Button (Right)
                    GestureDetector(
                      onTap: _isRunning ? _stopTimer : _startTimer,
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: _isRunning ? const Color(0xFFEB5757) : const Color(0xFF00D591),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: SvgPicture.asset(
                            _isRunning ? 'assets/icons/stop.svg' : 'assets/icons/play.svg',
                            width: 24,
                            height: 24,
                            colorFilter: const ColorFilter.mode(
                              Colors.white,
                              BlendMode.srcIn,
                            ),
                          ),
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
        Text(
          value,
          textAlign: TextAlign.center,
          style: GoogleFonts.quicksand(
            fontSize: 80,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF3A416F),
            height: 1.0, // Reduce line height to minimize default padding
          ),
        ),
        const SizedBox(height: 10), // Explicit 10px spacing
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
