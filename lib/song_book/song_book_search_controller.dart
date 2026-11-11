import 'package:flutter/widgets.dart';
import 'package:harcapp_core/song_book/song_search.dart';

import 'song_book_song.dart';

/// Stan wyszukiwania w spisie treści: fraza i zaznaczone tagi. Trzyma go
/// strona, nie sam spis — żeby kliknięcie autora czy tagu w otwartej
/// piosence mogło spis przefiltrować (jak w apce).
///
/// Zasady trafień i ich kolejność są wspólne z apką ([searchSongs]).
class SongBookSearchController extends ChangeNotifier{

  final List<SongBookSong> songs;
  final TextEditingController textController = TextEditingController();

  List<String> _checkedTags = [];
  List<String> get checkedTags => List.unmodifiable(_checkedTags);

  late List<SongBookSong> _results = songs;
  List<SongBookSong> get results => _results;

  SongBookSearchController(this.songs);

  String get phrase => textController.text;

  bool get isEmpty => phrase.isEmpty && _checkedTags.isEmpty;
  bool get isNotEmpty => !isEmpty;

  /// Fraza wpisana ręcznie — pole tekstowe już ją ma.
  void onPhraseChanged() => _run();

  /// Fraza z zewnątrz (np. kliknięty autor): wpisuje ją też do pola.
  void setPhrase(String phrase){
    textController.text = phrase;
    _checkedTags = [];
    _run();
  }

  void toggleTag(String tag){
    if(!_checkedTags.remove(tag)) _checkedTags = [..._checkedTags, tag]..sort();
    else _checkedTags = [..._checkedTags];
    _run();
  }

  /// Tylko ten jeden tag, bez frazy (np. kliknięty tag w piosence).
  void showTag(String tag){
    textController.text = '';
    _checkedTags = [tag];
    _run();
  }

  void clear(){
    textController.text = '';
    _checkedTags = [];
    _run();
  }

  void _run(){
    if(isEmpty)
      _results = songs;
    else
      _results = [
        for(final int i in searchSongs<SongBookSong>(
          songs,
          phrase,
          entryOf: (song) => song.searchEntry,
          filter: _checkedTags.isEmpty ? null : (song) => songHasTags(song, _checkedTags),
        )!) songs[i],
      ];
    notifyListeners();
  }

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }

}
