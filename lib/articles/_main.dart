import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:harcapp_core/comm_classes/app_text_style.dart';
import 'package:harcapp_core/comm_classes/color_pack.dart';
import 'package:harcapp_core/comm_classes/single_computer/single_computer_listener.dart';
import 'package:harcapp_core/comm_widgets/app_card.dart';
import 'package:harcapp_core/comm_widgets/simple_button.dart';
import 'package:harcapp_core/dimen.dart';
import 'package:harcapp_core/harcthought/articles/model/article.dart';
import 'package:harcapp_core/harcthought/articles/model/article_source.dart';
import 'package:harcapp_core/harcthought/articles/source_article_loader.dart';
import 'package:harcapp_core/harcthought/articles/thumbnail/article_card_widget.dart';
import 'package:harcapp_web/common/base_scaffold.dart';
import 'package:harcapp_web/router.dart';

import 'article_loader.dart';
import 'models/azymut.dart';
import 'models/harcapp.dart';
import 'models/pojutrze.dart';


class ArticlesPage extends StatefulWidget{

  final ArticleSource? source;

  const ArticlesPage({this.source});

  @override
  State<StatefulWidget> createState() => ArticlePageState();

}

class ArticlePageState extends State<ArticlesPage>{

  late SingleComputerListener<String> listener;

  List<CoreArticle>? get displayedArticles{
    switch(widget.source){
      case ArticleSource.harcApp: return ArticleHarcApp.all;
      case ArticleSource.azymut: return ArticleAzymut.all;
      case ArticleSource.pojutrze: return ArticlePojutrze.all;
      default:
        bool allNull = ArticleHarcApp.all == null && ArticleAzymut.all == null && ArticlePojutrze.all == null;
        if(allNull)
          return null;

        List<CoreArticle> all = [];
        if(ArticleHarcApp.all != null) all.addAll(ArticleHarcApp.all!);
        if(ArticleAzymut.all != null) all.addAll(ArticleAzymut.all!);
        if(ArticlePojutrze.all != null) all.addAll(ArticlePojutrze.all!);

        BaseSourceArticleLoader.sortByDate(all);
        return all;
    }
  }

  bool get allArticlesNull => ArticleHarcApp.all == null && ArticleAzymut.all == null && ArticlePojutrze.all == null;

  @override
  void initState() {

    listener = SingleComputerListener<String>(
      onEnd: (_, __, ___) => setState((){})
    );

    articleLoader.addListener(listener);

    if(!ArticleLoader.allLoaded && !articleLoader.running)
      articleLoader.run();

    super.initState();
  }

  @override
  Widget build(BuildContext context) => BaseScaffold(
      backgroundColor: background_(context),
      body: Align(
        alignment: Alignment.topCenter,
        child: Container(
            constraints: BoxConstraints(maxWidth: 1000),
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.only(top: Dimen.defMarg),
                  child: Row(
                    children: [
                      Expanded(
                        child: HeaderWidget(
                          selected: widget.source,
                          onTap: (ArticleSource? source){
                            if(source == null) context.go(pathArticles);
                            else context.go(pathArticlesSource.replaceAll(":source", source.name));
                          }
                        ),
                      ),
                      if(articleLoader.running)
                        Padding(
                          padding: EdgeInsets.only(right: Dimen.sideMarg),
                          child: Text(
                            'Ładowanie...',
                            style: AppTextStyle(fontWeight: weight.halfBold, fontSize: Dimen.textSizeBig),
                          ),
                        )
                    ],
                  ),
                ),
                Expanded(
                  child: ArticleGrid(articles: displayedArticles!),
                )

              ],
            )
        ),
      ),
  );


}

class HeaderWidget extends StatelessWidget{

  final ArticleSource? selected;
  final Function(ArticleSource?) onTap;

  HeaderWidget({required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => SizedBox(
    height: Dimen.iconFootprint,
    child: ListView(
      scrollDirection: Axis.horizontal,
      children: [
        SimpleButton.from(
            context: context,
            radius: AppCard.defRadius,
            text: 'Wszystkie',
            color: selected == null?backgroundIcon_(context):null,
            onTap: () => onTap.call(null)
        ),

        SimpleButton.from(
            context: context,
            radius: AppCard.defRadius,
            text: ArticleSource.harcApp.displayName,
            color: selected == ArticleSource.harcApp?backgroundIcon_(context):null,
            onTap: () => onTap.call(ArticleSource.harcApp)
        ),

        SimpleButton.from(
            context: context,
            radius: AppCard.defRadius,
            text: ArticleSource.azymut.displayName,
            color: selected == ArticleSource.azymut?backgroundIcon_(context):null,
            onTap: () => onTap.call(ArticleSource.azymut)
        ),

        SimpleButton.from(
            context: context,
            radius: AppCard.defRadius,
            text: ArticleSource.pojutrze.displayName,
            color: selected == ArticleSource.pojutrze?backgroundIcon_(context):null,
            onTap: () => onTap.call(ArticleSource.pojutrze)
        ),

      ],
    ),
  );

}

class ArticleGrid extends StatelessWidget {
  final List<CoreArticle> articles; // Replace with your Article model
  final double sideMarg = 8.0; // Example margin value

  const ArticleGrid({required this.articles});

  static Map<int?, int> countMap = {
    null: 6,
    6: 4,
    4: 3,
    3: 8,
    8: 6
  };

  List<List<CoreArticle>> _chunkArticles(List<CoreArticle> articles) {
    int? chunkSize = null;
    List<List<CoreArticle>> chunks = [];
    for (var i = 0; i < articles.length; i += chunkSize) {
      chunkSize = countMap[chunkSize]!;
      chunks.add(
        articles.sublist(
          i,
          i + chunkSize > articles.length ? articles.length : i + chunkSize,
        ),
      );
    }
    return chunks;
  }

  @override
  Widget build(BuildContext context) {
    List<List<CoreArticle>> groupedArticles = _chunkArticles(articles);

    return ListView.builder(
      padding: EdgeInsets.all(sideMarg),
      itemCount: groupedArticles.length,
      itemBuilder: (context, groupIndex) {
        // Determine crossAxisCount: even groups have 3, odd groups have 2
        int crossAxisCount = groupIndex.isEven ? 3 : 2;

        // Calculate the number of rows based on the group size and crossAxisCount
        int groupSize = groupedArticles[groupIndex].length;
        double childAspectRatio = 1.5; // Adjust as needed

        return Padding(
          padding: EdgeInsets.only(bottom: sideMarg),
          child: GridView.builder(
            shrinkWrap: true, // Important to wrap GridView inside ListView
            physics: NeverScrollableScrollPhysics(), // Disable GridView scrolling
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: sideMarg,
              mainAxisSpacing: sideMarg,
              childAspectRatio: childAspectRatio,
            ),
            itemCount: groupSize,
            itemBuilder: (context, index) {
              return ArticleCardWidget(
                groupedArticles[groupIndex][index],
                onTap: (context, article) =>
                  context.push(pathArticlesSourceItem.replaceAll(":source", article.source.name).replaceAll(":localId", article.localId))
              );
            },
          ),
        );
      },
    );
  }
}