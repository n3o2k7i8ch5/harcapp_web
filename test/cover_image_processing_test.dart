import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:harcapp_web/konspekt_workspace/cover/resizer_stub.dart';
import 'package:image/image.dart' as img;

void main() {
  group('cover image processing', () {
    group('resizeImage', () {
      test('downsizes large images to max dimensions', () async {
        final original = img.Image(width: 3000, height: 2000);
        img.fill(original, color: img.ColorRgb8(255, 0, 0));
        final inputBytes = Uint8List.fromList(img.encodePng(original));

        final result = await resizeCoverImage(inputBytes);

        final decoded = img.decodeImage(result);
        expect(decoded, isNotNull);
        expect(decoded!.width, equals(1500));
        expect(decoded.height, equals(1000));
      });

      test('keeps smaller images unchanged', () async {
        final original = img.Image(width: 1200, height: 800);
        img.fill(original, color: img.ColorRgb8(0, 255, 0));
        final inputBytes = Uint8List.fromList(img.encodePng(original));

        final result = await resizeCoverImage(inputBytes);

        final decoded = img.decodeImage(result);
        expect(decoded, isNotNull);
        expect(decoded!.width, equals(1200));
        expect(decoded.height, equals(800));
      });

      test('maintains aspect ratio when downsizing', () async {
        final original = img.Image(width: 4000, height: 3000); // 4:3
        img.fill(original, color: img.ColorRgb8(0, 0, 255));
        final inputBytes = Uint8List.fromList(img.encodePng(original));

        final result = await resizeCoverImage(inputBytes);

        final decoded = img.decodeImage(result);
        expect(decoded, isNotNull);
        // Should scale to fit within 1500x1000, maintaining 4:3
        // 1000 / 3000 = 0.333, 1500 / 4000 = 0.375 -> use 0.333
        expect(decoded!.width, equals(1333));
        expect(decoded.height, equals(1000));
      });
    });
  });
}
