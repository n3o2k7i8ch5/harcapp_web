import 'package:harcapp_core/harcthought/articles/model/article_data.dart';
import 'package:harcapp_core/harcthought/articles/model/article_source.dart';
import 'package:harcapp_core/harcthought/articles/model/azymut.dart';
import 'package:harcapp_core/harcthought/articles/model/article.dart';

import 'cache_cover_mixin.dart';


class ArticleAzymut extends CoreArticle with ArticleAzymutMixin, CacheCoverMixin{

  static List<ArticleAzymut>? all;

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
          ArticleData.fromJson(localId, ArticleSource.azymut, jsonMap)
      );

}