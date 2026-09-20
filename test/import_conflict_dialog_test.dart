import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harcapp_core/song_book/song_editor/song_raw.dart';
import 'package:harcapp_web/color_pack.dart';
import 'package:harcapp_core/song_book/providers.dart';
import 'package:harcapp_web/songs/left_panel/import_conflict_dialog.dart';
import 'package:harcapp_web/songs/song_preview_widget.dart';

SongRaw _song(String id, String title){
  SongRaw song = SongRaw.empty();
  song.id = id;
  song.title = title;
  return song;
}

void main(){
  testWidgets('tak samo dla pozostałych', (tester) async {
    Map<SongRaw, ImportConflictChoice>? result;
    List<ImportConflict> conflicts = [
      ImportConflict(_song('a', 'A'), [_song('a', 'A stara')]),
      ImportConflict(_song('b', 'B'), [_song('b', 'B stara')]),
    ];
    // Okno jest szerokie na dwa podglądy piosenki - na domyślnych 800x600
    // sam widget piosenki się nie mieści.
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(HarcAppSongBook(
      Builder(builder: (context) => MaterialApp(
        theme: ColorPackGraphite().themeData(context),
        home: Material(child: ImportConflictDialog(
          conflicts: conflicts,
          onResolved: (c) => result = c,
        )),
      )),
      SongBaseSettings(),
    ));
    await tester.pumpAndSettle();
    // Ikonka rozmiaru tekstu w widgecie piosenki przelewa się o 11px pod
    // testową czcionką - to nie sprawa tego okna, więc nie wywalamy testu.
    tester.takeException();

    await tester.tap(find.textContaining('Tak samo dla pozostałych'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Zachowaj nową'));
    await tester.pumpAndSettle();
    tester.takeException();
    expect(result?.values.toList(), [ImportConflictChoice.replace, ImportConflictChoice.replace]);
  });

  testWidgets('bez „tak samo dla pozostałych” pyta o każdą kolizję z osobna', (tester) async {
    Map<SongRaw, ImportConflictChoice>? result;
    List<ImportConflict> conflicts = [
      ImportConflict(_song('a', 'A'), [_song('a', 'A stara')]),
      ImportConflict(_song('b', 'B'), [_song('b', 'B stara')]),
    ];

    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(Builder(builder: (context) => MaterialApp(
      theme: ColorPackGraphite().themeData(context),
      home: Material(child: ImportConflictDialog(
        conflicts: conflicts,
        onResolved: (c) => result = c,
      )),
    )));
    await tester.pumpAndSettle();
    tester.takeException();

    await tester.tap(find.text('Zachowaj obie'));
    await tester.pumpAndSettle();
    tester.takeException();

    // Pierwsza kolizja załatwiona - okno stoi na drugiej, nie zamyka się.
    expect(result, isNull);
    expect(find.textContaining('2 z 2'), findsOneWidget);

    await tester.tap(find.text('Zachowaj starą'));
    await tester.pumpAndSettle();
    tester.takeException();

    expect(result?[conflicts[0].imported], ImportConflictChoice.keepBoth);
    expect(result?[conflicts[1].imported], ImportConflictChoice.keepOld);
  });

}
