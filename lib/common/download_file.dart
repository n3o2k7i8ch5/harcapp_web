import 'dart:convert';
import 'dart:html';
import 'package:flutter/foundation.dart';

void downloadFile({
  required String fileName,
  required String content,
}){
  final Uint8List bytes = utf8.encode(content);
  final Blob blob = Blob([bytes]);
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