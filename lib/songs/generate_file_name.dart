import 'package:flutter/cupertino.dart';
import 'package:harcapp_core_own_song/song_raw.dart';
import 'package:harcapp_web/songs/providers.dart';

String generateFileName({required SongRaw song, BuildContext? context, BindTitleFileNameProvider? prov}){

  assert(context != null || prov != null);

  String _conf = song.isConfid?'oc!_':'o!_';

  return _conf + song.generateFileName(withPerformer: (prov??BindTitleFileNameProvider.of(context!)).bindPerformer);

}