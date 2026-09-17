import 'package:harcapp_core/comm_classes/text_utils.dart';
import 'package:harcapp_core/song_book/song_editor/song_raw.dart';

/// Wspólne dopasowanie piosenki do frazy szukania - używane i przez listę
/// piosenek w lewym panelu, i przez okno wyboru piosenek do importu, żeby
/// "Szukaj" znaczyło wszędzie to samo.
///
/// `searchableString` zbija ogonki i spacje, więc "zolw" znajdzie "Żółw".
bool songMatchesPhrase(SongRaw song, String phrase, {bool withId = true}){
  String simplifiedPhrase = searchableString(phrase);
  if(simplifiedPhrase.isEmpty) return true;

  if(searchableString(song.title).contains(simplifiedPhrase)) return true;
  if(withId && searchableString(song.id).contains(simplifiedPhrase)) return true;

  return false;
}

List<SongRaw> searchSongs(Iterable<SongRaw> songs, String phrase, {bool withId = true}) =>
    songs.where((song) => songMatchesPhrase(song, phrase, withId: withId)).toList();
