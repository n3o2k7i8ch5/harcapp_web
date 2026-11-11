import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:harcapp_core/song_book/song_editor/song_raw.dart';
import 'package:harcapp_web/songs/utils/song_loader.dart';

import 'song_book_song.dart';

/// Oficjalne piosenki śpiewnika apki, w kolejności z pliku. Wczytywane raz,
/// przy pierwszym wejściu do śpiewnika — nie przy starcie strony.
class SongBookLoader{

  SongBookLoader._();

  static List<SongBookSong>? loaded;
  static Future<List<SongBookSong>>? _loading;

  static Future<List<SongBookSong>> load() =>
      _loading ??= _load().then((songs) => loaded = songs);

  /// Na webie nie ma osobnego wątku: co kilkanaście milisekund oddajemy go,
  /// żeby strona nie zamarzła na parsowaniu ~2,5 tys. piosenek.
  static Future<List<SongBookSong>> _load({Duration slice = const Duration(milliseconds: 12)}) async {
    final String code = await rootBundle.loadString(appSongsAsset);
    await Future<void>.delayed(Duration.zero);
    final Map official = jsonDecode(code)['official'];

    final List<(int, SongBookSong)> songs = [];
    final Stopwatch sw = Stopwatch()..start();
    for(final MapEntry entry in official.entries){
      try {
        final SongRaw raw = SongRaw.fromApiRespMap(entry.key, entry.value['song']);
        songs.add((entry.value['index'] as int, SongBookSong(raw)));
      } on Error catch(e, s){
        debugPrint('Śpiewnik: pominięto piosenkę ${entry.key}: $e\n$s');
      }
      if(sw.elapsed >= slice){
        await Future<void>.delayed(Duration.zero);
        sw.reset();
      }
    }

    songs.sort((a, b) => a.$1.compareTo(b.$1));
    return [for(final (_, song) in songs) song];
  }

}
