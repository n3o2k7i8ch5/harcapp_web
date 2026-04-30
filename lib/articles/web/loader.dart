import 'dart:async';
import 'dart:convert';

import 'package:harcapp_core/harcthought/articles/article_loader.dart';
import 'package:harcapp_core/harcthought/articles/model/article_data.dart';
import 'package:harcapp_core/harcthought/articles/model/article_source.dart';
import 'package:harcapp_core/harcthought/articles/source_article_loader.dart';
import 'package:isolate_manager/isolate_manager.dart';

import 'article_worker.dart';

class WebArticleLoader extends ArticleLoader {
  WebArticleLoader({
    required super.sourceArticleLoaders,
    required super.onNewArticles,
  });

  IsolateManager<String, String>? _manager;

  IsolateManager<String, String> _getManager() => _manager ??=
      IsolateManager<String, String>.createCustom(
        articleDownloadWorker,
        concurrent: ArticleSource.values.length,
      );

  Future<(String?, String?, bool?)> _downloadSourceViaWorker(
    ArticleSource source, {
    required bool fullReload,
    required FutureOr<void> Function(ArticleDataOrList) onArticleData,
  }) async {
    final mainLoader = sourceArticleLoaders[source]!;

    String? updatedNewestLocalIdSeen;
    String? updatedOldestLocalIdSeen;
    bool? updatedIsAllHistoryLoaded;

    final args = jsonEncode({
      'source': source.name,
      'newestLocalIdSeen':
          fullReload ? null : await mainLoader.getNewestLocalIdSeen(),
      'oldestLocalIdSeen':
          fullReload ? null : await mainLoader.getOldestLocalIdSeen(),
      'isAllHistoryLoaded':
          fullReload ? false : await mainLoader.getIsAllHistoryLoaded(),
    });

    final pendingCallbacks = <Future<void>>[];

    await _getManager().compute(args, callback: (value) {
      try {
        final decoded = jsonDecode(value) as Map;
        if (decoded['kind'] == 'end') return true;
        if (decoded['kind'] != 'data') return false;

        final articles = (decoded['articles'] as List).map((entry) {
          final m = entry as Map;
          final localId = m['localId'] as String;
          final jsonMap = m['jsonMap'] as Map;
          return ArticleData.fromJsonMap(localId, source, jsonMap);
        }).toList();

        pendingCallbacks.add(Future.sync(
            () => onArticleData(ArticleDataOrList.asList(articles))));

        if (decoded['newestLocalIdSeen'] != null) {
          updatedNewestLocalIdSeen = decoded['newestLocalIdSeen'] as String;
        }
        if (decoded['oldestLocalIdSeen'] != null) {
          updatedOldestLocalIdSeen = decoded['oldestLocalIdSeen'] as String;
        }
        if (decoded['isAllHistoryLoaded'] != null) {
          updatedIsAllHistoryLoaded = decoded['isAllHistoryLoaded'] as bool;
        }

        return false;
      } catch (_) {
        return true;
      }
    });

    await Future.wait(pendingCallbacks);

    return (
      updatedNewestLocalIdSeen,
      updatedOldestLocalIdSeen,
      updatedIsAllHistoryLoaded,
    );
  }

  @override
  Future<void> perform() async {
    final sourcesToLoad = fullReload
        ? ArticleSource.values.toList()
        : Set<ArticleSource>.from(ArticleLoader.unloadedArticleSources)
            .intersection(Set.from(restrictToSources))
            .toList()
            .cast<ArticleSource>();

    final futures = <Future<(String?, String?, bool?)>>[];
    for (final source in sourcesToLoad) {
      futures.add(_downloadSourceViaWorker(
        source,
        fullReload: fullReload,
        onArticleData: (dataOrList) async {
          await onNewArticles(source, dataOrList.toList());
          for (final listener in listeners) {
            await listener.onArticleData?.call(dataOrList);
          }
        },
      ));
    }

    final results = await Future.wait(futures);

    for (var i = 0; i < sourcesToLoad.length; i++) {
      final source = sourcesToLoad[i];
      final (newest, oldest, isAllHist) = results[i];

      if (newest != null) {
        await sourceArticleLoaders[source]!.saveNewestLocalIdSeen(newest);
      }
      if (oldest != null) {
        await sourceArticleLoaders[source]!.saveOldestLocalIdSeen(oldest);
      }
      if (isAllHist != null) {
        await sourceArticleLoaders[source]!.saveIsAllHistoryLoaded(isAllHist);
      }

      ArticleLoader.newLoaded[source] = true;
    }
  }
}
