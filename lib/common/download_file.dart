import 'dart:convert';
import 'dart:js_interop';

import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

void downloadFileFromString({
  required String fileName,
  required String content,
}){
  final Uint8List bytes = utf8.encode(content);
  downloadFileFromBytes(fileName: fileName, bytes: bytes);
}

void downloadFileFromBytes({
  required String fileName,
  required Uint8List bytes,
  String mimeType = 'application/octet-stream',
}){
  final blob = web.Blob(
    <JSAny>[bytes.toJS].toJS,
    web.BlobPropertyBag(type: mimeType),
  );
  final url = web.URL.createObjectURL(blob);
  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..download = fileName;
  anchor.style.display = 'none';

  web.document.body!.append(anchor);
  anchor.click();
  anchor.remove();
  web.URL.revokeObjectURL(url);
}
