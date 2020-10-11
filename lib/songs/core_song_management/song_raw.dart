
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:harcapp_web/songs/core_own_song/common.dart';
import 'package:harcapp_web/songs/core_song_management/song_core.dart';
import 'package:harcapp_web/songs/song_widget/song_rate.dart';

import 'song_element.dart';

class SongRaw implements SongCore{

  static const String TAB_CHAR = '   ';

  String fileName;
  String title;
  List<String> hidTitles;
  String author;
  String performer;
  String addPers;
  String youtubeLink;

  bool get official =>
      fileName.length > 3 && fileName.substring(0, 3) == 'o!_' ||
          fileName.length > 4 && fileName.substring(0, 4) == 'oc!_';

  List<String> tags;

  bool hasRefren;
  SongPart refrenPart;

  List<SongPart> songParts;

  bool get hasChords => chords.replaceAll('\n', '').replaceAll(' ', '').length!=0;

  //final String text;
  //final String chords;

  SongRaw({
    this.fileName,
    this.title,
    this.hidTitles,
    this.author,
    this.performer,
    this.addPers,
    this.youtubeLink,

    this.tags,

    this.hasRefren,
    this.refrenPart,

    this.songParts,
    //this.hasChords,

    //this.text,
    //this.chords,
  });

  static SongRaw empty(){

    return SongRaw(
      fileName: '',
      title: '',
      hidTitles: [],
      author: '',
      performer: '',
      addPers: '',
      youtubeLink: '',
      tags: [],
      hasRefren: false,
      refrenPart: SongPart.empty(),
      songParts: [],
      //hasChords: false,
      //text: '',
      //chords: ''
    );
  }

  static SongRaw parse(String fileName, String code) {
    Map<String, dynamic> map = jsonDecode(code)[fileName];
    return fromMap(fileName, map);
  }

  static SongRaw from(String codeBase64){
    String code = Utf8Decoder().convert(Base64Codec().decode(codeBase64).toList());
    return SongRaw.parse('_shared', code);
  }

  static SongRaw fromMap(String fileName, Map map){
    bool hasRefren = false;
    bool hasChords = false;

    String title = map['title'];
    List<String> hidTitles = (map['hid_titles'] as List).cast<String>();
    String author = map['text_author'];
    String performer = map['performer'];
    String youtubeLink = map['yt_link'];
    String addPers = map['add_pers'];
    List<String> tags = (map['tags'] as List).cast<String>();
    SongPart refrenPart;
    if (map.containsKey('refren')) {
      hasRefren = true;
      Map refrenMap = map['refren'];
      refrenPart = SongPart.from(SongElement.from(refrenMap['text'], refrenMap['chords'], true));
    }

    List<SongPart> songParts = [];
    List<dynamic> partsList = map['parts'];
    for (Map partMap in partsList) {
      if (partMap.containsKey('refren'))
        for (int i = 0; i < partMap['refren']; i++) {
          songParts.add(SongPart.from(refrenPart.element));

          if(refrenPart.chords.replaceAll('\n', '').length != 0)
            hasChords = true;

        }
      else {
        SongPart songPart = SongPart.from(SongElement.from(partMap['text'], partMap['chords'], partMap['shift']));
        songParts.add(songPart);

      }
    }

    return SongRaw(
      fileName: fileName,
      title: title,
      hidTitles: hidTitles,
      author: author,
      performer: performer,
      addPers: addPers,
      youtubeLink: youtubeLink,

      tags: tags,

      hasRefren: hasRefren,
      refrenPart: refrenPart,

      songParts: songParts,
      //hasChords: hasChords,
    );
  }

  String get text{

    String text = '';

    for (SongPart part in songParts) {

      text += part.getText(withTabs: part.shift);

      int textLines =  part.getText(withTabs: part.shift).split("\n").length;
      int chodsLines = part.chords.split("\n").length;

      for(int j=0; j<chodsLines-textLines; j++)
        text += '\n';

      text += '\n\n';
    }

    if(text.length>0) text = text.substring(0, text.length-2);

    return text;
  }

  String get chords{

    String chords = '';

    for (SongPart part in songParts) {

      chords += part.chords;

      int textLines =  part.getText(withTabs: part.shift).split("\n").length;
      int chodsLines = part.chords.split("\n").length;

      for(int j=0; j<textLines-chodsLines; j++)
        chords += '\n';

      chords += '\n\n';
    }

    if(chords.length>0) chords = chords.substring(0, chords.length-2);

    return chords;
  }

  String convertToCode(){

    Map map = {};
    map['title'] = title;
    map['additional_titles'] = [];
    map['text_author'] = author;
    map['performer'] = performer;
    map['yt_link'] = youtubeLink;
    map['add_pers'] = addPers;

    map['tags'] = tags;

    if(hasRefren && !refrenPart.isEmpty)
      map['refren'] = {
        'text': refrenPart.getText(),
        'chords': refrenPart.chords,
        'shift': true
      };

    List<Map> parts = [];

    int refCount = 0;
    for (SongPart part in songParts) {

      if (part == null) {
        refCount++;
        continue;

      }else {
        parts.add({
          'text': part.getText(),
          'chords': part.chords,
          'shift': part.shift
        });
      }

      if(refCount>0) {
        parts.add({'refren': refCount});
        refCount = 0;
      }
    }

    if(refCount>0)
      parts.add({'refren': refCount});

    map['parts'] = parts;

    return jsonEncode({fileName : map});
  }

  //bool operator == (Object other) => other is SongRaw && fileName == other.fileName;
  //int get hashCode => fileName.hashCode;

  @override
  String getChords() => chords;

  @override
  int get rate => SongRate.RATE_NULL;

/*
  static Future<SongRaw> read({@required String fileName}) async {
    String code = await getSongCode(fileName);
    return SongRaw.parse(fileName, code);
  }
*/
}
