import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:harcapp_core/song_book/song_editor/song_raw.dart';
import 'package:harcapp_web/songs/left_panel/song_from_code.dart';

String _codeWithoutId(String title) => jsonEncode((SongRaw.empty(id: 'x')..title = title).toApiJsonMap(withId: false));

void main(){
  group('songFromCode', (){
    test('edycja: kod bez id zostawia id piosenki — z przedrostkiem oc!_ i wykonawcą', (){
      final song = songFromCode(_codeWithoutId('Barka poprawiona'), editedId: 'oc!_barka@zespol', withPerformer: true);
      expect(song!.id, 'oc!_barka@zespol');
      expect(song.title, 'Barka poprawiona');
    });

    test('nowa piosenka z kodu bez id: id z tytułu', (){
      expect(songFromCode(_codeWithoutId('Barka'), withPerformer: false)!.id, 'o!_barka');
    });

    test('kod z id: to id wygrywa, także przy edycji', (){
      final code = jsonEncode({'o!_inna': jsonDecode(_codeWithoutId('Barka'))});
      expect(songFromCode(code, editedId: 'oc!_barka', withPerformer: false)!.id, 'o!_inna');
    });

    test('to nie kod piosenki → null', (){
      expect(songFromCode('ala ma kota', withPerformer: false), isNull);
    });
  });
}
