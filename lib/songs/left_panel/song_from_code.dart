import 'dart:convert';

import 'package:harcapp_core/song_book/song_core.dart';
import 'package:harcapp_core/song_book/song_editor/song_raw.dart';
import 'package:harcapp_web/songs/old/parse_old_code.dart';

/// Piosenka z kodu z edytora: stary kod, kod z id (`{"o!_id": {…}}`) albo
/// sama piosenka. Kod bez id nie zmienia id edytowanej piosenki ([editedId]) —
/// właśnie takim kodem wypełnia się pole przy edycji, a id to tożsamość
/// piosenki (przedrostek `oc!_`, wykonawca). Nowa piosenka bierze id z tytułu.
/// `null`, gdy kodu nie da się odczytać.
SongRaw? songFromCode(String code, {String? editedId, required bool withPerformer}){
  try{
    final song = parseOldCode('_nowa_piosenka', code);
    song.id = editedId ?? song.idFromTitle(withPerformer: withPerformer);
    return song;
  } catch(_){}

  final Map map;
  try{
    map = jsonDecode(code);
  } catch(_){
    return null;
  }

  // Cały kod: id → piosenka.
  try{
    final songId = map.keys.first as String;
    return SongRaw.fromApiRespMap(songId, map[songId]);
  } catch(_){}

  // Sama piosenka, bez poziomu z id.
  try{
    return SongRaw.fromApiRespMap(editedId ?? SongCore.officialIdFromTitle(map['title']), map);
  } catch(_){
    return null;
  }
}
