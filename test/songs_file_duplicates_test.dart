import 'package:flutter_test/flutter_test.dart';
import 'package:harcapp_core/song_book/import_hrcpsng.dart';
import 'package:harcapp_core/song_book/song_editor/song_raw.dart';
import 'package:harcapp_web/songs/providers.dart';

SongRaw _song(String id, String title) => SongRaw.empty(id: id)..title = title;

void main() {
  test('plik z warsztatu: zdublowanego id nie zapisze, a cache przeniesie je dalej', () {
    final prov = AllSongsProvider([_song('o!_barka', 'Barka'), _song('o!_barka', 'Barka druga')]);

    expect(() => prov.convertAllToCode(),
        throwsA(isA<HrcpsngDuplicateIdError>().having((e) => e.ids, 'ids', ['o!_barka'])));

    final cache = prov.convertAllToCode(allowDuplicateIds: true);
    expect(importHrcpsng(cache).$1.map((s) => s.title), ['Barka', 'Barka druga'],
        reason: 'po odświeżeniu duplikat dalej jest do naprawienia');
  });

  test('bez duplikatów: oficjalne i niejawne jak dotąd', () {
    final prov = AllSongsProvider([_song('o!_barka', 'Barka'), _song('oc!_tajna', 'Tajna')]);
    final (official, conf) = importHrcpsng(prov.convertAllToCode());
    expect(official.map((s) => s.id), ['o!_barka']);
    expect(conf.map((s) => s.id), ['oc!_tajna']);
  });
}
