import 'dart:io';

import 'package:harcapp_core/harcthought/poradnik/data.dart';
import 'package:harcapp_core/harcthought/poradnik/poradnik.dart';

import '../template.dart';

int generatePoradnikPages({
  required String baseUrl,
  required String buildDir,
  required ShareTemplate template,
}) {
  int count = 0;
  for (final p in allPoradniks) {
    if (_processPoradnik(p, template, baseUrl, buildDir)) count++;
  }
  return count;
}

bool _processPoradnik(
    Poradnik p, ShareTemplate template, String baseUrl, String buildDir) {
  final coverRel =
      'packages/harcapp_core/assets/poradnik/${p.name}/cover_raw.webp';
  final coverFile = File('$buildDir/assets/$coverRel');
  if (!coverFile.existsSync()) {
    stderr.writeln(
        'Skipping poradnik "${p.name}": cover not found at ${coverFile.path}');
    return false;
  }
  final pageUrl = '$baseUrl/p/${p.name}';
  final coverUrl = '$baseUrl/assets/$coverRel';
  final html = template.render(
    pageUrl: pageUrl,
    pageTitle: p.title,
    pageDescription: p.description,
    coverUrl: coverUrl,
  );
  writePage(buildDir, 'poradnik/${p.name}', html);
  writePage(buildDir, 'p/${p.name}', html);
  return true;
}
