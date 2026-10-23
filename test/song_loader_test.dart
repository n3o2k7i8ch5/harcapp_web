import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:harcapp_core/song_book/import_hrcpsng.dart';
import 'package:harcapp_core/song_book/similarity/similarity.dart';
import 'package:harcapp_core/song_book/song_editor/song_raw.dart';
import 'package:harcapp_web/songs/utils/song_loader.dart';

Map<String, dynamic> _song(String title) => {
  'title': title,
  'parts': [{'text': '$title — jedyny wers', 'chords': 'a', 'shift': false}],
};

/// Plik piosenek: [official] oficjalnych i [conf] niejawnych.
String _songsFile({required int official, required int conf}) => jsonEncode({
  'official': {
    for(int i = 0; i < official; i++) 'o!_piosenka_$i': {'song': _song('Piosenka $i'), 'index': i},
  },
  'conf': {
    for(int i = 0; i < conf; i++) 'oc!_niejawna_$i': {'song': _song('Niejawna $i'), 'index': i},
  },
});

void main(){

  // Na VM przechodzi zawsze. Pierwszy test pilnuje błędu DDC (web w trybie
  // debug), który widać dopiero w przeglądarce:
  // `flutter test --platform chrome test/song_loader_test.dart`.
  test('wczytuje każdą piosenkę z obu sekcji, choć oddaje wątek po każdej', () async {
    SongIndex<SongRaw> index = await appSongIndexFrom(_songsFile(official: 30, conf: 5), slice: Duration.zero);

    expect(index.length, 35);
    expect(index.byId('o!_piosenka_29')?.title, 'Piosenka 29');
    expect(index.byId('oc!_niejawna_4')?.title, 'Niejawna 4');
  });

  test('zepsuta piosenka wypada, reszta zostaje', () async {
    Map file = jsonDecode(_songsFile(official: 3, conf: 0));
    (file['official']['o!_piosenka_1']['song'] as Map).remove('title');

    SongIndex<SongRaw> index = await appSongIndexFrom(jsonEncode(file));

    expect(index.songs.map((s) => s.id), ['o!_piosenka_0', 'o!_piosenka_2']);
  });

  test('zdublowane id: nic się nie wczytuje', () async {
    String song = jsonEncode({'song': _song('Barka'), 'index': 0});
    String file = '{"official": {"o!_barka": $song, "o!_barka": $song}, "conf": {}}';

    await expectLater(appSongIndexFrom(file),
        throwsA(isA<HrcpsngDuplicateIdError>().having((e) => e.ids, 'ids', ['o!_barka'])));
  });

}
