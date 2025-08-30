import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:harcapp_core/values/colors.dart';
import 'package:harcapp_core/comm_classes/app_text_style.dart';
import 'package:harcapp_core/comm_widgets/app_scaffold.dart';
import 'package:harcapp_core/comm_widgets/simple_button.dart';
import 'package:harcapp_core/values/dimen.dart';

import 'package:image/image.dart' as im;
import 'package:image_picker_web/image_picker_web.dart';

import '../common/author.dart';
import '../common/float_act_butt.dart';
import 'article_editor/article_editor.dart';
import 'article_editor/common.dart';

class AuthorEditorPage extends StatefulWidget{

  @override
  State<StatefulWidget> createState() => AuthorEditorPageState();

}

class AuthorEditorPageState extends State<AuthorEditorPage> with AutomaticKeepAliveClientMixin{

  @override
  bool get wantKeepAlive => true;

  bool? saving;
  Uint8List? imageBytes;

  late TextEditingController nameController;
  String get name => nameController.text;

  late TextEditingController descController;
  String get desc => descController.text;


  @override
  void initState() {

    nameController = TextEditingController(text: '');
    descController = TextEditingController(text: '');

    saving = false;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
        body: Padding(
          padding: EdgeInsets.all(MARGIN),
          child: ListView(
            children: [

              Text(
                'Ta sekcja służy jedynie stworzeniu pliku z danymi autora.'
                '\nAby dodać informację do artykułu o autorze, przejdź do sekcji "Stwórz artykuł".'
                '\n',
                style: AppTextStyle(
                  fontSize: FONT_SIZE_NORM,
                  fontWeight: weightHalfBold,
                  color: Colors.red,
                ),
                textAlign: TextAlign.center,
              ),

              Card(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    SizedBox(
                      height: 200,
                      width: 200,
                      child: imageBytes==null?
                      SimpleButton(
                        onTap: () async {
                          await loadImage(context, this);
                        },
                        child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [

                                Icon(Icons.account_box, size: 64, color: AppColors.textHintEnab),
                                SizedBox(height: Dimen.iconMarg),

                                Padding(
                                  padding: EdgeInsets.all(10.0),
                                  child: Text(
                                    'KLIKNIJ, BY WCZYTAĆ ZDJĘCIE',
                                    textAlign: TextAlign.center,
                                    style: AppTextStyle(
                                        color: AppColors.textHintEnab,
                                        fontWeight: weightBold
                                    ),
                                  ),
                                )
                              ],
                            )
                        ),
                      ):
                      Stack(
                        children: [

                          Positioned(
                            top: 0,
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Image(
                              image: MemoryImage(imageBytes!),
                              fit: BoxFit.cover,
                            ),
                          ),

                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Material(
                              color: Colors.transparent,
                              child: SimpleButton(
                                padding: EdgeInsets.zero,
                                onTap: () async => await loadImage(context, this),
                                child: Container(
                                  color: Color.fromARGB(140, 0, 0, 0),
                                  child: Padding(
                                    padding: EdgeInsets.all(Dimen.defMarg),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [

                                        Icon(Icons.account_box, color: Colors.white,),
                                        SizedBox(width: Dimen.iconMarg),
                                        Text(
                                          'ZMIEŃ OBRAZ',
                                          style: AppTextStyle(
                                              fontWeight: weightBold,
                                              color: Colors.white
                                          ),
                                        )

                                      ],
                                    ),
                                  )
                                )
                              ),
                            ),
                          )

                        ],
                      ),
                    ),

                    SizedBox(width: 3*MARGIN),

                    Expanded(
                      child: Column(
                        children: [

                          SizedBox(height: Dimen.iconMarg),

                          Row(
                            children: [

                              Text(
                                'Kod autora: ',
                                style: AppTextStyle(
                                  fontSize: FONT_SIZE_NORM,
                                  color: AppColors.textHintEnab
                                ),
                              ),

                              SelectableText(
                                remSpecChars(remPolChars(name.replaceAll(' ', '_'))),
                                style: AppTextStyle(
                                  fontSize: FONT_SIZE_NORM,
                                  fontWeight: weightHalfBold,
                                  color: AppColors.textHintEnab
                                ),
                              ),

                            ],
                          ),

                          TextField(
                            decoration: InputDecoration(
                                hintText: 'Imię i nazwisko...',
                                hintStyle: AppTextStyle(
                                    fontSize: 1.5*FONT_SIZE_NORM,
                                    color: AppColors.textHintEnab,
                                    fontWeight: weightHalfBold,
                                  shadow: true
                                ),
                                border: InputBorder.none
                            ),
                            controller: nameController,
                            maxLines: 1,
                            style: AppTextStyle(
                                fontSize: 1.5*FONT_SIZE_NORM,
                                color: AppColors.textDefEnab,
                                fontWeight: weightHalfBold,
                                shadow: true
                            ),
                            onChanged: (text) => setState((){}),
                          ),

                          TextField(
                            decoration: InputDecoration(
                                hintText: 'Opis...',
                                hintStyle: AppTextStyle(
                                  fontSize: FONT_SIZE_NORM,
                                  color: AppColors.textHintEnab,
                                ),
                                border: InputBorder.none
                            ),
                            controller: descController,
                            maxLines: null,
                            maxLength: 350,
                            style: AppTextStyle(
                              fontSize: FONT_SIZE_NORM,
                              color: AppColors.textDefEnab,
                            ),
                          ),

                          SizedBox(height: Dimen.iconMarg),

                        ],
                      ),
                    ),

                    SizedBox(width: MARGIN),

                  ],
                ),
              ),

              SizedBox(height: MARGIN),

              // ZDJĘCIE
              Text(
                'Zdjęcie:\n',
                style: AppTextStyle(
                  fontSize: FONT_SIZE_NORM,
                  color: AppColors.textHintEnab,
                  fontWeight: weightBold
                ),
              ),

              Text(
                'Załączone zdjęcie powinno:'
                    '\n\t - być kwadratowe,'
                    '\n\t - przedstawiać autora w mundurze.',
                style: AppTextStyle(
                    fontSize: FONT_SIZE_NORM,
                    color: AppColors.textHintEnab,
                ),
              ),

              SizedBox(height: 3*MARGIN),

              // OPIS
              Text(
                'Opis:\n',
                style: AppTextStyle(
                    fontSize: FONT_SIZE_NORM,
                    color: AppColors.textHintEnab,
                    fontWeight: weightBold
                ),
              ),

              Text(
                'Opis powinien być krótki, treściwy i ciekawy. Może zawierać informacje takie jak:'
                    '\n\t - doświadczenie harcerskie,'
                    '\n\t - pełnione funkcje,'
                    '\n\t - zainteresowania,'
                    '\n\t - środowisko harcerskie,'
                    '\n\t - miejsce pochodzenia,'
                    '\n\t - szczególne informacje,'
                    '\n\t - życiowe motto.',
                style: AppTextStyle(
                  fontSize: FONT_SIZE_NORM,
                  color: AppColors.textHintEnab,
                ),
              )

            ],
          ),
        ),
        floatingActionButton: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FloatingButton(Icons.input, Colors.blueGrey, 'Wczytaj autora', saving!?null: () async {

              // FilePickerCross filePicker = await FilePickerCross.importFromStorage(
              //     type: FileTypeCross.custom,
              //     fileExtension: '.hrcpsng'
              // );

              FilePickerResult? result = await FilePicker.platform.pickFiles();

              //FilePickerCross filePicker = FilePickerCross();
              //await filePicker.pick();

              if(result==null)
                return;

              Uint8List uint8List = result.files.single.bytes!;
              String code = utf8.decode(uint8List);

              Author author = Author.fromJson(code);

              imageBytes = author.imageBytes;
              nameController.text = author.name!;
              descController.text = author.desc!;

              setState(() {});

            }),
            SizedBox(width: 20),
            FloatingButton(
                Icons.check,
                Colors.blueAccent,
                saving!?'Zapisywanie...':'Zapisz autora', saving!?null:(){


              if(name.isEmpty){
                AppScaffold.showMessage(context, text: "Nie podałeś swojego imienia i nazwiska.");
                return;
              }

              if(desc.isEmpty){
                AppScaffold.showMessage(context, text: "Napisz kilka słów o sobie!");
                return;
              }

              if(imageBytes == null){
                AppScaffold.showMessage(context, text: "Dodaj obraz swojej osoby.");
                return;
              }

              setState(() => saving = true);

              ()async{

                imageBytes = await compute<Uint8List?, Uint8List>(resize, imageBytes);


                Author author = Author(
                    imageBytes,
                    name,
                    desc
                );

                String json = jsonEncode(author.toJson());

                final bytes = utf8.encode(json);
                final blob = html.Blob([bytes]);
                final url = html.Url.createObjectUrlFromBlob(blob);
                final anchor = html.document.createElement('a') as html.AnchorElement
                  ..href = url
                  ..style.display = 'none'
                  ..download = '${remSpecChars(remPolChars(author.name!.replaceAll(' ', '_')))}.hrcpathr';
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

  void setImage(Uint8List? imageBytes) => imageBytes==null?null:setState(() => this.imageBytes = imageBytes);

}

Uint8List resize(Uint8List? imageBytes) {

  im.Image image = im.decodeImage(imageBytes!)!;

  image = im.copyResize(image, width: 400);

  imageBytes = Uint8List.fromList(im.encodeJpg(image, quality: 80));

  return imageBytes;
}

Future<void> loadImage(BuildContext context, AuthorEditorPageState state) async {
  Uint8List? imageBytes = await ImagePickerWeb.getImageAsBytes();

  if(imageBytes == null) return;

  ui.Image image = await decodeImageFromList(imageBytes);

  if(image.width != image.height)
    AppScaffold.showMessage(context, text: "Obraz musi być kwadratowy.");

  state.setState(() => state.imageBytes = imageBytes);
}