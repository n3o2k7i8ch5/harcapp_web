import 'package:clipboard/clipboard.dart';
import 'package:flutter/material.dart';
import 'package:harcapp_core/comm_classes/app_text_style.dart';
import 'package:harcapp_core/comm_classes/color_pack.dart';
import 'package:harcapp_core/comm_widgets/app_card.dart';
import 'package:harcapp_core/comm_widgets/app_scaffold.dart';
import 'package:harcapp_core/comm_widgets/app_text_field_hint.dart';
import 'package:harcapp_core/comm_widgets/simple_button.dart';
import 'package:harcapp_core/dimen.dart';
import 'package:harcapp_web/common/download_file.dart';
import 'package:harcapp_web/common/google_form_sender.dart';
import 'package:harcapp_web/songs/providers.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';

const String EMAIL_TO_SEND = 'harcapp@gmail.com';

class SaveSendWidget extends StatelessWidget{

  @override
  Widget build(BuildContext context) => SizedBox(
    height: Dimen.ICON_FOOTPRINT,
    child: Material(
      clipBehavior: Clip.hardEdge,
      color: cardEnab_(context),
      borderRadius: BorderRadius.circular(AppCard.bigRadius),
      child: Row(
        children: [

          Expanded(
              child: Consumer<SongFileNameDupErrProvider>(
                builder: (context, prov, child) => SimpleButton(
                    padding: EdgeInsets.all(Dimen.ICON_MARG),
                    radius: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          MdiIcons.folderDownloadOutline,
                          color: prov.count==0?iconEnab_(context):iconDisab_(context),
                        ),
                        SizedBox(width: Dimen.ICON_MARG),
                        Text(
                          'Zapisz wszystko',
                          style: AppTextStyle(
                              fontWeight: weight.halfBold,
                              color: prov.count==0?iconEnab_(context):iconDisab_(context)
                          ),
                        )
                      ],
                    ),
                    onTap: prov.count!=0?null:(){

                      SongFileNameDupErrProvider songFileNameDupErrProv = SongFileNameDupErrProvider.of(context);
                      songFileNameDupErrProv.checkAllDups(context);

                      if(songFileNameDupErrProv.count != 0) return;

                      AllSongsProvider allSongsProv = AllSongsProvider.of(context);
                      String code = allSongsProv.convertAllToCode();

                      int songCount = AllSongsProvider.of(context).length;
                      if(songCount <= 4)
                        AppScaffold.showMessage(context, 'Rozpoczęto pobieranie $songCount piosenki', duration: Duration(seconds: 5));
                      else
                        AppScaffold.showMessage(context, 'Rozpoczęto pobieranie $songCount piosenek', duration: Duration(seconds: 5));

                      downloadFile(content: code, fileName: '${songCount}_songs.hrcpsng');
                      AllSongsProvider.clearCachedSongs();
                    }
                ),
              )
          ),

          Expanded(
              child: SimpleButton(
                  padding: EdgeInsets.all(Dimen.ICON_MARG),
                  radius: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(MdiIcons.sendCircleOutline),
                      SizedBox(width: Dimen.ICON_MARG),
                      Text(
                        'Prześlij',
                        style: AppTextStyle(fontWeight: weight.halfBold, color: iconEnab_(context)),
                      )
                    ],
                  ),
                  onTap: () => showDialog(
                      context: context,
                      builder: (context) => Center(
                        child: SendSongWidget(),
                      )
                  )
              )
          ),

        ],
      ),
    ),
  );

}

class SendSongWidget extends StatefulWidget{

  @override
  State<StatefulWidget> createState() => SendSongWidgetState();

}

class SendSongWidgetState extends State<SendSongWidget>{

  static const String FORMS_URL = 'https://docs.google.com/forms/d/e/1FAIpQLSc4JtoEwQey4_MuE85SJ6oISyAfsgMlwTPMxkv84r-H1MFK6g/formResponse';

  static RegExp emailRegExp = RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+");

  TextEditingController? controller;

  @override
  void initState() {
    controller = TextEditingController(text: '');
    super.initState();
  }
  @override
  Widget build(BuildContext context) {

    bool sendable = emailRegExp.hasMatch(controller!.text);

    AllSongsProvider allSongsProv = AllSongsProvider.of(context);

    return SizedBox(
      width: 400,
      child: AppCard(
        radius: AppCard.bigRadius,
        padding: EdgeInsets.all(2*Dimen.ICON_MARG),
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
              hintStyle: AppTextStyle(color: hintEnab_(context)),
              style: AppTextStyle(color: textEnab_(context)),
              controller: controller,
              onAnyChanged: (text) => setState((){}),
            ),

            SizedBox(height: 20),

            Text(
              'Na adres email wysłana zostanie kopia przesyłanych piosenek.'
                  '\n\n'
                  'Możesz także pobrać plik z piosenkami i przesłać go na adres:',
              style: AppTextStyle(color: hintEnab_(context), fontSize: Dimen.TEXT_SIZE_NORMAL),
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
                    padding: EdgeInsets.all(Dimen.ICON_MARG),
                    child: Row(
                      children: [
                        Text(
                          'Prześlij',
                          style: AppTextStyle(
                            fontWeight: weight.halfBold,
                            color: sendable?iconEnab_(context):iconDisab_(context)
                          ),
                        ),
                        SizedBox(width: Dimen.ICON_MARG),
                        Icon(
                            MdiIcons.send,
                            color: sendable?iconEnab_(context):iconDisab_(context)
                        ),
                      ],
                    ),
                    onTap: sendable? ()async{

                      try {
                        GoogleFormSender sender = GoogleFormSender(FORMS_URL);
                        sender.addTextResponse('entry.1848845001', allSongsProv.convertAllToCode());
                        sender.addTextResponse('emailAddress', controller!.text);
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