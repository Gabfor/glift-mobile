import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:glift_mobile/services/settings_service.dart';

class DefaultTimerPage extends StatefulWidget {
  const DefaultTimerPage({
    super.key,
    required this.initialDuration,
  });

  final int initialDuration;

  @override
  State<DefaultTimerPage> createState() => _DefaultTimerPageState();
}

class _DefaultTimerPageState extends State<DefaultTimerPage> {
  late int _durationInSeconds;

  late final TextEditingController _minutesController;
  late final TextEditingController _secondsController;
  late final FocusNode _minutesFocusNode;
  late final FocusNode _secondsFocusNode;
  bool _isEditingMinutes = false;
  bool _isEditingSeconds = false;

  @override
  void initState() {
    super.initState();
    _durationInSeconds = widget.initialDuration;
    _minutesController = TextEditingController();
    _secondsController = TextEditingController();
    _minutesController.addListener(_handleMinutesTextChange);
    _secondsController.addListener(_handleSecondsTextChange);
    _minutesFocusNode = FocusNode();
    _secondsFocusNode = FocusNode();
    _minutesFocusNode.addListener(_handleMinutesFocusChange);
    _secondsFocusNode.addListener(_handleSecondsFocusChange);
  }

  @override
  void dispose() {
    _minutesController.removeListener(_handleMinutesTextChange);
    _secondsController.removeListener(_handleSecondsTextChange);
    _minutesController.dispose();
    _secondsController.dispose();
    _minutesFocusNode.dispose();
    _secondsFocusNode.dispose();
    super.dispose();
  }

  void _enterMinutesEdit() {
    if (_isEditingSeconds) {
      _finishSecondsEdit();
    }
    _minutesController.text = (_durationInSeconds ~/ 60).toString().padLeft(2, '0');
    setState(() {
      _isEditingMinutes = true;
      _isEditingSeconds = false;
    });
    _minutesFocusNode.requestFocus();
  }

  void _enterSecondsEdit() {
    if (_isEditingMinutes) {
      _finishMinutesEdit();
    }
    _secondsController.text = (_durationInSeconds % 60).toString().padLeft(2, '0');
    setState(() {
      _isEditingSeconds = true;
      _isEditingMinutes = false;
    });
    _secondsFocusNode.requestFocus();
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
    final minutes = _clampInt(minutesOverride ?? (_durationInSeconds ~/ 60), 0, 99);
    final seconds = _clampInt(secondsOverride ?? (_durationInSeconds % 60), 0, 59);
    return minutes * 60 + seconds;
  }

  void _handleMinutesTextChange() {
    // Only used for real-time validation if needed, but we save on finish
  }

  void _handleSecondsTextChange() {
    // Only used for real-time validation if needed, but we save on finish
  }

  void _finishMinutesEdit() {
    final pendingDuration =
        _computePendingDuration(minutesOverride: int.tryParse(_minutesController.text) ?? 0);
    _updateDuration(pendingDuration);
    setState(() {
      _isEditingMinutes = false;
    });
  }

  void _finishSecondsEdit() {
    final pendingDuration =
        _computePendingDuration(secondsOverride: int.tryParse(_secondsController.text) ?? 0);
    _updateDuration(pendingDuration);
    setState(() {
      _isEditingSeconds = false;
    });
  }

  void _updateDuration(int newDuration) {
    if (_durationInSeconds != newDuration) {
      setState(() {
        _durationInSeconds = newDuration;
      });
      SettingsService.instance.saveDefaultRestTime(_durationInSeconds);
    }
  }

  void _handleOutsideTap() {
    if (_isEditingMinutes || _isEditingSeconds) {
      FocusScope.of(context).unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final minutes = (_durationInSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_durationInSeconds % 60).toString().padLeft(2, '0');

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB), // Match options page bg
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _handleOutsideTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Content (Centered in screen)
            Center(
              child: Row(
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
            ),

            // Header (Fixed top)
            Positioned(
              top: MediaQuery.of(context).padding.top + 20,
              left: 20,
              right: 20,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _SettingsBackButton(onTap: () => Navigator.of(context).pop()),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Réglages',
                        style: GoogleFonts.quicksand(
                          color: const Color(0xFF3A416F),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Valeur par défaut',
                        style: GoogleFonts.quicksand(
                          color: const Color(0xFF3A416F),
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsBackButton extends StatelessWidget {
  const _SettingsBackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: const BoxDecoration(
          color: Color(0xFF3A416F),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.chevron_left,
          color: Colors.white,
          size: 28,
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
