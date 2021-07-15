import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:harcapp_core/comm_classes/color_pack_provider.dart';
import 'package:harcapp_core_own_song/providers.dart';
import 'package:harcapp_core_own_song/song_raw.dart';
import 'package:harcapp_core_tags/tag_layout.dart';
import 'package:harcapp_web/songs/generate_file_name.dart';
import 'package:harcapp_web/songs/providers.dart';
import 'package:provider/provider.dart';

import 'color_pack.dart';
import 'main_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {

  late AllSongsProvider allSongsProv;
  late CurrentItemProvider currItemProv;
  late BindTitleFileNameProvider bindTitleFileNameProv;
  late SongFileNameDupErrProvider songFileNameDupErrProv;

  @override
  Widget build(BuildContext context) {

    return MultiProvider(
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

        ChangeNotifierProvider(create: (context) => TitleCtrlProvider(
            onChanged: (text){
              LoadingProvider loadingProv = Provider.of<LoadingProvider>(context, listen: false);
              if(loadingProv.loading!)
                return;

              SongRaw? song = currItemProv.song;

              bool? isConf = allSongsProv.isConf(song);

              if(bindTitleFileNameProv.bind!)
                song.fileName = generateFileName(isConf: isConf!, title: text);

              songFileNameDupErrProv.chedkDupsFor(context, song);

              allSongsProv.notifyListeners();

            }
        )),
        /*
        ChangeNotifierProvider(create: (context) => AuthorCtrlProvider()),
        ChangeNotifierProvider(create: (context) => ComposerCtrlProvider()),
        ChangeNotifierProvider(create: (context) => PerformerCtrlProvider()),
        ChangeNotifierProvider(create: (context) => YTCtrlProvider()),
        ChangeNotifierProvider(create: (context) => AddPersCtrlProvider()),
*/
        ChangeNotifierProvider(create: (context) => HidTitlesProvider(hidTitles: [])),
        ChangeNotifierProvider(create: (context) => RefrenEnabProvider(true)),
        ChangeNotifierProvider(create: (context) => RefrenPartProvider()),
        ChangeNotifierProvider(create: (context) => TagsProvider(Tag.ALL_TAG_NAMES, [])),

        ChangeNotifierProvider(create: (context){
          bindTitleFileNameProv = BindTitleFileNameProvider();
          return bindTitleFileNameProv;
        }),

        ChangeNotifierProvider(create: (context) => WorkspaceBlockProvider()),
        ChangeNotifierProvider(create: (context){
          songFileNameDupErrProv = SongFileNameDupErrProvider();
          return songFileNameDupErrProv;
        }),

        ChangeNotifierProvider(create: (context) => ShowCodeEditorProvider()),

        ChangeNotifierProvider(create: (context) => SongPreviewProvider()),

        ChangeNotifierProvider(create: (context) => SongEditorPanelProvider()),
      ],
      builder: (context, child) => Consumer<ColorPackProvider>(
          builder: (context, prov, child){
            return MaterialApp(
              title: 'HarcApp Web',
              theme: prov.colorPack!.themeData,
              home: MainPage(),
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate, // ONLY if it's a RTL language
              ],
              supportedLocales: const [
                Locale('pl', 'PL'), // include country code too
              ],
            );
          }
      ),
    );

  }
}
