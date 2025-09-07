import 'package:flutter/cupertino.dart';
import 'package:harcapp_core/comm_classes/common.dart';
import 'package:harcapp_core/comm_classes/meto.dart';
import 'package:harcapp_core/harcthought/konspekts/konspekt.dart';
import 'package:harcapp_core/values/people.dart';
import 'package:harcapp_web/konspekt_workspace/models/konspekt_step_data.dart';

class KonspektData extends BaseKonspekt {
  
  final TextEditingController titleController;
  final List<TextEditingController> additionalSearchPhraseControllers;
  KonspektType type;
  final Map<KonspektSphere, KonspektSphereDetails?> spheres;

  final List<Meto> metos;
  final TextEditingController coverAuthorController;
  final Person? author;
  Duration? customDuration;
  final List<TextEditingController> aimControllers;
  final List<KonspektMaterial>? materials;
  final TextEditingController summaryController;
  final TextEditingController introController;
  final TextEditingController descriptionController;
  final List<TextEditingController> howToFailControllers;

  final List<KonspektStepData> stepsData;

  final List<KonspektAttachment>? attachments;

  //---

  String get name => titleAsFileName;
  String get title => titleController.text;
  List<String> get additionalSearchPhrases => additionalSearchPhraseControllers.map((e) => e.text).toList();
  KonspektCategory get category => KonspektCategory.harcerskie;
  String get coverAuthor => coverAuthorController.text;
  List<String> get aims => aimControllers.map((e) => e.text).toList();
  String get summary => summaryController.text;
  String get intro => introController.text;
  String get description => descriptionController.text;
  List<String> get howToFail => howToFailControllers.map((e) => e.text).toList();

  List<KonspektStep> get steps => stepsData.map((e) => e.toKonspektStep()).toList();

  KonspektData():
    titleController = TextEditingController(),
    additionalSearchPhraseControllers = [],
    type = KonspektType.zajecia,
    spheres = {},
    metos = [],
    coverAuthorController = TextEditingController(),
    author = null,
    customDuration = null,
    aimControllers = [],
    materials = null,
    summaryController = TextEditingController(),
    introController = TextEditingController(),
    descriptionController = TextEditingController(),
    howToFailControllers = [],
    stepsData = [KonspektStepData()],
    attachments = null;

  String get titleAsFileName =>
    remPolChars(titleController.text).trim()
        .replaceAll(":", "_")
        .replaceAll('-', '_')
        .replaceAll('/', '_')
        .replaceAll(' ', '_')
        .replaceAll(RegExp(r"_+"), "_")
        .replaceAll(RegExp(r"[^\w]"), '');

}