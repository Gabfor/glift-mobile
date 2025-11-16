import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:glift_mobile/widgets/embedded_raster_image.dart';

void main() {
  group('EmbeddedRasterImage.extractPrimaryImage', () {
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
