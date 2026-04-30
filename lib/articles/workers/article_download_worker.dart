import 'dart:async';
import 'dart:convert';

import 'package:harcapp_core/harcthought/articles/model/article_data.dart';
import 'package:harcapp_core/harcthought/articles/model/article_source.dart';
import 'package:harcapp_core/harcthought/articles/source_article_loader.dart';
import 'package:isolate_manager/isolate_manager.dart';

class _WorkerHarcAppLoader extends BaseArticleHarcAppLoader {
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

class _WorkerAzymutLoader extends BaseArticleAzymutLoader {
  const _WorkerAzymutLoader();
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

class _WorkerPojutrzeLoader extends BaseArticlePojutrzeLoader {
  const _WorkerPojutrzeLoader();
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

BaseSourceArticleLoader _stubLoaderFor(ArticleSource source) {
  switch (source) {
    case ArticleSource.harcApp:
      return _WorkerHarcAppLoader();
    case ArticleSource.azymut:
      return const _WorkerAzymutLoader();
    case ArticleSource.pojutrze:
      return const _WorkerPojutrzeLoader();
  }
}

@pragma('vm:entry-point')
@isolateManagerCustomWorker
void articleDownloadWorker(dynamic params) {
  IsolateManagerFunction.customFunction<String, String>(
    params,
    onEvent: (controller, message) async {
      final args = jsonDecode(message) as Map;
      final source = ArticleSource.values.byName(args['source'] as String);
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
    },
  );
}
