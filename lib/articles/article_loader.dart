import 'dart:async';

import 'package:harcapp_core/harcthought/articles/article_loader.dart';
import 'package:harcapp_core/harcthought/articles/model/article_data.dart';
import 'package:harcapp_core/harcthought/articles/model/article_source.dart';
import 'package:harcapp_web/articles/models/azymut.dart';
import 'package:harcapp_web/articles/models/harcapp.dart';
import 'package:harcapp_web/articles/models/pojutrze.dart';
import 'package:harcapp_web/idb.dart';
import 'package:harcapp_web/logger.dart';

mixin _CacheMixin on BaseArticleLoader{

  void saveNewestLocalIdSeen(String localId) => IDB.putNewestSeenLocalId(source, localId);

  @override
  Future<ArticleData?> getCached(String localId) async {
    try{
      Map? jsonMap = await IDB.getContent(source, localId);
      if(jsonMap == null) return null;
      return ArticleData.fromJson(localId, source, jsonMap);
    } catch(_){
      return null;
    }
  }

  @override
  Future<List<String>> getAllCachedIds() => IDB.getAllContentKeys(source);

  @override
  Future<void> cache(ArticleData articleData) async {
    await IDB.putContent(source, articleData.localId, articleData.toJson());
    logger.d("Article ${source.name} ${articleData.localId} cached.");
  }

}

class ArticleHarcAppLoader extends BaseArticleHarcAppLoader with _CacheMixin{}
class ArticleAzymutLoader extends BaseArticleAzymutLoader with _CacheMixin{}
class ArticlePojutrzeLoader extends BaseArticlePojutrzeLoader with _CacheMixin{}

ArticleHarcAppLoader articleHarcAppLoader = ArticleHarcAppLoader();
ArticleAzymutLoader articleAzymutLoader = ArticleAzymutLoader();
ArticlePojutrzeLoader articlePojutrzeLoader = ArticlePojutrzeLoader();

Future<void> downloadAllArticles() async {
  Future futureArticleHarcApp = articleHarcAppLoader.download(await IDB.getNewestSeenLocalId(ArticleSource.harcApp));
  Future futureArticleAzymut = articleAzymutLoader.download(await IDB.getNewestSeenLocalId(ArticleSource.azymut));
  Future futureArticlePojutrze = articlePojutrzeLoader.download(await IDB.getNewestSeenLocalId(ArticleSource.pojutrze));

  List result = await Future.wait([futureArticleHarcApp, futureArticleAzymut, futureArticlePojutrze]);

  var (articleDataHarcApp, newestLocalIdSeenHarcApp) = result[0];
  var (articleDataAzymut, newestLocalIdSeenAzymut) = result[1];
  var (articleDataPojutrze, newestLocalIdSeenPojutrze) = result[2];

  if(articleDataHarcApp != null) articleHarcAppLoader.cacheAll(articleDataHarcApp);
  if(articleDataAzymut != null) articleAzymutLoader.cacheAll(articleDataAzymut);
  if(articleDataPojutrze != null) articlePojutrzeLoader.cacheAll(articleDataPojutrze);

  if(newestLocalIdSeenHarcApp != null) articleHarcAppLoader.saveNewestLocalIdSeen(newestLocalIdSeenHarcApp);
  if(newestLocalIdSeenAzymut != null) articleAzymutLoader.saveNewestLocalIdSeen(newestLocalIdSeenAzymut);
  if(newestLocalIdSeenPojutrze != null) articlePojutrzeLoader.saveNewestLocalIdSeen(newestLocalIdSeenPojutrze);

  List<ArticleHarcApp> articlesHarcApp = articleDataHarcApp?.map((articleData) => ArticleHarcApp.fromData(articleData)).toList().cast<ArticleHarcApp>()??<ArticleHarcApp>[];
  List<ArticleAzymut> articlesAzymut = articleDataAzymut?.map((articleData) => ArticleAzymut.fromData(articleData)).toList().cast<ArticleAzymut>()??<ArticleAzymut>[];
  List<ArticlePojutrze> articlesPojutrze = articleDataPojutrze?.map((articleData) => ArticlePojutrze.fromData(articleData)).toList().cast<ArticlePojutrze>()??<ArticlePojutrze>[];

  ArticleHarcApp.all = articlesHarcApp;
  ArticleAzymut.all = articlesAzymut;
  ArticlePojutrze.all = articlesPojutrze;

}

