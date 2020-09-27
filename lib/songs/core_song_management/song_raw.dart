
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:harcapp_web/songs/core_song_management/song_core.dart';
import 'package:harcapp_web/songs/song_widget/song_rate.dart';

import 'song_element.dart';

class SongRaw implements SongCore{

  static const String TAB_CHAR = '   ';

  final String fileName;
  final String title;
  final List<String> hidTitles;
  final String author;
  final String performer;
  final String addPers;
  final String youtubeLink;

  bool get official =>
      fileName.length > 3 && fileName.substring(0, 3) == 'o!_' ||
      fileName.length > 4 && fileName.substring(0, 4) == 'oc!_';

  final List<String> tags;

  final bool hasRefren;
  final SongElement refrenElement;

  final List<SongElement> songElements;

  final bool hasChords;

  final String text;
  final String chords;

  SongRaw(
      this.fileName,
      this.title,
      this.hidTitles,
      this.author,
      this.performer,
      this.addPers,
      this.youtubeLink,

      this.tags,

      this.hasRefren,
      this.refrenElement,

      this.songElements,
      this.hasChords,

      this.text,
      this.chords,
    );

  static SongRaw parse(String fileName, String code) {
    bool hasRefren = false;
    bool hasChords = false;

    Map<String, dynamic> map = jsonDecode(code)[fileName];

    String title = map['title'];
    List<String> addTitles = (map['hid_titles'] as List).cast<String>();
    String author = map['text_author'];
    String performer = map['performer'];
    String ytLink = map['yt_link'];
    String moderator = map['add_pers'];
    List<String> tags = (map['tags'] as List).cast<String>();
    SongElement refren;
    if (map.containsKey('refren')) {
      hasRefren = true;
      Map refrenMap = map['refren'];
      refren = SongElement.from(refrenMap['text'], refrenMap['chords'], true);
    }

    String songChords = '';
    String songText = '';

    List<SongElement> songElements = [];
    List<dynamic> partsList = map['parts'];
    for (Map partMap in partsList) {
      if (partMap.containsKey('refren'))
        for (int i = 0; i < partMap['refren']; i++) {
          songElements.add(refren);
          songText += refren.getText(withTabs: true);
          songChords += refren.chords;

          int textLines =  refren.getText(withTabs: true).split("\n").length;
          int chodsLines = refren.chords.split("\n").length;

          for(int j=0; j<chodsLines-textLines; j++)
            songText += '\n';
          for(int j=0; j<textLines-chodsLines; j++)
            songChords += '\n';

          if(songChords.replaceAll('\n', '').length != 0)
            hasChords = true;

        }
      else {
        SongElement songElement = SongElement.from(partMap['text'], partMap['chords'], partMap['shift']);
        songElements.add(songElement);
        songText += songElement.getText();
        songChords += songElement.chords;

        int textLines = songText.split('\n').length;
        int chodsLines = songChords.split('\n').length;
        for(int j=0; j < chodsLines - textLines; j++)
          songText += '\n';
        for(int j=0; j < textLines - chodsLines; j++)
          songChords += '\n';

        if(songChords.replaceAll('\n', '').length != 0)
          hasChords = true;

      }

      songText += '\n\n';
      songChords += '\n\n';

    }

    //remove last '\n'
    if(songText.length>0)
      songText = songText.substring(0, songText.length - 2).replaceAll('\t', TAB_CHAR);

    if(songChords.length>0)
      songChords = songChords.substring(0, songChords.length -2);

    return SongRaw(
      fileName,
      title,
      addTitles,
      author,
      performer,
      moderator,
      ytLink,

      tags,

      hasRefren,
      refren,

      songElements,
      hasChords,

      songText,
      songChords,
    );
  }

  static SongRaw from(String codeBase64){
    String code = Utf8Decoder().convert(Base64Codec().decode(codeBase64).toList());
    return SongRaw.parse('_shared', code);
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

    if(hasRefren)
      map['refren'] = {
        'text': refrenElement.getText(),
        'chords': refrenElement.chords,
        'shift': true
      };

    List<Map> parts = [];

    int refCount = 0;
    for (SongElement element in songElements) {

      if (element == null) {
        refCount++;
        continue;

      }else {
        parts.add({
          'text': element.getText(),
          'chords': element.chords,
          'shift': element.shift
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

  bool operator == (Object other) => other is SongRaw && fileName == other.fileName;
  int get hashCode => fileName.hashCode;

  @override
  String getChords() => chords;

  @override
  int get rate => SongRate.RATE_NULL;

}
