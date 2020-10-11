

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:harcapp_web/common/app_text_style.dart';
import 'package:harcapp_web/common/color_pack.dart';
import 'package:harcapp_web/common/core_comm_classes/primitive_wrapper.dart';
import 'package:harcapp_web/common/dimen.dart';
import 'package:harcapp_web/songs/core_own_song/providers.dart';
import 'package:harcapp_web/songs/core_song_management/song_element.dart';
import 'package:harcapp_web/songs/core_song_management/song_raw.dart';
import 'package:harcapp_web/songs/core_tags/tag_layout.dart';
import 'package:provider/provider.dart';

import 'errors.dart';

const double CHORDS_WIDGET_MIN_WIDTH = 80.0;

Color COLOR_OK = Colors.green.withOpacity(0.5);
Color COLOR_WAR = Colors.red.withOpacity(0.3);
Color COLOR_ERR = Colors.red.withOpacity(0.7);

TextInputFormatter ALLOWED_TEXT_REGEXP = FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9ĄąĆćĘęŁłŃńÓóŚśŹźŻż \(\)\-\.\,\!\?\n]'));


class HeaderWidget extends StatelessWidget{

  final String title;
  final IconData icon;
  final Color iconColor;
  final bool enabled;
  const HeaderWidget(this.title, this.icon, {this.iconColor, this.enabled: true});

  @override
  Widget build(BuildContext context) {

    Color color = iconColor;
    if(color==null){
      color = enabled?textEnabled(context):hintEnabled(context);
    }

    return Padding(
      padding: EdgeInsets.all(2*Dimen.DEF_MARG),
      child: Row(
        children: [
          SizedBox(height: Dimen.ICON_FOOTPRINT),
          Icon(icon, color: color),
          SizedBox(width: 2*Dimen.MARG_ICON),
          Text(title,
            style: AppTextStyle(
                color: enabled?textEnabled(context):hintEnabled(context),
                fontWeight: weight.halfBold,
                fontSize: Dimen.TEXT_SIZE_BIG,
                shadow: enabled
            ),
          ),
        ],
      ),
    );
  }

}

class SongPart{

  final SongElement _songElement;
  final PrimitiveWrapper<bool> _isError;

  String getText({bool withTabs: false}) => _songElement.getText(withTabs: withTabs);
  void setText(String text) => _songElement.setText(text);

  SongElement get element => _songElement;

  String get chords => _songElement.chords;
  set chords(String text) => _songElement.chords = text;

  bool get shift => _songElement.shift;
  set shift(bool value) => _songElement.shift = value;

  bool get isEmpty => chords.length==0 && getText().length==0;

  SongPart copy() => SongPart.from(
    element.copy(),
  );

  static SongPart from(SongElement songElement){
    return SongPart(
        songElement,
        PrimitiveWrapper<bool>(hasAnyErrors(songElement.getText(), songElement.chords))
    );
  }

  static empty({isRefren: false}){
    return SongPart.from(SongElement.empty(isRefren: isRefren));
  }

  SongPart(this._songElement, this._isError);

  bool get isError => _isError.get();
  set isError(bool value) => _isError.set(value);

  bool isRefren(BuildContext context){
    RefrenPartProvider prov = Provider.of<RefrenPartProvider>(context, listen: false);
    return prov.isRefren(element);
  }

}

/*
String encodeChords(String chords){
  if(chords == null) return '';

  String output = '';
  List<String> chordlines = chords.split("\n");

  for(int i=0; i<chordlines.length; i++){
    bool foundRepetiton = false;
    for(int j=0; j<i; j++)
      if(chordlines[i] == chordlines[j]) {
        output += j.toString() + '\n';
        foundRepetiton = true;
        break;
      }

    if(!foundRepetiton)
      output += chordlines[i] + '\n';
  }

  if(output.length>0)
    output = output.substring(0, output.length - 1);

  return output;
}
*/

