import 'package:flutter/material.dart';
import 'package:harcapp_core/comm_classes/app_text_style.dart';
import 'package:harcapp_core/comm_widgets/harc_app.dart';
import 'package:harcapp_core/comm_widgets/simple_button.dart';
import 'package:harcapp_core/dimen.dart';

import 'article_editor/article_editor.dart';
import 'author_editor.dart';


class ArticlePage extends StatefulWidget{

  @override
  State<StatefulWidget> createState() => ArticlePageState();

}

class ArticlePageState extends State<ArticlePage>{

  PageController? controller;
  int? lastSetPage;

  @override
  void initState() {
    controller = PageController();
    lastSetPage = 0;

    controller!.addListener(() {

      if(controller!.page != lastSetPage &&
          controller!.page==0 || controller!.page==1
      ) {
        lastSetPage = controller!.page!.toInt();
        setState(() {});
      }

    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      constraints: BoxConstraints(maxWidth: 1000),
      child: Card(
        elevation: 6.0,
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.black,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HarcApp(size: 18, color: Colors.white54,),
                Text(
                  'Edytor ${lastSetPage==0?'artykułu':'autora'}',
                  style: AppTextStyle(fontSize: 14, color: Colors.white54),
                )
              ],
            ),
            actions: [

              TopButton(
                title: 'Stwórz artykuł',
                icon: Icons.view_headline,
                onTap: () => controller!.animateToPage(
                    0,
                    duration: Duration(milliseconds: 300),
                    curve: Curves.easeOutQuad
                ),
                isSelected: lastSetPage == 0,
              ),

              SizedBox(width: Dimen.iconMarg),

              TopButton(
                  title: 'Stwórz autora',
                  icon: Icons.account_circle,
                  onTap: () => controller!.animateToPage(
                      1,
                      duration: Duration(milliseconds: 300),
                      curve: Curves.easeOutQuad
                  ),
                  isSelected: lastSetPage == 1
              ),
              SizedBox(width: Dimen.iconMarg),


            ],
          ),
          body: PageView(
            controller: controller,
            physics: NeverScrollableScrollPhysics(),
            children: [
              ArticleEditorPage(),
              AuthorEditorPage()
            ],
          ),
          //floatingActionButton:
        ),
      ),
    ),
  );


}

class TopButton extends StatelessWidget{

  final String title;
  final IconData icon;
  final Function onTap;
  final bool isSelected;

  const TopButton({
    required this.title,
    required this.icon,
    required this.onTap,
    this.isSelected = false});

  @override
  Widget build(BuildContext context) {
    return SimpleButton(
      child: Row(
        children: [

          Padding(
            padding: EdgeInsets.only(left: Dimen.iconMarg, right: Dimen.iconMarg),
            child: Icon(icon, color: Colors.white,),
          ),

          Text(
            title,
            style: AppTextStyle(
              fontSize: FONT_SIZE_NORM,
              color: Colors.white,
              fontWeight: isSelected?weight.bold:weight.halfBold,
            ),
          ),
        ],
      ),
      onTap: isSelected?null:onTap as void Function()?,
    );
  }
}