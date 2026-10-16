import 'package:flutter_test/flutter_test.dart';
import 'package:harcapp_core/song_book/piosenkomat/piosenkomat_data.dart';
import 'package:harcapp_core/song_book/similarity/similarity.dart';
import 'package:harcapp_core/song_book/song_editor/song_raw.dart';
import 'package:harcapp_core/song_book/song_element.dart';
import 'package:harcapp_web/songs/providers.dart';
import 'package:harcapp_web/songs/similar_song_viewer.dart';

const _ognisko = 'Płonie ognisko i szumią knieje\nDrużynowy jest wśród nas\nOpowiada starodawne dzieje\nBohaterski wskrzesza czas';
const _morze = 'Zupełnie inny tekst o morzu\nŻagle na wietrze i sól na wargach\nDaleko od lasu i od ogniska';
const _gory = 'Hej góry moje góry\nWysoko pod chmury\nTam gdzie orzeł krąży\nA wiatr halny dąży';

SongRaw song(String id, String title, String lyrics){
  final s = SongRaw.empty(id: id);
  s.title = title;
  s.performers = ['Zespół'];
  s.hasRefren = false;
  s.songParts = [SongPart.from(SongElement(lyrics, 'a d e\na d e', false))];
  return s;
}

void main(){

  late SimilarSongProvider prov;

  setUp((){
    prov = SimilarSongProvider.withIndex(SongIndex<SongRaw>([
      song('o!_ognisko', 'Płonie ognisko', _ognisko),
      song('o!_morze', 'Morze', _morze),
      song('o!_gory', 'Góry', _gory),
    ]));
  });

  group('matchesFor:', (){

    test('apka i warsztat w jednej liście, od najsilniejszego, z podpisem skąd', (){
      SongRaw edited = song('o!_probe', 'Morze', _ognisko);
      SongRaw inWorkspace = song('o!_ognisko_kopia', 'Ognisko (kopia)', _ognisko);

      List<SongMatch<SongRaw>> got = prov.matchesFor(edited, workspace: [edited, inWorkspace]);

      // Tekst rozstrzyga, tytuł tylko opisuje: „Ognisko” z apki i jego kopia
      // z warsztatu mają ten sam tekst, więc wyprzedzają „Morze”, które ma
      // tylko ten sam tytuł.
      expect(got.map((m) => m.song.id), ['o!_ognisko', 'o!_ognisko_kopia', 'o!_morze']);
      expect(got.map((m) => m.source), [MatchSource.app, MatchSource.workspace, MatchSource.app]);
      expect(got.map((m) => m.level), [MatchLevel.sameSong, MatchLevel.sameSong, MatchLevel.sameTitleDifferentText]);
    });

    test('sama siebie w warsztacie nie jest trafieniem', (){
      SongRaw edited = song('o!_nowa', 'Nowa piosenka', 'Tekst bez żadnego wspólnego słowa');
      expect(prov.matchesFor(edited, workspace: [edited]), isEmpty);
    });

    test('pierwowzór poprawki idzie osobno, nie na listę', (){
      SongRaw correction = song('o!_hej', 'Hej góry', _gory)
        ..piosenkomatData = const PiosenkomatData(kind: SubmissionKind.correction, correctionTarget: 'o!_gory');

      expect(prov.matchesFor(correction), isEmpty,
          reason: '„Góry” z apki to pierwowzór, a nie podobna piosenka');
      OriginalMatch? original = prov.originalMatchOf(correction);
      expect(original?.match.song.id, 'o!_gory');
      expect(original?.match.source, MatchSource.app);
      expect(original?.match.similarities.whereType<SameText>(), hasLength(1));
      expect(original?.guessed, isFalse);
    });

    test('pierwowzór w warsztacie, gdy w apce go nie ma', (){
      SongRaw orig = song('o!_lokalna', 'Lokalna', _morze);
      SongRaw correction = song('o!_lokalna_v2', 'Lokalna v2', _morze)
        ..piosenkomatData = const PiosenkomatData(kind: SubmissionKind.correction, correctionTarget: 'o!_lokalna');

      OriginalMatch? original = prov.originalMatchOf(correction, workspace: [orig, correction]);
      expect(original?.match.song, same(orig));
      expect(original?.match.source, MatchSource.workspace);
    });

    test('pierwowzór znaleziony dopiero bez @wykonawca jest oznaczony jako zgadnięty', (){
      // Apka wskazała id sprzed zmiany wykonawcy — ta sama piosenka, ale domysł.
      SongRaw correction = song('o!_hej', 'Hej góry', _gory)
        ..piosenkomatData = const PiosenkomatData(kind: SubmissionKind.correction, correctionTarget: 'o!_gory@stary_zespol');
      OriginalMatch? original = prov.originalMatchOf(correction);
      expect(original?.match.song.id, 'o!_gory');
      expect(original?.guessed, isTrue);
    });

    test('kolizja id bez deklaracji to trafienie z SameId, nie pierwowzór', (){
      SongRaw copy = song('o!_morze', 'Morze', _morze);
      expect(prov.originalMatchOf(copy), isNull);
      List<SongMatch<SongRaw>> got = prov.matchesFor(copy);
      expect(got.single.song.id, 'o!_morze');
      expect(got.single.similarities.whereType<SameId>(), hasLength(1));
      expect(got.single.level, MatchLevel.identical);
    });

  });

  group('cache:', (){

    test('ten sam obiekt bez zmian → ten sam wynik (tożsamość listy)', (){
      SongRaw edited = song('o!_probe', 'Morze', _morze);
      List<SongMatch<SongRaw>> a = prov.matchesFor(edited);
      List<SongMatch<SongRaw>> b = prov.matchesFor(edited);
      expect(identical(a, b), isTrue);
    });

    test('zmiana tytułu unieważnia wynik', (){
      SongRaw edited = song('o!_probe', 'Morze', 'zupełnie własny tekst bez wspólnych słów');
      expect(prov.matchesFor(edited).map((m) => m.song.id), ['o!_morze']);

      edited.title = 'Góry';
      expect(prov.matchesFor(edited).map((m) => m.song.id), ['o!_gory']);
    });

    test('zmiana treści w warsztacie unieważnia wynik — po zgłoszeniu', (){
      SongRaw edited = song('o!_probe', 'Nic z apki', 'zupełnie własny tekst bez wspólnych słów');
      SongRaw other = song('o!_inna', 'Inna', 'tekst innej piosenki, też własny');
      expect(prov.matchesFor(edited, workspace: [edited, other]), isEmpty);

      // Zmiana w locie nie rusza listy, więc provider sam jej nie zobaczy —
      // ma się zgłosić ten, kto edytuje. W apce robi to CurrentItemProvider
      // (spięcie w `main.dart`), tu robimy to wprost.
      other.title = 'Nic z apki';
      prov.workspaceChanged();

      expect(prov.matchesFor(edited, workspace: [edited, other]).single.source, MatchSource.workspace);
    });

    test('zmiana składu warsztatu unieważnia wynik bez zgłaszania', (){
      SongRaw edited = song('o!_probe', 'Nic z apki', 'zupełnie własny tekst bez wspólnych słów');
      SongRaw other = song('o!_inna', 'Nic z apki', 'tekst innej piosenki, też własny');
      expect(prov.matchesFor(edited, workspace: [edited]), isEmpty);

      // Kto leży w warsztacie, widać po samej liście — tego zgłaszać nie trzeba.
      expect(prov.matchesFor(edited, workspace: [edited, other]).single.source, MatchSource.workspace);
    });

    test('podmiana piosenki na inną pod tym samym numerem też unieważnia', (){
      SongRaw edited = song('o!_probe', 'Nic z apki', 'zupełnie własny tekst bez wspólnych słów');
      SongRaw stara = song('o!_inna', 'Inna', 'tekst innej piosenki, też własny');
      SongRaw nowa = song('o!_inna', 'Nic z apki', 'tekst innej piosenki, też własny');
      expect(prov.matchesFor(edited, workspace: [edited, stara]), isEmpty);

      expect(prov.matchesFor(edited, workspace: [edited, nowa]).single.source, MatchSource.workspace);
    });

  });

  group('pisanie:', (){

    testWidgets('w trakcie pisania poprzedni wynik, po chwili ciszy nowy', (tester) async {
      SimilarSongProvider slow = SimilarSongProvider.withIndex(
        SongIndex<SongRaw>([song('o!_morze', 'Morze', _morze), song('o!_gory', 'Góry', _gory)]),
        settle: const Duration(milliseconds: 300),
      );
      int notified = 0;
      slow.addListener(() => notified++);

      SongRaw edited = song('o!_probe', 'Morze', 'zupełnie własny tekst bez wspólnych słów');
      expect(slow.matchesFor(edited).map((m) => m.song.id), ['o!_morze'], reason: 'pierwszy wynik od razu');

      edited.title = 'Góry';
      expect(slow.matchesFor(edited).map((m) => m.song.id), ['o!_morze'], reason: 'piszesz — jeszcze stary');
      await tester.pump(const Duration(milliseconds: 200));
      edited.title = 'Góry!';
      expect(slow.matchesFor(edited).map((m) => m.song.id), ['o!_morze'], reason: 'kolejny znak odsuwa przeliczenie');
      await tester.pump(const Duration(milliseconds: 200));
      expect(notified, 0);

      await tester.pump(const Duration(milliseconds: 150));
      expect(notified, 1, reason: 'po ciszy słuchacze dostają znać');
      expect(slow.matchesFor(edited).map((m) => m.song.id), ['o!_gory']);
      slow.dispose();
    });

  });

  group('podsumowania:', (){

    test('similarCountText odmienia po polsku', (){
      expect(similarCountText(1), '1 podobna piosenka');
      expect(similarCountText(2), '2 podobne piosenki');
      expect(similarCountText(5), '5 podobnych piosenek');
      expect(similarCountText(12), '12 podobnych piosenek');
      expect(similarCountText(22), '22 podobne piosenki');
    });

    test('similarSongsSummary: jedno — co i skąd; kilka — ile i najbliższe', (){
      SongRaw edited = song('o!_probe', 'Morze', _ognisko);
      List<SongMatch<SongRaw>> got = prov.matchesFor(edited);
      expect(similarSongsSummary(got),
          '2 podobne piosenki — najbliżej „Płonie ognisko” w apce: ta sama piosenka, drobne różnice');
      expect(similarSongsSummary([got.last]),
          '„Morze” w apce: ten sam tytuł, inna treść');
    });

  });

}
