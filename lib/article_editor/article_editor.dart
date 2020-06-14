import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:html' as html;

import 'package:file_picker_cross/file_picker_cross.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:harcapp_web/article_editor/common.dart';
import 'package:harcapp_web/article_editor/widgets.dart';
import 'package:harcapp_web/common/colors.dart';
import 'package:harcapp_web/common/dimen.dart';
import 'package:harcapp_web/common/simple_button.dart';
import 'package:image_picker_web/image_picker_web.dart';
import 'package:implicitly_animated_reorderable_list/implicitly_animated_reorderable_list.dart';
import 'package:implicitly_animated_reorderable_list/transitions.dart';

import '../common/app_text_style.dart';
import '../common/harc_app.dart';

const double MARGIN = 20.0;
const double FONT_SIZE_NORM = 16.0;
const Color HEADER_TEXT_COLOR = Colors.white;

const Map<int, String> month = {
  1:'stycznia',
  2:'lutego',
  3:'marca',
  4:'kwietnia',
  5:'maja',
  6:'czerwca',
  7:'lipca',
  8:'sierpnia',
  9:'września',
  10:'października',
  11:'listopada',
  12:'grudnia'
};

class ArticleEditorPage extends StatefulWidget{
  @override
  State<StatefulWidget> createState() => ArticleEditorPageState();

}

class ArticleEditorPageState extends State<ArticleEditorPage>{

  String title;
  String intro;

  DateTime articleDate;
  Uint8List imageBytes;

  List<ArticleElement> articleElements;

