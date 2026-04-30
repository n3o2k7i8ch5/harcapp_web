import 'dart:async';
import 'dart:convert';

import 'package:harcapp_core/harcthought/articles/model/article_data.dart';
import 'package:harcapp_core/harcthought/articles/model/article_source.dart';
import 'package:harcapp_core/harcthought/articles/source_article_loader.dart';
import 'package:isolate_manager/isolate_manager.dart';

/// Cache/state methods on [BaseSourceArticleLoader] are abstract, but inside
/// the worker none of them are exercised at runtime — `download()` is the only
/// entry point we call, and it is self-contained (HTTP + parse). These
/// no-op overrides exist purely to make the abstract subclasses concrete.
mixin _WorkerNoopCache on BaseSourceArticleLoader {
  @override
  Future<ArticleData?> getCached(String localId) async => null;
  @override
  Future<List<String>> getAllCachedIds() async => [];
  @override
  Future<void> cache(ArticleData articleData) async {}
  @override
  Future<void> saveNewestLocalIdSeen(String localId) async {}
  @override
  Future<String?> getNewestLocalIdSeen() async => null;
  @override
  Future<void> saveOldestLocalIdSeen(String localId) async {}
  @override
  Future<String?> getOldestLocalIdSeen() async => null;
  @override
  Future<void> saveIsAllHistoryLoaded(bool value) async {}
  @override
  Future<bool> getIsAllHistoryLoaded() async => false;
}

class _WorkerHarcAppLoader extends BaseArticleHarcAppLoader
    with _WorkerNoopCache {}

class _WorkerAzymutLoader extends BaseArticleAzymutLoader
    with _WorkerNoopCache {
  _WorkerAzymutLoader();
}

class _WorkerPojutrzeLoader extends BaseArticlePojutrzeLoader
    with _WorkerNoopCache {
  _WorkerPojutrzeLoader();
}

BaseSourceArticleLoader _stubLoaderFor(ArticleSource source) {
  switch (source) {
    case ArticleSource.harcApp:
      return _WorkerHarcAppLoader();
    case ArticleSource.azymut:
      return _WorkerAzymutLoader();
    case ArticleSource.pojutrze:
      return _WorkerPojutrzeLoader();
  }
}

@pragma('vm:entry-point')
@isolateManagerCustomWorker
void articleDownloadWorker(dynamic params) {
  IsolateManagerFunction.customFunction<String, String>(
    params,
    onEvent: (controller, message) async {
      try {
        final args = jsonDecode(message) as Map;
        final source = ArticleSource.fromName(args['source'] as String)!;
        final newestLocalIdSeen = args['newestLocalIdSeen'] as String?;
        final oldestLocalIdSeen = args['oldestLocalIdSeen'] as String?;
        final isAllHistoryLoaded = args['isAllHistoryLoaded'] as bool;

        final loader = _stubLoaderFor(source);

        await for (final event in loader.download(
          newestLocalIdSeen,
          oldestLocalIdSeen,
          isAllHistoryLoaded,
        )) {
          final dataOrList = event.$1;
          final newest = event.$2;
          final oldest = event.$3;
          final isAllHist = event.$4;

          final articles = dataOrList.toList();
          controller.sendResult(jsonEncode({
            'kind': 'data',
            'articles': articles
                .map((a) => {
                      'localId': a.localId,
                      'jsonMap': a.toJsonMap(),
                    })
                .toList(),
            'newestLocalIdSeen': newest,
            'oldestLocalIdSeen': oldest,
            'isAllHistoryLoaded': isAllHist,
          }));
        }

        return jsonEncode({'kind': 'end'});
      } catch (e, st) {
        return jsonEncode({
          'kind': 'end',
          'debug': 'ERROR: $e\nstack: $st',
        });
      }
    },
  );
}
