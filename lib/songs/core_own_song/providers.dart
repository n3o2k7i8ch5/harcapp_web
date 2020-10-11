
import 'package:flutter/widgets.dart';
import 'package:harcapp_web/common/core_comm_widgets/tag_layout.dart';
import 'package:harcapp_web/songs/core_song_management/song_element.dart';
import 'package:harcapp_web/songs/core_song_management/song_raw.dart';
import 'package:provider/provider.dart';

import '../providers.dart';
import 'common.dart';


class CurrentItemProvider extends ChangeNotifier{

  SongRaw _song;

  CurrentItemProvider({SongRaw song}){
    _song = song;//??SongRaw.empty();
  }

  SongRaw get song => _song;
  set song(SongRaw value){
    _song = value;
    notifyListeners();
  }

  set fileName(String value){
    _song.fileName = value;
    notifyListeners();
  }

  removePart(SongPart part){
    _song.songParts.remove(part);
    notifyListeners();
  }
  addPart(SongPart part){
    _song.songParts.add(part);
    notifyListeners();
  }

}

class HidTitlesProvider extends ChangeNotifier{

  List<TextEditingController> _controllers;
  bool _isLastEmpty;

  HidTitlesProvider({List<String> hidTitles}){
    if(hidTitles == null)
      _controllers = [];
    else
      _controllers = hidTitles.map((hidTitle) => TextEditingController(text: hidTitle)).toList();

    _isLastEmpty = hidTitles==null || (hidTitles.length > 0 && hidTitles.last.length==0);
  }

  void add({String hidTitle, Function() onChanged}){
    TextEditingController controller = TextEditingController(text: hidTitle??'');
    _isLastEmpty = controller.text.length==0;
    controller.addListener(() {
      if(controller == _controllers.last){

        if(controller.text.length==0 && !_isLastEmpty)
          notifyListeners();
        else if(controller.text.length!=0 && _isLastEmpty)
          notifyListeners();

        _isLastEmpty = controller.text.length==0;
      }
    });

    if(onChanged != null)
      controller.addListener(onChanged);

    _controllers.add(controller);

    notifyListeners();
  }

  void remove(TextEditingController controller){
    _controllers.remove(controller);
    notifyListeners();
  }

  List<String> get() => _controllers.map((ctrl) => ctrl.text).toList();

  bool get isLastEmpty => !hasAny?true:_controllers.last.text.length==0;

  bool get hasAny => _controllers.length != 0;

  List<TextEditingController> get controllers => _controllers;

}

class TextShiftProvider extends ChangeNotifier{

  bool _shifted;

  TextShiftProvider({bool shifted}){
    _shifted = shifted;
  }

  bool get shifted => _shifted;
  set shifted(bool value){
    _shifted = value;
    notifyListeners();
  }

  void reverseShift(){
    _shifted = !_shifted;
    notifyListeners();
  }

}

class TextProvider extends ChangeNotifier{

  String _text;

  TextEditingController controller;

  TextProvider({String text: ''}){
    _text = text;
    controller = TextEditingController(text: _text);
  }

  String get text => _text;
  set text(String value){
    _text = value;
    notifyListeners();
  }

}

class ChordsProvider extends ChangeNotifier{

  static isChordMissing(String text, String chords) => text != null && text.length>0 && (chords == null || chords.length==0);

  String _chords;

  TextEditingController chordsController;

  ChordsProvider({String chords: ''}){
    _chords = chords;
    chordsController = TextEditingController(text: chords);
  }

  String get chords => _chords;
  set chords(String value){
    _chords = value;
    notifyListeners();
  }

}

class RefrenEnabProvider extends ChangeNotifier{

  bool _refEnab;

  RefrenEnabProvider(bool refEnab){
    _refEnab = refEnab;
  }

  bool get refEnab => _refEnab;

  set refEnab(bool value){
    _refEnab = value;
    notifyListeners();
  }

}

class RefrenPartProvider extends SongPartProvider{

  RefrenPartProvider(SongPart part):super(part);

  String get chords => part.chords;
  set chords(String value){
    part.chords = value;
    notifyListeners();
  }

  String getText() => part.getText();
  void setText(String text) => part.setText(text);


  bool isRefren(SongElement element) => element == part.element;

  SongElement get element => part.element;
  bool get isError => part.isError;

  void notify() => notifyListeners();

}


class TagsProvider extends ChangeNotifier{
  List<bool> tagsChecked;

  TagsProvider(List<String> allTagNames, List<String> tags){
    tagsChecked = allTagNames.map((t) => tags.contains(t)).toList();
  }

  set(List<String> allTagNames, List<String> tags){
    tagsChecked = allTagNames.map((t) => tags.contains(t)).toList();
    notifyListeners();
  }

  neg(int idx){
    tagsChecked[idx] = !tagsChecked[idx];
    notifyListeners();
  }
  get(int idx) => tagsChecked[idx];

  toList(){

    List<String> list = [];

    for(int i=0; i<tagsChecked.length; i++)
      if(tagsChecked[i]) list.add(Tag.ALL_TAG_NAMES[i]);
  }

  int get count{
    int count = 0;
    for(int i=0; i<tagsChecked.length; i++)
      if(tagsChecked[i]) count++;
    return count;
  }
}

class TitleCtrlProvider extends ChangeNotifier{
  TextEditingController controller;
  TitleCtrlProvider({String text, Function(String text) onChanged}){
    controller = TextEditingController(text: text);
    if(onChanged!=null) controller.addListener(() => onChanged(controller.text));
  }

  set text(String value){
    controller.text = value;
    notifyListeners();
  }

}

class AuthorCtrlProvider extends ChangeNotifier{
  TextEditingController controller;
  AuthorCtrlProvider({String text}){
    controller = TextEditingController(text: text);
  }

  set text(String value){
    controller.text = value;
    notifyListeners();
  }
}

class PerformerCtrlProvider extends ChangeNotifier{
  TextEditingController controller;
  PerformerCtrlProvider({String text}){
    controller = TextEditingController(text: text);
  }

  set text(String value){
    controller.text = value;
    notifyListeners();
  }}

class YTCtrlProvider extends ChangeNotifier{
  TextEditingController controller;
  YTCtrlProvider({String text}){
    controller = TextEditingController(text: text);
  }

  set text(String value){
    controller.text = value;
    notifyListeners();
  }}

class AddPersCtrlProvider extends ChangeNotifier{
  TextEditingController controller;
  AddPersCtrlProvider({String text}){
    controller = TextEditingController(text: text);
  }

  set text(String value){
    controller.text = value;
    notifyListeners();
  }
}


class SongPartProvider extends ChangeNotifier{

  SongPart _part;
  SongPartProvider(this._part);

  set part(SongPart value){
    _part = value;
    notifyListeners();
  }
  SongPart get part => _part;

  void notify() => notifyListeners();

}