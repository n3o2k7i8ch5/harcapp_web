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

}