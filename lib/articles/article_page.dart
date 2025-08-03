import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:harcapp_core/comm_classes/app_text_style.dart';
import 'package:harcapp_core/comm_classes/color_pack.dart';
import 'package:harcapp_core/comm_widgets/app_card.dart';
import 'package:harcapp_core/comm_widgets/simple_button.dart';
import 'package:harcapp_core/values/dimen.dart';
import 'package:harcapp_core/harcthought/articles/article_loader.dart';
import 'package:harcapp_core/harcthought/articles/model/article.dart';
import 'package:harcapp_core/harcthought/articles/model/article_data.dart';
import 'package:harcapp_core/harcthought/articles/model/article_source.dart';
import 'package:harcapp_core/harcthought/articles/model/common.dart';
import 'package:harcapp_core/harcthought/articles/source_article_loader.dart';
import 'package:harcapp_core/harcthought/articles/thumbnail/article_cover_widget.dart';
import 'package:harcapp_core/harcthought/articles/thumbnail/article_info_widget.dart';
import 'package:harcapp_core/harcthought/articles/widgets.dart';
import 'package:harcapp_core/tag/tag.dart';
import 'package:harcapp_core/tag/tags_widget.dart';
import 'package:harcapp_web/common/base_scaffold.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../router.dart';
import 'article_loader.dart';
import 'models/azymut.dart';
import 'models/harcapp.dart';
import 'models/pojutrze.dart';

class ArticlePage extends StatefulWidget {
  final ArticleSource source;
  final String localId;

  const ArticlePage({required this.source, required this.localId});

  @override
  State<StatefulWidget> createState() => ArticlePageState();

}

class ArticlePageState extends State<ArticlePage>{
  ArticleSource get source => widget.source;
  String get localId => widget.localId;

  static String paraFontFamily = 'Lato';

  late ArticleLoaderListener listener;

  CoreArticle? article;

  @override
  void initState(){
    article = getArticle();

    listener = ArticleLoaderListener(
        onArticleData: (ArticleDataOrList dataOtList){
          if(dataOtList.isSingle && dataOtList.articleData.localId == localId)
            setState(() => article = getArticle());
          else if(dataOtList.isList){
            for(ArticleData articleData in dataOtList.list)
              if(articleData.localId == localId){
                setState(() => article = getArticle());
                break;
              }
          }
        }
    );

    articleLoader.addListener(listener);

    if(article == null)
      articleLoader.run(restrictToSources: [source]);

    super.initState();
  }

  CoreArticle? getArticle(){
    switch(source){
      case ArticleSource.harcApp:
        if (ArticleHarcApp.all == null) return null;
        try {
          return ArticleHarcApp.all!.firstWhere((element) => element.localId == localId);
        } catch(_){
          return null;
        }
      case ArticleSource.azymut:
        if (ArticleAzymut.all == null) return null;
        try{
          return ArticleAzymut.all!.firstWhere((element) => element.localId == localId);
        } catch(_){
          return null;
        }
      case ArticleSource.pojutrze:
        if (ArticlePojutrze.all == null) return null;
        try{
          return ArticlePojutrze.all!.firstWhere((element) => element.localId == localId);
        } catch(_){
          return null;
        }
    }
  }

  @override
  Widget build(BuildContext context) => BaseScaffold(
      backgroundColor: background_(context),
      body:Align(
          alignment: Alignment.topCenter,
          child:  Container(
            constraints: BoxConstraints(maxWidth: 1000),
            child: Builder(builder: (context){

              if(article == null && articleLoader.running)
                return Center(child: Text('Ładowanie...'));
              else if(article == null)
                return Center(child: Text('Brak artykułu'));

              return ListView(
                padding: EdgeInsets.all(Dimen.sideMarg),
                children: [

                  Align(
                    alignment: Alignment.centerLeft,
                    child: SimpleButton.from(
                        context: context,
                        margin: EdgeInsets.zero,
                        color: backgroundIcon_(context),
                        icon: MdiIcons.arrowLeft,
                        text: 'Powrót',
                        onTap: (){
                          if(GoRouter.of(context).canPop())
                            GoRouter.of(context).pop();
                          else
                            GoRouter.of(context).go(pathArticles);
                        }
                    ),
                  ),

                  const SizedBox(height: Dimen.sideMarg),

                  Container(
                    clipBehavior: Clip.hardEdge,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppCard.defRadius),
                    ),
                    child: ArticleCoverWidget(article!, bigResolution: true),
                  ),

                  const SizedBox(height: Dimen.sideMarg),

                  if(article!.tags.isNotEmpty)
                    TagsWidget.customLinear<String>(
                      allTags: article!.tags,
                      tagBuilder: (context, tag, checked) => Tag(
                        tag,
                        elevation: 0,
                        textColor: iconEnab_(context),
                      ),
                      separator: Dimen.iconMarg,
                    ),

                  SizedBox(height: 6*Dimen.sideMarg),

                  Align(
                      alignment: Alignment.center,
                      child: SizedBox(
                        width: 600,
                        child: ArticleInfoTitleWidget(
                          article!, titleCenter: true, fontSize: 28.0,
                        ),
                      )
                  ),

                  SizedBox(height: 6*Dimen.sideMarg),

                  ArticleInfoAuthorDateWidget(article!),

                  SizedBox(height: Dimen.sideMarg),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: Material(
                        borderRadius: BorderRadius.circular(AppCard.bigRadius),
                        color: cardEnab_(context),
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: Dimen.defMarg, horizontal: Dimen.iconMarg),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ArticleSource.icon,

                              Text(' ', style: AppTextStyle()),

                              Text(
                                  'Artykuł z: ',
                                  style: AppTextStyle(
                                      color: iconEnab_(context)
                                  )
                              ),
                              Text(
                                  article!.source.displayName,
                                  style: AppTextStyle(
                                      fontWeight: weightHalfBold,
                                      color: iconEnab_(context)
                                  )
                              ),

                            ],
                          ),
                        )
                    ),
                  ),

                  SizedBox(height: Dimen.sideMarg),

                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: (article!.articleElements).map((item){

                      if(item is ParagraphArticleElement)
                        return ParagraphArticleElementWidget(item, fontFamily: paraFontFamily);
                      else if (item is HeaderArticleElement)
                        return HeaderArticleElementWidget(item);
                      else if (item is ListItemArticleElement)
                        return ListItemArticleElementWidget(item, fontFamily: paraFontFamily);
                      else if (item is QuoteArticleElement)
                        return QuoteArticleElementWidget(item);
                      else if(item is PictureArticleElement)
                        return PictureArticleElementWidget(item);
                      else if(item is YoutubeArticleElement)
                        return YoutubeArticleElementWidget(item);
                      else if(item is CustomArticleElement)
                        return CustomArticleElementWidget(item, fontFamily: paraFontFamily);
                      else
                        return Container();
                    }).toList(),
                  ),

                  const SizedBox(height: Dimen.sideMarg),

                  Padding(
                      padding: const EdgeInsets.all(Dimen.iconMarg),
                      child: Icon(MdiIcons.circleMedium, color: textEnab_(context))
                  ),

                  const SizedBox(height: Dimen.sideMarg),

                ],
              );

            }),
          )
      )
  );

}