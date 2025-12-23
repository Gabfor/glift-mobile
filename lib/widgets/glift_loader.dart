import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:math';

class GliftLoader extends StatefulWidget {
  const GliftLoader({
    super.key,
    this.size = 32,
    this.strokeWidth = 4, // Unused but kept for compatibility
    this.color, // Unused but kept for compatibility
    this.centered = true,
  });

  final double size;
  final double strokeWidth;
  final Color? color;
  final bool centered;

  @override
  State<GliftLoader> createState() => _GliftLoaderState();
}

class _GliftLoaderState extends State<GliftLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final indicator = RotationTransition(
      turns: _controller,
      child: SvgPicture.asset(
        'assets/icons/loader.svg',
        width: widget.size,
        height: widget.size,
      ),
    );

    if (widget.centered) {
      return Center(child: indicator);
    }

    return indicator;
  }
}
