import 'dart:convert';
import 'dart:html';

import 'package:flutter/widgets.dart';

void downloadFile({
  @required String fileName,
  @required String content,
}){
  final bytes = utf8.encode(content);
  final blob = Blob([bytes]);
  final url = Url.createObjectUrlFromBlob(blob);
  final anchor = document.createElement('a') as AnchorElement
    ..href = url
    ..style.display = 'none'
    ..download = fileName;
  document.body.children.add(anchor);

  anchor.click();

  document.body.children.remove(anchor);
  Url.revokeObjectUrl(url);
}