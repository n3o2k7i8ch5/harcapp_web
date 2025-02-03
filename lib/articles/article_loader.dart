import 'dart:async';

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
// Solve this by creating multuple instances of `ArticleLoader` for each source (and one for all sources).

ArticleLoader articleLoader = ArticleLoader();

class ArticleLoader extends SingleComputer<String, SingleComputerListener<String>>{

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

  Future<Map<ArticleSource, String?>> get newestLocalIdsSeen async{
    Map<ArticleSource, String?> newestLocalIdsSeen = {};
    for(ArticleSource source in ArticleSource.values)
      newestLocalIdsSeen[source] = await sourceArticleLoaders[source]!.getNewestLocalIdSeen();

    return newestLocalIdsSeen;
  }

  static Map<ArticleSource, BaseSourceArticleLoader> sourceArticleLoaders = {
    ArticleSource.harcApp: articleHarcAppLoader,
    ArticleSource.azymut: articleAzymutLoader,
    ArticleSource.pojutrze: articlePojutrzeLoader,
  };

  static addAllArticlesAndCache(ArticleSource source, List<ArticleData> articleDataList){
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
    sourceArticleLoaders[source]!.cacheAll(articleDataList);
    newLoaded[source] = true;
  }

  static Future<Map<ArticleSource, (List<ArticleData>?, String?)>> _download(
    (List<ArticleSource>, Map<ArticleSource, String?>) args
  ) async {
    List<ArticleSource> sources = args.$1;
    Map<ArticleSource, String?> newestLocalIdsSeen = args.$2;

    List<Future> futures = [];
    for(ArticleSource source in sources)
      futures.add(sourceArticleLoaders[source]!.download(newestLocalIdsSeen[source]));

    List downloadedArticleData = await Future.wait(futures);

    Map<ArticleSource, (List<ArticleData>?, String?)> result = {};
    for(int i=0; i<sources.length; i++)
      result[sources[i]] = downloadedArticleData[i];

    return result;
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

    List<ArticleSource> sources = Set.from(unloadedArticleSources).intersection(Set.from(restrictToSources)).toList().cast();

    Map<ArticleSource, (List<ArticleData>?, String?)> newArticleData = await compute(
        _download,
        (sources, await newestLocalIdsSeen)
    );

    for(ArticleSource source in newArticleData.keys){
      List<ArticleData>? articleData = newArticleData[source]!.$1;
      String? updatedNewestLocalIdSeen = newArticleData[source]!.$2;

      if(articleData == null) continue;

      switch(source){
        case ArticleSource.harcApp:
          List<ArticleHarcApp> articles = articleData.map((data) => ArticleHarcApp.fromData(data)).toList().cast<ArticleHarcApp>();
          ArticleHarcApp.addAll(articles);
          break;
        case ArticleSource.azymut:
          List<ArticleAzymut> articles = articleData.map((data) => ArticleAzymut.fromData(data)).toList().cast<ArticleAzymut>();
          ArticleAzymut.addAll(articles);
          break;
        case ArticleSource.pojutrze:
          List<ArticlePojutrze> articles = articleData.map((data) => ArticlePojutrze.fromData(data)).toList().cast<ArticlePojutrze>();
          ArticlePojutrze.addAll(articles);
          break;
      }
      sourceArticleLoaders[source]!.cacheAll(articleData);
      if(updatedNewestLocalIdSeen != null)
        sourceArticleLoaders[source]!.saveNewestLocalIdSeen(updatedNewestLocalIdSeen);
      newLoaded[source] = true;

    }

  }

}