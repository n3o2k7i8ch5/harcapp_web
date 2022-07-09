import 'package:flutter/cupertino.dart';
import 'package:harcapp_core/comm_classes/common.dart';
import 'package:harcapp_core_own_song/song_raw.dart';
import 'package:harcapp_web/songs/providers.dart';
import 'package:provider/provider.dart';

String generateFileName({required SongRaw song, BuildContext? context, BindTitleFileNameProvider? prov}){

  assert(context != null || prov != null);

  String _conf = song.isConfid?'oc!_':'o!_';

  String _title = remPolChars(song.title)
      .replaceAll(' ', '_')
      .replaceAll(',', '')
      .replaceAll('.', '')
      .replaceAll('(', '')
      .replaceAll(')', '')
      .replaceAll(':', '')
      .replaceAll(';', '')
      .replaceAll('"', '').trim();

  bool performer = (prov??BindTitleFileNameProvider.of(context!)).bindPerformer;

  if(!performer || song.performers.isEmpty)
    return _conf + _title;

  String _performer = remPolChars(song.performers[0])
      .replaceAll(' ', '_')
      .replaceAll(',', '')
      .replaceAll('.', '')
      .replaceAll('(', '')
      .replaceAll(')', '')
      .replaceAll(':', '')
      .replaceAll(';', '')
      .replaceAll('"', '').trim();

  return _conf + _title + '@' + _performer;

}