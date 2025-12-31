import 'package:flutter/material.dart';

class AnimatedCheckmark extends StatefulWidget {
  final VoidCallback onAnimationComplete;

  const AnimatedCheckmark({
    super.key,
    required this.onAnimationComplete,
  });

  @override
  State<AnimatedCheckmark> createState() => _AnimatedCheckmarkState();
}

class _AnimatedCheckmarkState extends State<AnimatedCheckmark>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _controller.forward().whenComplete(widget.onAnimationComplete);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      height: 100,
      child: CustomPaint(
        painter: _CheckmarkPainter(_animation),
      ),
    );
  }
}

class _CheckmarkPainter extends CustomPainter {
  final Animation<double> animation;

  _CheckmarkPainter(this.animation) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00D591)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Define the checkmark path (normalized 0-1 then scaled)
    final path = Path();
    // Start slightly left-middle
    path.moveTo(size.width * 0.2, size.height * 0.5);
    // Down to bottom-middle
    path.lineTo(size.width * 0.45, size.height * 0.75);
    // Up to top-right
    path.lineTo(size.width * 0.8, size.height * 0.25);

    // Create a partial path based on animation value
    final pathMetrics = path.computeMetrics();
    final extractPath = Path();

    for (var metric in pathMetrics) {
      extractPath.addPath(
        metric.extractPath(0.0, metric.length * animation.value),
        Offset.zero,
      );
    }

    canvas.drawPath(extractPath, paint);
  }

  @override
  bool shouldRepaint(covariant _CheckmarkPainter oldDelegate) => true;
}
