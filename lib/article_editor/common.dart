import 'dart:convert';
import 'dart:typed_data';

class Article{
  final Uint8List imageBytes;
  final DateTime dateTime;
  final String title;
  final String intro;
  final List<ArticleElement> items;

  const Article(this.imageBytes, this.dateTime, this.title, this.intro, this.items);

  Object toJson() {

    String imageCode = imageBytes==null?
    null: base64Encode(imageBytes.toList());

    Map<String, Object> map = {
      'image': imageCode,
      'date': dateTime.toIso8601String(),
      'title': title,
      'intro': intro,
      'items': items.map((item) => item.toJson()).toList()
    };

    return map;
  }

  static Article fromJson(String code) {

    Map<String, Object> map = jsonDecode(code);

    final Uint8List imageBytes = map['image']==null?null:base64Decode(map['image']);
    final DateTime dateTime = DateTime.parse(map['date']);
    final String title = map['title'];
    final String intro = map['intro'];
    final List<dynamic> items = map['items'];

    List<ArticleElement> articleElements = items.map((dynamic item) => ArticleElement.decode(item)).toList();

    return Article(imageBytes, dateTime, title, intro, articleElements);

  }

}

abstract class ArticleElement{
  static int ID = 0;

  int _id;

  ArticleElement(){
    _id = ID++;
  }

  Object toJson();

  @override
  int get hashCode => _id.hashCode;

  @override
  bool operator == (other) => other is ArticleElement && other._id == _id;

  static ArticleElement decode(Object object){
    List<String> parts = (object as List<dynamic>).cast<String>().toList();
    if(parts[0]==Paragraph.JSON_NAME)
      return Paragraph(text: parts[1]);
    if(parts[0]==Header.JSON_NAME)
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

  static const String JSON_NAME = 'para';

  @override
  Object toJson(){
    return [
      JSON_NAME,
      text
    ];
  }
}