import 'package:flutter/cupertino.dart';
import 'package:harcapp_core/comm_classes/meto.dart';
import 'package:harcapp_core/harcthought/konspekts/konspekt.dart';
import 'package:harcapp_core/values/people.dart';
import 'package:harcapp_web/konspekt_workspace/models/konspekt_step_data.dart';

class KonspektData{
  final TextEditingController titleController;
  final List<TextEditingController> additionalSearchPhrases;
  KonspektType type;
  final Map<KonspektSphere, KonspektSphereDetails?> spheres;

  final List<Meto> metos;
  final TextEditingController coverAuthor;
  final Person? author;
  Duration? customDuration;
  final List<TextEditingController> aims;
  final List<KonspektMaterial>? materials;
  final TextEditingController summaryController;
  final TextEditingController introController;
  final TextEditingController descriptionController;
  final List<TextEditingController> howToFail;
  // If stepGroups is not null, steps will be ignored.
  final List<KonspektStepData> steps;

  final List<KonspektAttachment>? attachments;

  KonspektData():
    titleController = TextEditingController(),
    additionalSearchPhrases = [],
    type = KonspektType.zajecia,
    spheres = {},
    metos = [],
    coverAuthor = TextEditingController(),
    author = null,
    customDuration = null,
    aims = [],
    materials = null,
    summaryController = TextEditingController(),
    introController = TextEditingController(),
    descriptionController = TextEditingController(),
    howToFail = [],
    steps = [KonspektStepData()],
    attachments = null;

  Map toJsonMap() => {
    'title': titleController.text,
    'additionalSearchPhrases': additionalSearchPhrases.map((e) => e.text).toList(),
    'type': type.name,
    'spheres': spheres.map((key, value) => MapEntry(key.name, value?.toJsonMap())),
    'metos': metos.map((e) => e.name).toList(),
    'coverAuthor': coverAuthor.text,
    'author': author?.toJsonMap(),
    'customDuration': customDuration?.inSeconds,
    'aims': aims.map((e) => e.text).toList(),
    'materials': materials?.map((e) => e.toJsonMap()).toList(),
    'summary': summaryController.text,
    'intro': introController.text,
    'description': descriptionController.text,
    'howToFail': howToFail.map((e) => e.text).toList(),
    'steps': steps.map((e) => e.toJsonMap()).toList(),
    'attachments': attachments?.map((e) => e.toJsonMap()).toList(),
  };
}