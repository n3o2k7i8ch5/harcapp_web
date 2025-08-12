import 'dart:collection';

import 'package:harcapp_core/harcthought/articles/model/article_data.dart';
import 'package:harcapp_core/harcthought/articles/model/article_source.dart';
import 'package:harcapp_core/harcthought/articles/model/pojutrze.dart';
import 'package:harcapp_core/harcthought/articles/model/article.dart';
import 'package:harcapp_core/harcthought/articles/source_article_loader.dart';

import '../source_article_loader.dart';
import 'cache_cover_mixin.dart';

class ArticlePojutrze extends CoreArticle with ArticlePojutrzeMixin, CacheCoverMixin{

  static List<ArticlePojutrze>? all;
  static SplayTreeMap<String, ArticlePojutrze>? allMap;

  static Future<void> init() async {
    all = [];
    allMap = SplayTreeMap.of({});
    var (articleData, _) = await articlePojutrzeLoader.getAllCached();
    addAll(articleData.map((e) => fromData(e)));
    BaseSourceArticleLoader.sortByDate(all!);
  }

  static bool add(ArticlePojutrze article){
    all ??= [];
    allMap ??= SplayTreeMap.of({});

    if(allMap!.containsKey(article.localId)) return false;
    all!.add(article);
    allMap![article.localId] = article;
    return true;
  }

  static void addAll(Iterable<ArticlePojutrze> articles){
    for(ArticlePojutrze article in articles)
      add(article);
  }

  ArticlePojutrze(
      String localId,
      { required super.title,
        required super.tags,
        required super.date,
        required super.author,
        required super.link,
        required super.imageUrl,
        required super.articleElements
      }):super(
    ArticleSource.pojutrze,
    localId,
  );

  static ArticlePojutrze fromData(ArticleData data) => ArticlePojutrze(
    data.localId,
    title: data.title,
    tags: data.tags,
    date: data.date,
    author: data.author,
    link: data.link,
    imageUrl: data.imageUrl,
    articleElements: data.articleElements
  );

  static ArticlePojutrze fromJson(String localId, Map jsonMap) =>
      ArticlePojutrze.fromData(
          ArticleData.fromJsonMap(localId, ArticleSource.pojutrze, jsonMap)
      );

}