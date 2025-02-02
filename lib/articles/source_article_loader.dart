import 'dart:async';

import 'package:harcapp_core/harcthought/articles/source_article_loader.dart';
import 'package:harcapp_core/harcthought/articles/model/article_data.dart';
import 'package:harcapp_web/idb.dart';
import 'package:harcapp_web/logger.dart';

mixin _CacheMixin on BaseSourceArticleLoader{

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

  @override
  Future<void> saveNewestLocalIdSeen(String localId) => IDB.putNewestSeenLocalId(source, localId);

  @override
  Future<String?> getNewestLocalIdSeen() => IDB.getNewestSeenLocalId(source);

}

class ArticleHarcAppLoader extends BaseArticleHarcAppLoader with _CacheMixin{}
class ArticleAzymutLoader extends BaseArticleAzymutLoader with _CacheMixin{}
class ArticlePojutrzeLoader extends BaseArticlePojutrzeLoader with _CacheMixin{}

ArticleHarcAppLoader articleHarcAppLoader = ArticleHarcAppLoader();
ArticleAzymutLoader articleAzymutLoader = ArticleAzymutLoader();
ArticlePojutrzeLoader articlePojutrzeLoader = ArticlePojutrzeLoader();
