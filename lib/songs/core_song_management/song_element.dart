
import 'package:harcapp_web/common/core_comm_classes/primitive_wrapper.dart';

class SongElement{
  final PrimitiveWrapper<String> _text;
  final PrimitiveWrapper<String> _chords;
  final PrimitiveWrapper<bool> _shift;

  const SongElement(this._text, this._chords, this._shift);

  static SongElement empty(){
    return SongElement(PrimitiveWrapper(''), PrimitiveWrapper(''), PrimitiveWrapper(false));
  }

  static SongElement from(String text, String chords, bool shift){
    return SongElement(PrimitiveWrapper(text), PrimitiveWrapper(chords), PrimitiveWrapper(shift));
  }

  void setText(String text) => this._text.set(text);

  String getText({bool withTabs: false}){
    if(withTabs)
      return "\t" + _text.get().replaceAll('\n', '\n\t');
    else
      return _text.get();
  }

  set chords(String value) => this._chords.set(value);
  String get chords => _chords.get();

  set shift(bool value) => this._shift.set(value);
  bool get shift => _shift.get();
}