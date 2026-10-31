import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Joue une seule fois l'animation WebP (transparente) du splash screen
/// puis reste figée sur la dernière image.
class SplashAnimation extends StatefulWidget {
  const SplashAnimation({
    super.key,
    this.assetPath = 'assets/images/splash_animation.webp',
    this.width,
    this.onCompleted,
  });

  final String assetPath;
  final double? width;
  final VoidCallback? onCompleted;

  @override
  State<SplashAnimation> createState() => _SplashAnimationState();
}

class _SplashAnimationState extends State<SplashAnimation> {
  ui.Codec? _codec;
  ui.Image? _currentFrame;
  Timer? _timer;
  int _framesShown = 0;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await rootBundle.load(widget.assetPath);
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      if (_disposed) {
        codec.dispose();
        return;
      }
      _codec = codec;
      await _showNextFrame();
    } catch (e) {
      debugPrint('Splash animation error: $e');
      widget.onCompleted?.call();
    }
  }

  Future<void> _showNextFrame() async {
    final codec = _codec;
    if (codec == null || _disposed) return;

    final frameInfo = await codec.getNextFrame();
    if (_disposed) {
      frameInfo.image.dispose();
      return;
    }

    final previous = _currentFrame;
    setState(() => _currentFrame = frameInfo.image);
    previous?.dispose();
    _framesShown++;

    if (_framesShown >= codec.frameCount) {
      // Dernière image atteinte : on s'arrête dessus.
      widget.onCompleted?.call();
      return;
    }

    final duration = frameInfo.duration == Duration.zero
        ? const Duration(milliseconds: 16)
        : frameInfo.duration;
    _timer = Timer(duration, _showNextFrame);
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _currentFrame?.dispose();
    _codec?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final frame = _currentFrame;
    return SizedBox(
      width: widget.width,
      child: AspectRatio(
        aspectRatio: 620 / 533,
        child: frame == null
            ? const SizedBox.shrink()
            : RawImage(
                image: frame,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.medium,
              ),
      ),
    );
  }
}