  @override
  void initState() {
    articleDate = DateTime.now();
    articleElements = [
      Header(text: 'Chodzi Ci po głowie napisanie artykułu do HarcAppki?'),
      Paragraph(text: '"Jakiego artykułu?", "Weź, o co chodzi?"'),
      Paragraph(text: '"Przecież w HarcAppce nie ma żadnych artykułów!"'),
      Paragraph(text: 'To prawda, nie ma, ale już niebawem w jedynej słusznej aplikacji pojawi się możliwość publikowania swoich felietonów, rozważań, dywakacji i doświadczeń o tematyce harcerskiej. Ta strona z kolei jest częścią tego planu - została stworzona, żeby w łatwy sposób umożliwić napisanie tego, czym chcielibyście podzielić się w HarcAppce.'),
      Paragraph(text: 'Strona jest wciąż w trakcie udoskonalania, ma swoje mankamenty, ale... jak ktoś chce, proszę, można już z niej korzystać.'),
      Paragraph(text: 'Stworzone tu artykuły trzeba pobrać na komputer, a potem... jeszcze nie wiem. Na razie będą musiały jeszcze trochę poczekać - wciąż głowię się nad rozsądną metodą ich weryfikowania. c:'),
      Paragraph(text: 'Czuwaj!'),
      Paragraph(text: 'PS\nJeżeli się nad tym zastanawiacie, to nie: Nie wszystko, co napiszecie będzie publikowanie. Standardy będą wysokie, nie tylko językowe. c:'),
      Header(),
      Paragraph(text: '')
    ];
    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    return Center(
      child: Container(
        constraints: BoxConstraints(
            maxWidth: 1000
        ),
        child: Card(
          elevation: 6.0,
          child: Scaffold(
              appBar: AppBar(
                backgroundColor: Colors.black,
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    HarcApp(size: 18, color: Colors.white54,),
                    Text('Edytor artykułu',
                      style: AppTextStyle(fontSize: 14, color: Colors.white54),
                    )
                  ],
                ),
                actions: [

                  IconButton(
                    icon: Icon(Icons.image, color: HEADER_TEXT_COLOR),
                    onPressed: () async {

                      imageBytes = await ImagePickerWeb.getImage(outputType: ImageType.bytes);

                      setImage(imageBytes);

                    },
                  ),
                ],
              ),
              body: ArticleElementListWidget(
                  page: this,
                  header: Column(
                    children: [
                      ArticleTop(this),
                      SizedBox(width: MARGIN),
                      Padding(
                        padding: EdgeInsets.all(MARGIN),
                        child: TextField(
                          controller: TextEditingController(text: intro),
                          decoration: InputDecoration(
                              hintText: 'Krótki, przykuwający uwagę wstęp...',
                              hintStyle: AppTextStyle(
                                  fontSize: FONT_SIZE_NORM,
                                  color: AppColors.text_hint_enab,
                                  fontStyle: FontStyle.italic
                              ),
                              border: InputBorder.none
                          ),
                          maxLines: null,
                          keyboardType: TextInputType.multiline,
                          style: AppTextStyle(
                              fontSize: FONT_SIZE_NORM,
                              color: AppColors.text_def_enab,
                              fontStyle: FontStyle.italic
                          ),
                          maxLength: 500,
                        ),
                      )

                    ],
                  ),
                  footer: Padding(
                    padding: EdgeInsets.only(bottom: 100),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(top: MARGIN),
                          child: SimpleButton(
                            onTap: (){
                              setState(() => articleElements.add(Header()));
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Padding(
                                  padding: EdgeInsets.all(Dimen.icon_margin),
                                  child: Icon(Icons.add),
                                ),

                                SizedBox(width: MARGIN),
                                Text(
                                    'Dodaj nagłówek',
                                    style: AppTextStyle(
                                        fontSize: FONT_SIZE_NORM,
                                        fontWeight: weight.halfBold,
                                        color: Colors.black
                                    )
                                ),
                                SizedBox(width: 20),
                              ],
                            ),
                          ),
                        ),

                        SizedBox(width: MARGIN),

                        Padding(
                          padding: EdgeInsets.only(top: MARGIN),
                          child: SimpleButton(
                            onTap: (){
                              setState(() => articleElements.add(Paragraph()));
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Padding(
                                  padding: EdgeInsets.all(Dimen.icon_margin),
                                  child: Icon(Icons.playlist_add),
                                ),

                                SizedBox(width: MARGIN),
                                Text(
                                    'Dodaj akapit',
                                    style: AppTextStyle(
                                        fontSize: FONT_SIZE_NORM,
                                        fontWeight: weight.halfBold,
                                        color: Colors.black
                                    )
                                ),
                                SizedBox(width: 20),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ),
            floatingActionButton: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FloatingButton(Icons.input, Colors.blueGrey, 'Wczytaj', () async {

                  FilePickerCross filePicker = FilePickerCross();
                  await filePicker.pick();

                  Uint8List uint8List = filePicker.toUint8List();
                  String code = utf8.decode(uint8List);

                  Article article = Article.fromJson(code);

                  title = article.title;
                  articleDate = article.dateTime;
                  articleElements = article.items;
                  setImage(article.imageBytes);
                  setState(() {});

                }),
                SizedBox(width: 20),
                FloatingButton(Icons.check, Colors.blueAccent, 'Zapisz', (){

                  if(title == null || title.length==0){
                    Fluttertoast.showToast(
                        msg: "Podaj tytuł artykułu.",
                        toastLength: Toast.LENGTH_LONG,
                        gravity: ToastGravity.CENTER,
                        timeInSecForIosWeb: 2,
                        backgroundColor: Colors.black,
                        textColor: Colors.white,
                        fontSize: 16.0
                    );
                    return;
                  }

                  Article article = Article(
                      imageBytes,
                      articleDate,
                      title,
                      intro,
                      articleElements
                  );

                  String json = jsonEncode(article.toJson());

                  final bytes = utf8.encode(json);
                  final blob = html.Blob([bytes]);
                  final url = html.Url.createObjectUrlFromBlob(blob);
                  final anchor = html.document.createElement('a') as html.AnchorElement
                    ..href = url
                    ..style.display = 'none'
                    ..download = '${article.title.toLowerCase()}.harcapp_article';
                  html.document.body.children.add(anchor);

                  anchor.click();

                  html.document.body.children.remove(anchor);
                  html.Url.revokeObjectUrl(url);
                })
              ],
            )
          ),
        ),
      ),
    );

  }

  void removeElement(ArticleElement element) => setState(() => articleElements.remove(element));

  void setImage(Uint8List imageBytes) => imageBytes==null?null:setState(() => this.imageBytes = imageBytes);
}


class FloatingButton extends StatelessWidget{

