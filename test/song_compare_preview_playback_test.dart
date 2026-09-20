import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harcapp_core/song_book/playback/song_audio.dart';
import 'package:harcapp_core/song_book/providers.dart';
import 'package:harcapp_core/song_book/song_editor/song_raw.dart';
import 'package:harcapp_core/song_book/song_element.dart';
import 'package:harcapp_web/color_pack.dart';
import 'package:harcapp_web/songs/song_compare_preview.dart';
import 'package:harcapp_web/songs/song_preview_widget.dart';

SongRaw song(String id, {String? yt}) {
  final s = SongRaw.empty(id: id);
  s.title = 'Piosenka';
  s.youtubeVideoId = yt;
  s.hasRefren = false;
  s.songParts = [SongPart.from(SongElement('Ala ma kota', 'a d e', false))];
  return s;
}

Widget wrap(Widget child) => HarcAppSongBook(
  Builder(builder: (context) => MaterialApp(
    theme: const ColorPackGraphite().themeData(context),
    home: Material(child: Center(child: SizedBox(width: 500, height: 700, child: child))),
  )),
  SongBaseSettings(),
);

void main() {

  setUp(() => AudioMeta.set({'o!_x': const [SongAudio('x.mp3', performer: 'Ktoś')]}));
  tearDown(AudioMeta.reset);

  testWidgets('podgląd na stronie: pasek tylko do oglądania, przycisk YouTube żywy', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(wrap(SongComparePreview(
      song: song('o!_x', yt: 'abc'),
      label: 'w edytorze',
      icon: MdiIcons.pencilOutline,
    )));
    await tester.pumpAndSettle();
    // Ikonka rozmiaru tekstu w widgecie piosenki przelewa się pod testową
    // czcionką — nie sprawa tego widgetu.
    tester.takeException();

    // Kafelek nagrania mp3 (mp3 przed filmem) w trybie podglądu.
    expect(find.text('Ktoś'), findsOneWidget);
    expect(find.byIcon(MdiIcons.musicNote), findsOneWidget);
    expect(find.byIcon(MdiIcons.openInNew), findsOneWidget);
    expect(find.byIcon(MdiIcons.play), findsNothing, reason: 'na stronie nic nie gra');

    // Przycisk „YouTube” w rzędzie ikon jest — i ma co robić (otwiera link).
    expect(find.byIcon(MdiIcons.playCircleOutline), findsOneWidget);
  });

  testWidgets('bez filmu i nagrań: ani paska, ani przycisku YouTube', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(wrap(SongComparePreview(
      song: song('o!_bez'),
      label: 'w edytorze',
      icon: MdiIcons.pencilOutline,
    )));
    await tester.pumpAndSettle();
    tester.takeException();

    expect(find.byIcon(MdiIcons.openInNew), findsNothing);
    expect(find.byIcon(MdiIcons.playCircleOutline), findsNothing);
  });

}
