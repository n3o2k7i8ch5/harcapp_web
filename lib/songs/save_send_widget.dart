import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:harcapp_core/comm_classes/app_navigator.dart';
import 'package:harcapp_core/comm_classes/app_text_style.dart';
import 'package:harcapp_core/comm_classes/color_pack.dart';
import 'package:harcapp_core/comm_classes/web_utils_web.dart';
import 'package:harcapp_core/comm_widgets/app_button.dart';
import 'package:harcapp_core/comm_widgets/app_card.dart';
import 'package:harcapp_core/comm_widgets/app_scaffold.dart';
import 'package:harcapp_core/comm_widgets/app_text.dart';
import 'package:harcapp_core/comm_widgets/dialog/app_dialog.dart';
import 'package:harcapp_core/comm_widgets/simple_button.dart';
import 'package:harcapp_core/song_book/contrib_song_email.dart';
import 'package:harcapp_core/song_book/piosenkomat/file_names.dart';
import 'package:harcapp_core/values/dimen.dart';
import 'package:harcapp_web/common/download_file.dart';
import 'package:harcapp_web/consts.dart';
import 'package:harcapp_web/songs/providers.dart';
import 'package:harcapp_web/songs/song_contribution_rules_acceptance_manager.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:provider/provider.dart';
import 'package:harcapp_core/comm_widgets/dialog/alert_dialog.dart';

import '../router.dart';

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

                      String code = allSongsProv.convertAllToCode();

                      int songCount = AllSongsProvider.of(context).length;
                      if(songCount == 1)
                        AppScaffold.showMessage(context, text: 'Rozpoczęto pobieranie 1 piosenki', duration: Duration(seconds: 5));
                      else
                        AppScaffold.showMessage(context, text: 'Rozpoczęto pobieranie $songCount piosenek', duration: Duration(seconds: 5));

                      // Paczka z przeglądu pobiera się od razu jako
                      // `reviewed-*`, bez ręcznego przemianowywania.
                      downloadFileFromString(
                          content: code,
                          fileName: suggestedSaveFileName(allSongsProv.songs));
                      AllSongsProvider.clearCachedSongs();

                      // Paczka z przeglądu wraca do piosenkomatu, nie mejlem —
                      // nie ma o czym instruować.
                      if(piosenkomatReviewKind(allSongsProv.songs) != null) return;

                      await showAlertDialog(
                        context: context,
                        title: 'Jak wysłać mejla z piosenkami',
                        dismissible: false,
                        contentWidget: HowToSendEmailWidget(),
                        buttons: [
                          AppDialogButton(
                            text: 'Wszystko jasne!',
                            onTap: () => popPage(context),
                          ),
                        ],
                        scrollable: true,
                        maxWidth: appDialogMaxWidth,
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
                  onTap: () => showAlertDialog(
                    context: context,
                    title: 'Jak przesłać piosenki do weryfikacji?',
                    contentWidget: HowToContributeDialog(),
                    buttons: [
                      AppDialogButton(
                        text: 'Wszystko jasne!',
                        onTap: () => popPage(context),
                      ),
                    ],
                    scrollable: true,
                    maxWidth: appDialogMaxWidth,
                  )
              )
          ),

        ],
      ),
    ),
  );

}

/// Mejl w kształcie, który rozumie piosenkomat: znacznik `[hrcpsng/web]`
/// w temacie i belki w treści. Bez świeżaka i weterana — edytor liczy to sam
/// po adresie nadawcy, a w temacie i tak nikt tego nie parsował.
class HowToSendEmailWidget extends StatelessWidget{

  @override
  Widget build(BuildContext context){
    final songs = AllSongsProvider.of(context).songs;
    return Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [

      AppText(
        'Mejl musi mieć niniejszą formę, <b>inaczej</b> piosenki <b>nie będą rozpatrzone</b>!'
        '\n',
        selectable: true,
        size: Dimen.textSizeBig,
      ),

      BulletPoint(1, 'Tytuł'),
      SizedBox(height: HowToContributeDialog.textSeparation),

      Padding(
        padding: EdgeInsets.only(left: BulletPoint.bulletWidth,),
        child: CopiableText(
          title: 'Tytuł mejla',
          text: composeSubmissionEmailSubject(
            origin: SubmissionOrigin.web,
            song: songs.length == 1? songs.single: null,
            songCount: songs.length,
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
          text: composeSubmissionEmailBody(
            attachmentFileName: suggestedSaveFileName(songs),
            acceptRulesVersion:
                SongContributionRulesAcceptanceManager.acceptedRulesVersion,
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
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: [

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

      BulletPoint(3, 'Wyślij mejlem pobrany plik na adres: <b>$harcappEmail</b>.'),

      SizedBox(height: 24),

      Text(
        'Mejl z piosenkami',
        style: alertDialogTextStyle(context),
      ),
      SizedBox(height: appDialogDefMargin),

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
      mainAxisSize: MainAxisSize.min,
      children: [

        Container(
          color: backgroundIcon_(context),
          child: Row(
            children: [

              SizedBox(width: Dimen.iconMarg),

              Expanded(child: Text(title, style: AppTextStyle(fontSize: Dimen.textSizeBig, fontWeight: weightBold))),

              AppButton(
                icon: Icon(MdiIcons.contentCopy),
                onTap: () async {
                  await Clipboard.setData(ClipboardData(text: text));
                  AppScaffold.showMessage(context, text: 'Skopiowano!');
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