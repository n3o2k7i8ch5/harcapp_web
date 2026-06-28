import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:harcapp_core/comm_classes/missing_decode_param_error.dart';
import 'package:harcapp_core/comm_classes/text_utils.dart';
import 'package:harcapp_core/harcthought/common/file_format.dart';
import 'package:harcapp_core/harcthought/konspekts/konspekt.dart';
import 'package:harcapp_web/konspekt_workspace/models/platform_file_utils.dart';

class KonspektAttachmentData extends BaseKonspektAttachment{
  final TextEditingController nameController;
  final TextEditingController titleController;
  final Map<FileFormat, PlatformFile?> pickedFiles;
  final Map<FileFormat, String?> pickedUrls;

  bool printInfoEnabled;
  KonspektAttachmentPrintSide printSide;
  KonspektAttachmentPrintColor printColor;

  bool autoIdFromTitle;

  String get name => nameController.text;
  String get title => titleController.text;
  Map<FileFormat, String?> get assets => _buildAssetsMap();
  KonspektAttachmentPrint? get print => printInfoEnabled ? KonspektAttachmentPrint(
    side: printSide,
    color: printColor,
  ) : null;

  KonspektAttachmentData({
    required this.nameController,
    required this.titleController,
    required this.pickedFiles,
    required this.pickedUrls,
    required this.printInfoEnabled,
    required this.printSide,
    required this.printColor,
    required this.autoIdFromTitle,
  });

  static KonspektAttachmentData empty() => KonspektAttachmentData(
    nameController: TextEditingController(text: DateTime.now().microsecondsSinceEpoch.toString()),
    titleController: TextEditingController(),
    pickedFiles: {},
    pickedUrls: {},
    printInfoEnabled: false,
    printSide: KonspektAttachmentPrintSide.single,
    printColor: KonspektAttachmentPrintColor.monochrome,
    autoIdFromTitle: true,
  );

  Map toJsonMap() => {
    'name': name,
    'title': title,
    'pickedFiles': pickedFiles.map((key, value) => MapEntry(key.apiParam, value==null?null:platformFileToJsonMap(value))),
    'pickedUrls': pickedUrls.map((key, value) => MapEntry(key.apiParam, value)),
    'printInfoEnabled': printInfoEnabled,
    'printSide': printSide.apiParam,
    'printColor': printColor.apiParam,
    'autoIdFromTitle': autoIdFromTitle,
    // Format compatible with KonspektAttachment.fromJsonMap
    'assets': _buildAssetsJsonMap(),
    'print': print?.toJsonMap(),
  };

  Map<FileFormat, String> _buildAssetsMap() {
    final Map<FileFormat, String> assets = {};
    for (final entry in pickedFiles.entries) {
      if (entry.value != null) {
        assets[entry.key] = entry.value!.name;
      }
    }
    for (final entry in pickedUrls.entries) {
      if (entry.value != null && entry.value!.isNotEmpty) {
        assets[entry.key] = entry.value!;
      }
    }
    return assets;
  }

  Map<String, String> _buildAssetsJsonMap() {
    final Map<String, String> assets = {};
    for (final entry in pickedFiles.entries) {
      if (entry.value != null) {
        assets[entry.key.apiParam] = entry.value!.name;
      }
    }
    for (final entry in pickedUrls.entries) {
      if (entry.value != null && entry.value!.isNotEmpty) {
        assets[entry.key.apiParam] = entry.value!;
      }
    }
    return assets;
  }

  static KonspektAttachmentData fromJsonMap(Map<String, dynamic> map) => KonspektAttachmentData(
    nameController: TextEditingController(text: map['name']),
    titleController: TextEditingController(text: map['title']),
    pickedFiles: (map['pickedFiles'] as Map).map((key, value) => MapEntry(
        FileFormat.fromApiParam(key)??(throw InvalidDecodeParamError('FileFormat', key)),
        value==null?null:platformFileFromJsonMap(value))
    ).cast<FileFormat, PlatformFile?>(),
    pickedUrls: (map['pickedUrls'] as Map).map((key, value) => MapEntry(
        FileFormat.fromApiParam(key)??(throw InvalidDecodeParamError('FileFormat', key)),
        value as String?)
    ).cast<FileFormat, String?>(),
    printInfoEnabled: map['printInfoEnabled'],
    printSide: KonspektAttachmentPrintSide.fromApiParam(map['printSide'])??(throw InvalidDecodeParamError('KonspektAttachmentData.printSide', map['printSide'])),
    printColor: KonspektAttachmentPrintColor.fromApiParam(map['printColor'])??(throw InvalidDecodeParamError('KonspektAttachmentData.printColor', map['printColor'])),
    autoIdFromTitle: (map['autoIdFromTitle'] as bool?) ?? true,
  );

  /// [attachmentFiles] are the raw bytes unpacked from the .hrcpknspkt archive,
  /// keyed `'<attachmentName>.<ext>'` (see [KonspektData.toHrcpknspktData]).
  /// We reconnect each non-URL asset to its bytes so loaded file attachments
  /// keep their file instead of coming back empty.
  static KonspektAttachmentData fromKonspektAttachment(
    KonspektAttachment a, {
    Map<String, Uint8List> attachmentFiles = const {},
  }) {
    final Map<FileFormat, String?> urlAssets = {};
    final Map<FileFormat, PlatformFile?> fileAssets = {};
    for (final entry in a.assets.entries) {
      final FileFormat format = entry.key;
      if (format.isUrl) {
        urlAssets[format] = entry.value;
        continue;
      }
      final Uint8List? bytes = attachmentFiles['${a.name}.${format.extension}'];
      if (bytes == null) continue;
      // Prefer the asset's original filename; fall back to the archive key.
      final String fileName = (entry.value?.isNotEmpty ?? false)
          ? entry.value!
          : '${a.name}.${format.extension}';
      fileAssets[format] = PlatformFile(
        name: fileName,
        size: bytes.length,
        bytes: bytes,
      );
    }

    final String slugFromTitle = simplifyString(a.title);
    final bool autoIdFromTitle = slugFromTitle.isEmpty || a.name == slugFromTitle;

    return KonspektAttachmentData(
      nameController: TextEditingController(text: a.name),
      titleController: TextEditingController(text: a.title),
      pickedFiles: fileAssets,
      pickedUrls: urlAssets,
      printInfoEnabled: a.print != null,
      printSide: a.print?.side ?? KonspektAttachmentPrintSide.single,
      printColor: a.print?.color ?? KonspektAttachmentPrintColor.monochrome,
      autoIdFromTitle: autoIdFromTitle,
    );
  }

  String get displayTitle {
    final title = titleController.text.trim();
    return title.isNotEmpty ? title : 'bez nazwy';
  }

  bool get hasTitle => titleController.text.trim().isNotEmpty;

  static String? findTitleByName(List<KonspektAttachmentData> attachments, String name) {
    if (name.isEmpty) return null;
    for (final att in attachments)
      if (att.name == name)
        return att.displayTitle;

    return name;
  }
}