import 'dart:convert';
import 'dart:typed_data';

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
  static final _dataUriPattern = RegExp(
    r'''data:image/(?:png|jpeg);base64,([^"']+)''',
    dotAll: true,
  );

  static Future<Uint8List> _bytesFor(String asset) {
    return _cache.putIfAbsent(asset, () async {
      final svgContents = await rootBundle.loadString(asset);
      final match = _dataUriPattern.firstMatch(svgContents);
      if (match == null) {
        throw FlutterError(
          'Asset "$asset" does not contain an embedded base64 raster image.',
        );
      }
      return base64Decode(match.group(1)!.replaceAll(RegExp(r'\s+'), ''));
    });
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
