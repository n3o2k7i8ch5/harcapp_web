import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'article_editor/article_editor.dart';
import 'author_editor.dart';
import 'common/app_text_style.dart';
import 'common/dimen.dart';
import 'common/harc_app.dart';
import 'common/simple_button.dart';


class MainPage extends StatefulWidget{

  @override
  State<StatefulWidget> createState() => MainPageState();

}

class MainPageState extends State<MainPage>{

  PageController controller;
  int lastSetPage;

  @override
  void initState() {
    controller = PageController();
    lastSetPage = 0;

    controller.addListener(() {

      if(controller.page != lastSetPage &&
          controller.page==0 || controller.page==1
      ) {
        lastSetPage = controller.page.toInt();
        setState(() {});
      }

    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    return Center(
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
                    onTap: () => controller.animateToPage(
                        0,
                        duration: Duration(milliseconds: 300),
                        curve: Curves.easeOutQuad
                    ),
                    isSelected: lastSetPage == 0,
                  ),

                  SizedBox(width: Dimen.icon_margin),

                  TopButton(
                      title: 'Stwórz autora',
                      icon: Icons.account_circle,
                      onTap: () => controller.animateToPage(
                          1,
                          duration: Duration(milliseconds: 300),
                          curve: Curves.easeOutQuad
                      ),
                      isSelected: lastSetPage == 1
                  ),
                  SizedBox(width: Dimen.icon_margin),


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


}

class TopButton extends StatelessWidget{

  final String title;
  final IconData icon;
  final Function onTap;
  final bool isSelected;

  const TopButton({
    @required this.title,
    @required this.icon,
    @required this.onTap,
    this.isSelected: false});

  @override
  Widget build(BuildContext context) {
    return SimpleButton(
      child: Row(
        children: [

          Padding(
            padding: EdgeInsets.only(left: Dimen.icon_margin, right: Dimen.icon_margin),
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
      onTap: isSelected?null:onTap,
    );
  }
}