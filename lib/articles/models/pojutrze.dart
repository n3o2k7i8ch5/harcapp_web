import 'package:harcapp_core/harcthought/articles/model/article_data.dart';
import 'package:harcapp_core/harcthought/articles/model/article_source.dart';
import 'package:harcapp_core/harcthought/articles/model/pojutrze.dart';
import 'package:harcapp_core/harcthought/articles/model/article.dart';

import 'cache_cover_mixin.dart';

class ArticlePojutrze extends CoreArticle with ArticlePojutrzeMixin, CacheCoverMixin{

  static List<ArticlePojutrze>? all;

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
          ArticleData.fromJson(localId, ArticleSource.pojutrze, jsonMap)
      );

}