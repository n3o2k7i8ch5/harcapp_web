import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:harcapp_core/comm_classes/app_text_style.dart';
import 'package:harcapp_core/comm_widgets/simple_button.dart';
import 'package:harcapp_core/dimen.dart';
import 'package:image_picker_web/image_picker_web.dart';

import '../article_text_style.dart';
import 'article_editor.dart';

class ArticleTop extends StatelessWidget{

  final ArticleEditorPageState page;

  const ArticleTop(this.page);

  DateTime? get articleDate => page.articleDate;
  set articleDate(value) => page.articleDate = value;

  Uint8List? get imageBytes => page.imageBytes;

  ValueNotifier? get topNotifier => page.topNotifier;

  @override
  Widget build(BuildContext context) {

    Widget child = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        IconButton(
          icon: Icon(Icons.image, color: HEADER_TEXT_COLOR),
          onPressed: () async {

            Uint8List? imageBytes = await ImagePickerWeb.getImageAsBytes();

            page.setImage(imageBytes);

          },
        ),

        Expanded(
          child: Center(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Tytuł...',
                hintStyle: ArticleTextStyle(
                    fontSize: 38,
                    fontWeight: weight.bold,
                    color: HEADER_TEXT_COLOR.withAlpha(160)
                ),
                border: InputBorder.none,
              ),
              controller: TextEditingController(text: page.title),
              maxLines: null,
              textAlign: TextAlign.center,
              style: ArticleTextStyle(
                  fontSize: 38,
                  color: HEADER_TEXT_COLOR,
                  fontWeight: weight.bold
              ),
              onChanged: (text) => page.title = text,
            ),
          ),
        ),


        Row(
          children: [

            Expanded(child: Padding(
              padding: EdgeInsets.all(Dimen.defMarg),
              child: TextField(
                controller: TextEditingController(text: page.imageSource??''),
                decoration: InputDecoration(
                    hintText: 'Źródło grafiki tytułowej...',
                    hintStyle: AppTextStyle(
                        fontSize: FONT_SIZE_NORM,
                        color: HEADER_TEXT_COLOR.withAlpha(160),
                        fontStyle: FontStyle.italic
                    ),
                    border: InputBorder.none
                ),
                maxLines: 1,
                style: AppTextStyle(
                    fontSize: FONT_SIZE_NORM,
                    color: HEADER_TEXT_COLOR.withAlpha(160),
                    fontStyle: FontStyle.italic
                ),
                onChanged: (text) => page.imageSource = text,
              ),
            )),
            SimpleButton(
              onTap: () async {
                DateTime? dateTime = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                  helpText: 'Wybierz datę',
                );

                if(dateTime != null)
                  page.setState(() => articleDate = dateTime);

              },
              child: Text(
                '${articleDate!.day} ${month[articleDate!.month]} ${articleDate!.year} A.D.',
                style: ArticleTextStyle(
                    fontSize: 20.0,
                    fontWeight: weight.bold,
                    color: HEADER_TEXT_COLOR
                ),
              ),
            ),
          ],
        ),

      ],
    );

    return AspectRatio(
      aspectRatio: 1.3,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 400),
        child: Stack(
          children: [

            AspectRatio(
              aspectRatio: 1.3,
              child: Image(
                image: page.imageBytes==null?
                AssetImage('assets/images/def_bg.webp'):
                Image.memory(imageBytes!).image,
                fit: BoxFit.cover,
              ),
            ),

            AnimatedBuilder(
              child: Container(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.width/1.3,
                color: Colors.black38,
              ),
              animation: topNotifier!,
              builder: (context, child) => Opacity(
                child: child,
                opacity: 1-Interval(0, 1, curve: Curves.easeOutQuad).transform(topNotifier!.value),
              ),
            ),

            Container(
              height: MediaQuery.of(context).size.width/1.3,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter, // 10% of the width, so there are ten blinds.
                  colors: [
                    Colors.black,
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black,
                  ], // whitish to gray
                  tileMode: TileMode.repeated, // repeats the gradient over the canvas
                ),
              ),
            ),

            child
          ],
        ),
      ),
    );

  }

}