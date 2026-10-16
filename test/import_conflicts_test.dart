import 'package:flutter_test/flutter_test.dart';
import 'package:harcapp_core/song_book/piosenkomat/piosenkomat_data.dart';
import 'package:harcapp_core/song_book/song_editor/song_raw.dart';
import 'package:harcapp_web/songs/left_panel/import_conflict_dialog.dart';

SongRaw _song(String id, {PiosenkomatData? data}){
  SongRaw song = SongRaw.empty();
  song.id = id;
  song.title = id;
  song.piosenkomatData = data;
  return song;
}

void main(){

  test('final-correction: poprawka bez śladu piosenkomatu, poznana po id', () async {
    // `review --push` zdejmuje pole `piosenkomat` i ustawia id poprawianej piosenki.
    SongRaw existing = _song('o!_roadtrip@dream&pmbata');
    SongRaw imported = _song('o!_roadtrip@dream&pmbata');

    List<ImportConflict> conflicts = await findImportConflicts([imported], [existing]);

    expect(conflicts.length, 1);
    expect(identical(conflicts.single.imported, imported), isTrue);
    expect(conflicts.single.existing, [existing]);
  });

  test('candidates-correction: poprawka o innym id, poznana po correctionTarget', () async {
    SongRaw existing = _song('o!_ukraina');
    SongRaw imported = _song(
        'o!_hej_sokoly',
        data: const PiosenkomatData(
            kind: SubmissionKind.correction,
            correctionTarget: 'o!_ukraina',
        ),
    );

    expect((await findImportConflicts([imported], [existing])).single.existing, [existing]);
  });

  test('nowa piosenka, której nie ma w warsztacie, nie robi konfliktu', () async {
    expect(await findImportConflicts([_song('o!_nowa')], [_song('o!_stara')]), isEmpty);
  });

  test('basedOnSongId to nie kolizja — przerobiona z cudzej to inna piosenka', () async {
    SongRaw original = _song('o!_barka');
    SongRaw derived = _song('o!_moja_barka')..basedOnSongId = 'o!_barka';
    expect(await findImportConflicts([derived], [original]), isEmpty);
  });

  test('id powtórzone w warsztacie: kolizja wymienia obie stare', () async {
    SongRaw a = _song('o!_x');
    SongRaw b = _song('o!_x');
    List<ImportConflict> conflicts = await findImportConflicts([_song('o!_x')], [a, b]);
    expect(conflicts.single.existing, unorderedEquals([a, b]));
  });

  test('piosenka z tej samej paczki importu nie jest własnym pierwowzorem', () async {
    SongRaw a = _song('o!_ta_sama');
    SongRaw b = _song('o!_ta_sama');
    expect(await findImportConflicts([a, b], [a, b]), isEmpty);
  });

}
