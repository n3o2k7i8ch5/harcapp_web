import 'package:flutter/material.dart';

import 'core_own_song/common.dart';
import 'core_song_management/song_raw.dart';


class LoadingProvider extends ChangeNotifier{

  bool _loading;

  LoadingProvider(){
    _loading = false;
  }

  bool get loading => _loading;
  set loading(bool value){
    _loading = value;
    notifyListeners();
  }

}

class BindTitleFileNameProvider extends ChangeNotifier{

  bool _bind;

  BindTitleFileNameProvider(){
    _bind = true;
  }

  bool get bind => _bind;
  set bind(bool value){
    _bind = value;
    notifyListeners();
  }

}

class AllSongsProvider extends ChangeNotifier{

  List<SongRaw> _songs;

  int get length => _songs.length;

  List<SongRaw> get songs => _songs;

  AllSongsProvider(){
    _songs = [];
  }

  void add(SongRaw song){
    _songs.add(song);
    notifyListeners();
  }

  void remove(SongRaw song){
    _songs.remove(song);
    notifyListeners();
  }

  void removeAt(int index){
    _songs.removeAt(index);
    notifyListeners();
  }

  set songs(List<SongRaw> value){
    _songs = value;
    notifyListeners();
  }

  addAll(List<SongRaw> songs){
    _songs.addAll(songs);
    notifyListeners();
  }

}

class SongFileNameBlockProvider extends ChangeNotifier{

  bool _blocked;

  SongFileNameBlockProvider(){
    _blocked = false;
  }

  bool get blocked => _blocked;
  set blocked(bool value){
    _blocked = value;
    notifyListeners();
  }

}

class SongFileNameDupErrProvider extends ChangeNotifier{

  Map<SongRaw, List<SongRaw>> _errMap;

  SongFileNameDupErrProvider(){
    _errMap = {};
  }

  List<SongRaw> get(SongRaw song) => _errMap[song];
  void putPair(SongRaw song1, SongRaw song2){
    if(_errMap[song1] == null)
      _errMap[song1] = [];

    if(!_errMap[song1].contains(song2))
      _errMap[song1].add(song2);

    if(_errMap[song2] == null)
      _errMap[song2] = [];

    if(!_errMap[song2].contains(song1))
      _errMap[song2].add(song1);

    notifyListeners();
  }

  void removePair(SongRaw song1, SongRaw song2){
    if(_errMap[song1] != null)
      _errMap[song1].remove(song2);

    if(_errMap[song2] != null)
      _errMap[song2].remove(song1);
    notifyListeners();
  }

  int get count{
    int num = 0;
    for(SongRaw song in _errMap.keys)
      num += _errMap[song].length;

    return num;
  }

  bool hasAny(SongRaw song) => _errMap[song] != null && _errMap[song].length!= 0;

}

class SongPreviewProvider extends ChangeNotifier{

  bool _code;

  SongPreviewProvider(){
    _code = false;
  }

  bool get code => _code;
  set code(bool value){
    _code = value;
    notifyListeners();
  }

}

class ShowCodeEditorProvider extends ChangeNotifier{

  String _text;
  bool _value;
  SongRaw _song;

  ShowCodeEditorProvider(){
    _text = '';
    _value = false;
  }

  String get text => _text;
  set text(String val){
    _text = val;
  }

  bool get value => _value;
  set value(bool val){
    _value = val;
    notifyListeners();
  }

  SongRaw get song => _song;
  set song(SongRaw value){
    _song = value;
    notifyListeners();
  }

}