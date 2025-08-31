
import 'package:flutter/material.dart';
import 'package:harcapp_core/comm_widgets/app_button.dart';
import 'package:harcapp_core/values/colors.dart';
import 'package:harcapp_core/comm_classes/app_text_style.dart';
import 'package:harcapp_core/values/dimen.dart';
import 'package:implicitly_animated_reorderable_list_2/implicitly_animated_reorderable_list_2.dart';

import '../article_text_style.dart';
import 'article_editor.dart';
import 'common.dart';

abstract class ArticleElementWidget<T extends ArticleElement> extends StatelessWidget{

  final ArticleEditorPageState pageState;
  final T item;

  const ArticleElementWidget(this.pageState, this.item);

  Widget builder(BuildContext context);

  double get topPadding => 0;

  @override
  Widget build(BuildContext context) {

    bool showClose = pageState.articleElements!.length != 1;

    return Padding(
      padding: EdgeInsets.only(top: topPadding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Expanded(child: builder(context)),

          AnimatedOpacity(
            child: AppButton(
              icon: Icon(Icons.close),
              onTap: showClose?(){
                pageState.removeElement(item);
              }:null,
            ),
            opacity: showClose ? 1: 0,
            duration: Duration(milliseconds: 400),
          ),

          SizedBox(width: MARGIN),

          Handle(
            child: Padding(
              padding: EdgeInsets.all(Dimen.iconMarg),
              child: Icon(
                Icons.list,
                color: Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );

  }
}

class ParagraphWidget extends ArticleElementWidget<Paragraph>{

  ParagraphWidget(ArticleEditorPageState pageState, Paragraph paragraph) : super(pageState, paragraph);

  @override
  Widget builder(BuildContext context) {

    return TextField(
      keyboardType: TextInputType.multiline,
      textAlign: TextAlign.justify,
      decoration: InputDecoration(
          hintText: 'Akapit...',
          border: InputBorder.none,
          hintStyle: AppTextStyle(
              fontSize: FONT_SIZE_NORM,
              color: AppColors.textHintEnab,
              height: 1.5
          )
      ),
      maxLines: null,
      controller: TextEditingController(text: item.text),
      style: AppTextStyle(
        fontSize: FONT_SIZE_NORM,
        color: AppColors.textDefEnab,
        height: 1.5
      ),
      onChanged: (text){
        item.text = text;
      },
    );
  }

}

class HeaderWidget extends ArticleElementWidget<Header>{

  const HeaderWidget(ArticleEditorPageState pageState, Header header)
      : super(pageState, header);

  @override
  double get topPadding => MARGIN;

  @override
  Widget builder(BuildContext context) {
    return TextField(
      decoration: InputDecoration(
          hintText: 'Nagłówek...',
          border: InputBorder.none,
          hintStyle: ArticleTextStyle(
            fontSize: 24.0,
            fontWeight: weightBold,
            color: AppColors.textHintEnab,
          )
      ),
      maxLines: null,
      controller: TextEditingController(text: item.text),
      style: ArticleTextStyle(
          fontSize: 24.0,
          fontWeight: weightBold,
          color: AppColors.textDefEnab,
      ),
      onChanged: (text){
        item.text = text;
      },
    );
  }
}
