import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:harcapp_core/comm_classes/meto.dart';
import 'package:harcapp_core/comm_classes/text_utils.dart';
import 'package:harcapp_core/harcthought/konspekts/hrcpknspkt_data.dart';
import 'package:harcapp_core/harcthought/konspekts/konspekt.dart';
import 'package:harcapp_core/values/people/person.dart';
import 'package:harcapp_web/konspekt_workspace/models/konspekt_step_data.dart';
import 'package:harcapp_web/konspekt_workspace/models/konspekt_material_data.dart';

import 'konspekt_attachment_data.dart';

Map<String, dynamic> _deepCastMap(Map map) {
  return map.map((key, value) {
    if (value is Map) {
      return MapEntry(key.toString(), _deepCastMap(value));
    } else if (value is List) {
      return MapEntry(key.toString(), _deepCastList(value));
    } else {
      return MapEntry(key.toString(), value);
    }
  });
}

List<dynamic> _deepCastList(List list) {
  return list.map((item) {
    if (item is Map) {
      return _deepCastMap(item);
    } else if (item is List) {
      return _deepCastList(item);
    } else {
      return item;
    }
  }).toList();
}


class KonspektData extends BaseKonspekt {
  
  final TextEditingController titleController;
  final List<TextEditingController> additionalSearchPhraseControllers;
  KonspektCategory category;
  KonspektType type;
  final Map<KonspektSphere, KonspektSphereDetails?> spheres;

  final List<Meto> metos;
  final TextEditingController coverAuthorController;
  Uint8List? coverImageBytes;
  Person? author;
  Duration? customDuration;
  final List<TextEditingController> aimControllers;
  final List<KonspektAttachmentData> attachments;
  final List<KonspektMaterialData> materials;
  final TextEditingController summaryController;
  final TextEditingController introController;
  final TextEditingController descriptionController;
  final List<TextEditingController> howToFailControllers;

  final List<KonspektStepData> stepsData;

  //---

  String get name => titleAsFileName;
  String get title => titleController.text;
  List<String> get additionalSearchPhrases => additionalSearchPhraseControllers.map((e) => e.text).toList();
  String get coverAuthor => coverAuthorController.text;
  List<String> get aims => aimControllers.map((e) => e.text).toList();
  String get summary => summaryController.text;
  String get intro => introController.text;
  String get description => descriptionController.text;
  List<String> get howToFail => howToFailControllers.map((e) => e.text).toList();

  List<KonspektStep> get steps => stepsData.map((e) => e.toKonspektStep()).toList();

  KonspektData({
    required this.titleController,
    required this.additionalSearchPhraseControllers,
    required this.category,
    required this.type,
    required this.spheres,
    required this.metos,
    required this.coverAuthorController,
    required this.coverImageBytes,
    required this.author,
    required this.customDuration,
    required this.aimControllers,
    required this.materials,
    required this.summaryController,
    required this.introController,
    required this.descriptionController,
    required this.howToFailControllers,
    required this.stepsData,
    required this.attachments
  });

  static KonspektData empty() => KonspektData(
    titleController: TextEditingController(),
    additionalSearchPhraseControllers: [],
    category: KonspektCategory.harcerskie,
    type: KonspektType.zajecia,
    spheres: {},
    metos: [],
    coverAuthorController: TextEditingController(),
    coverImageBytes: null,
    author: null,
    customDuration: null,
    aimControllers: [],
    materials: [],
    summaryController: TextEditingController(),
    introController: TextEditingController(),
    descriptionController: TextEditingController(),
    howToFailControllers: [],
    stepsData: [KonspektStepData.empty()],
    attachments: []
  );

  String get titleAsFileName {
    final simplified = simplifyString(titleController.text);
    return simplified.isEmpty ? 'bez_nazwy' : simplified;
  }

  @override
  Map toJsonMap() {
    final map = super.toJsonMap();
    // Override spheres serialization - BaseKonspekt doesn't see our field
    map['spheres'] = {
      for (final entry in spheres.entries)
        if (entry.value != null)
          entry.key.name: entry.value!.toJsonMap(),
    };
    map['attachments'] =
        attachments.map((attachment) => attachment.toJsonMap()).toList();
    return map;
  }

  HrcpknspktData toHrcpknspktData() {
    final Map<String, Uint8List> attachmentFilesMap = {};
    for (final att in attachments) {
      for (final entry in att.pickedFiles.entries) {
        if (entry.value?.bytes != null) {
          attachmentFilesMap['${att.name}.${entry.key.extension}'] = entry.value!.bytes!;
        }
      }
    }
    return HrcpknspktData(
      coverImage: coverImageBytes,
      attachmentFiles: attachmentFilesMap,
      konspektCore: Konspekt.fromJsonMap(_deepCastMap(toJsonMap())),
    );
  }

  static KonspektData fromHrcpknspktData(HrcpknspktData data){
    final k = data.konspektCore;

    return KonspektData(
      titleController: TextEditingController(text: k.title),
      additionalSearchPhraseControllers: k.additionalSearchPhrases
          .map((phrase) => TextEditingController(text: phrase)).toList(),
      category: k.category,
      type: k.type,
      spheres: k.spheres,
      metos: k.metos,
      coverAuthorController: TextEditingController(text: k.coverAuthor),
      coverImageBytes: data.coverImage,
      author: k.author,
      customDuration: k.customDuration,
      aimControllers: k.aims
          .map((aim) => TextEditingController(text: aim)).toList(),
      materials: k.materials
          ?.map((m) => KonspektMaterialData.fromKonspektMaterial(m)).toList() ?? [],
      summaryController: TextEditingController(text: k.summary),
      introController: TextEditingController(text: k.intro),
      descriptionController: TextEditingController(text: k.description),
      howToFailControllers: (k.howToFail ?? [])
          .map((h) => TextEditingController(text: h)).toList(),
      stepsData: k.steps
          .map((s) => KonspektStepData.fromKonspektStep(s)).toList(),
      attachments: k.attachments
          ?.map((a) => KonspektAttachmentData.fromKonspektAttachment(a)).toList() ?? [],
    );
  }

}