import 'dart:convert';
import 'dart:typed_data';

class Article{
  final Uint8List? imageBytes;
  final String? imageSource;
  final String? authCode;
  final DateTime? date;
  final String? title;
  final String? intro;
  final List<ArticleElement?>? items;
  final List<String> otherArts;

  const Article(this.imageBytes, this.imageSource, this.authCode, this.date, this.title, this.intro, this.items, this.otherArts);

  static const String PARAM_IMAGE = 'image';
  static const String PARAM_IMAGE_SOURCE = 'image_source';
  static const String PARAM_AUTH_CODE = 'auth_code';
  static const String PARAM_DATE = 'date';

  static const String PARAM_TITLE = 'title';
  static const String PARAM_INTRO = 'intro';

  static const String PARAM_ITEMS = 'items';
  static const String PARAM_OTHER_ART_NAMES = 'other_art_names';


  Object toJson() {

    String? imageCode = imageBytes==null?
    null: base64Encode(imageBytes!.toList());

    List<ArticleElement?> notEmptyItems = [];
    for(ArticleElement? item in items!)
      if(!item!.isEmpty)
        notEmptyItems.add(item);


    Map<String, Object?> map = {
      PARAM_IMAGE: imageCode,
      PARAM_IMAGE_SOURCE: imageSource,
      PARAM_AUTH_CODE: authCode,
      PARAM_DATE: date!.toIso8601String(),
      PARAM_TITLE: title,
      PARAM_INTRO: intro,
      PARAM_ITEMS: notEmptyItems.map((item) => item!.toJson()).toList(),
      PARAM_OTHER_ART_NAMES: otherArts
    };

    return map;
  }

  static Article fromJson(String code) {

    Map<String, Object> map = jsonDecode(code);

    final Uint8List? imageBytes = map[PARAM_IMAGE]==null?null:base64Decode(map[PARAM_IMAGE] as String);
    final String? imageSource = map[PARAM_IMAGE_SOURCE] as String?;
    final String? authCode = map[PARAM_AUTH_CODE] as String?;
    final DateTime dateTime = DateTime.parse(map[PARAM_DATE] as String);
    final String? title = map[PARAM_TITLE] as String?;
    final String? intro = map[PARAM_INTRO] as String?;
    final List<dynamic> _items = (map[PARAM_ITEMS] as List<dynamic>?)??[];
    final List<dynamic> /*String*/ _otherArts = (map[PARAM_OTHER_ART_NAMES] as List<dynamic>?)??[];

    List<ArticleElement?> articleElements = _items.map((dynamic item) => ArticleElement.decode(item)).toList();

    List<String> otherArts = _otherArts.cast<String>();

    return Article(
        imageBytes,
        imageSource,
        authCode, dateTime, title, intro, articleElements, otherArts);

  }

}

abstract class ArticleElement{
  static int ID = 0;

  int? _id;

  ArticleElement(){
    _id = ID++;
  }

  Object toJson();

  bool get isEmpty;

  @override
  int get hashCode => _id.hashCode;

  @override
  bool operator == (other) => other is ArticleElement && other._id == _id;

  static ArticleElement? decode(Object object){
    List<String> parts = (object as List<dynamic>).cast<String>().toList();
    if(parts[0] == Paragraph.JSON_NAME)
      return Paragraph(text: parts[1]);
    if(parts[0] == Header.JSON_NAME)
      return Header(text: parts[1]);
    else
      return null;
  }

}

class Header extends ArticleElement{

  String text;

  Header({this.text:''}):super();

  static const String JSON_NAME = 'head';

  @override
  bool get isEmpty => text==null || text.length==0;

  @override
  Object toJson(){
    return [
      JSON_NAME,
      text
    ];
  }

}

class Paragraph extends ArticleElement{

  String text;

  Paragraph({this.text:''}):super();

  @override
  bool get isEmpty => text==null || text.length==0;

  static const String JSON_NAME = 'para';

  @override
  Object toJson(){
    return [
      JSON_NAME,
      text
    ];
  }
}

String remPolChars(String string){
  return string.toLowerCase()
      .replaceAll('ą', 'a')
      .replaceAll('á', 'a')
      .replaceAll('ć', 'c')
      .replaceAll('ę', 'e')
      .replaceAll('é', 'e')
      .replaceAll('í', 'i')
      .replaceAll('ł', 'l')
      .replaceAll('ń', 'n')
      .replaceAll('ó', 'o')
      .replaceAll('ö', 'o')
      .replaceAll('ő', 'o')
      .replaceAll('ś', 's')
      .replaceAll('ú', 'u')
      .replaceAll('ü', 'u')
      .replaceAll('ű', 'u')
      .replaceAll('ź', 'z')
      .replaceAll('ż', 'z');
}

String remSpecChars(String string){
  return string.toLowerCase()
      .replaceAll('.', '')
      .replaceAll(',', '')
      .replaceAll('?', '')
      .replaceAll('!', '')
      .replaceAll('(', '')
      .replaceAll(')', '')
      .replaceAll(':', '')
      .replaceAll(';', '')
      .replaceAll('"', '');
}