/*
String convertToCode(BuildContext context, String fileName) {

  RefrenPartProvider refPartProv = Provider.of<RefrenPartProvider>(context, listen: false);
  RefrenEnabProvider refEnabProv = Provider.of<RefrenEnabProvider>(context, listen: false);
  SongPartsProvider songPartsProv = Provider.of<SongPartsProvider>(context, listen: false);

  HidTitlesProvider hidTitleProv = Provider.of<HidTitlesProvider>(context, listen: false);

  TagsProvider tagsProv = Provider.of<TagsProvider>(context, listen: false);

  Map map = {};
  map['title'] = textCtrlsProv.controllerTitle.text;

  List<String> hidTitles = hidTitleProv.controllers.map((ctrl) => ctrl.text).toList();
  hidTitles.removeWhere((hidTitle) => hidTitle.length==0);
  map['hid_titles'] = hidTitles;
  map['text_author'] = textCtrlsProv.controllerAuthor.text;
  map['performer'] = textCtrlsProv.controllerPerformer.text;
  map['yt_link'] = textCtrlsProv.controllerYT.text;
  map['add_pers'] = textCtrlsProv.controllerAddPers.text;

  List<String> tags = [];
  for(int i=0; i<Tag.ALL_TAG_NAMES.length; i++)
    if(tagsProv.get(i)) tags.add(Tag.ALL_TAG_NAMES[i]);

  map['tags'] = tags;

  if(refEnabProv.refEnab)
    map['refren'] = {
      'text': refPartProv.getText(),
      'chords': refPartProv.chords,
      'shift': true
    };

  List<Map> parts = [];

  int refCount = 0;
  for (SongPart part in songPartsProv.all) {

    if(refCount>0) {
      parts.add({'refren': refCount});
      refCount = 0;
    }

    if (part.isRefren(context)) {
      refCount++;
      continue;

    }else {
      parts.add({
        'text': part.getText(),
        'chords': part.chords,
        'shift': part.shift
      });
    }

  }

  if(refCount>0)
    parts.add({'refren': refCount});

  map['parts'] = parts;

  return jsonEncode({fileName : map});



  /*
  String text = parent.controllerTitle.text + '\n';
  text += '0\n'; // version
  text += parent.controllerAuthor.text + '\n';
  text += parent.controllerPerformer.text + '\n';
  text += '\n'; //moderator
  text += parent.controllerYT.text + '\n'; //youtube link
  String tags = '';
  for(int i=0; i<Tag.ALL_TAG_NAMES.length; i++)
    if(parent.tagsChecked[i]) tags += Tag.ALL_TAG_NAMES[i] + ';';
  if(tags.length >0) tags = tags.substring(0, tags.length-1);
  text += tags + '\n';

  text += '<';
  if (parent.hasRefren) {
    text += (encodeChords(parent.refrenPart.getChords()));
    text += '>' + parent.refrenPart.getText();
  }

  String firstZwrotkaChords;
  for (SongPart parts in parent.parts) {

    String zwrotkaText = parts.getText();
    String zwrotkaChords = parts.getChords();

    if (parts.isRefren) {
      if(parent.hasRefren) text += '<';
    }else {
      if (firstZwrotkaChords != null) {
        if (firstZwrotkaChords == zwrotkaChords) text += '<1';
        else text += '<' + encodeChords(zwrotkaChords);
      } else {
        firstZwrotkaChords = zwrotkaChords;
        text += '<' + encodeChords(zwrotkaChords);
      }

      text += '>' + zwrotkaText;
    }
  }
   */
}
*/

Map convertToCode(SongRaw song) {

  Map map = {};
  map['title'] = song.title;
  map['hid_titles'] = song.hidTitles;
  map['text_author'] = song.author;
  map['performer'] = song.performer;
  map['yt_link'] = song.youtubeLink;
  map['add_pers'] = song.addPers;

  map['tags'] = song.tags;

  if(song.hasRefren)
    map['refren'] = {
      'text': song.refrenPart.getText(),
      'chords': song.refrenPart.chords,
      'shift': true
    };

  List<Map> parts = [];

  int refCount = 0;
  for (SongPart part in song.songParts) {

    if(refCount>0) {
      parts.add({'refren': refCount});
      refCount = 0;
    }

    if (part.element == song.refrenPart?.element) { //part.isRefren
      refCount++;
      continue;

    }else {
      parts.add({
        'text': part.getText(),
        'chords': part.chords,
        'shift': part.shift
      });
    }

  }

  if(refCount>0)
    parts.add({'refren': refCount});

  map['parts'] = parts;

  return map;

}