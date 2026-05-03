// Generates per-slug static index.html files under build/web so that crawlers
// (Facebook/Messenger, Slack, Discord, Twitter, LinkedIn, Telegram) get proper
// og:image / og:title / og:description for each article, konspekt and poradnik
// instead of the generic site-level fallback.
//
// Self-contained sub-project — does not import from the main app's lib/.
// Network I/O goes through curl (Process.run) because Cloudflare blocks Dart's
// TLS fingerprint on *.zhr.pl, so any in-process Dart HTTP client (Dio, http,
// dart:io) returns 400 even though the URL works fine in browsers and curl.
//
// Runs as a Flutter test because harcapp_core transitively imports dart:ui via
// package:flutter — pure `dart run` cannot resolve that.
//
// Invocation (from this directory):
//   flutter test test/generate_test.dart
//
// Run AFTER `flutter build web` so the cover assets exist under
// build/web/assets/packages/harcapp_core/assets/...

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:harcapp_core/harcthought/konspekts/initialize.dart';
import 'package:share_pages/sources/articles.dart';
import 'package:share_pages/sources/konspekty.dart';
import 'package:share_pages/sources/poradniki.dart';
import 'package:share_pages/template.dart';

const String _baseUrl = 'https://harcapp.web.app';
const String _fallbackArticleCoverUrl = '$_baseUrl/icons/icon-512.png';

// Paths are relative to the repo root (../../ from this sub-project).
const String _repoRoot = '../..';
const String _buildDir = '$_repoRoot/build/web';
const String _templatePath = '$_repoRoot/web/index.html';
// Cache lives inside the sub-project, gets committed → first deploy seeds it,
// subsequent deploys skip the per-article HTML scrape for known articles.
const String _articleCachePath = 'cache/articles.json';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('generate share pages', () async {
    expect(File(_templatePath).existsSync(), isTrue,
        reason: 'Template not found at $_templatePath');
    expect(Directory(_buildDir).existsSync(), isTrue,
        reason: 'Build dir not found at $_buildDir. '
            'Run `flutter build web` first.');

    final template = ShareTemplate.load(_templatePath);
    await initKonspekts();

    final konspektCount = generateKonspektPages(
      baseUrl: _baseUrl, buildDir: _buildDir, template: template,
    );
    final poradnikCount = generatePoradnikPages(
      baseUrl: _baseUrl, buildDir: _buildDir, template: template,
    );
    final articleCount = await generateArticlePages(
      baseUrl: _baseUrl,
      buildDir: _buildDir,
      template: template,
      fallbackCoverUrl: _fallbackArticleCoverUrl,
      cachePath: _articleCachePath,
    );

    stdout.writeln('Generated $konspektCount konspekt pages, '
        '$poradnikCount poradnik pages, '
        '$articleCount article pages.');

    expect(konspektCount + poradnikCount + articleCount, greaterThan(0),
        reason: 'No share pages generated — check cover paths and network.');
  }, timeout: const Timeout(Duration(minutes: 10)));
}
