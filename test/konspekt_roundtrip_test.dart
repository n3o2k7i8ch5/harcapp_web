import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harcapp_core/comm_classes/meto.dart';
import 'package:harcapp_core/comm_classes/text_utils.dart';
import 'package:harcapp_core/harcthought/common/file_format.dart';
import 'package:harcapp_core/harcthought/konspekts/hrcpknspkt_data.dart';
import 'package:harcapp_core/harcthought/konspekts/konspekt.dart';
import 'package:harcapp_core/values/people/person.dart';
import 'package:harcapp_web/konspekt_workspace/models/konspekt_data.dart';
import 'package:harcapp_web/konspekt_workspace/models/konspekt_material_data.dart';
import 'package:harcapp_web/konspekt_workspace/models/konspekt_step_data.dart';

const _exampleFilesDir = 'test/example_files';

File _exampleFile(String name) => File('$_exampleFilesDir/$name');

KonspektData _buildBaseKonspekt({
  required Map<KonspektSphere, KonspektSphereDetails?> spheres,
}) {
  final KonspektMaterialData material = KonspektMaterialData(
    nameController: TextEditingController(text: 'Materiał'),
    commentController: TextEditingController(text: 'Komentarz'),
    additionalPreparationController: TextEditingController(text: 'Przygotowanie'),
    attachmentNameController: TextEditingController(text: 'zalacznik'),
    amountController: TextEditingController(text: '1'),
    amountAttendantFactorController: TextEditingController(text: '0'),
  );

  final KonspektStepData step = KonspektStepData(
    titleController: TextEditingController(text: 'Krok'),
    duration: const Duration(minutes: 10),
    activeForm: KonspektStepActiveForm.static,
    required: true,
    contentController: TextEditingController(text: 'Opis kroku'),
    aimControllers: [
      TextEditingController(text: 'Cel'),
    ],
    materials: [material],
  );

  final KonspektAttachmentData attachment = KonspektAttachmentData(
    name: 'zalacznik',
    titleController: TextEditingController(text: 'Załącznik'),
    idController: TextEditingController(text: 'zalacznik_id'),
    pickedFiles: const {},
    pickedUrls: const {},
    printInfoEnabled: false,
    printSide: KonspektAttachmentPrintSide.single,
    printColor: KonspektAttachmentPrintColor.monochrome,
    autoIdFromTitle: true,
  );

  return KonspektData(
    titleController: TextEditingController(text: 'Tytuł'),
    additionalSearchPhraseControllers: [
      TextEditingController(text: 'fraza'),
    ],
    category: KonspektCategory.harcerskie,
    type: KonspektType.zajecia,
    spheres: spheres,
    metos: Meto.values.isNotEmpty ? [Meto.values.first] : [],
    coverAuthorController: TextEditingController(text: 'Autor'),
    coverImageBytes: Uint8List.fromList([1, 2, 3, 4]),
    author: null,
    customDuration: const Duration(minutes: 30),
    aimControllers: [
      TextEditingController(text: 'Cel główny'),
    ],
    materials: [material],
    summaryController: TextEditingController(text: 'Podsumowanie'),
    introController: TextEditingController(text: 'Wstęp'),
    descriptionController: TextEditingController(text: 'Opis'),
    howToFailControllers: [
      TextEditingController(text: 'Jak nie robić'),
    ],
    stepsData: [step],
    attachments: [attachment],
  );
}

