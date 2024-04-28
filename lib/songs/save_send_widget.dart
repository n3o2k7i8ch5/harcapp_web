import 'package:clipboard/clipboard.dart';
import 'package:flutter/material.dart';
import 'package:harcapp_core/comm_classes/app_text_style.dart';
import 'package:harcapp_core/comm_classes/color_pack.dart';
import 'package:harcapp_core/comm_widgets/app_card.dart';
import 'package:harcapp_core/comm_widgets/app_scaffold.dart';
import 'package:harcapp_core/comm_widgets/app_text_field_hint.dart';
import 'package:harcapp_core/comm_widgets/simple_button.dart';
import 'package:harcapp_core/dimen.dart';
import 'package:harcapp_core/song_book/song_editor/song_raw.dart';
import 'package:harcapp_web/common/alert_dialog.dart';
import 'package:harcapp_web/common/download_file.dart';
import 'package:harcapp_web/common/google_form_sender.dart';
import 'package:harcapp_web/songs/left_panel/song_tile.dart';
import 'package:harcapp_web/songs/providers.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';

const String EMAIL_TO_SEND = 'harcapp@gmail.com';

class SaveSendWidget extends StatelessWidget{

  @override
  Widget build(BuildContext context) => SizedBox(
    height: Dimen.iconFootprint,
    child: Material(
      clipBehavior: Clip.hardEdge,
      color: cardEnab_(context),
      borderRadius: BorderRadius.circular(AppCard.bigRadius),
      child: Row(
        children: [

          Expanded(
              child: Consumer<SongFileNameDupErrProvider>(
                builder: (context, prov, child) => SimpleButton(
                    padding: EdgeInsets.all(Dimen.iconMarg),
                    radius: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          MdiIcons.folderDownloadOutline,
                          color: prov.count==0?iconEnab_(context):iconDisab_(context),
                        ),
                        SizedBox(width: Dimen.iconMarg),
                        Text(
                          'Zapisz wszystko',
                          style: AppTextStyle(
                              fontWeight: weight.halfBold,
                              color: prov.count==0?iconEnab_(context):iconDisab_(context)
                          ),
                        )
                      ],
                    ),
                    onTap: prov.count!=0?null:() async {

                      SongFileNameDupErrProvider songFileNameDupErrProv = SongFileNameDupErrProvider.of(context);
                      songFileNameDupErrProv.checkAllDups(context);

                      if(songFileNameDupErrProv.count != 0) return;

                      AllSongsProvider allSongsProv = AllSongsProvider.of(context);

                      List<SongRaw> songsWithouTitle = [];
                      List<SongRaw> songsWithoutYT = [];
                      List<SongRaw> songsWithoutChords = [];
                      for(SongRaw song in allSongsProv.songs) {
                        if (song.title.isEmpty)
                          songsWithouTitle.add(song);

                        if (song.youtubeLink == null || song.youtubeLink!.isEmpty)
                          songsWithoutYT.add(song);

                        if (!song.hasChords)
                          songsWithoutChords.add(song);
                      }

                      if(songsWithouTitle.isNotEmpty) {
                        bool goAhead = await showMissingContentAlert(
                            context: context,
                            songs: songsWithouTitle,
                            title: 'Brakuje tytułów!',
                            content: "W niektórych piosenkach <b>brakuje tytułów</b>."
                                "\n"
                                "\nPiosenki bez tytułu nie będą dodane do aplikacji."
                                "\nWięc nie śwituj i nie marnuj czasu moderatorów HarcAppki i dopisz tytuły tam, gdzie ich brakuje :)"
                        );
                        if(!goAhead) return;
                      }

                      if(songsWithoutYT.isNotEmpty) {
                        bool goAhead = await showMissingContentAlert(
                          context: context,
                          songs: songsWithoutYT,
                          title: 'Brakuje jutuba!',
                          content: "W niektórych piosenkach <b>brakuje linków</b> do YouTube'a."
                              "\n"
                              "\nLink do odtworzenia piosenki jest potrzebny, żeby osoby, które jej nie znają <b>mogły się jej nauczyć</b>."
                              "\n"
                              "\nPiosenki bez linków do YT przysparzają dodającym je do HarcAppki moderatorom dużo <b>dodatkowej pracy</b> - bądź dla nich łaskawy! :)"
                        );
                        if(!goAhead) return;
                      }

                      if(songsWithoutChords.isNotEmpty) {
                        bool goAhead = await showMissingContentAlert(
                            context: context,
                            songs: songsWithoutChords,
                            title: 'Brakuje chwytów!',
                            content: "W niektórych piosenkach <b>brakuje chwytów</b>."
                                "\n"
                                "\nPiosenki bez chwytów, które da się zagrać na gitarze, nie będą dodane do aplikacji."
                                "\nNieważne jak ładnie poprosisz :)"
                        );
                        if(!goAhead) return;
                      }

                      String code = allSongsProv.convertAllToCode();

                      int songCount = AllSongsProvider.of(context).length;
                      if(songCount == 1)
                        AppScaffold.showMessage(context, 'Rozpoczęto pobieranie 1 piosenki', duration: Duration(seconds: 5));
                      else
                        AppScaffold.showMessage(context, 'Rozpoczęto pobieranie $songCount piosenek', duration: Duration(seconds: 5));

                      downloadFileFromString(content: code, fileName: '${songCount}_songs.hrcpsng');
                      AllSongsProvider.clearCachedSongs();
                    }
                ),
              )
          ),

          Expanded(
              child: SimpleButton(
                  padding: EdgeInsets.all(Dimen.iconMarg),
                  radius: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(MdiIcons.sendCircleOutline),
                      SizedBox(width: Dimen.iconMarg),
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

  Future<bool> showMissingContentAlert({required BuildContext context, required List<SongRaw> songs, required String title, required String content}) async {

    List<SongRaw> shortSongs;
    if(songs.length > 3) shortSongs = songs.sublist(0, 3);
    else shortSongs = songs;

    bool goAhead = false;
    await showAlertDialog(
    context,
    title: title,
    content: "$content"
        "\n"
        "\n"
        "\nBraki dotyczą piosenek (w liczbie: ${songs.length}):"
        "\n<b><i>${shortSongs.map((song) => song.title.isEmpty?SongTileState.HINT_FILE_TITLE:song.title).join("\n")}"
        "${songs.length > shortSongs.length ? "\n..." : ""}"
        "</i></b>",
    actionBuilder: (context) =>
    [
      AlertDialogButton(text: "Kontynuuj pomimo to",
          onTap: (){
            goAhead = true;
            Navigator.pop(context);
          },
          textColor: hintEnab_(context)
      ),
      AlertDialogButton(
          text: "Wracam uzupełnić braki!",
          onTap: (){
            goAhead = false;
            Navigator.pop(context);
          }
      ),
    ]
    );

    return goAhead;

  }

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
        padding: EdgeInsets.all(2*Dimen.iconMarg),
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [

            Text(
              'Prześlij piosenki do weryfikacji',
              style: AppTextStyle(fontWeight: weight.halfBold, fontSize: Dimen.textSizeAppBar),
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
              style: AppTextStyle(color: hintEnab_(context), fontSize: Dimen.textSizeNormal),
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
                    padding: EdgeInsets.all(Dimen.iconMarg),
                    child: Row(
                      children: [
                        Text(
                          'Prześlij',
                          style: AppTextStyle(
                            fontWeight: weight.halfBold,
                            color: sendable?iconEnab_(context):iconDisab_(context)
                          ),
                        ),
                        SizedBox(width: Dimen.iconMarg),
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