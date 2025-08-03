import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:go_router/go_router.dart';
import 'package:harcapp_core/comm_classes/app_text_style.dart';
import 'package:harcapp_core/comm_classes/color_pack.dart';
import 'package:harcapp_core/comm_widgets/app_card.dart';
import 'package:harcapp_core/comm_widgets/simple_button.dart';
import 'package:harcapp_core/values/dimen.dart';
import 'package:harcapp_core/harcthought/articles/article_loader.dart';
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

  late ArticleLoaderListener listener;

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

  bool get allArticlesNullOrEmpty =>
        (ArticleHarcApp.all == null || ArticleHarcApp.all!.length == 0) &&
        (ArticleAzymut.all == null || ArticleAzymut.all!.length == 0) &&
        (ArticlePojutrze.all == null || ArticlePojutrze.all!.length == 0);

  @override
  void initState() {
    listener = ArticleLoaderListener(
        onArticleData: (articleData) => mounted?setState((){}):null,
        onEnd: (_, __, ___) => mounted?setState((){}):null
    );

    articleLoader.addListener(listener);

    if(!ArticleLoader.allLoaded && !articleLoader.running)
      articleLoader.run();

    super.initState();
  }

  bool get showLoading{
    if(widget.source == null)
      return articleLoader.running && allArticlesNullOrEmpty;

    bool anyArticles;
    switch(widget.source){
      case ArticleSource.harcApp: anyArticles = (ArticleHarcApp.all != null && ArticleHarcApp.all!.length>0); break;
      case ArticleSource.azymut: anyArticles = (ArticleAzymut.all != null && ArticleAzymut.all!.length>0); break;
      case ArticleSource.pojutrze: anyArticles = (ArticlePojutrze.all != null && ArticlePojutrze.all!.length>0); break;
      default: anyArticles = !allArticlesNullOrEmpty;
    }

    return !anyArticles && articleLoader.isSourceRunning(widget.source!);
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [

                    Padding(
                      padding: EdgeInsets.symmetric(vertical: Dimen.defMarg),
                      child: Material(
                        elevation: 5.0,
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(AppCard.defRadius),
                        child: Padding(
                          padding: EdgeInsets.all(Dimen.defMarg),
                          child: Text(
                            'Wersja testowa. Strona będzie się zacinać.',
                            style: AppTextStyle(color: Colors.white, fontSize: 18.0, fontWeight: weightHalfBold,),
                            textAlign: TextAlign.center,
                          ),
                        )
                      )
                    ),

                    Row(
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
                            child: SpinKitChasingDots(
                              color: Colors.grey,
                              size: 20.0,
                            ),
                          )
                      ],
                    ),
                  ],
                )
              ),

              Expanded(
                child: showLoading?
                LoadingGrid(count: 12):
                ArticleGrid(articles: displayedArticles!),
              )

            ],
          )
      ),
    ),
  );


}

class HeaderWidget extends StatelessWidget{

  static const double showCountWidth = 620;

  final ArticleSource? selected;
  final Function(ArticleSource?) onTap;

  HeaderWidget({required this.selected, required this.onTap});

  String get allCount => ArticleHarcApp.all == null && ArticleAzymut.all == null && ArticlePojutrze.all == null?
    '...':
    ((ArticleHarcApp.all?.length??0) + (ArticleAzymut.all?.length??0) + (ArticlePojutrze.all?.length??0)).toString();
  String get harcAppCount => ArticleHarcApp.all == null?'...':ArticleHarcApp.all!.length.toString();
  String get azymutCount => ArticleAzymut.all == null?'...':ArticleAzymut.all!.length.toString();
  String get pojutrzeCount => ArticlePojutrze.all == null?'...':ArticlePojutrze.all!.length.toString();

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (BuildContext context, BoxConstraints constraints) => SizedBox(
      height: Dimen.iconFootprint,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          SimpleButton.from(
              context: context,
              radius: AppCard.defRadius,

              text:
              constraints.maxWidth>=showCountWidth?
              'Wszystkie ($allCount)':
              'Wszystkie',

              color: selected == null?backgroundIcon_(context):null,
              onTap: () => onTap.call(null)
          ),

          SimpleButton.from(
              context: context,
              radius: AppCard.defRadius,

              text:
              constraints.maxWidth>=showCountWidth?
              '${ArticleSource.harcApp.displayName} ($harcAppCount)':
              ArticleSource.harcApp.displayName,

              color: selected == ArticleSource.harcApp?backgroundIcon_(context):null,
              onTap: () => onTap.call(ArticleSource.harcApp)
          ),

          SimpleButton.from(
              context: context,
              radius: AppCard.defRadius,

              text: constraints.maxWidth>=showCountWidth?
              '${ArticleSource.azymut.displayName} ($azymutCount)':
              ArticleSource.azymut.displayName,

              color: selected == ArticleSource.azymut?backgroundIcon_(context):null,
              onTap: () => onTap.call(ArticleSource.azymut)
          ),

          SimpleButton.from(
              context: context,
              radius: AppCard.defRadius,
              text:
              constraints.maxWidth>=showCountWidth?
              '${ArticleSource.pojutrze.displayName} ($pojutrzeCount)':
              ArticleSource.pojutrze.displayName,
              color: selected == ArticleSource.pojutrze?backgroundIcon_(context):null,
              onTap: () => onTap.call(ArticleSource.pojutrze)
          ),

        ],
      ),
    ),
  );

}


class BaseGrid<T> extends StatefulWidget {
  final Widget Function(BuildContext, T) itemBuilder;
  final List<T> items;

