import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:html' as html;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/rendering.dart';
import 'package:harcapp_core/colors.dart';
import 'package:harcapp_core/comm_classes/app_text_style.dart';
import 'package:harcapp_core/comm_widgets/app_scaffold.dart';
import 'package:harcapp_core/comm_widgets/simple_button.dart';
import 'package:harcapp_core/dimen.dart';
import 'package:harcapp_web/common/float_act_butt.dart';
import 'package:image/image.dart' as im;

import 'article_elements.dart';
import 'article_top.dart';
import 'articles_other.dart';
import 'common.dart';

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

class ArticleEditorPageState extends State<ArticleEditorPage> with AutomaticKeepAliveClientMixin{

  @override
  bool get wantKeepAlive => true;

  String? title;
  String? intro;
  String? imageSource;
  String? authCode;
  List<OtherArtItem>? otherArts;

  DateTime? articleDate;
  Uint8List? imageBytes;

  ValueNotifier? topNotifier;
  late ScrollController scrollController;

  List<ArticleElement?>? articleElements;

  bool saving = false;

  @override
  void initState() {
    otherArts = [];
    articleDate = DateTime.now();
    articleElements = [
      Header(text: 'Chodzi Ci po głowie napisanie artykułu do HarcAppki?'),
      Paragraph(text: '"Jakiego artykułu?", "O co chodzi?", "Przecież w HarcAppce nie ma żadnych artykułów!"'),
      Paragraph(text: 'To prawda, nie ma, ale już niebawem aplikacji pojawi się możliwość publikowania swoich felietonów, rozważań, dywakacji i doświadczeń o tematyce harcerskiej. Ta strona jest częścią tego planu - została stworzona, żeby w łatwy sposób umożliwić napisanie tego, czym chcielibyście podzielić się w HarcAppce.'),
      Paragraph(text: 'Strona jest w formie szablonowej - jest wciaż trochę toporna, a część błędów (np. zachowanie kursora) póki co jest nierozwiązywalna. Ale! jak ktoś chce, proszę, można już z niej testowo korzystać.'),
      Header(text: 'Co zrobić z napisanym artykułem?'),
      Paragraph(text: 'Stworzone tu artykuły należy pobrać na komputer, a następnie wysłać mailem (gdzie dokładnie? Za wcześnie, żeby powiedzieć). Na razie artykuły będą musiały trochę poczekać - rozważam rozsądne metody ich weryfikowania. c:'),
      Paragraph(text: 'Czuwaj!'),
      Paragraph(text: 'PS\nNie wszystko, co napiszecie będzie publikowanie. Wprowadzone zostaną jasne, ale wysokie standardy, nie tylko językowe.'),
      Header(),
      Paragraph(text: '')
    ];

    saving = false;

    topNotifier = ValueNotifier<double>(0.0);
    scrollController = ScrollController();
    scrollController.addListener(() => topNotifier!.value = scrollController.offset);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
        body: ArticleElementListWidget(
          page: this,
          //scrollController: scrollController, To niestety nie działa! <ValueNotifier>
          header: Column(
            children: [
              ArticleTop(this),
              SizedBox(width: MARGIN),

              Padding(
                padding: EdgeInsets.all(MARGIN),
                child: TextField(
                  controller: TextEditingController(text: intro),
                  decoration: InputDecoration(
                      hintText: 'Krótki, przykuwający uwagę wstęp... '
                          '(wstęp wyświetla się także przy przeglądaniu listy artykułów)',
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
                  onChanged: (text) => this.intro = text,
                ),
              )

            ],
          ),
          footer: Padding(
              padding: EdgeInsets.only(bottom: 100),
              child: Column(
                children: [

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(top: MARGIN),
                        child: SimpleButton(
                          onTap: (){
                            setState(() => articleElements!.add(Header()));
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Padding(
                                padding: EdgeInsets.all(Dimen.ICON_MARG),
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
                            setState(() => articleElements!.add(Paragraph()));
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Padding(
                                padding: EdgeInsets.all(Dimen.ICON_MARG),
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

                  Padding(
                    padding: EdgeInsets.all(MARGIN),
                    child: TextField(
                      controller: TextEditingController(text: authCode??''),
                      decoration: InputDecoration(
                          hintText: 'Kod autora...',
                          hintStyle: AppTextStyle(
                              fontSize: FONT_SIZE_NORM,
                              color: AppColors.text_hint_enab,
                              fontWeight: weight.halfBold
                          ),
                          border: InputBorder.none
                      ),
                      maxLines: 1,
                      keyboardType: TextInputType.multiline,
                      style: AppTextStyle(
                          fontSize: FONT_SIZE_NORM,
                          color: AppColors.text_def_enab,
                          fontWeight: weight.halfBold
                      ),
                      onChanged: (text) => this.authCode = text,
                      textAlign: TextAlign.end,
                    ),
                  ),

                  ArticlesOther(this),

                ],
              )
          ),
        ),
        floatingActionButton: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FloatingButton(Icons.input, Colors.blueGrey, 'Wczytaj artykuł', saving?null: () async {

              FilePickerResult? result = await FilePicker.platform.pickFiles();

              if(result==null)
                return;


              //FilePickerCross filePicker = FilePickerCross();
              //await filePicker.pick();
              try {
                Uint8List uint8List = result.files.single.bytes!;
                String code = utf8.decode(uint8List);

                Article article = Article.fromJson(code);

                title = article.title;
                intro = article.intro;
                authCode = article.authCode;
                articleDate = article.date;
                articleElements = article.items;
                setImage(article.imageBytes);
                imageSource = article.imageSource;

                for (String str in article.otherArts)
                  otherArts!.add(OtherArtItem(str));


              } on Exception catch (error){

                AppScaffold.showMessage(context, 'Wystąpił błąd: ${error.toString()}');
                print(error.toString());

              }
              setState(() {});

            }),
            SizedBox(width: 20),
            FloatingButton(
                Icons.check,
                Colors.blueAccent,
                saving?'Zapisywanie...':'Zapisz atrykuł', saving?null:(){

              if(title == null || title!.length==0){
                AppScaffold.showMessage(context, "Podaj tytuł artykułu.");
                return;
              }

              if(intro == null || intro!.length==0){
                AppScaffold.showMessage(context, "Wstęp artykułu nie może być pusty.");
                return;
              }

              if(authCode == null || authCode!.length==0){
                AppScaffold.showMessage(context, "Nie został podany autor artykułu.");
                return;
              }

              setState(() => saving = true);

              ()async{

                if(imageBytes!=null)
                  imageBytes = await compute<Uint8List?, Uint8List>(resize, imageBytes);

                List<OtherArtItem> notEmptyOthertArts = [];
                for(OtherArtItem item in otherArts!)
                  if(item.string != null && item.string.length>0)
                    notEmptyOthertArts.add(item);

                Article article = Article(
                    imageBytes,
                    imageSource,
                    authCode,
                    articleDate,
                    title,
                    intro,
                    articleElements,
                    notEmptyOthertArts.map((item) => item.string).toList()
                );

                String json = jsonEncode(article.toJson());

                final bytes = utf8.encode(json);
                final blob = html.Blob([bytes]);
                final url = html.Url.createObjectUrlFromBlob(blob);
                final anchor = html.document.createElement('a') as html.AnchorElement
                  ..href = url
                  ..style.display = 'none'
                  ..download = '${article.date!.year}'
                      '_${article.date!.month}'
                      '_${article.date!.day}_'
                      '${remSpecChars(remPolChars(article.title!.replaceAll(' ', '_')))}.hrcpartcl';
                html.document.body!.children.add(anchor);

                anchor.click();

                html.document.body!.children.remove(anchor);
                html.Url.revokeObjectUrl(url);

                setState(() => saving = false);

              }();

            }, saving: saving)
          ],
        )
    );

  }

  void removeElement(ArticleElement element) => setState(() => articleElements!.remove(element));

  void setImage(Uint8List? imageBytes) => imageBytes==null?null:setState(() => this.imageBytes = imageBytes);

}

Uint8List resize(Uint8List? imageBytes) {

  im.Image image = im.decodeImage(imageBytes!)!;

  if(image.width<image.height)
    image = im.copyResize(image, width: 1000);
  else
    image = im.copyResize(image, height: 1000);

  imageBytes = Uint8List.fromList(im.encodeJpg(image, quality: 80));

  return imageBytes;
}