import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:go_router/go_router.dart';
import 'package:harcapp_core/comm_classes/color_pack.dart';
import 'package:harcapp_core/comm_widgets/app_card.dart';
import 'package:harcapp_core/comm_widgets/tab_bar.dart';
import 'package:harcapp_core/folder/folder_tab.dart';
import 'package:harcapp_core/folder/folder_tab_indicator.dart';
import 'package:harcapp_core/values/dimen.dart';
import 'package:harcapp_core/harcthought/articles/article_loader.dart';
import 'package:harcapp_core/harcthought/articles/model/article.dart';
import 'package:harcapp_core/harcthought/articles/model/article_source.dart';
import 'package:harcapp_core/harcthought/articles/source_article_loader.dart';
import 'package:harcapp_core/harcthought/articles/thumbnail/article_card_widget.dart';
import 'package:harcapp_web/common/base_scaffold.dart';
import 'package:harcapp_web/common/page_width_bar.dart';
import 'package:harcapp_web/consts.dart';
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

class ArticlePageState extends State<ArticlesPage>
    with SingleTickerProviderStateMixin {

  /// Tab order: index 0 is "all sources", subsequent indices are individual
  /// sources in [ArticleSource.values] order.
  static final List<ArticleSource?> _tabSources = <ArticleSource?>[
    null,
    ...ArticleSource.values,
  ];

  late ArticleLoaderListener listener;
  late TabController _tabController;

  int _tabIndexFor(ArticleSource? source) {
    final idx = _tabSources.indexOf(source);
    return idx < 0 ? 0 : idx;
  }

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

  String _countTextFor(ArticleSource? source) {
    switch (source) {
      case null:
        if (ArticleHarcApp.all == null &&
            ArticleAzymut.all == null &&
            ArticlePojutrze.all == null) return '...';
        return ((ArticleHarcApp.all?.length ?? 0) +
                (ArticleAzymut.all?.length ?? 0) +
                (ArticlePojutrze.all?.length ?? 0))
            .toString();
      case ArticleSource.harcApp:
        return ArticleHarcApp.all?.length.toString() ?? '...';
      case ArticleSource.azymut:
        return ArticleAzymut.all?.length.toString() ?? '...';
      case ArticleSource.pojutrze:
        return ArticlePojutrze.all?.length.toString() ?? '...';
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _tabSources.length,
      initialIndex: _tabIndexFor(widget.source),
      vsync: this,
    );

    listener = ArticleLoaderListener(
        onArticleData: (articleData) => mounted?setState((){}):null,
        onEnd: (_, __, ___) => mounted?setState((){}):null
    );

    articleLoader.addListener(listener);

    if(!ArticleLoader.allLoaded && !articleLoader.running)
      articleLoader.run();
  }

  @override
  void didUpdateWidget(ArticlesPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.source != oldWidget.source) {
      final newIdx = _tabIndexFor(widget.source);
      if (_tabController.index != newIdx) {
        _tabController.animateTo(newIdx);
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    articleLoader.removeListener(listener);
    super.dispose();
  }

  void _onTabTap(int index) {
    final source = _tabSources[index];
    final target = source == null
        ? pathArticles
        : pathArticlesSource.replaceAll(':source', source.name);
    final currentUrl = GoRouterState.of(context).uri.toString();
    if (currentUrl == target) return;
    context.go(target);
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
  Widget build(BuildContext context) {
    final barColor = cardEnab_(context);
    final bodyColor = background_(context);
    return BaseScaffold(
      backgroundColor: bodyColor,
      body: Column(
        children: [
          Stack(
            children: [
              PageWidthBar(
                backgroundColor: barColor,
                child: TabBarX(
                  controller: _tabController,
                  isScrollable: true,
                  indicator: FolderTabIndicator(color: bodyColor),
                  indicatorSize: TabBarIndicatorSize.tab,
                  splashBorderRadius: FolderTabIndicator.defBorderRadius,
                  labelColor: textEnab_(context),
                  unselectedLabelColor: textEnab_(context),
                  onTap: _onTabTap,
                  tabs: [
                    for (final source in _tabSources)
                      FolderTwoLineTab(
                        text: source == null
                            ? 'Wszystkie'
                            : source.displayName,
                        subText:
                            'Liczba artykułów: ${_countTextFor(source)}',
                      ),
                  ],
                ),
              ),
              if (articleLoader.running)
                Positioned(
                  right: Dimen.sideMarg,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: SpinKitChasingDots(
                      color: textEnab_(context),
                      size: 20.0,
                    ),
                  ),
                ),
            ],
          ),
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: defPageWidth),
                child: showLoading
                    ? LoadingGrid(count: 12)
                    : ArticleGrid(articles: displayedArticles!),
              ),
            ),
          ),
        ],
      ),
    );
  }
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
    if (groupDenseCrossCount == this.groupDenseCrossCount &&
        _lastItemsLength == items.length) return;
    this.groupDenseCrossCount = groupDenseCrossCount;
    this.groupLooseCrossCount = groupLooseCrossCount;
    _lastItemsLength = items.length;

    countMap = _getCountMap(groupDenseCrossCount);
    groupedItems = _groupItems(countMap);
  }

  Widget Function(BuildContext, T) get itemBuilder => widget.itemBuilder;
  List<T> get items => widget.items;

  late List<List<T>> groupedItems;
  late Map<int?, int> countMap;
  late int groupDenseCrossCount;
  late int groupLooseCrossCount;
  int _lastItemsLength = -1;

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
      items: articles,
      itemBuilder: (context, article) => ArticleCardWidget(
          key: ValueKey(("Article Card", article.uniqName)),
          fallbackCoverKey: ValueKey(("Article Cover Fallback", article.uniqName)),
          article,
          onTap: (context, article) => context.push(pathArticlesSourceItem
              .replaceAll(':source', article.source.name)
              .replaceAll(':localId', article.localId))
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

