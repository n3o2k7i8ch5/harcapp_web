import 'dart:async';
import 'dart:convert';
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:harcapp_core/harcthought/articles/model/article.dart';
import 'package:harcapp_core/harcthought/articles/model/article_source.dart';
import 'package:harcapp_core/logger.dart';
import 'package:harcapp_web/articles/cover_worker.dart';
import 'package:harcapp_web/idb.dart';
import 'package:isolate_manager/isolate_manager.dart';
import 'package:web/web.dart' as web;

IsolateManager<Map, String>? _coverManager;

IsolateManager<Map, String> _getCoverManager() => _coverManager ??=
    IsolateManager<Map, String>.createCustom(
      articleCoverWorker,
      workerName: 'articleCoverWorker',
      concurrent: 3,
    );

bool _supportsCoverWorker(ArticleSource source) =>
    source == ArticleSource.azymut || source == ArticleSource.pojutrze;

const Duration _coverWorkerTimeout = Duration(seconds: 30);

/// Resolve the og:image URL for an article. Order:
///   1. The article already carries an `imageUrl` (e.g. HarcApp from JSON).
///   2. IDB cache (set by previous worker calls in this app's history).
///   3. Cover worker fetches the article HTML and extracts og:image.
Future<String?> _resolveCoverUrl(CoreArticle article) async {
  if (article.imageUrl != null && article.imageUrl!.isNotEmpty) {
    return article.imageUrl;
  }
  if (!_supportsCoverWorker(article.source)) return null;

  final cached = await IDB.getCoverImageUrl(article.source, article.localId);
  if (cached != null && cached.isNotEmpty) return cached;

  try {
    final result = await _getCoverManager()
        .compute(jsonEncode({'link': article.link}))
        .timeout(_coverWorkerTimeout);
    if (result['success'] != true) {
      logger.w('Cover worker failed for ${article.source.name} '
          '${article.localId}: ${result['debug'] ?? 'no debug'}');
      return null;
    }
    final url = result['imageUrl'] as String?;
    if (url != null && url.isNotEmpty) {
      await IDB.putCoverImageUrl(article.source, article.localId, url);
      return url;
    }
  } catch (e) {
    logger.w('Cover worker exception for ${article.source.name} '
        '${article.localId}: $e');
  }
  return null;
}

/// Renders an article cover image on Flutter web by embedding a raw
/// `<img>` HTMLImageElement via [HtmlElementView]. This bypasses Flutter's
/// XHR-based image loaders (which would CORS-fail against ZHR servers) and
/// lets the browser load and decode the image natively, off the main isolate.
class WebCoverImage extends StatefulWidget {
  final CoreArticle article;
  final bool big;

  const WebCoverImage({super.key, required this.article, required this.big});

  @override
  State<WebCoverImage> createState() => _WebCoverImageState();
}

class _WebCoverImageState extends State<WebCoverImage> {
  static final Map<String, String> _viewTypeForUrl = {};

  String? _resolvedViewType;
  bool _resolveFailed = false;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  Future<void> _resolve() async {
    final url = await _resolveCoverUrl(widget.article);
    if (!mounted) return;
    if (url == null) {
      setState(() => _resolveFailed = true);
      return;
    }
    setState(() => _resolvedViewType = _ensureViewTypeFor(url));
  }

  String _ensureViewTypeFor(String url) {
    final existing = _viewTypeForUrl[url];
    if (existing != null) return existing;
    final viewType = 'cover-img-${_viewTypeForUrl.length}';
    _viewTypeForUrl[url] = viewType;
    ui_web.platformViewRegistry.registerViewFactory(viewType, (int _) {
      return web.HTMLImageElement()
        ..src = url
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = 'cover'
        ..style.display = 'block';
    });
    return viewType;
  }

  @override
  Widget build(BuildContext context) {
    if (_resolveFailed) {
      return const _CoverFallbackPlaceholder(failed: true);
    }
    final viewType = _resolvedViewType;
    if (viewType == null) {
      return const _CoverFallbackPlaceholder(failed: false);
    }
    return HtmlElementView(viewType: viewType);
  }
}

class _CoverFallbackPlaceholder extends StatelessWidget {
  final bool failed;
  const _CoverFallbackPlaceholder({required this.failed});

  @override
  Widget build(BuildContext context) => Container(
        color: failed ? Colors.grey.shade300 : Colors.grey.shade200,
        alignment: Alignment.center,
        child: failed
            ? const Icon(Icons.image_not_supported, color: Colors.grey)
            : const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
      );
}
