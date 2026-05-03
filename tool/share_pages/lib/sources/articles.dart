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

  Map<String, dynamic> toJson() => {
    'title': title,
    'author': author,
    'date': date.toIso8601String(),
    'imageUrl': imageUrl,
  };

  static _Article fromJson(
          String sourceName, String localId, Map<dynamic, dynamic> json) =>
      _Article(
        sourceName: sourceName,
        localId: localId,
        title: json['title'] as String,
        author: json['author'] as String,
        date: DateTime.parse(json['date'] as String),
        imageUrl: json['imageUrl'] as String?,
      );
}

/// Persistent on-disk cache of article records, keyed by source + localId.
/// Skips per-article curls (HarcApp JSON, ZHR HTML scrape for og:image) on
/// re-runs. The cache file is committed to the repo so deploys benefit from
/// previous runs' work.
class _ArticleCache {
  final Map<String, Map<String, _Article>> _bySource = {};
  final String _path;

  _ArticleCache(this._path);

  static _ArticleCache load(String path) {
    final cache = _ArticleCache(path);
    final file = File(path);
    if (!file.existsSync()) return cache;
    try {
      final data = jsonDecode(file.readAsStringSync()) as Map<dynamic, dynamic>;
      data.forEach((src, ids) {
        final m = <String, _Article>{};
        (ids as Map).forEach((id, json) {
          m[id as String] =
              _Article.fromJson(src as String, id as String, json as Map);
        });
        cache._bySource[src as String] = m;
      });
    } catch (e) {
      stderr.writeln('cache load failed, starting fresh: $e');
    }
    return cache;
  }

  _Article? get(String source, String localId) =>
      _bySource[source]?[localId];

  void put(_Article a) {
    _bySource.putIfAbsent(a.sourceName, () => {})[a.localId] = a;
  }

  void save() {
    final file = File(_path);
    file.parent.createSync(recursive: true);
    // Sorted output → deterministic diffs, friendly for git review.
    final sortedSources = _bySource.keys.toList()..sort();
    final json = <String, Map<String, dynamic>>{};
    for (final src in sortedSources) {
      final m = _bySource[src]!;
      final sortedIds = m.keys.toList()..sort();
      final out = <String, dynamic>{};
      for (final id in sortedIds) {
        out[id] = m[id]!.toJson();
      }
      json[src] = out;
    }
    const encoder = JsonEncoder.withIndent('  ');
    file.writeAsStringSync('${encoder.convert(json)}\n');
  }

  int get totalCount =>
      _bySource.values.fold(0, (sum, m) => sum + m.length);
}

Future<int> generateArticlePages({
  required String baseUrl,
  required String buildDir,
  required ShareTemplate template,
  required String fallbackCoverUrl,
  required String cachePath,
}) async {
  final cache = _ArticleCache.load(cachePath);
  final cacheSizeBefore = cache.totalCount;

  final results = await Future.wait([
    _fetchZhr('azymut', 'https://azymut.zhr.pl/feed/atom/', cache),
    _fetchZhr('pojutrze', 'https://pojutrze.zhr.pl/feed/atom/', cache),
    _fetchHarcApp(cache),
  ]);

  cache.save();
  stdout.writeln('article cache: ${cacheSizeBefore} → ${cache.totalCount} '
      '(+${cache.totalCount - cacheSizeBefore} new)');

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
// Feed is always re-fetched (cheap, gives fresh title/author/date). Per-
// article HTML scrape is skipped if cache already has imageUrl.
// =========================================================================

const _zhrFullPageSize = 40;

Future<List<_Article>> _fetchZhr(
    String sourceName, String feedBase, _ArticleCache cache) async {
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

    final articles = await Future.wait(
        feed.items.map((it) => _resolveZhrArticle(sourceName, it, cache)));

    for (final a in articles) {
      if (a == null) continue;
      cache.put(a);
      all.add(a);
    }

    final isLastPage = feed.items.length < _zhrFullPageSize;
    if (isLastPage) break;
  }
  return all;
}

Future<_Article?> _resolveZhrArticle(
    String sourceName, AtomItem item, _ArticleCache cache) async {
  final id = item.id;
  if (id == null || !id.contains('?p=')) return null;
  final localId = id.split('?p=')[1];

  final title = item.title;
  final author = item.authors.isNotEmpty ? item.authors[0].name : null;
  final published = item.published;
  if (title == null || author == null || published == null) return null;
  final date = DateTime.tryParse(published);
  if (date == null) return null;

  // Use cached og:image if we have one — that's the expensive scrape we skip.
  final cached = cache.get(sourceName, localId);
  String? imageUrl = cached?.imageUrl;
  if (imageUrl == null && item.links.isNotEmpty) {
    final link = item.links[0].href;
    if (link != null) {
      final html = await curlGet(link);
      if (html != null) imageUrl = _extractOgImage(html);
    }
  }

  return _Article(
    sourceName: sourceName,
    localId: localId,
    title: title,
    author: author,
    date: date,
    imageUrl: imageUrl,
  );
}

String? _extractOgImage(String html) {
  final m = RegExp(r'<meta\s+property="og:image"\s+content="([^"]+)"')
      .firstMatch(html);
  return m?.group(1);
}

// =========================================================================
// HarcApp: GitLab tree API for index, raw blob for each article (JSON).
// Index is always re-fetched. Per-article curl is skipped entirely if cached.
// =========================================================================

const _harcAppExt = 'hrcpartcl';
const _harcAppIndexUrl =
    'https://gitlab.com/api/v4/projects/n3o2k7i8ch5%2Fharcapp_data/repository/tree?path=articles&per_page=100';
String _harcAppArticleUrl(String localId) =>
    'https://gitlab.com/n3o2k7i8ch5/harcapp_data/-/raw/master/articles/$localId.$_harcAppExt';

Future<List<_Article>> _fetchHarcApp(_ArticleCache cache) async {
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

  final fetched = await Future.wait(localIds.map((id) => _resolveHarcAppOne(id, cache)));
  return fetched.whereType<_Article>().toList();
}

Future<_Article?> _resolveHarcAppOne(String localId, _ArticleCache cache) async {
  final cached = cache.get('harcApp', localId);
  if (cached != null) return cached;

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
  final article = _Article(
    sourceName: 'harcApp',
    localId: localId,
    title: title,
    author: author,
    date: date,
    imageUrl: json['imageUrl'] as String?,
  );
  cache.put(article);
  return article;
}
