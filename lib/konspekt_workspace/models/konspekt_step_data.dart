import 'package:flutter/cupertino.dart';
import 'package:harcapp_core/comm_classes/missing_decode_param_error.dart';
import 'package:harcapp_core/harcthought/konspekts/konspekt.dart';
import 'package:harcapp_web/konspekt_workspace/models/konspekt_material_data.dart';

class KonspektStepData extends BaseKonspektStep{

  final TextEditingController titleController;
  Duration duration;
  KonspektStepActiveForm activeForm;
  bool required;
  final TextEditingController contentController;
  final List<TextEditingController> aimControllers;
  final List<KonspektMaterialData>? materials;

  KonspektStepData({
    required this.titleController,
    required this.duration,
    required this.activeForm,
    required this.required,
    required this.contentController,
    required this.aimControllers,
    required this.materials,
  });

  static KonspektStepData empty() => KonspektStepData(
    titleController: TextEditingController(),
    duration: Duration(minutes: 15),
    activeForm: KonspektStepActiveForm.static,
    required: true,
    contentController: TextEditingController(),
    aimControllers: [],
    materials: null
  );

  String get title => titleController.text;
  String get content => contentController.text;
  List<String> get aims => aimControllers.map((controller) => controller.text).toList();

  KonspektStep toKonspektStep() => KonspektStep(
    title: title,
    duration: duration,
    activeForm: activeForm,
    required: required,
    content: content,
    aims: aims,
    materials: materials?.map((materialData) => materialData.toKonspektMaterial()).toList(),
  );


  static KonspektStepData fromJsonMap(Map<String, dynamic> map) => KonspektStepData(
    titleController: TextEditingController(text: map['title']??(throw MissingDecodeParamError('title'))),
    duration: Duration(seconds: map['duration']??(throw MissingDecodeParamError('duration'))),
    activeForm: KonspektStepActiveForm.fromApiParam(map['activeForm'])??(throw MissingDecodeParamError('activeForm')),
    required: map['required']??(throw MissingDecodeParamError('required')),
    contentController: TextEditingController(text: map['content']??(throw MissingDecodeParamError('content'))),
    aimControllers: (map['aims'] as List<dynamic>?)?.map((e) => TextEditingController(text: e as String)).toList()??[],
    materials: (map['materials'] as List<dynamic>?)?.map((e) => KonspektMaterialData.fromJsonMap(e as Map<String, dynamic>)).toList(),
  );

  static KonspektStepData fromKonspektStep(KonspektStep s) => KonspektStepData(
    titleController: TextEditingController(text: s.title),
    duration: s.duration,
    activeForm: s.activeForm,
    required: s.required,
    contentController: TextEditingController(text: s.content ?? ''),
    aimControllers: (s.aims ?? []).map((a) => TextEditingController(text: a)).toList(),
    materials: s.materials?.map((m) => KonspektMaterialData.fromKonspektMaterial(m)).toList(),
  );

}