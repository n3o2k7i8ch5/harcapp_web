import 'dart:io';

import 'package:harcapp_core/harcthought/konspekts/data/harcerskie/all.dart';
import 'package:harcapp_core/harcthought/konspekts/data/ksztalcenie/all.dart';
import 'package:harcapp_core/harcthought/konspekts/konspekt.dart';

import '../template.dart';

int generateKonspektPages({
  required String baseUrl,
  required String buildDir,
  required ShareTemplate template,
}) {
  int count = 0;
  for (final k in [...allHarcerskieKonspekts, ...allKsztalcenieKonspekts]) {
    if (_processKonspekt(k, template, baseUrl, buildDir)) count++;
  }
  return count;
}

bool _processKonspekt(
    Konspekt k, ShareTemplate template, String baseUrl, String buildDir) {
  final coverFile = File('$buildDir/assets/${k.coverPath}');
  if (!coverFile.existsSync()) {
    stderr.writeln(
        'Skipping konspekt "${k.name}": cover not found at ${coverFile.path}');
    return false;
  }
  // Canonical URL points to the short form — that's what new shares use.
  final pageUrl = '$baseUrl/k/${k.category.pathShort}/${k.name}';
  final coverUrl = '$baseUrl/assets/${k.coverPath}';
  final html = template.render(
    pageUrl: pageUrl,
    pageTitle: k.title,
    pageDescription: k.summary,
    coverUrl: coverUrl,
  );
  // Both long and short paths so legacy and new links both work.
  writePage(buildDir, 'konspekty/${k.category.path}/${k.name}', html);
  writePage(buildDir, 'k/${k.category.pathShort}/${k.name}', html);
  return true;
}
