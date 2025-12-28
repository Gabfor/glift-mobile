import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

class SupersetGroupCard extends StatefulWidget {
  final List<Widget> children;
  final VoidCallback onComplete;
  final VoidCallback onIgnore;
  final VoidCallback onMoveDown;
  final bool isCompleted;
  final bool isIgnored;
  final bool isLast;

  const SupersetGroupCard({
    super.key,
    required this.children,
    required this.onComplete,
    required this.onIgnore,
    required this.onMoveDown,
    required this.isCompleted,
    required this.isIgnored,
    required this.isLast,
  });

  @override
  State<SupersetGroupCard> createState() => _SupersetGroupCardState();
}

class _SupersetGroupCardState extends State<SupersetGroupCard> {
  bool _isCompleting = false;
  bool _isIgnoring = false;

  Future<void> _handleIgnore() async {
    HapticFeedback.lightImpact();
    setState(() {
      _isIgnoring = true;
    });

    await Future.delayed(const Duration(milliseconds: 500));

    widget.onIgnore();

    if (mounted) {
      setState(() {
        _isIgnoring = false;
      });
    }
  }

  void _handleMoveDown() {
    HapticFeedback.lightImpact();
    widget.onMoveDown();
  }

  Future<void> _handleComplete() async {
    // Immediate feedback
    HapticFeedback.lightImpact();
    setState(() {
      _isCompleting = true;
    });

    // Small delay to let the user see the visual change
    await Future.delayed(const Duration(milliseconds: 500));

    // Call parent action
    widget.onComplete();

    // Reset state (though widget might move/dispose)
    if (mounted) {
      setState(() {
        _isCompleting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // effectively completed if parent says so OR we are in the process of completing
    final effectiveIsCompleted = widget.isCompleted || _isCompleting;
    final effectiveIsIgnored = widget.isIgnored || _isIgnoring;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: CustomPaint(
        foregroundPainter: DashedBorderPainter(color: const Color(0xFF7069FA)),
        child: Column(
          children: [
            ...widget.children,
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ActionButton(
                    label: 'Ignorer',
                    icon: 'assets/icons/close.svg',
                    iconWidth: 12,
                    iconHeight: 12,
                    color: effectiveIsCompleted
                        ? const Color(0xFFECE9F1)
                        : (effectiveIsIgnored ? Colors.white : const Color(0xFFC2BFC6)),
                    backgroundColor:
                        effectiveIsIgnored ? const Color(0xFFC2BFC6) : Colors.white,
                    isDisabled: effectiveIsCompleted,
                    onTap: (effectiveIsCompleted || effectiveIsIgnored)
                        ? null
                        : () {
                            _handleIgnore();
                          },
                  ),
                  ActionButton(
                    label: 'Déplacer',
                    icon: 'assets/icons/arrow_small.svg',
                    iconWidth: 12,
                    iconHeight: 12,
                    color: (widget.isLast || effectiveIsCompleted)
                        ? const Color(0xFFECE9F1)
                        : const Color(0xFFC2BFC6),
                    isDisabled: widget.isLast || effectiveIsCompleted || _isIgnoring,
                    onTap: (widget.isLast || effectiveIsCompleted || _isIgnoring)
                        ? null
                        : () {
                            _handleMoveDown();
                          },
                  ),
                  ActionButton(
                    label: 'Terminé',
                    icon: 'assets/icons/check_small.svg',
                    iconWidth: 12,
                    iconHeight: 12,
                    color: effectiveIsIgnored
                        ? const Color(0xFFECE9F1)
                        : (effectiveIsCompleted ? Colors.white : const Color(0xFF00D591)),
                    backgroundColor:
                        effectiveIsCompleted ? const Color(0xFF00D591) : Colors.white,
                    isPrimary: true,
                    isDisabled: effectiveIsIgnored,
                    onTap: _handleComplete,
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

class ActionButton extends StatefulWidget {
  const ActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    this.backgroundColor = Colors.white,
    this.isDisabled = false,
    this.isPrimary = false,
    this.onTap,
    this.iconWidth = 24,
    this.iconHeight = 24,
  });

  final String label;
  final String icon;
  final double iconWidth;
  final double iconHeight;
  final Color color;
  final Color backgroundColor;
  final bool isDisabled;
  final bool isPrimary;
  final VoidCallback? onTap;

  @override
  State<ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<ActionButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.isDisabled ? const Color(0xFFECE9F1) : widget.color;
    final backgroundColor = widget.isDisabled ? Colors.white : widget.backgroundColor;
    final contentColor =
        widget.isPrimary && !widget.isDisabled && backgroundColor != Colors.white
            ? Colors.white
            : baseColor;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.isDisabled ? null : widget.onTap,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 140),
        scale: widget.isDisabled || !_isPressed ? 1 : 0.97,
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: widget.isPrimary && backgroundColor == Colors.white
                  ? baseColor
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

class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;
  final double radius;

  DashedBorderPainter({
    required this.color,
    this.strokeWidth = 2.0,
    this.dashWidth = 5.0,
    this.dashSpace = 3.0,
    this.radius = 15.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final RRect rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(radius),
    );

    final Path path = Path()..addRRect(rrect);
    final Path dashPath = Path();
    for (final PathMetric metric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        dashPath.addPath(
          metric.extractPath(distance, distance + dashWidth),
          Offset.zero,
        );
        distance += dashWidth + dashSpace;
      }
    }

    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
