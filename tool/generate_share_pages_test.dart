// Generates per-slug static index.html files under build/web so that
// crawlers (Facebook/Messenger, Slack, Discord, Twitter, LinkedIn,
// Telegram) get proper og:image / og:title / og:description for each
// konspekt and poradnik instead of the generic site-level fallback.
//
// Runs as a Flutter test because harcapp_core transitively imports
// dart:ui via package:flutter — pure `dart run` cannot resolve that.
//
// Invocation:
//   flutter test tool/generate_share_pages_test.dart
//
// Run AFTER `flutter build web` so the cover assets exist under
// build/web/assets/packages/harcapp_core/assets/...

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:harcapp_core/harcthought/konspekts/data/harcerskie/all.dart';
import 'package:harcapp_core/harcthought/konspekts/data/ksztalcenie/all.dart';
import 'package:harcapp_core/harcthought/konspekts/initialize.dart';
import 'package:harcapp_core/harcthought/konspekts/konspekt.dart';
import 'package:harcapp_core/harcthought/poradnik/data.dart';
import 'package:harcapp_core/harcthought/poradnik/poradnik.dart';

const String _baseUrl = 'https://harcapp.web.app';
const String _buildDir = 'build/web';
const String _templatePath = 'web/index.html';

String _htmlEscape(String s) => s
    .replaceAll('&', '&amp;')
    .replaceAll('"', '&quot;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;');

String _singleLine(String s) => s.replaceAll(RegExp(r'\s+'), ' ').trim();

String _renderPage({
  required String template,
  required String pageUrl,
  required String pageTitle,
  required String pageDescription,
  required String coverUrl,
}) {
  final t = _htmlEscape(pageTitle);
  final d = _htmlEscape(_singleLine(pageDescription));
  final u = _htmlEscape(pageUrl);
  final c = _htmlEscape(coverUrl);

  String out = template;
  out = out.replaceFirst(
      RegExp(r'<title>[^<]*</title>'), '<title>$t</title>');
  out = out.replaceFirst(
      RegExp(r'<meta name="description" content="[^"]*">'),
      '<meta name="description" content="$d">');
  out = out.replaceFirst(
      RegExp(r'<link rel="canonical" href="[^"]*">'),
      '<link rel="canonical" href="$u">');
  out = out.replaceFirst(
      RegExp(r'<meta property="og:title" content="[^"]*">'),
      '<meta property="og:title" content="$t">');
  out = out.replaceFirst(
      RegExp(r'<meta property="og:description" content="[^"]*">'),
      '<meta property="og:description" content="$d">');
  out = out.replaceFirst(
      RegExp(r'<meta property="og:url" content="[^"]*">'),
      '<meta property="og:url" content="$u">');
  out = out.replaceFirst(
      RegExp(r'<meta property="og:image" content="[^"]*">'),
      '<meta property="og:image" content="$c">');
  out = out.replaceFirst(
      RegExp(r'<meta name="twitter:title" content="[^"]*">'),
      '<meta name="twitter:title" content="$t">');
  out = out.replaceFirst(
      RegExp(r'<meta name="twitter:description" content="[^"]*">'),
      '<meta name="twitter:description" content="$d">');
  out = out.replaceFirst(
      RegExp(r'<meta name="twitter:image" content="[^"]*">'),
      '<meta name="twitter:image" content="$c">');
  return out;
}

void _writePage(String relPath, String content) {
  final file = File('$_buildDir/$relPath/index.html');
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(content);
}

bool _processKonspekt(Konspekt k, String template) {
  final coverFile = File('$_buildDir/assets/${k.coverPath}');
  if (!coverFile.existsSync()) {
    stderr.writeln(
        'Skipping konspekt "${k.name}": cover not found at ${coverFile.path}');
    return false;
  }
  // Canonical URL points to the short form — that's what new shares use.
  final pageUrl = '$_baseUrl/k/${k.category.pathShort}/${k.name}';
  final coverUrl = '$_baseUrl/assets/${k.coverPath}';
  final html = _renderPage(
    template: template,
    pageUrl: pageUrl,
    pageTitle: k.title,
    pageDescription: k.summary,
    coverUrl: coverUrl,
  );
  // Generate at both long and short paths so legacy and new links both work.
  _writePage('konspekty/${k.category.path}/${k.name}', html);
  _writePage('k/${k.category.pathShort}/${k.name}', html);
  return true;
}

bool _processPoradnik(Poradnik p, String template) {
  final coverRel =
      'packages/harcapp_core/assets/poradnik/${p.name}/cover_raw.webp';
  final coverFile = File('$_buildDir/assets/$coverRel');
  if (!coverFile.existsSync()) {
    stderr.writeln(
        'Skipping poradnik "${p.name}": cover not found at ${coverFile.path}');
    return false;
  }
  final pageUrl = '$_baseUrl/p/${p.name}';
  final coverUrl = '$_baseUrl/assets/$coverRel';
  final html = _renderPage(
    template: template,
    pageUrl: pageUrl,
    pageTitle: p.title,
    pageDescription: p.description,
    coverUrl: coverUrl,
  );
  _writePage('poradnik/${p.name}', html);
  _writePage('p/${p.name}', html);
  return true;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('generate share pages', () async {
    final templateFile = File(_templatePath);
    expect(templateFile.existsSync(), isTrue,
        reason: 'Template not found at $_templatePath');
    expect(Directory(_buildDir).existsSync(), isTrue,
        reason: 'Build dir not found at $_buildDir. '
            'Run `flutter build web` first.');

    final template = templateFile.readAsStringSync();
    await initKonspekts();

    int konspektCount = 0;
    int poradnikCount = 0;

    for (final k in allHarcerskieKonspekts) {
      if (_processKonspekt(k, template)) konspektCount++;
    }
    for (final k in allKsztalcenieKonspekts) {
      if (_processKonspekt(k, template)) konspektCount++;
    }
    for (final p in allPoradniks) {
      if (_processPoradnik(p, template)) poradnikCount++;
    }

    stdout.writeln('Generated $konspektCount konspekt pages, '
        '$poradnikCount poradnik pages.');

    expect(konspektCount + poradnikCount, greaterThan(0),
        reason: 'No share pages generated — check cover paths.');
  });
}
