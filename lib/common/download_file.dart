import 'dart:convert';
import 'dart:html';
import 'package:flutter/foundation.dart';

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
  final Blob blob = Blob([bytes], mimeType);
  final String url = Url.createObjectUrlFromBlob(blob);
  final AnchorElement anchor = document.createElement('a') as AnchorElement
    ..href = url
    ..style.display = 'none'
    ..download = fileName;

  document.body!.children.add(anchor);

  anchor.click();

  document.body!.children.remove(anchor);
  Url.revokeObjectUrl(url);
}