import 'package:clipboard/clipboard.dart';
import 'package:flutter/material.dart';
import 'package:harcapp_core/comm_classes/app_navigator.dart';
import 'package:harcapp_core/comm_classes/app_text_style.dart';
import 'package:harcapp_core/comm_classes/color_pack.dart';
import 'package:harcapp_core/comm_widgets/app_card.dart';
import 'package:harcapp_core/comm_widgets/app_scaffold.dart';
import 'package:harcapp_core/comm_widgets/app_text.dart';
import 'package:harcapp_core/comm_widgets/app_text_field_hint.dart';
import 'package:harcapp_core/comm_widgets/simple_button.dart';
import 'package:harcapp_core/comm_widgets/title_show_row_widget.dart';
import 'package:harcapp_core/song_book/contrib_song.dart';
import 'package:harcapp_core/song_book/song_contribution_rules.dart';
import 'package:harcapp_core/values/dimen.dart';
import 'package:harcapp_core/song_book/song_editor/song_raw.dart';
import 'package:harcapp_web/common/alert_dialog.dart';
import 'package:harcapp_web/common/download_file.dart';
import 'package:harcapp_web/common/google_form_sender.dart';
import 'package:harcapp_web/common/open_in_new_tab.dart' show openPathInNewTab;
import 'package:harcapp_web/songs/left_panel/song_tile.dart';
import 'package:harcapp_web/songs/providers.dart';
import 'package:harcapp_web/songs/song_contribution_rules_acceptance_manager.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';

import '../router.dart';

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
                              fontWeight: weightHalfBold,
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

                        if (song.youtubeVideoId == null || song.youtubeVideoId!.isEmpty)
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

                      await openDialog(
                        context: context,
                        builder: (context) => Center(
                          child: Container(
                              constraints: BoxConstraints(maxWidth: 500),
                              child: Material(
                                borderRadius: BorderRadius.circular(AppCard.bigRadius),
                                clipBehavior: Clip.hardEdge,
                                color: background_(context),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [

                                    Text(
                                      'Mejl z piosenkami',
                                      style: DialogTheme.of(context).titleTextStyle?.copyWith(
                                        fontFamily: 'Ubuntu'
                                      ),
                                    ),

                                    Padding(
                                        padding: EdgeInsets.all(Dimen.sideMarg),
                                        child: HowToSendEmailWidget()
                                    ),
                                    
                                    SizedBox(height: Dimen.defMarg),
                                    
                                    SimpleButton.from(
                                      context: context,
                                      radius: 0,
                                      margin: EdgeInsets.zero,
                                      color: cardEnab_(context),
                                      text: 'Wszystko jasne!',
                                      onTap: () => popPage(context)
                                    )
                                    
                                  ],
                                )
                              )
                          ),
                        )
                      );

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
                        'Jak przesłać?',
                        style: AppTextStyle(fontWeight: weightHalfBold, color: iconEnab_(context)),
                      )
                    ],
                  ),
                  onTap: () => showDialog(
                      context: context,
                      builder: (context) => Center(
                        child: HowToContributeDialog(),
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

class HowToSendEmailWidget extends StatelessWidget{

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [

      TitleShortcutRowWidget(
        title: 'Mejl z piosenkami',
        textAlign: TextAlign.left,
      ),

      AppText(
        'Mejl musi mieć niniejszą formę, <b>inaczej</b> piosenki <b>nie będą rozpatrzone</b>!',
        selectable: true,
        size: Dimen.textSizeBig,
      ),
      SizedBox(height: HowToContributeDialog.textSeparation),

      BulletPoint(1, 'Tytuł'),
      SizedBox(height: HowToContributeDialog.textSeparation),

      Padding(
        padding: EdgeInsets.only(left: BulletPoint.bulletWidth,),
        child: CopiableText(
          title: 'Tytuł mejla',
          text: composeContribAttachedSongsEmailSubject(
              songs: AllSongsProvider.of(context).songs
          ),
        ),
      ),
      SizedBox(height: 3*HowToContributeDialog.textSeparation),

      BulletPoint(2, 'Treść'),
      SizedBox(height: HowToContributeDialog.textSeparation),

      Padding(
        padding: EdgeInsets.only(
          left: BulletPoint.bulletWidth,
        ),
        child: CopiableText(
          title: 'Treść mejla',
          text: composeContribAttachedSongsEmail(
            songs: AllSongsProvider.of(context).songs,
            source: SongSource.web,
            acceptRulesVersion: SongContributionRulesAcceptanceManager.acceptedRulesVersion,
            // person: ,
          ),
        ),
      ),
      SizedBox(height: 3*HowToContributeDialog.textSeparation),

      AppText(
        '3. Załącz pobrany plik z piosenkami.',
        size: Dimen.textSizeBig,
      ),

    ],
  );

}

class HowToContributeDialog extends StatelessWidget{

  static const double textSeparation = 5.0;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: EdgeInsets.all(Dimen.sideMarg),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 500,
        ),
        child: Material(
            borderRadius: BorderRadius.circular(AppCard.bigRadius),
            clipBehavior: Clip.hardEdge,
            color: background_(context),
            child: Padding(
                padding: EdgeInsets.all(Dimen.sideMarg),
                child: ListView(
                  physics: BouncingScrollPhysics(),
                  shrinkWrap: true,
                  children: [

                    TitleShortcutRowWidget(
                      title: 'Jak przesłać piosenki do weryfikacji?',
                      textAlign: TextAlign.left,
                    ),

                    AppText(
                      'Przesłanie piosenek do weryfikacji jest bajecznie proste!',
                      selectable: true,
                      size: Dimen.textSizeBig,
                    ),
                    SizedBox(height: textSeparation),

                    BulletPoint(1, '<b>Przygotuj propozycje piosenek</b>, do śpiewnika HarcApp.'),
                    SizedBox(height: textSeparation),

                    BulletPoint(2, 'Pobierz plik z piosenkami przyciskiem "<b>Zapisz wszystko</b>".'),
                    SizedBox(height: textSeparation),

                    BulletPoint(3, 'Wyślij mejlem pobrany plik na adres: <b>harcapp@gmail.com</b>.'),

                    SizedBox(height: 24),

                    HowToSendEmailWidget(),

                    SizedBox(height: 24 + 8),

                    MouseRegion(
                        cursor: SystemMouseCursors.click, // Changes cursor to hand/pointer
                        child: GestureDetector(
                          child: AppText(
                            'Przesłanie propozycji piosenek jest równoznaczne z akceptacją <b>zasad dodawania piosenek</b>.',
                            size: Dimen.textSizeBig,
                          ),
                          onTap: () => openPathInNewTab(pathSongContributionRules),
                        )
                    )

                  ],
                )
            )
        ),
      ),
    ),
  );

}

