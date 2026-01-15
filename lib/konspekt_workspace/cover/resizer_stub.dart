import 'dart:typed_data';

import 'package:image/image.dart' as img;

import 'cover_processing.dart';

Future<Uint8List> resizeCoverImage(Uint8List bytes) async {
  var image = img.decodeImage(bytes);
  if (image == null) throw StateError('Failed to decode image');

  if (image.width > coverMaxWidth || image.height > coverMaxHeight) {
    final scale = (coverMaxWidth / image.width).clamp(0.0, coverMaxHeight / image.height);
    image = img.copyResize(
      image,
      width: (image.width * scale).round(),
      height: (image.height * scale).round(),
      interpolation: img.Interpolation.average,
    );
  }

  return Uint8List.fromList(img.encodePng(image));
}
