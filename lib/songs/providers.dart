import 'package:flutter/material.dart';
import 'package:harcapp_core_own_song/song_raw.dart';
import 'package:provider/provider.dart';

import 'generate_file_name.dart';

class ShowSongProvider extends ChangeNotifier{

  static ShowSongProvider of(BuildContext context) => Provider.of<ShowSongProvider>(context, listen: false);

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
      (song.fileName.contains('@') && bindTitle) || song.fileName == 'o!_' || song.fileName == 'oc!_';
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

  static SongFileNameDupErrProvider of(BuildContext context) => Provider.of<SongFileNameDupErrProvider>(context, listen: false);
  static notify_(BuildContext context) => of(context).notify();

  late Map<String, List<SongRaw>> _map;

  SongFileNameDupErrProvider(){
    _map = {};
  }

  List<SongRaw> get(SongRaw song) => _map[song.fileName]??[];

  int get count{
    int num = 0;
    for(String songFileName in _map.keys)
      if(_map[songFileName]!.length > 1)
        num += _map[songFileName]!.length;

    return num;
  }

  bool hasDup(SongRaw song) => _map[song.fileName] != null && _map[song.fileName]!.length > 1;

  void checkAllDups(BuildContext context){
    _map.clear();

    for(SongRaw song in Provider.of<AllSongsProvider>(context, listen: false).songs) {
      if(_map[song.fileName] == null)
        _map[song.fileName] = [];
      _map[song.fileName]!.add(song);
    }

    notifyListeners();
  }

  void notify() => notifyListeners();

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

class SongEditorPanelProvider extends ChangeNotifier{

  static SongEditorPanelProvider of(BuildContext context) => Provider.of<SongEditorPanelProvider>(context, listen: false);
  static void notify_(BuildContext context) => of(context).notify();

  void notify() => notifyListeners();

}