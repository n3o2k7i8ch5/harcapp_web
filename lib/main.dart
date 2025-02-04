import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:harcapp_core/color_pack_app.dart';
import 'package:harcapp_core/comm_classes/color_pack_provider.dart';
import 'package:harcapp_core/comm_classes/sha_pref.dart';
import 'package:harcapp_core/song_book/providers.dart';
import 'package:harcapp_core/song_book/song_editor/providers.dart';
import 'package:harcapp_core/song_book/song_editor/song_raw.dart';
import 'package:harcapp_core/song_book/song_tags.dart';
import 'package:harcapp_web/logger.dart';
import 'package:harcapp_web/router.dart';
import 'package:harcapp_web/songs/providers.dart';
import 'package:harcapp_web/songs/song_preview_widget.dart';
import 'package:provider/provider.dart';
import 'package:url_strategy/url_strategy.dart';

import 'articles/models/azymut.dart';
import 'articles/models/harcapp.dart';
import 'articles/models/pojutrze.dart';
import 'color_pack.dart';
import 'idb.dart';

Future<void> initArticles() async {
  await ArticleHarcApp.init();
  await ArticleAzymut.init();
  await ArticlePojutrze.init();
}

void main() async {
  // When changing this, delete the `web` folder.
  setPathUrlStrategy();
  initLogger();
  await IDB.init();
  await initArticles();
  await ShaPref.init();
  List<SongRaw> loadedSongs = await AllSongsProvider.loadCachedSongs();
  MyApp.lastLoadedSongs = loadedSongs;
  // Make context.push() change url.
  GoRouter.optionURLReflectsImperativeAPIs = true;
  runApp(HarcAppSongBook(MyApp(), SongBaseSettings()));
}

class MyApp extends StatefulWidget {

  static late List<SongRaw> lastLoadedSongs;

  MyApp({Key? key}): super(key: key);

  @override
  State<StatefulWidget> createState() => MyAppState();

}

class MyAppState extends State<MyApp>{

  late AllSongsProvider allSongsProv;
  late CurrentItemProvider currItemProv;
  late BindTitleFileNameProvider bindTitleFileNameProv;
  late SongFileNameDupErrProvider songFileNameDupErrProv;

  @override
  Widget build(BuildContext context) => ColorPackApp(
      initColorPack: ColorPackGraphite(),
      isDark: () => false,
      child: MultiProvider(
          providers: [

            ChangeNotifierProvider(create: (context){
              allSongsProv = AllSongsProvider(MyApp.lastLoadedSongs);
              return allSongsProv;
            }),

            ChangeNotifierProvider(create: (context){
              currItemProv = CurrentItemProvider(song: SongRaw.empty());
              return currItemProv;
            }),

            ChangeNotifierProvider(create: (context){
              SimilarSongProvider prov = SimilarSongProvider();
              prov.init();
              return prov;
            }),

            ChangeNotifierProvider(create: (context) => RefrenEnabProvider(true)),
            ChangeNotifierProvider(create: (context) => RefrenPartProvider()),
            ChangeNotifierProvider(create: (context) => TagsProvider(SongTag.ALL, [])),

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
              builder: (context, prov, child) => MaterialApp.router(
                routerConfig: router,
                title: 'HarcApp',
                theme: prov.colorPack.themeData,
                builder: (context, child) => child!,
                localizationsDelegates: const [
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate, // ONLY if it's a RTL language
                  GlobalCupertinoLocalizations.delegate,
                ],
                supportedLocales: const [
                  Locale('pl', 'PL'), // include country code too
                ],
              )
          )
      )
  );
}