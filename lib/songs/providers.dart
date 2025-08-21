import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:harcapp_core/comm_classes/common.dart';
import 'package:harcapp_core/comm_classes/sha_pref.dart';
import 'package:harcapp_core/song_book/song_editor/song_raw.dart';
import 'package:harcapp_web/common/sha_pref.dart';
import 'package:harcapp_web/songs/utils/song_loader.dart';
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
      // (song.lclId.contains('@') && bindTitle) || song.lclId == 'o!_' || song.lclId == 'oc!_';
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
    _songs.remove(song);
    _confMap.remove(song);
    _cacheSongs();
    notifyListeners();
  }

  void addAll(List<SongRaw> songs, Map<SongRaw, bool> confMap){
    _songs.addAll(songs);
    _confMap.addAll(confMap);
    _cacheSongs();
    notifyListeners();
  }

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

    Map<String, List<SongRaw>> decodedSongs = decodeSongs(code);

    List<SongRaw> result = [];
    for (List<SongRaw> songs in decodedSongs.values)
      result.addAll(songs);

    return result;
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
      Map map = song.toApiJsonMap(withId: false);
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
    return allSongs![remSpecChars(remPolChars(title))]??[];
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