  const BaseGrid({super.key, required this.itemBuilder, required this.items});

  @override
  State<StatefulWidget> createState() => BaseState<T>();
}

class BaseState<T> extends State<BaseGrid<T>> {

  static const double sideMarg = 8.0;

  static Map<int?, int> count3Map = {
    null: 6,
    6: 4,
    4: 3,
    3: 8,
    8: 6
  };

  static Map<int?, int> count2Map = {
    null: 6,
    6: 4,
    4: 1,
    1: 8,
    8: 6
  };

  static Map<int?, int> count1Map = {
    null: 1,
    1: 1
  };

  (int, int) _getCrossAxisCount(double screenWidth){
    if(screenWidth < 600) return (1, 1);
    if(screenWidth < 950) return (2, 1);
    return (3, 2);
  }

  Map<int?, int> _getCountMap(maxCrossAxisCount){
    if(maxCrossAxisCount >= 3) return count3Map;
    if(maxCrossAxisCount == 2) return count2Map;
    return count1Map;
  }

  List<List<T>> _groupItems(Map<int?, int> countMap) {
    int? chunkSize = null;
    List<List<T>> chunks = [];
    for (var i = 0; i < items.length; i += chunkSize) {
      chunkSize = countMap[chunkSize]!;
      chunks.add(
        items.sublist(
          i,
          i + chunkSize > items.length ? items.length : i + chunkSize,
        ),
      );
    }
    return chunks;
  }

  void groupItems(double screenWidth){
    var (groupDenseCrossCount, groupLooseCrossCount) = _getCrossAxisCount(screenWidth);
    if (groupDenseCrossCount == this.groupDenseCrossCount) return;
    this.groupDenseCrossCount = groupDenseCrossCount;
    this.groupLooseCrossCount = groupLooseCrossCount;

    countMap = _getCountMap(groupDenseCrossCount);
    groupedItems = _groupItems(countMap);
  }

  Widget Function(BuildContext, T) get itemBuilder => widget.itemBuilder;
  List<T> get items => widget.items;

  late List<List<T>> groupedItems;
  late Map<int?, int> countMap;
  late int groupDenseCrossCount;
  late int groupLooseCrossCount;

  @override
  void initState() {
    groupedItems = [];
    countMap = {};
    groupDenseCrossCount = 0;
    groupLooseCrossCount = 0;

    super.initState();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (BuildContext context, BoxConstraints constraints) {
      groupItems(constraints.maxWidth);
      return ListView.builder(
        key: ValueKey(("Article Groups ListView", groupedItems.length)),
        padding: EdgeInsets.all(sideMarg),
        itemCount: groupedItems.length,
        itemBuilder: (context, groupIndex) {

          int crossAxisCount = groupIndex.isEven ? groupDenseCrossCount : groupLooseCrossCount;

          // Calculate the number of rows based on the group size and crossAxisCount
          int groupSize = groupedItems[groupIndex].length;
          double childAspectRatio = 1.5; // Adjust as needed

          return GridView.builder(
            key: ValueKey(("Article Group GridView", groupIndex)),
            padding: EdgeInsets.only(bottom: sideMarg),
            shrinkWrap: true, // Important to wrap GridView inside ListView
            physics: NeverScrollableScrollPhysics(), // Disable GridView scrolling
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: sideMarg,
              mainAxisSpacing: sideMarg,
              childAspectRatio: childAspectRatio,
            ),
            itemCount: groupSize,
            itemBuilder: (context, index) => itemBuilder(context, groupedItems[groupIndex][index]),
          );
        },
      );

    },
  );
}

class ArticleGrid extends StatelessWidget{

  final List<CoreArticle> articles;

  const ArticleGrid({required this.articles});

  @override
  Widget build(BuildContext context) => BaseGrid<CoreArticle>(
      key: ValueKey(("Article BaseGrid", articles.length)),
      items: articles,
      itemBuilder: (context, article) => ArticleCardWidget(
          fallbackCoverKey: ValueKey(("Article Cover Fallback", article.uniqName)),
          article,
          onTap: (context, article) =>
              context.push(pathArticlesSourceItem.replaceAll(":source", article.source.name).replaceAll(":localId", article.localId))
      )
  );
}

class PulsingContainer extends StatefulWidget{

  final Widget child;
  final Duration duration;

  const PulsingContainer({required this.child, this.duration = const Duration(milliseconds: 1000)});

  @override
  State<StatefulWidget> createState() => PulsingContainerState();
}

class PulsingContainerState extends State<PulsingContainer> with SingleTickerProviderStateMixin{

  late AnimationController controller;
  late Animation<double> animation;

  @override
  void initState() {

    Duration duration = widget.duration + Duration(milliseconds: Random().nextInt(1000));

    controller = AnimationController(vsync: this, duration: duration);
    animation = Tween<double>(begin: .2, end: .7).animate(controller)
      ..addListener(() => setState((){}))
      ..addStatusListener((status) {
        if(status == AnimationStatus.completed)
          controller.reverse();
        else if(status == AnimationStatus.dismissed)
          controller.forward();
      });

    controller.forward();
    super.initState();
  }

  @override
  Widget build(BuildContext context) => Opacity(
    opacity: 1 - animation.value,
    child: widget.child,
  );

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}

class LoadingGrid extends StatelessWidget{

  final int count;

  const LoadingGrid({this.count = 12});

  @override
  Widget build(BuildContext context) => BaseGrid(
      items: List.generate(count, (index) => index),
      itemBuilder: (context, _) => PulsingContainer(
          child: PulsingContainer(child: Container(
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(AppCard.defRadius),
              )
          ))
      )
  );

}