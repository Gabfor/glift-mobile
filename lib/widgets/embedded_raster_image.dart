import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Displays raster image data that is embedded inside an SVG asset as a
/// `data:image/*;base64,` URI.
class EmbeddedRasterImage extends StatelessWidget {
  const EmbeddedRasterImage({
    super.key,
    required this.svgAsset,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
  });

  final String svgAsset;
  final double? width;
  final double? height;
  final BoxFit fit;

  static final _cache = <String, Future<Uint8List>>{};
  static const _hrefAttr = '(?:xlink:)?href';
  static final _imageElementPattern = RegExp(
    r'''<image[^>]+id=["']([^"']+)["'][^>]+''' r'$_hrefAttr' r'''=["']data:image/(?:png|jpe?g|webp);base64,([^"']+)["'][^>]*>''',
    dotAll: true,
    caseSensitive: false,
  );
  static final _patternUsePattern = RegExp(
    r'''<pattern[^>]+id=["']([^"']+)["'][^>]*>.*?<use[^>]+''' r'$_hrefAttr' r'''=["']#([^"']+)["']''',
    dotAll: true,
    caseSensitive: false,
  );
  static final _rectPatternPattern = RegExp(
    r'''<rect[^>]+fill=["']url\(#([^"')]+)\)["'][^>]*>''',
    dotAll: true,
  );

  static Future<Uint8List> _bytesFor(String asset) {
    return _cache.putIfAbsent(asset, () async {
      final svgContents = await rootBundle.loadString(asset);
      final bytes = extractPrimaryImage(svgContents);
      if (bytes == null) {
        throw FlutterError(
          'Asset "$asset" does not contain an embedded base64 raster image.',
        );
      }
      return bytes;
    });
  }

  /// Selects the raster image that best represents [svgContents].
  ///
  /// When several `data:image/*;base64` payloads are present, the image used by
  /// the largest rectangle filled via `url(#pattern)` is preferred.
  @visibleForTesting
  static Uint8List? extractPrimaryImage(String svgContents) {
    final embeddedImages = <String, String>{};
    for (final match in _imageElementPattern.allMatches(svgContents)) {
      embeddedImages[match.group(1)!] = match.group(2)!;
    }

    if (embeddedImages.isEmpty) {
      return null;
    }

    final patternToImage = <String, String>{};
    for (final match in _patternUsePattern.allMatches(svgContents)) {
      patternToImage[match.group(1)!] = match.group(2)!;
    }

    double bestArea = -1;
    String? bestImageId;

    for (final match in _rectPatternPattern.allMatches(svgContents)) {
      final patternId = match.group(1)!;
      final imageId = patternToImage[patternId];
      if (imageId == null) {
        continue;
      }

      final source = match.group(0)!;
      final width = _extractDimension(source, 'width');
      final height = _extractDimension(source, 'height');
      if (width == null || height == null) {
        continue;
      }

      final area = width * height;
      if (area > bestArea) {
        bestArea = area;
        bestImageId = imageId;
      }
    }

    final base64Payload = bestImageId != null
        ? embeddedImages[bestImageId]
        : embeddedImages.values.first;

    return base64Decode(
      base64Payload!.replaceAll(RegExp(r'\s+'), ''),
    );
  }

  static double? _extractDimension(String source, String attribute) {
    final match = RegExp(
      '$attribute=["\']([^"\']+)["\']',
    ).firstMatch(source);
    if (match == null) {
      return null;
    }
    return double.tryParse(match.group(1)!);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: _bytesFor(svgAsset),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return SizedBox(
            width: width,
            height: height,
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData) {
          return SizedBox(
            width: width,
            height: height,
            child: const Center(child: Icon(Icons.error_outline)),
          );
        }

        return Image.memory(
          snapshot.data!,
          width: width,
          height: height,
          fit: fit,
        );
      },
    );
  }
}
