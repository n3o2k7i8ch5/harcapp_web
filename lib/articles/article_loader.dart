import 'dart:async';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:harcapp_core/comm_classes/single_computer/single_computer.dart';
import 'package:harcapp_core/comm_classes/single_computer/single_computer_listener.dart';
import 'package:harcapp_core/harcthought/articles/model/article_data.dart';
import 'package:harcapp_core/harcthought/articles/model/article_source.dart';
import 'package:harcapp_core/harcthought/articles/source_article_loader.dart';
import 'package:harcapp_web/articles/models/azymut.dart';
import 'package:harcapp_web/articles/models/harcapp.dart';
import 'package:harcapp_web/articles/models/pojutrze.dart';
import 'package:harcapp_web/articles/source_article_loader.dart';

// TODO:
// Make this common also for the harcapp repo.

// There is an issue currently. If someone calls `ArticleLoader` with only one
// source, and while it's running, calls it again with another source, the first
// source will finish and the second will be ignored.
// Solve this by creating multiple instances of `ArticleLoader` for each source (and one for all sources).

ArticleLoader articleLoader = ArticleLoader();

class ArticleLoaderListener extends SingleComputerListener<String>{

  final FutureOr<void> Function(ArticleDataOrList articleData)? onArticleData;

  ArticleLoaderListener({
    super.onStart,
    super.onError,
    super.onEnd,
    this.onArticleData
  });

}

class ArticleLoader extends SingleComputer<String, ArticleLoaderListener>{

  static _initNewLoaded(){
    Map<ArticleSource, bool> newLoaded = {};
    for(ArticleSource source in ArticleSource.values)
      newLoaded[source] = false;

    return newLoaded;
  }

  static Map<ArticleSource, bool> newLoaded = _initNewLoaded();

  static bool get allLoaded => newLoaded.values.every((element) => element);

  static List<ArticleSource> get unloadedArticleSources => ArticleSource.values.where((source) => !newLoaded[source]!).toList();

  bool isSourceRunning(ArticleSource source) => running && articleLoader.restrictToSources.contains(source);

  @override
  String get computerName => 'ArticleLoader';

  static Future<String?> newestLocalIdsSeen(ArticleSource source) async{
    return await sourceArticleLoaders[source]!.getNewestLocalIdSeen();
  }

  static Future<String?> oldestLocalIdsSeen(ArticleSource source) async{
    return await sourceArticleLoaders[source]!.getOldestLocalIdSeen();
  }

  static Future<bool> isAllHistoryLoaded(ArticleSource source) async{
    return await sourceArticleLoaders[source]!.getIsAllHistoryLoaded();
  }

  static Map<ArticleSource, BaseSourceArticleLoader> sourceArticleLoaders = {
    ArticleSource.harcApp: articleHarcAppLoader,
    ArticleSource.azymut: articleAzymutLoader,
    ArticleSource.pojutrze: articlePojutrzeLoader,
  };

  static Future<void> addAllArticlesAndCache(ArticleSource source, List<ArticleData> articleDataList) async {
    switch(source){
      case ArticleSource.harcApp:
        List<ArticleHarcApp> articles = articleDataList.map((articleData) => ArticleHarcApp.fromData(articleData)).toList().cast<ArticleHarcApp>();
        ArticleHarcApp.addAll(articles);
        break;
      case ArticleSource.azymut:
        List<ArticleAzymut> articles = articleDataList.map((articleData) => ArticleAzymut.fromData(articleData)).toList().cast<ArticleAzymut>();
        ArticleAzymut.addAll(articles);
        break;
      case ArticleSource.pojutrze:
        List<ArticlePojutrze> articles = articleDataList.map((articleData) => ArticlePojutrze.fromData(articleData)).toList().cast<ArticlePojutrze>();
        ArticlePojutrze.addAll(articles);
        break;
    }
    await sourceArticleLoaders[source]!.cacheAll(articleDataList);
  }

  static Future<void> _downloadFromStream(
      ( dynamic port,
        ArticleSource source,
        String? newestLocalIdsSeen,
        String? oldestLocalIdSeen,
        bool isAllHistoryLoaded
      ) args
  ) async {
    dynamic sendPort = args.$1;
    ArticleSource source = args.$2;
    String? newestLocalIdsSeen = args.$3;
    String? oldestLocalIdSeen = args.$4;
    bool isAllHistoryLoaded = args.$5;

    BaseSourceArticleLoader loader = sourceArticleLoaders[source]!;
    await loader.download(
        newestLocalIdsSeen,
        oldestLocalIdSeen,
        isAllHistoryLoaded
    ).forEach(kIsWeb ? sendPort.add : sendPort.send);
  }

  static Future<String?> _downloadSource(
      ArticleSource source,
      {FutureOr Function(ArticleDataOrList articleData)? onArticleData}
      ) async {

    String? updatedNewestLocalIdsSeen = null;
    void onDataReceived(dynamic data) async {

      if(!(data is (ArticleDataOrList, String?)))
        return;

      await onArticleData?.call(data.$1);
      if(data.$2 != null)
        updatedNewestLocalIdsSeen = data.$2!;
    }

    late StreamController<dynamic> webMockPort;
    late ReceivePort receivePort;

    if(kIsWeb){
      webMockPort = StreamController<dynamic>();
      webMockPort.stream.listen(onDataReceived);
    } else{
      receivePort = ReceivePort();
      receivePort.listen(onDataReceived);
    }

    var args = (
      kIsWeb ? webMockPort : receivePort.sendPort,
      source,
      await newestLocalIdsSeen(source),
      await oldestLocalIdsSeen(source),
      await isAllHistoryLoaded(source)
    );

    await compute(_downloadFromStream, args);

    return updatedNewestLocalIdsSeen;

  }

  FutureOr<void> _callOnArticleListeners(ArticleDataOrList articleData) async {
    for(ArticleLoaderListener listener in listeners)
        await listener.onArticleData?.call(articleData);
  }

  late bool all;
  late List<ArticleSource> restrictToSources;

  @override
  Future<bool> run({
    bool awaitFinish = false,
    bool all=false,
    List<ArticleSource> restrictToSources = ArticleSource.values
  }){
    this.all = all;
    this.restrictToSources = restrictToSources;
    return super.run(awaitFinish: awaitFinish);
  }

  @override
  Future<void> perform() async {

    List<ArticleSource> sourcesToLoad = Set.from(unloadedArticleSources).intersection(Set.from(restrictToSources)).toList().cast();

    List<Future> futures = [];
    for(ArticleSource source in sourcesToLoad)
      futures.add(
          _downloadSource(
              source,
              onArticleData: (ArticleDataOrList dataOrList) async {
                await addAllArticlesAndCache(source, dataOrList.toList());
                await _callOnArticleListeners(dataOrList);
              }
          )
      );

    List updatedNewestLocalIdsSeen = await Future.wait(futures);
    for(int i=0; i<sourcesToLoad.length; i++) {
      ArticleSource source = sourcesToLoad[i];
      if(updatedNewestLocalIdsSeen[i] == null) continue;
      sourceArticleLoaders[source]!.saveNewestLocalIdSeen(updatedNewestLocalIdsSeen[i]);
      newLoaded[source] = true;
    }

  }

}