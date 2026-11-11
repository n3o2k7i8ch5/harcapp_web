import 'dart:io';

import 'package:harcapp_core/harcthought/harcapp_links.dart';
import 'package:harcapp_core/harcthought/poradnik/data.dart';
import 'package:harcapp_core/harcthought/poradnik/poradnik.dart';

import '../template.dart';

const String _listTitle = 'Poradnik harcerski';
const String _listDescription =
    'Poradniki dla harcerzy i kadry do pobrania i czytania w HarcApp.';

/// A page per poradnik and the poradnik list, as the app routes them.
int generatePoradnikPages({
  required String buildDir,
  required ShareTemplate template,
}) {
  int count = 0;
  final listText = HtmlText()
    ..h1(_listTitle)
    ..p(_listDescription);
  for (final p in allPoradniks) {
    if (_processPoradnik(p, template, buildDir)) count++;
    listText
      ..link(Uri.parse(HarcappLinks.poradnikOf(p)).path, p.title)
      ..p(p.description);
  }
  writePage(
    buildDir,
    HarcappLinks.poradnikListTemplate,
    template.render(
      pageUrl: HarcappLinks.poradnikList(),
      pageTitle: _listTitle,
      pageDescription: _listDescription,
      coverUrl: '${HarcappLinks.baseUrl}/icons/icon-512.png',
      content: listText.toString(),
    ),
  );
  return count + 1;
}

bool _processPoradnik(Poradnik p, ShareTemplate template, String buildDir) {
  final coverRel =
      'packages/harcapp_core/assets/poradnik/${p.name}/cover_raw.webp';
  final coverFile = File('$buildDir/assets/$coverRel');
  if (!coverFile.existsSync()) {
    stderr.writeln(
        'Skipping poradnik "${p.name}": cover not found at ${coverFile.path}');
    return false;
  }
  final pageUrl = HarcappLinks.poradnikOf(p, short: true);
  final html = template.render(
    pageUrl: pageUrl,
    pageTitle: p.title,
    pageDescription: p.description,
    coverUrl: '${HarcappLinks.baseUrl}/assets/$coverRel',
  );
  writePage(buildDir, Uri.parse(HarcappLinks.poradnikOf(p)).path, html);
  writePage(buildDir, Uri.parse(pageUrl).path, html);
  return true;
}
