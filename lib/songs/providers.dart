import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:harcapp_core/comm_classes/sha_pref.dart';
import 'package:harcapp_core/comm_classes/text_utils.dart';
import 'package:harcapp_core/song_book/import_hrcpsng.dart';
import 'package:harcapp_core/song_book/song_editor/song_raw.dart';
import 'package:harcapp_web/common/sha_pref.dart';
import 'package:harcapp_web/songs/utils/song_loader.dart';
import 'package:harcapp_web/songs/utils/song_search.dart';
import 'package:provider/provider.dart';


class BindTitleFileNameProvider extends ChangeNotifier{

  static BindTitleFileNameProvider of(BuildContext context) => Provider.of<BindTitleFileNameProvider>(context, listen: false);

  static const bool DEF_VAL = true;

  late bool _bindTitle;
  late bool _bindPerformer;

  BindTitleFileNameProvider(){
    _bindTitle = DEF_VAL;
    _bindPerformer = DEF_VAL;
  }

  bool get bindTitle => _bindTitle;
  set bindTitle(bool value){
    _bindTitle = value;
    notifyListeners();
  }

  bool get bindPerformer => _bindPerformer;
  set bindPerformer(bool value){
    _bindPerformer = value;
    notifyListeners();
  }

  void setSetBasedOnSong(SongRaw song){
    bindTitle = song.id.split('@')[0] == (song.isConfid?'oc!_':'o!_') + song.generateFileName(withPerformer: false);

    bindPerformer = song.id == (song.isConfid?'oc!_':'o!_') + song.generateFileName(withPerformer: true);
    notifyListeners();
  }

}

class AllSongsProvider extends ChangeNotifier{

  static AllSongsProvider of(BuildContext context) => Provider.of<AllSongsProvider>(context, listen: false);

  List<SongRaw> _songs;
  Map<SongRaw, bool> _confMap = {};

  int get length => _songs.length;

  List<SongRaw> get songs => _songs;

  AllSongsProvider(List<SongRaw> songs): _songs = songs, _confMap = {for (SongRaw song in songs) song: song.isConfid};

  void clear(){
    _songs.clear();
    _confMap.clear();
    _cacheSongs();
    notifyListeners();
  }

  void addOff(SongRaw song){
    _songs.add(song);
    _confMap[song] = false;
    _cacheSongs();
    notifyListeners();
  }

  void addConf(SongRaw song){
    _songs.add(song);
    _confMap[song] = true;
    _cacheSongs();
    notifyListeners();
  }

  void remove(SongRaw? song){
    // `removeWhere`, a nie `remove`: gdyby ten sam obiekt trafił na listę
    // więcej niż raz, `remove` zdjęłoby tylko pierwsze wystąpienie i piosenka
    // zostałaby na liście (z fałszywym alarmem o powtórzonej nazwie).
    _songs.removeWhere((s) => identical(s, song));
    _confMap.remove(song);
    _cacheSongs();
    notifyListeners();
  }

  void removeAll(List<SongRaw> songs){
    for(SongRaw song in songs){
      _songs.removeWhere((s) => identical(s, song));
      _confMap.remove(song);
    }
    _cacheSongs();
    notifyListeners();
  }

  void addAll(List<SongRaw> songs, Map<SongRaw, bool> confMap){
    _songs.addAll(songs);
    _confMap.addAll(confMap);
    _cacheSongs();
    notifyListeners();
  }

  /// Ile piosenek faktycznie wchodzi do śpiewnika. Przy przeglądzie
  /// piosenkomatem resztę zgasiłeś przełącznikiem; poza przeglądem
  /// równe [length].
  int get goingInCount =>
      _songs.where((s) => s.piosenkomatData?.goesIn != false).length;

  bool? isConf(SongRaw song) => _confMap[song];

  void set(SongRaw song, bool isConf){
    _confMap[song] = isConf;
    _cacheSongs();
    notifyListeners();
  }

  void _cacheSongs() =>
    ShaPref.setString(SHA_PREF_LAST_EDITED_SONGS, convertAllToCode());

  static Future<List<SongRaw>> loadCachedSongs() async {
    String? code = ShaPref.getStringOrNull(SHA_PREF_LAST_EDITED_SONGS);
    if(code == null) return [];

    // Cache jest pisany przez `convertAllToCode()`, czyli w formacie hrcpsng —
    // i tak samo go czytamy. `decodeSongs()` to indeks tytuł -> piosenki (dla
    // szukania podobnych) i wrzuca ten sam obiekt raz na tytuł i raz na każdy
    // tytuł ukryty, więc piosenka z `hidTitles` lądowała na liście kilka razy
    // (fałszywy alarm o powtórzonej nazwie, a usunięcie zdejmowało tylko jedno
    // wystąpienie).
    try {
      (List<SongRaw>, List<SongRaw>) songsResult = importHrcpsng(code);
      return songsResult.$2.cast<SongRaw>() + songsResult.$1.cast<SongRaw>();
    } catch(e){
      // Stary/nadgryziony cache (np. pomieszane indeksy) — wtedy ratujemy, co
      // się da, starą drogą, ale z odsiewaniem powtórzonych wystąpień.
      Map<String, List<SongRaw>> decodedSongs = decodeSongs(code);

      Set<SongRaw> seen = Set.identity();
      List<SongRaw> result = [];
      for (List<SongRaw> songs in decodedSongs.values)
        for (SongRaw song in songs)
          if(seen.add(song)) result.add(song);

      return result;
    }
  }