Map<String, Map<KonspektSphere, KonspektSphereDetails?>> _buildSphereVariants() => {
  'no_spheres': {
    KonspektSphere.cialo: null,
    KonspektSphere.umysl: null,
    KonspektSphere.duch: null,
    KonspektSphere.emocje: null,
    KonspektSphere.relacje: null,
  },
  'cialo_other_only': {
    KonspektSphere.cialo: KonspektSphereDetails(
      levels: {
        KonspektSphereLevel.other: KonspektSphereFields(
          fields: {
            'Bieganie': null,
          },
        ),
      },
    ),
    KonspektSphere.umysl: null,
    KonspektSphere.duch: null,
    KonspektSphere.emocje: null,
    KonspektSphere.relacje: null,
  },
  'duch_postawy_only': {
    KonspektSphere.cialo: null,
    KonspektSphere.umysl: null,
    KonspektSphere.duch: KonspektSphereDetails(
      levels: {
        KonspektSphereLevel.duchPostawy: KonspektSphereFields(
          fields: {
            'Odwaga': null,
          },
        ),
      },
    ),
    KonspektSphere.emocje: null,
    KonspektSphere.relacje: null,
  },
  'duch_wartosci_only': {
    KonspektSphere.cialo: null,
    KonspektSphere.umysl: null,
    KonspektSphere.duch: KonspektSphereDetails(
      levels: {
        KonspektSphereLevel.duchWartosci: KonspektSphereFields(
          fields: {
            'Służba': null,
          },
        ),
      },
    ),
    KonspektSphere.emocje: null,
    KonspektSphere.relacje: null,
  },
  'duch_postawy_and_wartosci': {
    KonspektSphere.cialo: null,
    KonspektSphere.umysl: null,
    KonspektSphere.duch: KonspektSphereDetails(
      levels: {
        KonspektSphereLevel.duchPostawy: KonspektSphereFields(
          fields: {
            'Odwaga': null,
            'Odpowiedzialność': null,
          },
        ),
        KonspektSphereLevel.duchWartosci: KonspektSphereFields(
          fields: {
            'Służba': null,
          },
        ),
      },
    ),
    KonspektSphere.emocje: null,
    KonspektSphere.relacje: null,
  },
};

