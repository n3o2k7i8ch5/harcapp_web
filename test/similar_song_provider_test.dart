import 'package:flutter_test/flutter_test.dart';
import 'package:harcapp_core/song_book/piosenkomat/piosenkomat_data.dart';
import 'package:harcapp_core/song_book/similarity/similarity.dart';
import 'package:harcapp_core/song_book/similarity/song_index.dart';
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

      // Warsztatowa kopia ma ten sam tekst co „Ognisko” z apki, ale to tytuł
      // („Morze”) daje wyższy poziom — więc „Morze” pierwsze.
      expect(got.map((m) => m.song.id), ['o!_morze', 'o!_ognisko', 'o!_ognisko_kopia']);
      expect(got.map((m) => m.source), [MatchSource.app, MatchSource.app, MatchSource.workspace]);
      expect(got[0].level, MatchLevel.sameTitleDifferentText);
      expect(got[1].level, MatchLevel.similarText);
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
      SongMatch<SongRaw>? original = prov.originalMatchOf(correction);
      expect(original?.song.id, 'o!_gory');
      expect(original?.source, MatchSource.app);
      expect(original?.similarities.whereType<SameText>(), hasLength(1));
    });

    test('pierwowzór w warsztacie, gdy w apce go nie ma', (){
      SongRaw orig = song('o!_lokalna', 'Lokalna', _morze);
      SongRaw correction = song('o!_lokalna_v2', 'Lokalna v2', _morze)
        ..piosenkomatData = const PiosenkomatData(kind: SubmissionKind.correction, correctionTarget: 'o!_lokalna');

      SongMatch<SongRaw>? original = prov.originalMatchOf(correction, workspace: [orig, correction]);
      expect(original?.song, same(orig));
      expect(original?.source, MatchSource.workspace);
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

    test('zmiana w warsztacie unieważnia wynik', (){
      SongRaw edited = song('o!_probe', 'Nic z apki', 'zupełnie własny tekst bez wspólnych słów');
      SongRaw other = song('o!_inna', 'Inna', 'tekst innej piosenki, też własny');
      expect(prov.matchesFor(edited, workspace: [edited, other]), isEmpty);

      other.title = 'Nic z apki';
      expect(prov.matchesFor(edited, workspace: [edited, other]).single.source, MatchSource.workspace);
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
          '2 podobne piosenki — najbliżej „Morze” w apce: ten sam tytuł, inna treść');
      expect(similarSongsSummary([got.last]),
          '„Płonie ognisko” w apce: podobny tekst');
    });

  });

}
