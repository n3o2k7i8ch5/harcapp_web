import 'dart:convert';
import 'dart:math';

import 'package:clipboard/clipboard.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:harcapp_core/comm_classes/app_text_style.dart';
import 'package:harcapp_core/comm_classes/color_pack.dart';
import 'package:harcapp_core/comm_widgets/app_card.dart';
import 'package:harcapp_core/comm_widgets/app_scaffold.dart';
import 'package:harcapp_core/comm_widgets/app_text_field_hint.dart';
import 'package:harcapp_core/comm_widgets/simple_button.dart';
import 'package:harcapp_core/dimen.dart';
import 'package:harcapp_core_own_song/song_raw.dart';
import 'package:harcapp_web/common/download_file.dart';
import 'package:harcapp_web/common/google_form_sender.dart';
import 'package:harcapp_web/songs/providers.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';

const String EMAIL_TO_SEND = 'harcapp@gmail.com';

class SaveSendWidget extends StatelessWidget{

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [

        Expanded(
            child: Consumer<SongFileNameDupErrProvider>(
              builder: (context, prov, child) => SimpleButton(
                  padding: EdgeInsets.all(Dimen.MARG_ICON),
                  margin: EdgeInsets.zero,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        MdiIcons.folderDownloadOutline,
                        color: prov.count==0?iconEnabledColor(context):iconDisabledColor(context),
                      ),
                      SizedBox(width: Dimen.MARG_ICON),
                      Text(
                        'Zapisz',
                        style: AppTextStyle(
                            fontWeight: weight.halfBold,
                            color: prov.count==0?iconEnabledColor(context):iconDisabledColor(context)
                        ),
                      )
                    ],
                  ),
                  onTap: prov.count!=0?null:(){

                    SongFileNameDupErrProvider songFileNameDupErrProv = Provider.of<SongFileNameDupErrProvider>(context, listen: false);
                    songFileNameDupErrProv.checkAllDups(context);

                    if(songFileNameDupErrProv.count != 0) return;

                    String code = convertAllToCode(context);

                    downloadFile(content: code, fileName: 'songs.hrcpsng');
                  }
              ),
            )
        ),

        Expanded(
            child: SimpleButton(
                padding: EdgeInsets.all(Dimen.MARG_ICON),
                margin: EdgeInsets.zero,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(MdiIcons.sendCircleOutline),
                    SizedBox(width: Dimen.MARG_ICON),
                    Text(
                      'Prześlij',
                      style: AppTextStyle(fontWeight: weight.halfBold, color: iconEnabledColor(context)),
                    )
                  ],
                ),
                onTap: ()async{

                  showDialog(
                    context: context,
                    builder: (context) => Center(
                      child: SendSongWidget(

                      ),
                    )
                  );


                }
            )
        ),
        
      ],
    );
  }

}

class SendSongWidget extends StatefulWidget{

  @override
  State<StatefulWidget> createState() => SendSongWidgetState();

}

class SendSongWidgetState extends State<SendSongWidget>{

  static const String FORMS_URL = 'https://docs.google.com/forms/d/e/1FAIpQLSc4JtoEwQey4_MuE85SJ6oISyAfsgMlwTPMxkv84r-H1MFK6g/formResponse';

  static RegExp emailRegExp = RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+");

  TextEditingController controller;

