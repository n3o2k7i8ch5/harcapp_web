import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:dio/browser.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:harcapp_core/color_pack_app.dart';
import 'package:harcapp_core/comm_classes/color_pack_provider.dart';
import 'package:harcapp_core/comm_classes/common.dart';
import 'package:harcapp_core/song_book/providers.dart';
import 'package:harcapp_core/song_book/song_editor/providers.dart';
import 'package:harcapp_core/song_book/song_editor/song_raw.dart';
import 'package:harcapp_core/song_book/song_tags.dart';
import 'package:harcapp_web/common/sha_pref.dart';
import 'package:harcapp_web/router.dart';
import 'package:harcapp_web/songs/providers.dart';
import 'package:harcapp_web/songs/song_preview_widget.dart';
import 'package:provider/provider.dart';
import 'package:url_strategy/url_strategy.dart';

import 'color_pack.dart';

double dialogWidth = 500;
double drawerWidth = 450;

void main() async {
  // When changing this, delete the `web` folder.
  setPathUrlStrategy();
  await ShaPref.init();
  List<SongRaw> loadedSongs = await AllSongsProvider.loadCachedSongs();
  MyApp.lastLoadedSongs = loadedSongs;
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

  late bool loadedDownloadMetadata;
  static String availableAppVersion = '?.?.?';
  static String availableAppApkSource = 'https://gitlab.com/n3o2k7i8ch5/harcapp_data/-/raw/master/unofficial_apk_version/harcapp.apk';

  Future<void> getMetaData() async {

    String metadataUrl = 'https://gitlab.com/n3o2k7i8ch5/harcapp_data/-/raw/master/unofficial_apk_version/version';

    try {
      Dio dio = Dio();
      dio.httpClientAdapter = BrowserHttpClientAdapter();

      Response response = await dio.get(
          'https://cors-anywhere.herokuapp.com/$metadataUrl'
      );
      String dataStr = response.data;
      Map dataMap = jsonDecode(dataStr);
      availableAppVersion = dataMap['versionName'];
      availableAppApkSource = dataMap['apkSource'];
    } catch(e) {
      availableAppVersion = '?.?.?';
      availableAppApkSource = 'https://gitlab.com/n3o2k7i8ch5/harcapp_data/-/raw/master/unofficial_apk_version/harcapp.apk';
    }

    post(() => setState(() => loadedDownloadMetadata = true));
  }

  @override
  void initState() {
    loadedDownloadMetadata = false;

    getMetaData();
    super.initState();
  }

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
          builder: (context, child) =>
          loadedDownloadMetadata || true?  // TODO: remove this metadata stuff.
          Consumer<ColorPackProvider>(
              builder: (context, prov, child) => MaterialApp.router(
                routerConfig: router,
                title: 'HarcApp',
                theme: prov.colorPack.themeData,
                builder: (context, child) => child!,
                localizationsDelegates: const [
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate, // ONLY if it's a RTL language
                ],
                supportedLocales: const [
                  Locale('pl', 'PL'), // include country code too
                ],
              )
          ):
          Container()
      )
  );
}