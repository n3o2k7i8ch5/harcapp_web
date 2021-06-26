
import 'dart:convert';
import 'dart:typed_data';

class Author{
  final Uint8List? imageBytes;
  final String? name;
  final String? desc;

  const Author(this.imageBytes, this.name, this.desc);

  Object toJson() {

    String? imageCode = imageBytes==null?
    null: base64Encode(imageBytes!.toList());

    Map<String, Object?> map = {
      'image': imageCode,
      'name': name,
      'desc': desc,
    };

    return map;
  }

  static Author fromJson(String code) {

    Map<String, Object> map = jsonDecode(code);

    final Uint8List? imageBytes = map['image']==null?null:base64Decode(map['image'] as String);
    final String? name = map['name'] as String?;
    final String? desc = map['desc'] as String?;

    return Author(imageBytes, name, desc);

  }

}