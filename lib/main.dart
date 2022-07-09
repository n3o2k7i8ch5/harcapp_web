import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:harcapp_core/comm_classes/color_pack_provider.dart';
import 'package:harcapp_core_own_song/providers.dart';
import 'package:harcapp_core_own_song/song_raw.dart';
import 'package:harcapp_core_song_widget/providers.dart';
import 'package:harcapp_core_tags/tag_layout.dart';
import 'package:harcapp_web/songs/generate_file_name.dart';
import 'package:harcapp_web/songs/providers.dart';
import 'package:harcapp_web/songs/song_editor_panel.dart';
import 'package:harcapp_web/songs/song_preview.dart';
import 'package:provider/provider.dart';

import 'color_pack.dart';
import 'main_page.dart';

void main() => runApp(HarcAppSongBook(MyApp(), SongBaseSettings()));

class MyApp extends StatelessWidget {

  late AllSongsProvider allSongsProv;
  late CurrentItemProvider currItemProv;
  late BindTitleFileNameProvider bindTitleFileNameProv;
  late SongFileNameDupErrProvider songFileNameDupErrProv;

  MyApp({Key? key}): super(key: key);

  @override
  Widget build(BuildContext context) => MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (context) => ShowSongProvider(false)),
      ChangeNotifierProvider(create: (context) => ColorPackProvider(
          colorPackDark: ColorPackGraphite(),
          initColorPack: ColorPackGraphite(),
          isDark: () => false
      )),

      ChangeNotifierProvider(create: (context){
        allSongsProv = AllSongsProvider();
        return allSongsProv;
      }),

      ChangeNotifierProvider(create: (context) => LoadingProvider()),
      ChangeNotifierProvider(create: (context){
        currItemProv = CurrentItemProvider(song: SongRaw.empty());
        return currItemProv;
      }),

      ChangeNotifierProvider(create: (context){
        SimilarSongProvider prov = SimilarSongProvider();
        prov.init();
        return prov;
      }),

      ChangeNotifierProvider(create: (context) => TitleCtrlProvider(
          onChanged: (text){
            LoadingProvider loadingProv = Provider.of<LoadingProvider>(context, listen: false);
            if(loadingProv.loading!)
              return;

            SongRaw? song = currItemProv.song;

            if(bindTitleFileNameProv.bindTitle)
              song.fileName = generateFileName(song: song, context: context);

            songFileNameDupErrProv.chedkDupsFor(context, song);

            allSongsProv.notifyListeners();

          }
      )),

      ChangeNotifierProvider(create: (context) => HidTitlesProvider(hidTitles: [])),
      ChangeNotifierProvider(create: (context) => RefrenEnabProvider(true)),
      ChangeNotifierProvider(create: (context) => RefrenPartProvider()),
      ChangeNotifierProvider(create: (context) => TagsProvider(Tag.ALL_TAG_NAMES, [])),

      ChangeNotifierProvider(create: (context){
        bindTitleFileNameProv = BindTitleFileNameProvider();
        return bindTitleFileNameProv;
      }),

      ChangeNotifierProvider(create: (context){
        songFileNameDupErrProv = SongFileNameDupErrProvider();
        return songFileNameDupErrProv;
      }),

      ChangeNotifierProvider(create: (context) => SongPreviewProvider()),

      ChangeNotifierProvider(create: (context) => SongEditorPanelProvider()),
    ],
    builder: (context, child) => Consumer<ColorPackProvider>(
        builder: (context, prov, child) => MaterialApp(
          title: 'HarcApp Web',
          theme: prov.colorPack.themeData,
          home: MainPage(),
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate, // ONLY if it's a RTL language
          ],
          supportedLocales: const [
            Locale('pl', 'PL'), // include country code too
          ],
        )
    ),
  );
}
