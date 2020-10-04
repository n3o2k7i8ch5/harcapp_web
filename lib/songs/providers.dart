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