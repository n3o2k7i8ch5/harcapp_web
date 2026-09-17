import 'package:harcapp_core/comm_classes/text_utils.dart';

class SongElementOld{
  final String _text;
  final String _chords;

  const SongElementOld(this._text, this._chords);

  static SongElementOld decodeOld(String code, {String? firstElementChords}){
    String text, chords;
    List<String> parts = code.split('>');
    text = parts[1];

    if(parts[0] != '1') chords =  _decodeChords(parts[0]);
    else if(firstElementChords != null) chords =  _decodeChords(firstElementChords);
    else throw Exception();

    return SongElementOld(text, chords);
  }

  String getText() => _text;

  String getChords() => _chords;

  static String _decodeChords(String code){
    String output = "";
    List<String> codeLines = code.split("\n");

    for(int i=0; i<codeLines.length; i++) {

      String? firstChar;
      if(codeLines[i].length>0)
        firstChar = codeLines[i].substring(0, 1);
      else
        firstChar = null;

      if (codeLines[i].length > 0 && isDigit(firstChar!))
        output += codeLines[int.parse(codeLines[i])] + "\n";
      else
        output += codeLines[i] + "\n";
    }

    if(output.length > 0)
      output = output.substring(0, output.length - 1); //(0, -1) ?

    return output;
  }
}