  static void clearCachedSongs() =>
      ShaPref.remove(SHA_PREF_LAST_EDITED_SONGS);
  
  String convertAllToCode(){

    Map offSongMap = {};
    Map confSongMap = {};

    _songs.sort((a, b) => compareText(a.title, b.title));

    int iterOff = 0;
    int iterConf = 0;
    for(SongRaw song in _songs){
      // Z uwagami piosenkomatu: to ten plik wraca do narzędzia jako
      // `reviewed.hrcpsng` i po nich poznaje, co zostało ogarnięte.
      Map map = song.toApiJsonMap(withId: false, withPiosenkomatData: true);
      if(isConf(song)!)
        confSongMap[song.id] = {
          'song': map,
          'index': iterConf++
        };
      else
        offSongMap[song.id] = {
          'song': map,
          'index': iterOff++
        };
    }

    String code = jsonEncode({
      'official': offSongMap,
      'conf': confSongMap,
    });

    return code;
  }

}

class SongFileNameDupErrProvider extends ChangeNotifier{

  static SongFileNameDupErrProvider of(BuildContext context) => Provider.of<SongFileNameDupErrProvider>(context, listen: false);
  static notify_(BuildContext context) => of(context).notify();

  late Map<String, List<SongRaw>> _map;

  SongFileNameDupErrProvider(){
    _map = {};
  }

  get lclIds => _map.keys.toList();
  get dupLclIds => lclIds.where((lclId) => _map[lclId]!.length > 1).toList();

  List<SongRaw> get(SongRaw song) => _map[song.id]??[];

  int get count{
    int num = 0;
    for(String songFileName in _map.keys)
      if(_map[songFileName]!.length > 1)
        num += _map[songFileName]!.length;

    return num;
  }

  bool hasDup(SongRaw song) => _map[song.id] != null && _map[song.id]!.length > 1;

  void checkAllDups(BuildContext context){
    _map.clear();

    for(SongRaw song in AllSongsProvider.of(context).songs) {
      if(_map[song.id] == null) _map[song.id] = [];
      _map[song.id]!.add(song);
    }

    notifyListeners();
  }

  void notify() => notifyListeners();

}

class SongPreviewProvider extends ChangeNotifier{

  static SongPreviewProvider of(BuildContext context) => Provider.of<SongPreviewProvider>(context, listen: false);

  late bool _code;
  late bool _showSong;

  SongPreviewProvider(){
    _code = false;
    _showSong = false;
  }

  bool get code => _code;
  set code(bool value){
    _code = value;
    notifyListeners();
  }

  bool get showSong => _showSong;
  set showSong(bool value){
    if(_showSong == value) return;
    _showSong = value;
    notifyListeners();
  }

}

class EmailSongUnlockProvider extends ChangeNotifier{

  static EmailSongUnlockProvider of(BuildContext context) => Provider.of<EmailSongUnlockProvider>(context, listen: false);

  static const int _unlockClickCount = 4;
  static const Duration _resetTimeout = Duration(seconds: 2);

  int _clickCount = 0;
  DateTime? _lastClickTime;
  bool _unlocked = false;

  bool get unlocked => _unlocked;

  void registerClick(){
    if(_unlocked) return;

    DateTime now = DateTime.now();
    if(_lastClickTime != null && now.difference(_lastClickTime!) > _resetTimeout)
      _clickCount = 0;

    _lastClickTime = now;
    _clickCount++;

    if(_clickCount >= _unlockClickCount){
      _unlocked = true;
      notifyListeners();
    }
  }

}

class SongEditorPanelProvider extends ChangeNotifier{

  static SongEditorPanelProvider of(BuildContext context) => Provider.of<SongEditorPanelProvider>(context, listen: false);
  static void notify_(BuildContext context) => of(context).notify();

  void notify() => notifyListeners();

}

class SimilarSongProvider extends ChangeNotifier{

  static SimilarSongProvider of(BuildContext context) => Provider.of<SimilarSongProvider>(context, listen: false);

  // A dict containing simplified song titles and hidden titles as keys and
  // lists of similar songs with that title or hidden title as values.
  Map<String, List<SongRaw>>? allSongs;

  List<SongRaw>? getSimilarSongs(String title){
    if(allSongs == null) return null;
    return allSongs![searchableString(title)]??[];
  }

  bool hasSimilarSong(String title){
    List<SongRaw>? similarSongs = getSimilarSongs(title);
    if(similarSongs == null) return false;

    return similarSongs.isNotEmpty;
  }

  void init() async {
    allSongs = await loadSongs();
    notifyListeners();
  }

}

class SearchListProvider extends ChangeNotifier{

  static SearchListProvider of(BuildContext context) => Provider.of<SearchListProvider>(context, listen: false);

  late bool anySearchPhrase;

  late List<SongRaw> currSongList;

  late String searchPhrase;

  List<SongRaw> _allSongs;

  List<SongRaw> get allSongs => _allSongs;

  SearchListProvider(this._allSongs){
    searchPhrase = '';
    anySearchPhrase = false;
    currSongList = [];
  }

  void changeSearchPhrase(String text){
    searchPhrase = text;
    anySearchPhrase = text.length!=0;
    currSongList = searchSongs(allSongs, text);

    notifyListeners();

  }

  void research() => changeSearchPhrase(searchPhrase);

  int get length{
    if(anySearchPhrase)
      return currSongList.length;
    else
      return allSongs.length;
  }

  SongRaw? get(int index){
    if(anySearchPhrase)
      return currSongList[index];
    else
      return allSongs[index];
  }

}