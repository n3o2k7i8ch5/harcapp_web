import 'dart:collection';

import 'package:harcapp_core/harcthought/articles/model/article_data.dart';
import 'package:harcapp_core/harcthought/articles/model/article_source.dart';
import 'package:harcapp_core/harcthought/articles/model/harcapp.dart';
import 'package:harcapp_core/harcthought/articles/model/article.dart';
import 'package:harcapp_core/harcthought/articles/source_article_loader.dart';

import '../source_article_loader.dart';
import 'cache_cover_mixin.dart';

class ArticleHarcApp extends CoreArticle with ArticleHarcAppMixin, CacheCoverMixin{

  static List<ArticleHarcApp>? all;
  static SplayTreeMap<String, ArticleHarcApp>? allMap;

  static Future<void> init() async {
    all = [];
    allMap = SplayTreeMap.of({});
    var (articleData, _) = await articleHarcAppLoader.getAllCached();
    addAll(articleData.map((e) => fromData(e)));
    BaseSourceArticleLoader.sortByDate(all!);
  }

  static bool add(ArticleHarcApp article){
    all ??= [];
    allMap ??= SplayTreeMap.of({});

    if(allMap!.containsKey(article.uniqName)) return false;
    all!.add(article);
    allMap![article.uniqName] = article;
    return true;
  }

  static void addAll(Iterable<ArticleHarcApp> articles){
    for(ArticleHarcApp article in articles)
      add(article);
  }

  ArticleHarcApp(
      String localId,
      { required super.title,
        required super.tags,
        required super.date,
        required super.author,
        required super.link,
        required super.imageUrl,
        required super.articleElements
      }):super(
    ArticleSource.harcApp,
    localId,
  );

  static ArticleHarcApp fromData(ArticleData data) => ArticleHarcApp(
      data.localId,
      title: data.title,
      tags: data.tags,
      date: data.date,
      author: data.author,
      link: data.link,
      imageUrl: data.imageUrl,
      articleElements: data.articleElements
  );

  static ArticleHarcApp fromJson(String localId, Map jsonMap) =>
      ArticleHarcApp.fromData(
          ArticleData.fromJsonMap(localId, ArticleSource.harcApp, jsonMap)
      );

}