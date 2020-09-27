
import 'package:flutter/widgets.dart';
import 'package:harcapp_web/songs/core_song_management/song_element.dart';

import 'common.dart';

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

  void add({hidTitle}){
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

    _controllers.add(controller);

    notifyListeners();
  }

  void remove(TextEditingController controller){
    _controllers.remove(controller);
    notifyListeners();
  }

  bool get isLastEmpty => _controllers.last.text.length==0;

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

class RefrenPartProvider extends ChangeNotifier{

  SongPart _part;

  RefrenPartProvider(SongPart part){
    _part = part;
  }

  String get chords => _part.chords;
  set chords(String value){
    _part.chords = value;
    notifyListeners();
  }

  String getText() => _part.getText();
  void setText(String text) => _part.setText(text);


  bool isRefren(SongElement element) => element == _part.element;

  SongPart get part => _part;
  SongElement get element => _part.element;
  bool get isError => _part.isError;

  void notify() => notifyListeners();

}

class SongPartsProvider extends ChangeNotifier{

  List<SongPart> _songParts;

  SongPartsProvider(List<SongPart> songParts){
    _songParts = songParts;
  }

  List<SongPart> get all => _songParts;

  void add(SongPart part){
    _songParts.add(part);
    notifyListeners();
  }

  void remove(SongPart part){
    _songParts.remove(part);
    notifyListeners();
  }

}

class TagsProvider extends ChangeNotifier{
  List<bool> tagsChecked;

  TagsProvider(List<String> allTagNames, List<String> tags){
    tagsChecked = allTagNames.map((t) => tags.contains(t)).toList();
  }

  neg(int idx){
    tagsChecked[idx] = !tagsChecked[idx];
    notifyListeners();
  }
  get(int idx) => tagsChecked[idx];

  int get count{
    int count = 0;
    for(int i=0; i<tagsChecked.length; i++)
      if(tagsChecked[i]) count++;
    return count;
  }
}

class TextCtrlsProvider extends ChangeNotifier{

  TextEditingController controllerTitle;
  TextEditingController controllerAuthor;
  TextEditingController controllerPerformer;
  TextEditingController controllerYT;
  TextEditingController controllerAddPers;

  TextCtrlsProvider({
    this.controllerTitle,
    this.controllerAuthor,
    this.controllerPerformer,
    this.controllerYT,
    this.controllerAddPers,
  });

}

class SongPartProvider extends ChangeNotifier{

  SongPart songPart;
  SongPartProvider(this.songPart);

  void notify() => notifyListeners();

}