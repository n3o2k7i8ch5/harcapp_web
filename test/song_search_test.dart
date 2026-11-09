import 'package:flutter_test/flutter_test.dart';
import 'package:harcapp_core/song_book/song_editor/song_raw.dart';
import 'package:harcapp_core/song_book/song_origin.dart';
import 'package:harcapp_web/songs/utils/song_search.dart';

void main(){

  final mamTeMoc = SongRaw.empty(id: 'o!_mam_te_moc')
    ..title = 'Mam tę moc'
    ..origins = const [SongOrigin(SongOriginType.animation, 'Kraina lodu')];

  test('po tytule i po pochodzeniu, bez ogonków', (){
    expect(songMatchesPhrase(mamTeMoc, 'mam te'), isTrue);
    expect(songMatchesPhrase(mamTeMoc, 'kraina lodu'), isTrue);
    expect(songMatchesPhrase(mamTeMoc, 'Shrek'), isFalse);
  });

  test('rodzaju pochodzenia nie szukamy — „bajki” to nie nazwa', (){
    expect(songMatchesPhrase(mamTeMoc, 'z bajki', withId: false), isFalse);
  });

}
