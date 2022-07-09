import 'package:flutter/material.dart';
import 'package:harcapp_core_own_song/song_raw.dart';
import 'package:provider/provider.dart';

import 'generate_file_name.dart';

class ShowSongProvider extends ChangeNotifier{

  bool _showSong;

  ShowSongProvider(this._showSong);

  bool get showSong => _showSong;
  set showSong(bool value){
    if(_showSong == value) return;
    _showSong = value;
    notifyListeners();
  }

}

class LoadingProvider extends ChangeNotifier{

  bool? _loading;

  LoadingProvider(){
    _loading = false;
  }

  bool? get loading => _loading;
  set loading(bool? value){
    _loading = value;
    notifyListeners();
  }

}

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
    bindTitle =
        song.fileName == generateFileName(prov: this, song: song);

    bindPerformer =
        song.fileName.contains('@') && bindTitle;
    notifyListeners();
  }

}

class AllSongsProvider extends ChangeNotifier{

  static AllSongsProvider of(BuildContext context) => Provider.of<AllSongsProvider>(context, listen: false);

  //List<SongRaw> _songs;

  void init(List<SongRaw> songs, Map<SongRaw, bool> confMap){
    _songs = songs;
    _confMap = confMap;
    notifyListeners();
  }

  List<SongRaw> _songs;
  Map<SongRaw, bool> _confMap = {};

  int get length => _songs.length;

  List<SongRaw> get songs => _songs;

  AllSongsProvider(): _songs = [], _confMap = {};

  void addOff(SongRaw song){
    _songs.add(song);
    _confMap[song] = false;
    notifyListeners();
  }

  void addConf(SongRaw song){
    _songs.add(song);
    _confMap[song] = true;
    notifyListeners();
  }

  void remove(SongRaw? song){
    _songs.remove(song);
    _confMap.remove(song);
    notifyListeners();
  }

  addAll(List<SongRaw> songs, Map<SongRaw, bool> confMap){
    _songs.addAll(songs);
    _confMap.addAll(confMap);

    notifyListeners();
  }

  isConf(SongRaw song){
    return _confMap[song];
  }

  set(SongRaw song, bool isConf){
    _confMap[song] = isConf;
    notifyListeners();
  }

}

class SongFileNameDupErrProvider extends ChangeNotifier{

  late Map<SongRaw?, List<SongRaw?>> _errMap;

  SongFileNameDupErrProvider(){
    _errMap = {};
  }

  List<SongRaw?>? get(SongRaw? song) => _errMap[song];
  void putPair(SongRaw? song1, SongRaw? song2){
    if(_errMap[song1] == null)
      _errMap[song1] = [];

    if(!_errMap[song1]!.contains(song2))
      _errMap[song1]!.add(song2);

    if(_errMap[song2] == null)
      _errMap[song2] = [];

    if(!_errMap[song2]!.contains(song1))
      _errMap[song2]!.add(song1);

    notifyListeners();
  }

  void removePair(SongRaw? song1, SongRaw? song2){
    if(_errMap[song1] != null)
      _errMap[song1]!.remove(song2);

    if(_errMap[song2] != null)
      _errMap[song2]!.remove(song1);
    notifyListeners();
  }

  int get count{
    int num = 0;
    for(SongRaw? song in _errMap.keys)
      num += _errMap[song]!.length;

    return num;
  }

  bool hasAny(SongRaw? song) => _errMap[song] != null && _errMap[song]!.length!= 0;

  void checkAllDups(BuildContext context){
    AllSongsProvider allSongsProv = Provider.of<AllSongsProvider>(context, listen: false);

    for(SongRaw? song1 in allSongsProv.songs)
      for(SongRaw? song2 in allSongsProv.songs)
        if(song1 != song2 && song1!.fileName == song2!.fileName){
          putPair(song1, song2);
        }
  }

  void chedkDupsFor(BuildContext context, SongRaw? song){
    AllSongsProvider allSongsProv = Provider.of<AllSongsProvider>(context, listen: false);
    List<SongRaw?> allSongs = allSongsProv.songs;
    for(SongRaw? _song in allSongs)
      if(_song != song && song!.fileName == _song!.fileName)
        putPair(_song, song);
      else
        removePair(_song, song);

  }

}

class SongPreviewProvider extends ChangeNotifier{

  bool? _code;

  SongPreviewProvider(){
    _code = false;
  }

  bool? get code => _code;
  set code(bool? value){
    _code = value;
    notifyListeners();
  }

}

/*
class ShowCodeEditorProvider extends ChangeNotifier{

  String? _text;
  bool? _value;
  SongRaw? _song;

  ShowCodeEditorProvider(){
    _text = '';
    _value = false;
  }

  String? get text => _text;
  set text(String? val){
    _text = val;
  }

  bool? get value => _value;
  set value(bool? val){
    _value = val;
    notifyListeners();
  }

  SongRaw? get song => _song;
  set song(SongRaw? value){
    _song = value;
    notifyListeners();
  }

}
*/

class SongEditorPanelProvider extends ChangeNotifier{

  void notify() => notifyListeners();

}