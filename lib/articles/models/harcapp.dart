import 'package:harcapp_core/harcthought/articles/model/article_data.dart';
import 'package:harcapp_core/harcthought/articles/model/article_source.dart';
import 'package:harcapp_core/harcthought/articles/model/harcapp.dart';
import 'package:harcapp_core/harcthought/articles/model/article.dart';

import 'cache_cover_mixin.dart';

class ArticleHarcApp extends CoreArticle with ArticleHarcAppMixin, CacheCoverMixin{

  static List<ArticleHarcApp>? all;

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
          ArticleData.fromJson(localId, ArticleSource.harcApp, jsonMap)
      );

}