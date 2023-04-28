import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:dio/browser.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:harcapp_core/comm_classes/color_pack_provider.dart';
import 'package:harcapp_core_own_song/providers.dart';
import 'package:harcapp_core_own_song/song_raw.dart';
import 'package:harcapp_core_song_widget/providers.dart';
import 'package:harcapp_core_tags/tag_layout.dart';
import 'package:harcapp_web/router.dart';
import 'package:harcapp_web/songs/providers.dart';
import 'package:harcapp_web/songs/song_editor_panel.dart';
import 'package:harcapp_web/songs/song_preview_widget.dart';
import 'package:provider/provider.dart';
import 'package:url_strategy/url_strategy.dart';

import 'color_pack.dart';


void main(){
  // When changing this, delete the `web` folder.
  setPathUrlStrategy();
  runApp(HarcAppSongBook(MyApp(), SongBaseSettings()));
}

class MyApp extends StatefulWidget {

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
  static String? availableAppVersion;
  static String? availableAppApkSource;

  Future<void> getMetaData() async {

    String metadataUrl = 'https://gitlab.com/n3o2k7i8ch5/harcapp_data/-/raw/master/unofficial_apk_version/version';

    Dio dio = Dio();
    dio.httpClientAdapter = BrowserHttpClientAdapter();

    try {
      Response response = await dio.get(
          'https://cors-anywhere.herokuapp.com/$metadataUrl'
      );
      String dataStr = response.data;
      Map dataMap = jsonDecode(dataStr);
      availableAppVersion = dataMap['versionName'];
      availableAppApkSource = dataMap['apkSource'];
    }catch(e){
      availableAppVersion = '?.?.?';
      availableAppApkSource = 'https://gitlab.com/n3o2k7i8ch5/harcapp_data/-/raw/master/unofficial_apk_version/harcapp.apk';
    }

    setState(() => loadedDownloadMetadata = true);
  }

  @override
  void initState() {
    loadedDownloadMetadata = false;
    getMetaData();
    super.initState();
  }

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
        currItemProv = CurrentItemProvider(
          song: SongRaw.empty(),

        );
        return currItemProv;
      }),

      ChangeNotifierProvider(create: (context){
        SimilarSongProvider prov = SimilarSongProvider();
        prov.init();
        return prov;
      }),

      // ChangeNotifierProvider(create: (context) => TitleCtrlProvider(
      //     onChanged: (text){
      //       LoadingProvider loadingProv = Provider.of<LoadingProvider>(context, listen: false);
      //       if(loadingProv.loading!)
      //         return;
      //
      //       SongRaw? song = currItemProv.song;
      //
      //       if(bindTitleFileNameProv.bindTitle)
      //         song.fileName = generateFileName(song: song, context: context);
      //
      //       songFileNameDupErrProv.checkAllDups(context);
      //
      //       allSongsProv.notifyListeners();
      //
      //     }
      // )),

      // ChangeNotifierProvider(create: (context) => HidTitlesProvider(hidTitles: [])),
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
    builder: (context, child) =>
    loadedDownloadMetadata?
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
  );
}