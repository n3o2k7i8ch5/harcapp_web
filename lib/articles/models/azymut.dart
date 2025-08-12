import 'dart:collection';

import 'package:harcapp_core/harcthought/articles/model/article_data.dart';
import 'package:harcapp_core/harcthought/articles/model/article_source.dart';
import 'package:harcapp_core/harcthought/articles/model/azymut.dart';
import 'package:harcapp_core/harcthought/articles/model/article.dart';
import 'package:harcapp_core/harcthought/articles/source_article_loader.dart';

import '../source_article_loader.dart';
import 'cache_cover_mixin.dart';

class ArticleAzymut extends CoreArticle with ArticleAzymutMixin, CacheCoverMixin{

  static List<ArticleAzymut>? all;
  static SplayTreeMap<String, ArticleAzymut>? allMap;

  static Future<void> init() async {
    all = [];
    allMap = SplayTreeMap.of({});
    var (articleData, _) = await articleAzymutLoader.getAllCached();
    addAll(articleData.map((data) => fromData(data)));
    BaseSourceArticleLoader.sortByDate(all!);
  }

  static bool add(ArticleAzymut article){
    all ??= [];
    allMap ??= SplayTreeMap.of({});

    if(allMap!.containsKey(article.uniqName)) return false;
    all!.add(article);
    allMap![article.uniqName] = article;
    return true;
  }

  static void addAll(Iterable<ArticleAzymut> articles){
    for(ArticleAzymut article in articles)
      add(article);
  }

  ArticleAzymut(
      String localId,
      { required super.title,
        required super.tags,
        required super.date,
        required super.author,
        required super.link,
        required super.imageUrl,
        required super.articleElements
      }):super(
    ArticleSource.azymut,
    localId,
  );

  static ArticleAzymut fromData(ArticleData data) => ArticleAzymut(
    data.localId,
    title: data.title,
    tags: data.tags,
    date: data.date,
    author: data.author,
    link: data.link,
    imageUrl: data.imageUrl,
    articleElements: data.articleElements
  );

  static ArticleAzymut fromJson(String localId, Map jsonMap) =>
      ArticleAzymut.fromData(
          ArticleData.fromJsonMap(localId, ArticleSource.azymut, jsonMap)
      );

}