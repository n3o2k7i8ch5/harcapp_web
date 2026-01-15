import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

import 'cover_processing.dart';

Future<Uint8List> resizeCoverImage(Uint8List bytes) async {
  final blob = web.Blob([bytes.toJS].toJS);
  final url = web.URL.createObjectURL(blob);

  try {
    final img = await _loadImage(url);
    
    var width = img.naturalWidth;
    var height = img.naturalHeight;

    if (width > coverMaxWidth || height > coverMaxHeight) {
      final scale = (coverMaxWidth / width).clamp(0.0, coverMaxHeight / height);
      width = (width * scale).round();
      height = (height * scale).round();
    }

    return _canvasToPng(img, width, height);
  } finally {
    web.URL.revokeObjectURL(url);
  }
}

Future<web.HTMLImageElement> _loadImage(String url) async {
  final img = web.HTMLImageElement();
  final completer = Completer<void>();

  img.onLoad.first.then((_) => completer.complete());
  img.onError.first.then((_) => completer.completeError('Failed to load image'));
  img.src = url;

  await completer.future;
  return img;
}

Future<Uint8List> _canvasToPng(web.HTMLImageElement img, int width, int height) async {
  final canvas = web.HTMLCanvasElement()
    ..width = width
    ..height = height;

  final ctx = canvas.getContext('2d') as web.CanvasRenderingContext2D;
  ctx.drawImageScaled(img, 0, 0, width.toDouble(), height.toDouble());

  final completer = Completer<web.Blob?>();
  canvas.toBlob(((web.Blob? b) => completer.complete(b)).toJS, 'image/png');

  final blob = await completer.future;
  if (blob == null) throw StateError('Failed to encode image');

  final arrayBuffer = await blob.arrayBuffer().toDart;
  return arrayBuffer.toDart.asUint8List();
}
