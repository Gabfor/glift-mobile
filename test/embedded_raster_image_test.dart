import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:glift_mobile/widgets/embedded_raster_image.dart';

void main() {
  group('EmbeddedRasterImage.extractPrimaryImage', () {
    test('extracts images from onboarding assets', () {
      final names = [
        'onboarding_creer.svg',
        'onboarding_suivre.svg',
        'onboarding_noter.svg',
        'onboarding_visualiser.svg'
      ];
      for (final name in names) {
        final file = File('assets/images/$name');
        final contents = file.readAsStringSync();
        
        final embeddedImages = <String, String>{};
        int startScan = 0;
        while (true) {
          final imgStart = contents.indexOf('<image', startScan);
          if (imgStart == -1) break;
          final imgEnd = contents.indexOf('>', imgStart);
          if (imgEnd == -1) break;
          final imgTag = contents.substring(imgStart, imgEnd + 1);
          startScan = imgEnd + 1;
          
          String? id;
          for (final quote in ['"', "'"]) {
            final prefix = 'id=$quote';
            final idx = imgTag.indexOf(prefix);
            if (idx != -1) {
              final start = idx + prefix.length;
              final end = imgTag.indexOf(quote, start);
              if (end != -1) {
                id = imgTag.substring(start, end);
                break;
              }
            }
          }
          if (id == null) continue;
          
          String? base64Payload;
          for (final prefix in [
            'href="data:image/png;base64,',
            'href="data:image/jpeg;base64,',
            "href='data:image/png;base64,",
            "href='data:image/jpeg;base64,",
          ]) {
            final idx = imgTag.indexOf(prefix);
            if (idx != -1) {
              final start = idx + prefix.length;
              final quote = prefix.contains('"') ? '"' : "'";
              final end = imgTag.indexOf(quote, start);
              if (end != -1) {
                base64Payload = imgTag.substring(start, end);
                break;
              }
            }
          }
          
          if (base64Payload != null) {
            embeddedImages[id] = base64Payload;
          }
        }
        
        expect(embeddedImages, isNotEmpty, reason: '$name should have embedded images');
      }
    });

    test('picks image referenced by the largest rectangle', () {
      final smallBytes = base64Encode([0, 1, 2]);
      final bigBytes = base64Encode([3, 4, 5, 6]);
      final svg = '''
<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">
  <defs>
    <pattern id="patternSmall"><use xlink:href="#imageSmall" /></pattern>
    <pattern id="patternBig"><use xlink:href="#imageBig" /></pattern>
  </defs>
  <rect width="10" height="10" fill="url(#patternSmall)" />
  <rect width="200" height="100" fill="url(#patternBig)" />
  <image id="imageSmall" xlink:href="data:image/png;base64,$smallBytes" />
  <image id="imageBig" xlink:href="data:image/png;base64,$bigBytes" />
</svg>
''';

      final result = EmbeddedRasterImage.extractPrimaryImage(svg);

      expect(result, Uint8List.fromList([3, 4, 5, 6]));
    });

    test('falls back to the first embedded image when no rect match exists', () {
      final first = base64Encode([7, 8]);
      final second = base64Encode([9, 10]);
      final svg = '''
<svg xmlns="http://www.w3.org/2000/svg">
  <image id="first" xlink:href="data:image/png;base64,$first" />
  <image id="second" xlink:href="data:image/png;base64,$second" />
</svg>
''';

      final result = EmbeddedRasterImage.extractPrimaryImage(svg);

      expect(result, Uint8List.fromList([7, 8]));
    });
  });
}
