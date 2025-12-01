import 'package:flutter/material.dart';

import '../theme/glift_theme.dart';

class GliftLoader extends StatelessWidget {
  const GliftLoader({
    super.key,
    this.size = 32,
    this.strokeWidth = 4,
    this.color,
    this.centered = true,
  });

  final double size;
  final double strokeWidth;
  final Color? color;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    final indicator = SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        color: color ?? GliftTheme.accent,
      ),
    );

    if (centered) {
      return Center(child: indicator);
    }

    return indicator;
  }
}
