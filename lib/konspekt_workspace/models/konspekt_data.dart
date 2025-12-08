import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:harcapp_core/comm_classes/meto.dart';
import 'package:harcapp_core/comm_classes/missing_decode_param_error.dart';
import 'package:harcapp_core/comm_classes/text_utils.dart';
import 'package:harcapp_core/harcthought/common/file_format.dart';
import 'package:harcapp_core/harcthought/konspekts/hrcpknspkt_data.dart';
import 'package:harcapp_core/harcthought/konspekts/konspekt.dart';
import 'package:harcapp_core/values/people/person.dart';
import 'package:harcapp_web/konspekt_workspace/models/konspekt_step_data.dart';
import 'package:harcapp_web/konspekt_workspace/models/konspekt_material_data.dart';
import 'package:harcapp_web/konspekt_workspace/models/platform_file_utils.dart';

class KonspektAttachmentData{
  final String name;
  final TextEditingController titleController;
  TextEditingController? idController;
  final Map<FileFormat, PlatformFile?> pickedFiles;
  final Map<FileFormat, String?> pickedUrls;

  bool printInfoEnabled;
  KonspektAttachmentPrintSide printSide;
  KonspektAttachmentPrintColor printColor;

  bool autoIdFromTitle;

  KonspektAttachmentData({
    required this.name,
    required this.titleController,
    required this.idController,
    required this.pickedFiles,
    required this.pickedUrls,
    required this.printInfoEnabled,
    required this.printSide,
    required this.printColor,
    required this.autoIdFromTitle,
  });

  static KonspektAttachmentData empty() => KonspektAttachmentData(
    name: DateTime.now().microsecondsSinceEpoch.toString(),
    titleController: TextEditingController(),
    idController: TextEditingController(),
    pickedFiles: {},
    pickedUrls: {},
    printInfoEnabled: false,
    printSide: KonspektAttachmentPrintSide.single,
    printColor: KonspektAttachmentPrintColor.monochrome,
    autoIdFromTitle: true,
  );

  AttachmentData toAttachmentData() {

    Map<FileFormat, String?> _urlData = Map.of(pickedUrls);
    _urlData.removeWhere((fileFormat, url) => url == null);
    Map<FileFormat, String> urlData = _urlData.cast<FileFormat, String>();

    Map<FileFormat, Uint8List> fileData = {};
    for(MapEntry<FileFormat, PlatformFile?> entry in pickedFiles.entries)
      if(entry.value?.bytes != null)
        fileData[entry.key] = entry.value!.bytes!;

    // Id załącznika – jeśli wpisane, używamy go, w przeciwnym razie generujemy ze slugowanej nazwy
    final TextEditingController effectiveIdController =
        idController ??= TextEditingController();

    final String effectiveId = effectiveIdController.text.trim().isNotEmpty
        ? effectiveIdController.text.trim()
        : simplifyString(titleController.text).isNotEmpty
            ? simplifyString(titleController.text)
            : name;

    return AttachmentData(
      name: effectiveId,
      title: titleController.text,
      fileData: fileData,
      urlData: urlData,
      printInfoEnabled: printInfoEnabled,
      printSide: printSide,
      printColor: printColor,
    );
  }

  Map toJsonMap() => {
    'name': name,
    'id': idController?.text ?? '',
    'title': titleController.text,
    'pickedFiles': pickedFiles.map((key, value) => MapEntry(key.apiParam, value==null?null:platformFileToJsonMap(value))),
    'pickedUrls': pickedUrls.map((key, value) => MapEntry(key.apiParam, value)),
    'printInfoEnabled': printInfoEnabled,
    'printSide': printSide.apiParam,
    'printColor': printColor.apiParam,
    'autoIdFromTitle': autoIdFromTitle,
  };

  static KonspektAttachmentData fromJsonMap(Map<String, dynamic> map) => KonspektAttachmentData(
      name: map['name'],
      titleController: TextEditingController(text: map['title']),
      idController: TextEditingController(text: (map['id'] ?? map['name']) as String),
      pickedFiles: map['pickedFiles'].map((key, value) => MapEntry(
          FileFormat.fromApiParam(key)??(throw InvalidDecodeParamError('FileFormat', key)),
          value==null?null:platformFileFromJsonMap(value))
      ).cast<FileFormat, PlatformFile?>(),
      pickedUrls: map['pickedUrls'].cast<FileFormat, String?>(),
      printInfoEnabled: map['printInfoEnabled'],
      printSide: KonspektAttachmentPrintSide.fromApiParam(map['printSide'])??(throw InvalidDecodeParamError('KonspektAttachmentData.printSide', map['printSide'])),
      printColor: KonspektAttachmentPrintColor.fromApiParam(map['printColor'])??(throw InvalidDecodeParamError('KonspektAttachmentData.printColor', map['printColor'])),
      autoIdFromTitle: (map['autoIdFromTitle'] as bool?) ?? true,
  );

}

