import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:harcapp_core/comm_classes/text_utils.dart';
import 'package:harcapp_core/song_book/similarity/song_index.dart';
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

/// Cały śpiewnik jako indeks do porównań. Profile (zbiory słów, klucze
/// tytułów, odwrócony indeks) liczą się raz — tu, w `compute`, żeby start
/// strony nie stawał. Zepsuta pojedyncza piosenka nie wywala indeksu, tak
/// samo jak w [decodeSongs].
Future<SongIndex<SongRaw>> loadAppSongIndex() async {
  String allSongsCode = await rootBundle.loadString('packages/harcapp_core/assets/songs/all_songs.hrcpsng');
  return await compute(buildAppSongIndex, allSongsCode);
}

SongIndex<SongRaw> buildAppSongIndex(String allSongsCode) {

  Map allSongsJSONMap = jsonDecode(allSongsCode);

  List<SongRaw> songs = [];

  for(String section in const ['official', 'conf'])
    for(String songId in allSongsJSONMap[section].keys)
      try {
        songs.add(SongRaw.fromApiRespMap(songId, allSongsJSONMap[section][songId]['song']));
      } on Error catch(e, s){
        debugPrint('Pominięto piosenkę $section/$songId: $e\n$s');
      }

  return SongIndex(songs);

}