class BulletPoint extends StatelessWidget{

  static const double bulletWidth = 20.0;

  final int index;
  final String text;

  const BulletPoint(this.index, this.text, {super.key});

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(width: bulletWidth, child: AppText('$index.', size: Dimen.textSizeBig)),
      Expanded(
          child: AppText(
            text,
            selectable: true,
            size: Dimen.textSizeBig,
          )
      )
    ],
  );

}

class CopiableText extends StatelessWidget {

  final String title;
  final String text;

  const CopiableText({required this.title, required this.text, super.key});

  @override
  Widget build(BuildContext context) => Material(
    borderRadius: BorderRadius.circular(AppCard.defRadius),
    clipBehavior: Clip.hardEdge,
    color: cardEnab_(context),

    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [

        Container(
          color: backgroundIcon_(context),
          child: Row(
            children: [

              SizedBox(width: Dimen.iconMarg),

              Expanded(child: Text(title, style: AppTextStyle(fontSize: Dimen.textSizeBig, fontWeight: weightBold))),

              IconButton(
                icon: Icon(MdiIcons.contentCopy),
                onPressed: () async {
                  await FlutterClipboard.copy(text);
                  AppScaffold.showMessage(context, 'Skopiowano!');
                },
              )

            ],
          ),
        ),
        Padding(
            padding: EdgeInsets.all(Dimen.iconMarg),
            child: SelectableText(text, style: AppTextStyle(fontSize: Dimen.textSizeBig))
        ),

      ],
    ),


  );

}