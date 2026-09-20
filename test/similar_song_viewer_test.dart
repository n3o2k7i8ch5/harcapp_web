import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harcapp_core/song_book/providers.dart';
import 'package:harcapp_core/song_book/similarity/similarity.dart';
import 'package:harcapp_core/song_book/similarity/song_index.dart';
import 'package:harcapp_core/song_book/song_editor/song_raw.dart';
import 'package:harcapp_core/song_book/song_element.dart';
import 'package:harcapp_web/color_pack.dart';
import 'package:harcapp_web/songs/similar_song_viewer.dart';
import 'package:harcapp_web/songs/song_preview_widget.dart';

const _ognisko = 'Płonie ognisko i szumią knieje\nDrużynowy jest wśród nas';
const _morze = 'Zupełnie inny tekst o morzu\nŻagle na wietrze i sól na wargach';

SongRaw song(String id, String title, String lyrics){
  final s = SongRaw.empty(id: id);
  s.title = title;
  s.hasRefren = false;
  s.songParts = [SongPart.from(SongElement(lyrics, 'a d e', false))];
  return s;
}

Widget wrap(Widget child) => HarcAppSongBook(
  Builder(builder: (context) => MaterialApp(
    theme: const ColorPackGraphite().themeData(context),
    home: Material(child: child),
  )),
  SongBaseSettings(),
);

void main(){

  final current = song('o!_probe', 'Morze', _ognisko);
  final morze = song('o!_morze', 'Morze', _morze);
  final ognisko = song('o!_ognisko', 'Płonie ognisko', _ognisko);

  List<SongMatch<SongRaw>> matchesFor(SongRaw probe, List<SongRaw> songs) =>
      SongIndex<SongRaw>(songs).matches(SongProfile(probe));

  testWidgets('lista trafień: skąd i poziom przy każdym; klik przełącza środek', (tester) async {
    tester.view.physicalSize = const Size(1800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final matches = matchesFor(current, [morze, ognisko]);
    expect(matches.length, 2);

    await tester.pumpWidget(wrap(SimilarSongViewerDialog(currentSong: current, matches: matches)));
    await tester.pumpAndSettle();
    // Ikonka rozmiaru tekstu w widgecie piosenki przelewa się pod testową
    // czcionką — nie sprawa tego okna.
    tester.takeException();

    expect(find.text('2 PODOBNE PIOSENKI'), findsOneWidget);
    expect(find.text('w apce · ten sam tytuł, inna treść'), findsOneWidget);
    expect(find.text('w apce · podobny tekst'), findsOneWidget);

    // Pośrodku pierwsze trafienie: „Morze” z pastylką „ten sam tytuł”.
    expect(find.text('ten sam tytuł'), findsOneWidget);

    await tester.tap(find.text('Płonie ognisko'));
    await tester.pumpAndSettle();
    tester.takeException();

    // Drugie trafienie nie ma wspólnego tytułu, za to tekst ma dosłownie ten
    // sam — pastylka tytułu znika, wchodzi „ten sam tekst” (a „tekst 100%”
    // obok niej jest celowo ukryte, bo nie mówi nic nowego).
    expect(find.text('ten sam tytuł'), findsNothing);
    expect(find.text('ten sam tekst'), findsOneWidget);
    expect(find.text('tekst 100%'), findsNothing);
  });

  testWidgets('jedno trafienie: bez listy, dwie kolumny', (tester) async {
    tester.view.physicalSize = const Size(1800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final matches = matchesFor(current, [morze]);
    await tester.pumpWidget(wrap(SimilarSongViewerDialog(currentSong: current, matches: matches)));
    await tester.pumpAndSettle();
    tester.takeException();

    expect(find.textContaining('PODOBN'), findsNothing);
    expect(find.text('W APCE'), findsOneWidget);
    expect(find.text('W EDYTORZE'), findsOneWidget);
  });

  testWidgets('pierwowzór poprawki pierwszy na liście, podpisany osobno', (tester) async {
    tester.view.physicalSize = const Size(1800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final original = SongMatch<SongRaw>(
      song: morze,
      similarities: compare(SongProfile(current), SongProfile(morze)),
    );
    final matches = matchesFor(current, [ognisko]);

    await tester.pumpWidget(wrap(SimilarSongViewerDialog(
      currentSong: current,
      matches: matches,
      original: original,
      title: 'Poprawka piosenki',
    )));
    await tester.pumpAndSettle();
    tester.takeException();

    expect(find.text('w apce · poprawiana piosenka'), findsOneWidget);
    expect(find.text('POPRAWIANA PIOSENKA · W APCE'), findsOneWidget);
    // Licznik liczy tylko podobne, bez pierwowzoru.
    expect(find.text('1 PODOBNA PIOSENKA'), findsOneWidget);
  });

}
