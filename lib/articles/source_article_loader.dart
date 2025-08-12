import 'dart:async';

import 'package:harcapp_core/harcthought/articles/source_article_loader.dart';
import 'package:harcapp_core/harcthought/articles/model/article_data.dart';
import 'package:harcapp_core/logger.dart';
import 'package:harcapp_web/idb.dart';

mixin _CacheMixin on BaseSourceArticleLoader{

  @override
  Future<ArticleData?> getCached(String localId) async {
    try{
      Map? jsonMap = await IDB.getContent(source, localId);
      if(jsonMap == null) return null;
      return ArticleData.fromJsonMap(localId, source, jsonMap);
    } catch(_){
      return null;
    }
  }

  @override
  Future<List<String>> getAllCachedIds() => IDB.getAllContentKeys(source);

  @override
  Future<void> cache(ArticleData articleData) async {
    await IDB.putContent(source, articleData.localId, articleData.toJsonMap());
    logger.d("Article ${source.name} ${articleData.localId} cached.");
  }

  @override
  Future<void> cacheAll(List<ArticleData> data) async {
    Map<String, dynamic> _data = Map.fromEntries(data.map((d) => MapEntry(d.localId, d.toJsonMap())));
    await IDB.putAllContent(source, _data);
    logger.d("Articles ${source.name} ${data.map((d) => d.localId).toList()} cached.");
  }

  @override
  Future<void> saveNewestLocalIdSeen(String localId) async {
    await IDB.putNewestSeenLocalId(source, localId);
    logger.d("Newest seen local id for ${source.name} saved: $localId");
  }

  @override
  Future<String?> getNewestLocalIdSeen() => IDB.getNewestSeenLocalId(source);

  @override
  Future<void> saveOldestLocalIdSeen(String localId) async {
    await IDB.putOldestSeenLocalId(source, localId);
    logger.d("Oldest seen local id for ${source.name} saved: $localId");
  }

  @override
  Future<String?> getOldestLocalIdSeen() => IDB.getOldestSeenLocalId(source);

  @override
  FutureOr<void> saveIsAllHistoryLoaded(bool value) async {
    await IDB.saveIsAllHistoryLoaded(source, value);
    logger.d("Is all history loaded for ${source.name} saved: $value");
  }

  @override
  FutureOr<bool> getIsAllHistoryLoaded() => IDB.getIsAllHistoryLoaded(source);
}

class ArticleHarcAppLoader extends BaseArticleHarcAppLoader with _CacheMixin{}
class ArticleAzymutLoader extends BaseArticleAzymutLoader with _CacheMixin{}
class ArticlePojutrzeLoader extends BaseArticlePojutrzeLoader with _CacheMixin{}

ArticleHarcAppLoader articleHarcAppLoader = ArticleHarcAppLoader();
ArticleAzymutLoader articleAzymutLoader = ArticleAzymutLoader();
ArticlePojutrzeLoader articlePojutrzeLoader = ArticlePojutrzeLoader();