class KonspektData extends BaseKonspekt {
  
  final TextEditingController titleController;
  final List<TextEditingController> additionalSearchPhraseControllers;
  KonspektType type;
  final Map<KonspektSphere, KonspektSphereDetails?> spheres;

  final List<Meto> metos;
  final TextEditingController coverAuthorController;
  Uint8List? coverImageBytes;
  final Person? author;
  Duration? customDuration;
  final List<TextEditingController> aimControllers;
  final List<KonspektMaterialData> materials;
  final TextEditingController summaryController;
  final TextEditingController introController;
  final TextEditingController descriptionController;
  final List<TextEditingController> howToFailControllers;

  final List<KonspektStepData> stepsData;

  final List<KonspektAttachmentData> attachments;

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

  KonspektData({
    required this.titleController,
    required this.additionalSearchPhraseControllers,
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
    map['attachments'] =
        attachments.map((attachment) => attachment.toJsonMap()).toList();
    return map;
  }

  HrcpknspktData toHrcpknspktData() => HrcpknspktData(
      coverImage: coverImageBytes,
      attachments: attachments.map((attachment) => attachment.toAttachmentData()).toList(),
      konspektCoreData: jsonEncode(toJsonMap())
  );

  static KonspektData fromHrcpknspktData(HrcpknspktData data){

    Map coreData = jsonDecode(data.konspektCoreData);

    TextEditingController titleController = TextEditingController(
        text: coreData['title']??(throw MissingDecodeParamError('title'))
    );

    List<TextEditingController> additionalSearchPhraseControllers = (coreData["additionalSearchPhrases"]??(throw MissingDecodeParamError('additionalSearchPhrases')))
        .map((phrase) => TextEditingController(text: phrase)).toList().cast<TextEditingController>();

    KonspektType type = KonspektType.fromApiParam(coreData['type'])??(throw MissingDecodeParamError('type'));

    Map<KonspektSphere, KonspektSphereDetails?> spheres = (coreData['spheres']??(throw MissingDecodeParamError('spheres')))
        .map((key, value) => MapEntry(
          KonspektSphere.fromApiParam(key)??(throw InvalidDecodeParamError('KonspektSphere', key)),
          value == null ? null : KonspektSphereDetails.fromJsonMap((value as Map).cast<String, dynamic>())
        )).cast<KonspektSphere, KonspektSphereDetails?>();

    List<Meto> metos = (coreData['metos']??(throw MissingDecodeParamError('metos')))
        .map((e) => Meto.fromApiParam(e)).toList().cast<Meto>();

    TextEditingController coverAuthorController = TextEditingController(
        text: coreData['coverAuthor']??(throw MissingDecodeParamError('coverAuthor'))
    );

    Person? author = coreData['author'] == null ? null : Person.fromApiJsonMap((coreData['author'] as Map).cast<String, dynamic>());

    Duration? customDuration = coreData['customDuration'] == null ? null : Duration(seconds: coreData['customDuration'] as int);

    List<TextEditingController> aimControllers = (coreData['aims']??(throw MissingDecodeParamError('aims')))
        .map((aim) => TextEditingController(text: aim)).toList().cast<TextEditingController>();

    List<KonspektMaterialData> materials = (coreData['materials']??(throw MissingDecodeParamError('materials')))
        .map((material) => KonspektMaterialData.fromJsonMap((material as Map).cast<String, dynamic>())).toList().cast<KonspektMaterialData>();

    TextEditingController summaryController = TextEditingController(text: coreData['summary']);

    TextEditingController introController = TextEditingController(text: coreData['intro']);

    TextEditingController descriptionController = TextEditingController(text: coreData['description']);

    List<TextEditingController> howToFailControllers = (coreData['howToFail']??(throw MissingDecodeParamError('howToFail')))
        .map((howToFail) => TextEditingController(text: howToFail)).toList().cast<TextEditingController>();

    List<KonspektStepData> stepsData = (coreData['steps']??(throw MissingDecodeParamError('steps')))
        .map((step) => KonspektStepData.fromJsonMap((step as Map).cast<String, dynamic>())).toList().cast<KonspektStepData>();

    List<KonspektAttachmentData> attachments = (coreData['attachments']??[])
        .map((attachment) => KonspektAttachmentData.fromJsonMap((attachment as Map).cast<String, dynamic>())).toList().cast<KonspektAttachmentData>();

    return KonspektData(
      titleController: titleController,
      additionalSearchPhraseControllers: additionalSearchPhraseControllers,
      type: type,
      spheres: spheres,
      metos: metos,
      coverAuthorController: coverAuthorController,
      coverImageBytes: data.coverImage,
      author: author,
      customDuration: customDuration,
      aimControllers: aimControllers,
      materials: materials,
      summaryController: summaryController,
      introController: introController,
      descriptionController: descriptionController,
      howToFailControllers: howToFailControllers,
      stepsData: stepsData,
      attachments: attachments,
    );

  }

}