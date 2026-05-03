import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:html_unescape/html_unescape.dart';
import 'package:rss_dart/domain/atom_feed.dart';
import 'package:rss_dart/domain/atom_item.dart';

import '../curl.dart';
import '../template.dart';

class _Article {
  final String sourceName;
  final String localId;
  final String title;
  final String author;
  final DateTime date;
  final String? imageUrl;

  const _Article({
    required this.sourceName,
    required this.localId,
    required this.title,
    required this.author,
    required this.date,
    required this.imageUrl,
  });
}

Future<int> generateArticlePages({
  required String baseUrl,
  required String buildDir,
  required ShareTemplate template,
  required String fallbackCoverUrl,
}) async {
  final results = await Future.wait([
    _fetchZhr('azymut', 'https://azymut.zhr.pl/feed/atom/'),
    _fetchZhr('pojutrze', 'https://pojutrze.zhr.pl/feed/atom/'),
    _fetchHarcApp(),
  ]);

  int count = 0;
  for (final articles in results) {
    for (final a in articles) {
      _writeArticlePage(a, baseUrl, buildDir, template, fallbackCoverUrl);
      count++;
    }
  }
  return count;
}

void _writeArticlePage(
  _Article a,
  String baseUrl,
  String buildDir,
  ShareTemplate template,
  String fallbackCoverUrl,
) {
  final pageUrl = '$baseUrl/a/${a.sourceName}/${a.localId}';
  final coverUrl = _isShareableImageUrl(a.imageUrl) ? a.imageUrl! : fallbackCoverUrl;
  final dateStr = _formatDate(a.date);
  final description = '${a.author} · $dateStr';
  final html = template.render(
    pageUrl: pageUrl,
    pageTitle: a.title,
    pageDescription: description,
    coverUrl: coverUrl,
  );
  // Both long and short paths so legacy and new links both work.
  writePage(buildDir, 'articles/${a.sourceName}/${a.localId}', html);
  writePage(buildDir, 'a/${a.sourceName}/${a.localId}', html);
}

bool _isShareableImageUrl(String? url) {
  if (url == null) return false;
  final t = url.trim();
  if (t.isEmpty) return false;
  // Crawlers want absolute https URLs.
  return t.startsWith('https://');
}

const _months = [
  'sty', 'lut', 'mar', 'kwi', 'maj', 'cze',
  'lip', 'sie', 'wrz', 'paź', 'lis', 'gru'
];
String _formatDate(DateTime d) =>
    '${d.day} ${_months[d.month - 1]} ${d.year} A.D.';

// =========================================================================
// ZHR (azymut, pojutrze): paginated Atom feed → localId from item.id "?p=N",
//                          og:image scraped from the article's HTML page.
// =========================================================================

const _zhrFullPageSize = 40;

Future<List<_Article>> _fetchZhr(String sourceName, String feedBase) async {
  final all = <_Article>[];
  final unescape = HtmlUnescape();

  for (int page = 0;; page++) {
    final raw = await curlGet('$feedBase?paged=$page');
    if (raw == null || raw.trim().isEmpty) break;

    AtomFeed feed;
    try {
      feed = AtomFeed.parse(unescape.convert(raw));
    } catch (e) {
      stderr.writeln('$sourceName page $page: AtomFeed.parse failed: $e');
      break;
    }
    if (feed.items.isEmpty) break;

    final imageUrls = await Future.wait(
        feed.items.map((it) => _extractZhrCoverFromItem(it)));

    for (int i = 0; i < feed.items.length; i++) {
      final a = _zhrAtomToArticle(sourceName, feed.items[i], imageUrls[i]);
      if (a != null) all.add(a);
    }

    final isLastPage = feed.items.length < _zhrFullPageSize;
    if (isLastPage) break;
  }
  return all;
}

_Article? _zhrAtomToArticle(String sourceName, AtomItem item, String? imageUrl) {
  try {
    final id = item.id;
    if (id == null || !id.contains('?p=')) return null;
    final localId = id.split('?p=')[1];
    final title = item.title;
    final author = item.authors.isNotEmpty ? item.authors[0].name : null;
    final published = item.published;
    if (title == null || author == null || published == null) return null;
    final date = DateTime.tryParse(published);
    if (date == null) return null;
    return _Article(
      sourceName: sourceName,
      localId: localId,
      title: title,
      author: author,
      date: date,
      imageUrl: imageUrl,
    );
  } catch (_) {
    return null;
  }
}

Future<String?> _extractZhrCoverFromItem(AtomItem item) async {
  if (item.links.isEmpty) return null;
  final link = item.links[0].href;
  if (link == null) return null;
  final html = await curlGet(link);
  if (html == null) return null;
  return _extractOgImage(html);
}

String? _extractOgImage(String html) {
  final m = RegExp(r'<meta\s+property="og:image"\s+content="([^"]+)"')
      .firstMatch(html);
  return m?.group(1);
}

// =========================================================================
// HarcApp: GitLab tree API for index, raw blob for each article (JSON).
// =========================================================================

const _harcAppExt = 'hrcpartcl';
const _harcAppIndexUrl =
    'https://gitlab.com/api/v4/projects/n3o2k7i8ch5%2Fharcapp_data/repository/tree?path=articles&per_page=100';
String _harcAppArticleUrl(String localId) =>
    'https://gitlab.com/n3o2k7i8ch5/harcapp_data/-/raw/master/articles/$localId.$_harcAppExt';

Future<List<_Article>> _fetchHarcApp() async {
  final indexJson = await curlGet(_harcAppIndexUrl);
  if (indexJson == null) return const [];

  final List<dynamic> entries;
  try {
    entries = jsonDecode(indexJson) as List<dynamic>;
  } catch (e) {
    stderr.writeln('harcApp index: invalid JSON: $e');
    return const [];
  }

  final localIds = <String>[];
  for (final entry in entries) {
    final name = (entry as Map)['name'] as String?;
    if (name == null) continue;
    if (!name.endsWith('.$_harcAppExt')) continue;
    localIds.add(name.substring(0, name.length - _harcAppExt.length - 1));
  }

  final fetched = await Future.wait(localIds.map(_fetchHarcAppOne));
  return fetched.whereType<_Article>().toList();
}

Future<_Article?> _fetchHarcAppOne(String localId) async {
  final raw = await curlGet(_harcAppArticleUrl(localId));
  if (raw == null) return null;
  Map<dynamic, dynamic> json;
  try {
    json = jsonDecode(raw) as Map<dynamic, dynamic>;
  } catch (_) {
    return null;
  }
  final title = json['title'] as String?;
  final author = json['author'] as String?;
  final dateStr = json['date'] as String?;
  if (title == null || author == null || dateStr == null) return null;
  final date = DateTime.tryParse(dateStr);
  if (date == null) return null;
  return _Article(
    sourceName: 'harcApp',
    localId: localId,
    title: title,
    author: author,
    date: date,
    imageUrl: json['imageUrl'] as String?,
  );
}
