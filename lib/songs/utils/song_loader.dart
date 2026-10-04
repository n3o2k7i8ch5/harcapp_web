import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:harcapp_core/comm_classes/text_utils.dart';
import 'package:harcapp_core/song_book/import_hrcpsng.dart';
import 'package:harcapp_core/song_book/similarity/similarity.dart';
import 'package:harcapp_core/song_book/song_editor/song_raw.dart';

/// Wrzuca piosenkę do indeksu pod jej tytułem i pod każdym tytułem ukrytym.
void _indexSong(Map<String, List<SongRaw>> songsMap, String songId, Map songMap){
  SongRaw song = SongRaw.fromApiRespMap(songId, songMap);

  for(String title in [song.title, ...song.hidTitles]){
    String key = searchableString(title);
    if(!songsMap.containsKey(key)) songsMap[key] = [];
    songsMap[key]!.add(song);
  }
}

Map<String, List<SongRaw>> decodeSongs(String allSongsCode) {

  Map allSongsJSONMap = jsonDecode(allSongsCode);

  Map<String, List<SongRaw>> songsMap = {};

  for(String section in const ['official', 'conf'])
    for(String songId in allSongsJSONMap[section].keys)
      try {
        _indexSong(songsMap, songId, allSongsJSONMap[section][songId]['song']);
      } on Error catch(e, s){
        // Pojedyncza zepsuta piosenka nie może wywalić całego indeksu, ale
        // niech chociaż zostawi ślad - inaczej znika bez śladu.
        debugPrint('Pominięto piosenkę $section/$songId: $e\n$s');
      }

  return songsMap;

}

/// Cały śpiewnik jako indeks do porównań.
///
/// Na webie `compute` nie ma osobnego wątku — liczy na głównym, więc jeden
/// ciąg parsowania i odcisków 2,5 tys. piosenek zamrażał stronę na start.
/// Tu co kilkanaście milisekund oddajemy wątek: strona żyje, a indeks
/// dochodzi w tle (do tego czasu `SimilarSongProvider.loaded` jest `false`).
/// W jednym kawałku zostaje tylko `jsonDecode` pliku. Zepsuta pojedyncza
/// piosenka nie wywala indeksu, tak samo jak w [decodeSongs]. Zdublowane id
/// wywalają: [HrcpsngDuplicateIdError].
Future<SongIndex<SongRaw>> loadAppSongIndex() async {
  String allSongsCode = await rootBundle.loadString('packages/harcapp_core/assets/songs/all_songs.hrcpsng');
  await Future<void>.delayed(Duration.zero);
  Map allSongsJSONMap = jsonDecode(allSongsCode);
  // `jsonDecode` z powtórzonego klucza zostawia po cichu ostatni wpis —
  // śpiewnik ze zdublowanym id się nie wczytuje, zamiast zgubić piosenkę.
  final duplicates = hrcpsngDuplicateIds(allSongsCode);
  if(duplicates.isNotEmpty) throw HrcpsngDuplicateIdError(duplicates);

  List<SongRaw> songs = [];
  Stopwatch sw = Stopwatch()..start();
  for(String section in const ['official', 'conf'])
    for(String songId in allSongsJSONMap[section].keys){
      try {
        songs.add(SongRaw.fromApiRespMap(songId, allSongsJSONMap[section][songId]['song']));
      } on Error catch(e, s){
        debugPrint('Pominięto piosenkę $section/$songId: $e\n$s');
      }
      if(sw.elapsedMilliseconds >= 12){
        await Future<void>.delayed(Duration.zero);
        sw.reset();
      }
    }

  return SongIndex.inSlices(songs);
}
