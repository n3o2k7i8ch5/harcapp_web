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

  test('final-correction: poprawka bez śladu piosenkomatu, poznana po id', (){
    // `prepare` zdejmuje pole `piosenkomat` i ustawia id poprawianej piosenki.
    SongRaw existing = _song('o!_roadtrip@dream&pmbata');
    SongRaw imported = _song('o!_roadtrip@dream&pmbata');

    List<ImportConflict> conflicts = findImportConflicts([imported], [existing]);

    expect(conflicts.length, 1);
    expect(identical(conflicts.single.imported, imported), isTrue);
    expect(conflicts.single.existing, [existing]);
  });

  test('candidates-correction: poprawka o innym id, poznana po correctionTarget', (){
    SongRaw existing = _song('o!_ukraina');
    SongRaw imported = _song(
        'o!_hej_sokoly',
        data: const PiosenkomatData(
            kind: SubmissionKind.correction,
            correctionTarget: 'o!_ukraina',
        ),
    );

    expect(findImportConflicts([imported], [existing]).single.existing, [existing]);
  });

  test('nowa piosenka, której nie ma w warsztacie, nie robi konfliktu', (){
    expect(findImportConflicts([_song('o!_nowa')], [_song('o!_stara')]), isEmpty);
  });

  test('piosenka z tej samej paczki importu nie jest własnym pierwowzorem', (){
    SongRaw a = _song('o!_ta_sama');
    SongRaw b = _song('o!_ta_sama');
    expect(findImportConflicts([a, b], [a, b]), isEmpty);
  });

}
