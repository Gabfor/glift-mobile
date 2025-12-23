import 'dart:math';

import 'package:custom_refresh_indicator/custom_refresh_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class GliftPullToRefresh extends StatefulWidget {
  final Widget child;
  final Future<void> Function() onRefresh;

  const GliftPullToRefresh({
    super.key,
    required this.child,
    required this.onRefresh,
  });

  @override
  State<GliftPullToRefresh> createState() => _GliftPullToRefreshState();
}

class _GliftPullToRefreshState extends State<GliftPullToRefresh>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomRefreshIndicator(
      onRefresh: widget.onRefresh,
      offsetToArmed: 100.0, // Distance to trigger refresh
      builder: (context, child, controller) {
        return Stack(
          clipBehavior: Clip.none, // Allow overflow if needed, but we position carefully
          children: [
            // The content (Scrollable)
            AnimatedBuilder(
              animation: controller,
              child: child,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0.0, controller.value * 100.0),
                  child: child,
                );
              },
            ),
            
            // The Loader
            AnimatedBuilder(
              animation: controller,
              builder: (context, _) {
                // Calculation:
                // Idle (value 0): Hidden above content.
                // Armed (value 1): At desired position.
                // Request: "baisser de 20px" (lower by 20px).
                // Previous logic clamped 10..50.
                // New logic:
                // Start: -40px (hidden)
                // End: 50px (visible)
                
                final double startY = -40.0;
                final double endY = 50.0;
                final double currentY = startY + (controller.value * (endY - startY));
                
                // Hide if barely pulled to avoid glitchy edge appearance
                // Calculate normalized progress from 0.15 to 1.0
                // Ensure final opacity is strictly between 0.0 and 1.0
                final double rawOpacity = (controller.value - 0.15) / 0.85;
                final double opacity = rawOpacity.clamp(0.0, 1.0);

                if (opacity <= 0) return const SizedBox.shrink();

                return Positioned(
                  top: currentY, 
                  left: 0,
                  right: 0,
                  child: Opacity(
                    opacity: opacity,
                    child: Center(
                      child: _buildLoader(controller),
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
      child: widget.child,
    );
  }

  Widget _buildLoader(IndicatorController controller) {
    if (controller.isLoading) {
      if (!_rotationController.isAnimating) {
        _rotationController.repeat();
      }
      return RotationTransition(
        turns: _rotationController,
        child: SvgPicture.asset(
          'assets/icons/loader.svg',
          width: 32,
          height: 32,
        ),
      );
    } else {
      // Logic for pull phase: rotate based on pull distance
      if (_rotationController.isAnimating) {
        _rotationController.stop();
        _rotationController.reset();
      }
      return Transform.rotate(
        angle: controller.value * 2 * pi,
        child: SvgPicture.asset(
          'assets/icons/loader.svg',
          width: 32,
          height: 32,
        ),
      );
    }
  }
}
