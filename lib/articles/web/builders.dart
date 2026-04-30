import 'package:flutter/material.dart';
import 'package:harcapp_core/harcthought/articles/model/article.dart';
import 'package:harcapp_web/articles/web/cover_image.dart';
import 'package:harcapp_web/articles/web/network_image.dart';

/// `coverBuilder` for [ArticleRenderers]. Picks the right cover renderer
/// per article:
///   * If the article carries a non-empty `imageUrl` (HarcApp from JSON, or
///     ZHR after lazy worker resolution caches it on a previous load), the
///     URL is rendered directly via [WebNetworkImage].
///   * Otherwise (e.g. ZHR first-time view), [WebCoverImage] kicks off the
///     cover worker to scrape `og:image` from the article HTML, caches the
///     result in IDB, and renders via [WebNetworkImage] when ready.
Widget webCoverBuilder(CoreArticle article) {
  final url = article.imageUrl;
  if (url != null && url.isNotEmpty) {
    return WebNetworkImage(url: url);
  }
  return WebCoverImage(article: article, big: true);
}

/// `imageBuilder` for [ArticleRenderers]. Inline article images (
/// [PictureArticleElement.link], plus `<img>` tags rendered by
/// [CustomArticleElementWidget]) come with a known URL — render via
/// [WebNetworkImage] which embeds a native `<img>` through HtmlElementView,
/// bypassing CORS that would otherwise block [CachedNetworkImage].
Widget webImageBuilder(String url) => WebNetworkImage(url: url);
