import 'dart:async';
import 'package:harcapp_core/harcthought/articles/article_loader.dart';
import 'package:harcapp_core/harcthought/articles/model/article_data.dart';
import 'package:harcapp_core/harcthought/articles/model/article_source.dart';
import 'package:harcapp_core/harcthought/articles/source_article_loader.dart';
import 'package:harcapp_web/articles/models/azymut.dart';
import 'package:harcapp_web/articles/models/harcapp.dart';
import 'package:harcapp_web/articles/models/pojutrze.dart';
import 'package:harcapp_web/articles/source_article_loader.dart';

// TODO:
// There is an issue currently. If someone calls `ArticleLoader` with only one
// source, and while it's running, calls it again with another source, the first
// source will finish and the second will be ignored.
// Solve this by creating multiple instances of `ArticleLoader` for each source (and one for all sources).

Map<ArticleSource, BaseSourceArticleLoader> sourceArticleLoaders = {
  ArticleSource.harcApp: articleHarcAppLoader,
  ArticleSource.azymut: articleAzymutLoader,
  ArticleSource.pojutrze: articlePojutrzeLoader,
};

Future<void> addAllArticlesAndCache(ArticleSource source, List<ArticleData> articleDataList) async {
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
  await sourceArticleLoaders[source]!.cacheAll(articleDataList);
}

ArticleLoader articleLoader = ArticleLoader(
    sourceArticleLoaders: sourceArticleLoaders,
    onNewArticles: addAllArticlesAndCache
);