  IconData iconData;
  Color color;
  String text;
  Function onPressed;

  FloatingButton(this.iconData, this.color, this.text, this.onPressed);

  @override
  Widget build(BuildContext context) {

    return RawMaterialButton(
        fillColor: color,
        padding: EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(100))),
        elevation: 6.0,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              iconData,
              color: Colors.white,
            ),

            SizedBox(width: 16),

            Text(
                text,
                style: AppTextStyle(
                    fontWeight: weight.bold,
                    fontSize: 16,
                    color: Colors.white
                )
            ),
            SizedBox(width: 10),
          ],
        ),
        onPressed: onPressed
    );
  }

}

class ArticleTop extends StatelessWidget{

  final ArticleEditorPageState page;

  const ArticleTop(this.page);

  DateTime get articleDate => page.articleDate;
  set articleDate(value) => page.articleDate = value;

  Uint8List get imageBytes => page.imageBytes;

  @override
  Widget build(BuildContext context) {

    Widget child = Column(
      children: [
        Row(
          children: [
            Expanded(child: Container()),
            SimpleButton(
              onTap: () async {
                DateTime dateTime = await showDatePicker(
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
                '${articleDate.day} ${month[articleDate.month]} ${articleDate.year} A.D.',
                style: ArticleTextStyle(
                    fontSize: FONT_SIZE_NORM,
                    fontWeight: weight.bold,
                    color: HEADER_TEXT_COLOR
                ),
              ),
            ),
          ],
        ),

        TextField(
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
      ],
    );

    return AnimatedContainer(
      duration: Duration(milliseconds: 400),
      child: Stack(
        children: [

          AspectRatio(
            aspectRatio: 2,
            child: Image(
              image: page.imageBytes==null?
              AssetImage('assets/images/def_bg.webp'):
              Image.memory(imageBytes).image,
              fit: BoxFit.cover,
            ),
          ),

          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter, // 10% of the width, so there are ten blinds.
                colors: [Colors.black, Colors.transparent], // whitish to gray
                tileMode: TileMode.repeated, // repeats the gradient over the canvas
              ),
            ),
          ),

          child
        ],
      ),
    );

  }

}


class ArticleElementListWidget extends StatefulWidget{

  List<ArticleElement> get articleElements => page.articleElements;


  final ArticleEditorPageState page;

  final Widget header;
  final Widget footer;

  const ArticleElementListWidget({@required this.page, this.header, this.footer});

  @override
  State<StatefulWidget> createState() => ArticleElementListWidgetState();

}

class ArticleElementListWidgetState extends State<ArticleElementListWidget>{

  List<ArticleElement> get articleElements => widget.articleElements;

  @override
  Widget build(BuildContext context) {
    return ImplicitlyAnimatedReorderableList<ArticleElement>(
      items: articleElements,
      areItemsTheSame: (oldItem, newItem) => oldItem.hashCode == newItem.hashCode,
      onReorderFinished: (item, from, to, newItems) {
        // Remember to update the underlying data when the list has been
        // reordered.

        setState(() {
          articleElements
            ..clear()
            ..addAll(newItems);
        });
      },
      itemBuilder: (context, itemAnimation, item, index) {
        
        Widget child;
        if(item is Paragraph)
          child = ParagraphWidget(
              widget.page,
              item
          );
        else if (item is Header)
          child = HeaderWidget(
              widget.page,
              item
          );
        
        return Reorderable(
          key: ValueKey(item.hashCode),
          builder: (context, dragAnimation, inDrag) {
            final t = dragAnimation.value;
            final elevation = ui.lerpDouble(0, 8, t);
            final color = Color.lerp(Colors.white, Colors.white.withOpacity(0.8), t);

            return SizeFadeTransition(
              sizeFraction: 0.7,
              curve: Curves.easeInOut,
              animation: itemAnimation,
              child: Material(
                color: color,
                elevation: elevation,
                type: MaterialType.transparency,
                child: child
              ),
            );
          },
        );
      },
      header: widget.header??Container(),
      footer: widget.footer??Container(),
      shrinkWrap: true,
      padding: EdgeInsets.all(MARGIN),
    );
  }

}