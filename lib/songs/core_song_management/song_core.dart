abstract class SongCore{

  String get fileName;
  String get title;
  List<String> get hidTitles;
  String get author;
  String get performer;
  String get addPers;
  String get youtubeLink;
  bool get official;

  List<String> get tags;
  bool get hasChords;

  String get text;
  String getChords();
  int get rate;

}