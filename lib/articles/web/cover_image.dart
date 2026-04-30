import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:harcapp_core/harcthought/articles/model/article.dart';
import 'package:harcapp_core/harcthought/articles/model/article_source.dart';
import 'package:harcapp_core/harcthought/articles/thumbnail/article_cover_widget.dart';
import 'package:harcapp_core/logger.dart';
import 'package:harcapp_web/articles/web/network_image.dart';
import 'package:harcapp_web/articles/workers/article_cover_worker.dart';
import 'package:harcapp_web/idb.dart';
import 'package:isolate_manager/isolate_manager.dart';

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

/// Web-specific implementation of an article cover. Asks the cover worker
/// for the og:image URL (cached in IDB), then renders it via
/// [WebNetworkImage] (HtmlElementView + `<img>` + Flutter [IgnorePointer]
/// for click-through to the article card's button).
class WebCoverImage extends StatefulWidget {
  final CoreArticle article;

  const WebCoverImage({super.key, required this.article});

  @override
  State<WebCoverImage> createState() => _WebCoverImageState();
}

class _WebCoverImageState extends State<WebCoverImage> {
  String? _resolvedUrl;
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
    setState(() => _resolvedUrl = url);
  }

  @override
  Widget build(BuildContext context) {
    if (_resolveFailed) return const CoverProblemWidget();
    final url = _resolvedUrl;
    if (url == null) return const WebImageLoadingPlaceholder();
    return WebNetworkImage(url: url);
  }
}