  @override
  void initState() {
    controller = TextEditingController(text: '');
    super.initState();
  }
  @override
  Widget build(BuildContext context) {

    bool sendable = emailRegExp.hasMatch(controller.text);
    print(controller.text);
    print(sendable);

    return SizedBox(
      width: 400,
      child: AppCard(
        padding: EdgeInsets.all(2*Dimen.MARG_ICON),
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [

            Text(
              'Prześlij piosenki do weryfikacji',
              style: AppTextStyle(fontWeight: weight.halfBold, fontSize: Dimen.TEXT_SIZE_APPBAR),
            ),

            SizedBox(height: 20),

            AppTextFieldHint(
              hint: 'Podaj swój email:',
              hintTop: 'Email:',
              hintStyle: AppTextStyle(color: hintEnabled(context)),
              style: AppTextStyle(color: textEnabled(context)),
              controller: controller,
              onChanged: (text) => setState((){}),
            ),

            SizedBox(height: 20),

            Text(
              'Na adres email wysłana zostanie kopia przesyłanych piosenek.'
                  '\n\n'
                  'Możesz także pobrać plik z piosenkami i przesłać go na adres:',
              style: AppTextStyle(color: hintEnabled(context), fontSize: Dimen.TEXT_SIZE_NORMAL),
            ),

            Row(
              children: [
                SelectableText(EMAIL_TO_SEND, style: AppTextStyle(fontWeight: weight.halfBold)),
                IconButton(icon: Icon(MdiIcons.contentCopy), onPressed: () => FlutterClipboard.copy(EMAIL_TO_SEND))
              ],
            ),

            SizedBox(height: 20),

            Row(
              children: [
                if(!sendable)
                  Text('Podaj email.', style: AppTextStyle(color: Colors.red)),

                Expanded(child: Container()),
                SimpleButton(
                    padding: EdgeInsets.all(Dimen.MARG_ICON),
                    child: Row(
                      children: [
                        Text(
                          'Prześlij',
                          style: AppTextStyle(
                            fontWeight: weight.halfBold,
                            color: sendable?iconEnabledColor(context):iconDisabledColor(context)
                          ),
                        ),
                        SizedBox(width: Dimen.MARG_ICON),
                        Icon(
                            MdiIcons.send,
                            color: sendable?iconEnabledColor(context):iconDisabledColor(context)
                        ),
                      ],
                    ),
                    onTap: sendable? ()async{

                      try {
                        GoogleFormSender sender = GoogleFormSender(FORMS_URL);
                        sender.addTextResponse('entry.1848845001', convertAllToCode(context));
                        sender.addTextResponse('emailAddress', controller.text);
                        await sender.submit();

                        AppScaffold.showMessage(context, 'Przesłano piosenkę. Dzięki!');
                        Navigator.pop(context);

                      } catch (e){

                        AppScaffold.showMessage(context,
                          'Błąd! Niestety funkcja wysyłania wciąż czasami nie działa. Pobierz piosenkę i prześlij plik na <b>$EMAIL_TO_SEND</b>',
                          duration: Duration(seconds: 10)
                        );

                      }
                    }:null

                ),
              ],
            )
          ],
        ),
      ),
    );
  }

}

String convertAllToCode(BuildContext context){

  Map offSongMap = {};
  Map confSongMap = {};

  AllSongsProvider allSongsProv = Provider.of<AllSongsProvider>(context, listen: false);
  List<SongRaw> allSongs = allSongsProv.songs;

  allSongs.sort(
          (a, b) => compare(a.title, b.title)
  );

  int iterOff = 0;
  int iterConf = 0;
  for(SongRaw song in allSongs){
    Map map = song.toMap(withFileName: false);
    if(allSongsProv.isConf(song))
      confSongMap[song.fileName] = {
        'song': map,
        'index': iterConf++
      };
    else
      offSongMap[song.fileName] = {
        'song': map,
        'index': iterOff++
      };
  }

  String code = jsonEncode({
    'official': offSongMap,
    'conf': confSongMap,
  });

  return code;
}

int compare(String s1, String s2){

  s1 = s1.toLowerCase()
      .replaceAll(RegExp(r'[^a-ząćęłńóśźżA-ZĄĆĘŁŃÓŚŹŻ0-9]'), '');

  s2 = s2.toLowerCase()
      .replaceAll(RegExp(r'[^a-ząćęłńóśźżA-ZĄĆĘŁŃÓŚŹŻ0-9]'), '');

  String a_ja = 'a ja nie chcę czekolady';
  if(s1 == a_ja || s2 == a_ja)
    int a = 10;

  for(int i=0; i<min(s1.length, s2.length); i++){

    String c1 = s1[i];
    String c2 = s2[i];

    int int1 = charToInt(c1);
    int int2 = charToInt(c2);

    if(int1 != int2)
      return int1-int2;

  }

  return s1.length - s2.length;
}

int charToInt(String c) {
  switch (c) {
    case ' ':
      return 0;
    case 'a':
      return 1;
    case 'ą':
      return 2;
    case 'b':
      return 3;
    case 'c':
      return 4;
    case 'ć':
      return 5;
    case 'd':
      return 6;
    case 'e':
      return 7;
    case 'ę':
      return 8;
    case 'f':
      return 9;
    case 'g':
      return 10;
    case 'h':
      return 11;
    case 'i':
      return 12;
    case 'j':
      return 13;
    case 'k':
      return 14;
    case 'l':
      return 15;
    case 'ł':
      return 16;
    case 'm':
      return 17;
    case 'n':
      return 18;
    case 'ń':
      return 19;
    case 'o':
      return 20;
    case 'ó':
      return 21;
    case 'p':
      return 22;
    case 'q':
      return 23;
    case 'r':
      return 24;
    case 's':
      return 25;
    case 'ś':
      return 26;
    case 't':
      return 27;
    case 'u':
      return 28;
    case 'v':
      return 29;
    case 'w':
      return 30;
    case 'x':
      return 31;
    case 'y':
      return 32;
    case 'z':
      return 33;
    case 'ź':
      return 34;
    case 'ż':
      return 35;
    default:
      return -1;
  }
}