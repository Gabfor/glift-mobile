import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

class SupersetGroupCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: CustomPaint(
        foregroundPainter: DashedBorderPainter(color: const Color(0xFF7069FA)),
        child: Column(
          children: [
            ...children,
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ActionButton(
                    label: 'Ignorer',
                    icon: 'assets/icons/croix_small.svg',
                    iconWidth: 12,
                    iconHeight: 12,
                    color: isCompleted
                        ? const Color(0xFFECE9F1)
                        : (isIgnored ? Colors.white : const Color(0xFFC2BFC6)),
                    backgroundColor:
                        isIgnored ? const Color(0xFFC2BFC6) : Colors.white,
                    isDisabled: isCompleted,
                    onTap: onIgnore,
                  ),
                  ActionButton(
                    label: 'Déplacer',
                    icon: 'assets/icons/arrow_small.svg',
                    iconWidth: 12,
                    iconHeight: 12,
                    color: isLast ? const Color(0xFFECE9F1) : const Color(0xFFC2BFC6),
                    isDisabled: isLast,
                    onTap: isLast ? () {} : onMoveDown,
                  ),
                  ActionButton(
                    label: 'Terminé',
                    icon: 'assets/icons/check_small.svg',
                    iconWidth: 12,
                    iconHeight: 12,
                    color: isIgnored
                        ? const Color(0xFFECE9F1)
                        : (isCompleted ? Colors.white : const Color(0xFF00D591)),
                    backgroundColor:
                        isCompleted ? const Color(0xFF00D591) : Colors.white,
                    isPrimary: true,
                    isDisabled: isIgnored,
                    onTap: onComplete,
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
    required this.onTap,
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
  final VoidCallback onTap;

  @override
  State<ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<ActionButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.isDisabled ? const Color(0xFFECE9F1) : widget.color;
    final backgroundColor = widget.isPrimary && !widget.isDisabled
        ? widget.backgroundColor
        : Colors.white;
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