KonspektData _roundtrip(KonspektData original) {
  final HrcpknspktData hrcp1 = HrcpknspktData(
    coverImage: original.coverImageBytes,
    attachments: const [],
    konspektCoreData: jsonEncode(original.toJsonMap()),
  );
  final Uint8List bytes = hrcp1.toBytes();
  final HrcpknspktData hrcp2 = HrcpknspktData.fromBytes(bytes);
  return KonspektData.fromHrcpknspktData(hrcp2);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('KonspektData spheres roundtrip for multiple variants', () {
    final baseSpheres = _buildSphereVariants();

    baseSpheres.forEach((name, spheres) {
      final original = _buildBaseKonspekt(spheres: spheres);
      final restored = _roundtrip(original);

      expect(restored.spheres.keys.toSet(), original.spheres.keys.toSet(), reason: name);

      for (final sphere in original.spheres.keys) {
        final originalDetails = original.spheres[sphere];
        final restoredDetails = restored.spheres[sphere];

        if (originalDetails == null) {
          expect(restoredDetails, isNull, reason: name);
        } else {
          expect(restoredDetails, isNotNull, reason: name);
          expect(restoredDetails!.levels.keys.toSet(), originalDetails.levels.keys.toSet(), reason: name);

          for (final level in originalDetails.levels.keys) {
            final originalFields = originalDetails.levels[level]!.fields.keys.toSet();
            final restoredFields = restoredDetails.levels[level]!.fields.keys.toSet();
            expect(restoredFields, originalFields, reason: '$name/$level');
          }
        }
      }
    });
  });

  test('KonspektData -> HrcpknspktData -> bytes -> HrcpknspktData -> KonspektData roundtrip preserves data', () {
    // Przygotowanie przykładowych danych wejściowych – możliwie pełnych.

    final KonspektMaterialData material1 = KonspektMaterialData(
      nameController: TextEditingController(text: 'Świeczka'),
      commentController: TextEditingController(text: 'Uważać na ogień'),
      additionalPreparationController: TextEditingController(text: 'Kupić dzień wcześniej'),
      attachmentNameController: TextEditingController(text: 'zalacznik_swieczka'),
      amountController: TextEditingController(text: '10'),
      amountAttendantFactorController: TextEditingController(text: '2'),
    );

    final KonspektMaterialData material2 = KonspektMaterialData(
      nameController: TextEditingController(text: 'Mapa terenu'),
      commentController: TextEditingController(text: 'Aktualna wersja'),
      additionalPreparationController: TextEditingController(text: 'Wydrukować w kolorze'),
      attachmentNameController: TextEditingController(text: 'zalacznik_mapa'),
      amountController: TextEditingController(text: '1'),
      amountAttendantFactorController: TextEditingController(text: '0'),
    );

    final KonspektStepData step1 = KonspektStepData(
      titleController: TextEditingController(text: 'Zbiórka i wprowadzenie'),
      duration: const Duration(minutes: 20),
      activeForm: KonspektStepActiveForm.static,
      required: true,
      contentController: TextEditingController(text: 'Powitanie, sprawdzenie obecności, przedstawienie celu zajęć.'),
      aimControllers: [
        TextEditingController(text: 'Zintegrowanie zastępu'),
        TextEditingController(text: 'Przedstawienie ramówki spotkania'),
      ],
      materials: [material1],
    );

    final KonspektStepData step2 = KonspektStepData(
      titleController: TextEditingController(text: 'Gra terenowa'),
      duration: const Duration(minutes: 60),
      activeForm: KonspektStepActiveForm.active,
      required: true,
      contentController: TextEditingController(text: 'Gra w terenie z podziałem na patrole i punktami zadaniowymi.'),
      aimControllers: [
        TextEditingController(text: 'Rozwijanie współpracy w patrolu'),
        TextEditingController(text: 'Ćwiczenie orientacji w terenie'),
      ],
      materials: [material2],
    );

    final KonspektAttachmentData attachment1 = KonspektAttachmentData(
      name: 'zalacznik_swieczka',
      titleController: TextEditingController(text: 'Instrukcja bezpieczeństwa przy ogniu'),
      idController: TextEditingController(text: 'instr_bezpieczenstwo_ogien'),
      pickedFiles: const {},
      pickedUrls: const {},
      printInfoEnabled: true,
      printSide: KonspektAttachmentPrintSide.single,
      printColor: KonspektAttachmentPrintColor.monochrome,
      autoIdFromTitle: false,
    );

    final KonspektAttachmentData attachment2 = KonspektAttachmentData(
      name: 'zalacznik_mapa',
      titleController: TextEditingController(text: 'Mapa terenu gry'),
      idController: TextEditingController(text: 'mapa_gry'),
      pickedFiles: const {},
      pickedUrls: const {},
      printInfoEnabled: false,
      printSide: KonspektAttachmentPrintSide.double,
      printColor: KonspektAttachmentPrintColor.color,
      autoIdFromTitle: true,
    );

    final KonspektSphereDetails cialoDetails = KonspektSphereDetails(
      levels: {
        KonspektSphereLevel.other: KonspektSphereFields(
          fields: {
            'Bieganie': null,
            'Skakanie przez przeszkody': null,
          },
        ),
      },
    );

    final KonspektSphereDetails duchDetails = KonspektSphereDetails(
      levels: {
        KonspektSphereLevel.duchPostawy: KonspektSphereFields(
          fields: {
            'Odwaga': null,
            'Odpowiedzialność': null,
          },
        ),
        KonspektSphereLevel.duchWartosci: KonspektSphereFields(
          fields: {
            'Służba': null,
          },
        ),
      },
    );

    const Person author = Person(
      name: 'phm. Jan Harcerz',
      email: ['jan.harcerz@example.com'],
    );

    final KonspektData original = KonspektData(
      titleController: TextEditingController(text: 'Wyprawa na skraj lasu'),
      additionalSearchPhraseControllers: [
        TextEditingController(text: 'gra terenowa'),
        TextEditingController(text: 'integracja zastępu'),
      ],
      category: KonspektCategory.harcerskie,
      type: KonspektType.zajecia,
      spheres: {
        KonspektSphere.cialo: cialoDetails,
        KonspektSphere.umysl: null,
        KonspektSphere.duch: duchDetails,
        KonspektSphere.emocje: null,
        KonspektSphere.relacje: null,
      },
      // Używamy dwóch przykładowych wartości z Meto.values, żeby nie polegać na konkretnych nazwach.
      metos: Meto.values.length >= 2
          ? [Meto.values.first, Meto.values.last]
          : Meto.values.toList(),
      coverAuthorController: TextEditingController(text: 'phm. Jan Harcerz'),
      coverImageBytes: Uint8List.fromList(List<int>.generate(16, (i) => i)),
      // author może być null – unikamy zależności od konkretnego API konstruktora Person.
      author: author,
      customDuration: const Duration(minutes: 90),
      aimControllers: [
        TextEditingController(text: 'Rozwijanie współpracy w grupie'),
        TextEditingController(text: 'Nauka orientacji w terenie'),
      ],
      materials: [material1, material2],
      summaryController: TextEditingController(text: 'Krótka gra terenowa z elementami współpracy i orientacji.'),
      introController: TextEditingController(text: 'Wprowadzenie do tematu przygody w lesie.'),
      descriptionController: TextEditingController(text: 'Szczegółowy opis przebiegu zajęć, przygotowania oraz metodyki.'),
      howToFailControllers: [
        TextEditingController(text: 'Brak przygotowania materiałów przed zbiórką'),
        TextEditingController(text: 'Nieprzekazanie zasad bezpieczeństwa przed wyjściem w teren'),
      ],
      stepsData: [step1, step2],
      attachments: [attachment1, attachment2],
    );

    // Pierwsze przejście: KonspektData -> HrcpknspktData -> bytes.
    // Konstruujemy HrcpknspktData ręcznie z pustą listą załączników binarnych,
    // żeby skupić się na poprawności konspektCoreData (czyli tego, co trafia do edytora).
    final HrcpknspktData hrcp1 = HrcpknspktData(
      coverImage: original.coverImageBytes,
      attachments: const [],
      konspektCoreData: jsonEncode(original.toJsonMap()),
    );
    final Uint8List bytes = hrcp1.toBytes();

    // Drugie przejście: bytes -> HrcpknspktData -> KonspektData.
    final HrcpknspktData hrcp2 = HrcpknspktData.fromBytes(bytes);
    final KonspektData restored = KonspektData.fromHrcpknspktData(hrcp2);

    // Sprawdzenie najważniejszych pól i struktur.
    expect(restored.titleController.text, original.titleController.text);
    expect(restored.additionalSearchPhrases, original.additionalSearchPhrases);
    expect(restored.type, original.type);
    expect(restored.metos, original.metos);
    expect(restored.coverAuthorController.text, original.coverAuthorController.text);
    expect(restored.author, isNotNull);
    expect(restored.author!.toApiJsonMap(), original.author!.toApiJsonMap());
    expect(restored.coverImageBytes, original.coverImageBytes);
    expect(restored.customDuration, original.customDuration);
    expect(restored.aims, original.aims);
    expect(restored.summaryController.text, original.summaryController.text);
    expect(restored.introController.text, original.introController.text);
    expect(restored.descriptionController.text, original.descriptionController.text);
    expect(restored.howToFail, original.howToFail);

    // Kroki
    expect(restored.stepsData.length, original.stepsData.length);
    for (int i = 0; i < original.stepsData.length; i++) {
      final o = original.stepsData[i];
      final r = restored.stepsData[i];
      expect(r.titleController.text, o.titleController.text);
      expect(r.duration, o.duration);
      expect(r.activeForm, o.activeForm);
      expect(r.required, o.required);
      expect(r.contentController.text, o.contentController.text);
      expect(r.aims, o.aims);
    }

    // Materiały
    expect(restored.materials.length, original.materials.length);
    for (int i = 0; i < original.materials.length; i++) {
      final o = original.materials[i];
      final r = restored.materials[i];
      expect(r.nameController.text, o.nameController.text);
      expect(r.commentController?.text, o.commentController?.text);
      expect(r.additionalPreparationController?.text, o.additionalPreparationController?.text);
      expect(r.attachmentNameController?.text, o.attachmentNameController?.text);
      expect(r.amountController?.text, o.amountController?.text);
      expect(r.amountAttendantFactorController?.text, o.amountAttendantFactorController?.text);
    }

    // Załączniki (na poziomie rdzenia konspektu, nie binarnych plików).
    expect(restored.attachments.length, original.attachments.length);
    for (int i = 0; i < original.attachments.length; i++) {
      final o = original.attachments[i];
      final r = restored.attachments[i];
      expect(r.titleController.text, o.titleController.text);
      expect(r.idController?.text, o.idController?.text);
      expect(r.printInfoEnabled, o.printInfoEnabled);
      expect(r.printSide, o.printSide);
      expect(r.printColor, o.printColor);
      expect(r.autoIdFromTitle, o.autoIdFromTitle);
    }

    // Sfery – w tym te puste; tutaj tylko sprawdzamy, że klucze się zgadzają.
    expect(restored.spheres.keys.toSet(), original.spheres.keys.toSet());

    for (final sphere in original.spheres.keys) {
      final originalDetails = original.spheres[sphere];
      final restoredDetails = restored.spheres[sphere];

      if (originalDetails == null) {
        expect(restoredDetails, isNull);
      } else {
        expect(restoredDetails, isNotNull);
        expect(restoredDetails!.levels.keys.toSet(), originalDetails.levels.keys.toSet());

        for (final level in originalDetails.levels.keys) {
          final originalFields = originalDetails.levels[level]!.fields.keys.toSet();
          final restoredFields = restoredDetails.levels[level]!.fields.keys.toSet();
          expect(restoredFields, originalFields);
        }
      }
    }
  });

  test('HrcpknspktData attachments roundtrip with example files', () {
    final pdfFile = _exampleFile('example.pdf');
    final docxFile = _exampleFile('example.docx');
    final webpFile = _exampleFile('example.webp');

    final pdfBytes = pdfFile.readAsBytesSync();
    final docxBytes = docxFile.readAsBytesSync();
    final webpBytes = webpFile.readAsBytesSync();

    final KonspektAttachmentData konspektAttachment = KonspektAttachmentData(
      name: 'example_attachments',
      titleController: TextEditingController(text: 'Przykładowe załączniki'),
      idController: TextEditingController(text: 'example_attachments'),
      pickedFiles: {
        FileFormat.pdf: PlatformFile(
          name: 'example.pdf',
          path: pdfFile.path,
          size: pdfBytes.length,
          bytes: pdfBytes,
        ),
        FileFormat.docx: PlatformFile(
          name: 'example.docx',
          path: docxFile.path,
          size: docxBytes.length,
          bytes: docxBytes,
        ),
        FileFormat.webp: PlatformFile(
          name: 'example.webp',
          path: webpFile.path,
          size: webpBytes.length,
          bytes: webpBytes,
        ),
      },
      pickedUrls: const {},
      printInfoEnabled: true,
      printSide: KonspektAttachmentPrintSide.single,
      printColor: KonspektAttachmentPrintColor.monochrome,
      autoIdFromTitle: false,
    );

    final AttachmentData attachmentData = konspektAttachment.toAttachmentData();

    expect(attachmentData.fileData.keys.toSet(), {FileFormat.pdf, FileFormat.docx, FileFormat.webp});
    expect(attachmentData.fileData[FileFormat.pdf]!.isNotEmpty, true);
    expect(attachmentData.fileData[FileFormat.docx]!.isNotEmpty, true);
    expect(attachmentData.fileData[FileFormat.webp]!.isNotEmpty, true);
  });
  
  test('KonspektData.toHrcpknspktData uses coverImageBytes and toJsonMap', () {
    final konspekt = _buildBaseKonspekt(spheres: _buildSphereVariants()['no_spheres']!);

    final HrcpknspktData data = konspekt.toHrcpknspktData();

    expect(data.coverImage, konspekt.coverImageBytes);
    expect(data.attachments.length, konspekt.attachments.length);
    expect(data.konspektCoreData, jsonEncode(konspekt.toJsonMap()));
  });

  test('KonspektData.empty provides sane defaults', () {
    final KonspektData empty = KonspektData.empty();

    expect(empty.titleController.text, '');
    expect(empty.additionalSearchPhrases, isEmpty);
    expect(empty.spheres, isEmpty);
    expect(empty.metos, isEmpty);
    expect(empty.aimControllers, isEmpty);
    expect(empty.materials, isEmpty);
    expect(empty.attachments, isEmpty);
    expect(empty.stepsData.length, 1);
    expect(empty.steps.length, 1);
  });

  test('KonspektAttachmentData.toAttachmentData generates id from title when missing', () {
    final KonspektAttachmentData attachmentTitleOnly = KonspektAttachmentData(
      name: 'internal_name',
      titleController: TextEditingController(text: 'Moja załączka'),
      idController: TextEditingController(),
      pickedFiles: const {},
      pickedUrls: const {},
      printInfoEnabled: false,
      printSide: KonspektAttachmentPrintSide.single,
      printColor: KonspektAttachmentPrintColor.monochrome,
      autoIdFromTitle: true,
    );

    final AttachmentData dataTitleOnly = attachmentTitleOnly.toAttachmentData();
    expect(dataTitleOnly.name, simplifyString('Moja załączka'));

    final KonspektAttachmentData attachmentWithId = KonspektAttachmentData(
      name: 'internal_name',
      titleController: TextEditingController(text: 'Moja załączka'),
      idController: TextEditingController(text: 'custom_id'),
      pickedFiles: const {},
      pickedUrls: const {},
      printInfoEnabled: false,
      printSide: KonspektAttachmentPrintSide.single,
      printColor: KonspektAttachmentPrintColor.monochrome,
      autoIdFromTitle: true,
    );

    final AttachmentData dataWithId = attachmentWithId.toAttachmentData();
    expect(dataWithId.name, 'custom_id');

    final KonspektAttachmentData attachmentNoTitle = KonspektAttachmentData(
      name: 'internal_name',
      titleController: TextEditingController(text: ''),
      idController: TextEditingController(),
      pickedFiles: const {},
      pickedUrls: const {},
      printInfoEnabled: false,
      printSide: KonspektAttachmentPrintSide.single,
      printColor: KonspektAttachmentPrintColor.monochrome,
      autoIdFromTitle: true,
    );

    final AttachmentData dataNoTitle = attachmentNoTitle.toAttachmentData();
    expect(dataNoTitle.name, 'internal_name');
  });

  test('KonspektAttachmentData.toJsonMap encodes pickedUrls with apiParam keys', () {
    final KonspektAttachmentData attachment = KonspektAttachmentData(
      name: 'urls',
      titleController: TextEditingController(text: 'Linki'),
      idController: TextEditingController(text: 'urls'),
      pickedFiles: const {},
      pickedUrls: {
        FileFormat.urlPdf: 'https://example.com/file.pdf',
      },
      printInfoEnabled: false,
      printSide: KonspektAttachmentPrintSide.single,
      printColor: KonspektAttachmentPrintColor.monochrome,
      autoIdFromTitle: false,
    );

    final Map map = attachment.toJsonMap();
    final Map pickedUrls = map['pickedUrls'] as Map;

    expect(pickedUrls[FileFormat.urlPdf.apiParam], 'https://example.com/file.pdf');
  });

  test('AttachmentData.toJson/fromJson roundtrip preserves all fields', () {
    final Uint8List pngBytes = Uint8List.fromList([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);

    final AttachmentData original = AttachmentData(
      name: 'test_attachment',
      title: 'Test Attachment Title',
      fileData: {FileFormat.png: pngBytes},
      urlData: {FileFormat.urlPdf: 'https://example.com/doc.pdf'},
      printInfoEnabled: true,
      printSide: KonspektAttachmentPrintSide.double,
      printColor: KonspektAttachmentPrintColor.color,
    );

    final Map<String, dynamic> json = original.toJson();

    // Verify JSON contains all required fields
    expect(json['name'], 'test_attachment');
    expect(json['title'], 'Test Attachment Title');
    expect(json['formats'], isNotNull);
    expect(json['files'], isNotNull);
    expect(json['urls'], isNotNull);
    expect(json['printInfoEnabled'], true);
    expect(json['printSide'], 'double');
    expect(json['printColor'], 'color');

    // Verify roundtrip
    final AttachmentData restored = AttachmentData.fromJson(json);

    expect(restored.name, original.name);
    expect(restored.title, original.title);
    expect(restored.fileData.keys, contains(FileFormat.png));
    expect(restored.fileData[FileFormat.png], pngBytes);
    expect(restored.urlData[FileFormat.urlPdf], 'https://example.com/doc.pdf');
    expect(restored.printInfoEnabled, original.printInfoEnabled);
    expect(restored.printSide, original.printSide);
    expect(restored.printColor, original.printColor);
  });

  test('AttachmentData.toJson/fromJson roundtrip with empty title', () {
    final AttachmentData original = AttachmentData(
      name: 'no_title_attachment',
      title: '',
      fileData: const {},
      urlData: const {},
    );

    final Map<String, dynamic> json = original.toJson();
    expect(json['title'], '');

    final AttachmentData restored = AttachmentData.fromJson(json);
    expect(restored.name, 'no_title_attachment');
    expect(restored.title, '');
  });

  test('AttachmentData.toJson includes formats field', () {
    final AttachmentData attachment = AttachmentData(
      name: 'formats_test',
      title: 'Formats Test',
      fileData: {FileFormat.png: Uint8List.fromList([1, 2, 3])},
      urlData: {FileFormat.urlPdf: 'https://example.com'},
    );

    final Map<String, dynamic> json = attachment.toJson();

    expect(json['formats'], isA<List>());
    final List formats = json['formats'] as List;
    expect(formats, contains('png'));
    expect(formats, contains('urlPdf'));
  });

  test('KonspektData intro field roundtrip preserves content', () {
    final KonspektData original = _buildBaseKonspekt(spheres: _buildSphereVariants()['no_spheres']!);
    
    // Verify original intro value
    expect(original.introController.text, 'Wstęp');
    
    final KonspektData restored = _roundtrip(original);
    
    expect(restored.introController.text, original.introController.text);
  });

  test('KonspektData intro field roundtrip with empty value', () {
    final KonspektData original = _buildBaseKonspekt(spheres: _buildSphereVariants()['no_spheres']!);
    original.introController.text = '';
    
    final KonspektData restored = _roundtrip(original);
    
    expect(restored.introController.text, '');
  });

  test('KonspektData intro field roundtrip with HTML content', () {
    final KonspektData original = _buildBaseKonspekt(spheres: _buildSphereVariants()['no_spheres']!);
    original.introController.text = '<p>Wstęp z <strong>formatowaniem</strong> i <em>kursywą</em>.</p>';
    
    final KonspektData restored = _roundtrip(original);
    
    expect(restored.introController.text, original.introController.text);
  });
}
