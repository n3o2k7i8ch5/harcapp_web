import 'dart:io';

import 'package:harcapp_core/harcthought/harcapp_links.dart';
import 'package:harcapp_core/harcthought/konspekts/data/harcerskie/all.dart';
import 'package:harcapp_core/harcthought/konspekts/data/ksztalcenie/all.dart';
import 'package:harcapp_core/harcthought/konspekts/konspekt.dart';

import '../template.dart';

const Map<KonspektCategory, (String, String)> _listTitles = {
  KonspektCategory.harcerskie: (
    'Konspekty harcerskie',
    'Gotowe konspekty zbiórek, gier i form harcerskich – cele, materiały '
        'i przebieg krok po kroku, w HarcApp.',
  ),
  KonspektCategory.ksztalcenie: (
    'Konspekty kształceniowe',
    'Konspekty zajęć kształceniowych dla kadry harcerskiej – cele, materiały '
        'i przebieg krok po kroku, w HarcApp.',
  ),
};

/// A page per konspekt and per category list, as the app routes them.
int generateKonspektPages({
  required String buildDir,
  required ShareTemplate template,
}) {
  int count = 0;
  for (final MapEntry(key: category, value: konspekts) in {
    KonspektCategory.harcerskie: allHarcerskieKonspekts,
    KonspektCategory.ksztalcenie: allKsztalcenieKonspekts,
  }.entries) {
    final (title, description) = _listTitles[category]!;
    final listText = HtmlText()
      ..h1(title)
      ..p(description);
    for (final k in konspekts) {
      if (_processKonspekt(k, template, buildDir)) count++;
      listText
        ..link(Uri.parse(HarcappLinks.konspektOf(k)).path, k.title)
        ..p(k.summary);
    }
    writePage(
      buildDir,
      HarcappLinks.konspektCategoryListPath(category),
      template.render(
        pageUrl: HarcappLinks.konspektCategoryList(category),
        pageTitle: title,
        pageDescription: description,
        coverUrl: '${HarcappLinks.baseUrl}/icons/icon-512.png',
        content: listText.toString(),
      ),
    );
    count++;
  }
  return count;
}

bool _processKonspekt(Konspekt k, ShareTemplate template, String buildDir) {
  final coverFile = File('$buildDir/assets/${k.coverPath}');
  if (!coverFile.existsSync()) {
    stderr.writeln(
        'Skipping konspekt "${k.name}": cover not found at ${coverFile.path}');
    return false;
  }
  // Canonical URL points to the short form — that's what new shares use.
  final pageUrl = HarcappLinks.konspektOf(k, short: true);
  final html = template.render(
    pageUrl: pageUrl,
    pageTitle: k.title,
    pageDescription: k.summary,
    coverUrl: '${HarcappLinks.baseUrl}/assets/${k.coverPath}',
    content: _konspektText(k),
  );
  // Both long and short paths so legacy and new links both work.
  writePage(buildDir, Uri.parse(HarcappLinks.konspektOf(k)).path, html);
  writePage(buildDir, Uri.parse(pageUrl).path, html);
  return true;
}

String _konspektText(Konspekt k) {
  final t = HtmlText()
    ..h1(k.title)
    ..p(k.summary)
    ..p(k.intro)
    ..p(k.description);
  if (k.aims.isNotEmpty) {
    t
      ..h2('Cele')
      ..list(k.aims);
  }
  final materials = k.materials ?? const [];
  if (materials.isNotEmpty) {
    t
      ..h2('Materiały')
      ..list(materials.map((m) => m.name));
  }
  final steps = k.allSteps;
  if (steps.isNotEmpty) {
    t.h2('Przebieg');
    for (final s in steps) {
      t
        ..h3(s.title)
        ..p(s.content);
    }
  }
  return t.toString();
}
