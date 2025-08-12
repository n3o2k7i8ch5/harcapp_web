import 'package:flutter/cupertino.dart';
import 'package:harcapp_core/harcthought/konspekts/konspekt.dart';

class KonspektStepData{

  final TextEditingController titleController;
  Duration duration;
  KonspektStepActiveForm activeForm;
  bool required;
  final TextEditingController contentController;
  final List<TextEditingController> aims;
  final List<KonspektMaterial>? materials;

  KonspektStepData():
    titleController = TextEditingController(),
    duration = Duration(minutes: 15),
    activeForm = KonspektStepActiveForm.static,
    required = true,
    contentController = TextEditingController(),
    aims = [],
    materials = null;

  String get title => titleController.text;
  String get content => contentController.text;

  Map toJsonMap() => {
    'title': title,
    'duration': duration.inSeconds,
    'activeForm': activeForm.name,
    'required': required,
    'content': content,
    'aims': aims.map((e) => e.text).toList(),
    'materials': materials?.map((e) => e.toJsonMap()).toList(),
  };

}