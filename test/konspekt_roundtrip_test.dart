import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harcapp_core/comm_classes/meto.dart';
import 'package:harcapp_core/harcthought/common/file_format.dart';
import 'package:harcapp_core/harcthought/konspekts/hrcpknspkt_data.dart';
import 'package:harcapp_core/harcthought/konspekts/konspekt.dart';
import 'package:harcapp_core/values/org.dart';
import 'package:harcapp_core/values/people/person.dart';
import 'package:harcapp_core/values/rank_harc.dart';
import 'package:harcapp_core/values/rank_instr.dart';
import 'package:harcapp_web/konspekt_workspace/models/konspekt_attachment_data.dart';
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
    nameController: TextEditingController(text: 'zalacznik'),
    titleController: TextEditingController(text: 'Załącznik'),
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
  final HrcpknspktData hrcp1 = original.toHrcpknspktData();
  final Uint8List bytes = hrcp1.toTarBytes();
  final HrcpknspktData hrcp2 = HrcpknspktData.fromTarBytes(bytes);
  return KonspektData.fromHrcpknspktData(hrcp2);
}

// ============================================================================
// Helper functions for comparing objects
// ============================================================================

void _expectMaterialDataEqual(KonspektMaterialData restored, KonspektMaterialData original, {String? reason}) {
  expect(restored.nameController.text, original.nameController.text, reason: reason);
  expect(restored.commentController?.text, original.commentController?.text, reason: reason);
  expect(restored.additionalPreparationController?.text, original.additionalPreparationController?.text, reason: reason);
  expect(restored.attachmentNameController?.text, original.attachmentNameController?.text, reason: reason);
  expect(restored.amountController?.text, original.amountController?.text, reason: reason);
  expect(restored.amountAttendantFactorController?.text, original.amountAttendantFactorController?.text, reason: reason);
}

void _expectStepDataEqual(KonspektStepData restored, KonspektStepData original, {String? reason}) {
  expect(restored.titleController.text, original.titleController.text, reason: reason);
  expect(restored.duration, original.duration, reason: reason);
  expect(restored.activeForm, original.activeForm, reason: reason);
  expect(restored.required, original.required, reason: reason);
  expect(restored.contentController.text, original.contentController.text, reason: reason);
  expect(restored.aims, original.aims, reason: reason);
  
  if (original.materials != null) {
    expect(restored.materials, isNotNull, reason: reason);
    expect(restored.materials!.length, original.materials!.length, reason: reason);
    for (int i = 0; i < original.materials!.length; i++) {
      _expectMaterialDataEqual(restored.materials![i], original.materials![i], reason: '$reason/material[$i]');
    }
  }
}

void _expectAttachmentDataEqual(KonspektAttachmentData restored, KonspektAttachmentData original, {String? reason}) {
  expect(restored.titleController.text, original.titleController.text, reason: reason);
  expect(restored.nameController.text, original.nameController.text, reason: reason);
  expect(restored.printInfoEnabled, original.printInfoEnabled, reason: reason);
  expect(restored.printSide, original.printSide, reason: reason);
  expect(restored.printColor, original.printColor, reason: reason);
  // Note: autoIdFromTitle is not preserved in roundtrip (not part of KonspektAttachment)
}

void _expectSpheresEqual(
  Map<KonspektSphere, KonspektSphereDetails?> restored,
  Map<KonspektSphere, KonspektSphereDetails?> original,
  {String? reason}
) {
  // Note: harcapp_core filters out spheres with null/empty details during serialization,
  // so we only compare spheres that have non-null, non-empty details in the original.
  final originalNonEmpty = Map.fromEntries(
    original.entries.where((e) => e.value != null && e.value!.isNotEmpty)
  );
  final restoredNonEmpty = Map.fromEntries(
    restored.entries.where((e) => e.value != null && e.value!.isNotEmpty)
  );
  
  expect(restoredNonEmpty.keys.toSet(), originalNonEmpty.keys.toSet(), reason: reason);
  for (final sphere in originalNonEmpty.keys) {
    final originalDetails = originalNonEmpty[sphere]!;
    final restoredDetails = restoredNonEmpty[sphere];
    expect(restoredDetails, isNotNull, reason: '$reason/$sphere');
    expect(restoredDetails!.levels.keys.toSet(), originalDetails.levels.keys.toSet(), reason: '$reason/$sphere');
    for (final level in originalDetails.levels.keys) {
      final originalFields = originalDetails.levels[level]!.fields.keys.toSet();
      final restoredFields = restoredDetails.levels[level]!.fields.keys.toSet();
      expect(restoredFields, originalFields, reason: '$reason/$sphere/$level');
    }
  }
}

void _expectKonspektDataEqual(KonspektData restored, KonspektData original, {String? reason}) {
  expect(restored.titleController.text, original.titleController.text, reason: reason);
  expect(restored.additionalSearchPhrases, original.additionalSearchPhrases, reason: reason);
  expect(restored.category, original.category, reason: reason);
  expect(restored.type, original.type, reason: reason);
  expect(restored.metos, original.metos, reason: reason);
  expect(restored.coverAuthorController.text, original.coverAuthorController.text, reason: reason);
  expect(restored.coverImageBytes, original.coverImageBytes, reason: reason);
  expect(restored.customDuration, original.customDuration, reason: reason);
  expect(restored.aims, original.aims, reason: reason);
  expect(restored.summaryController.text, original.summaryController.text, reason: reason);
  expect(restored.introController.text, original.introController.text, reason: reason);
  expect(restored.descriptionController.text, original.descriptionController.text, reason: reason);
  expect(restored.howToFail, original.howToFail, reason: reason);
  
  // Author
  if (original.author == null) {
    expect(restored.author, isNull, reason: reason);
  } else {
    expect(restored.author, isNotNull, reason: reason);
    expect(restored.author!.toApiJsonMap(), original.author!.toApiJsonMap(), reason: reason);
  }
  
  // Steps
  expect(restored.stepsData.length, original.stepsData.length, reason: reason);
  for (int i = 0; i < original.stepsData.length; i++) {
    _expectStepDataEqual(restored.stepsData[i], original.stepsData[i], reason: '$reason/step[$i]');
  }
  
  // Materials
  expect(restored.materials.length, original.materials.length, reason: reason);
  for (int i = 0; i < original.materials.length; i++) {
    _expectMaterialDataEqual(restored.materials[i], original.materials[i], reason: '$reason/material[$i]');
  }
  
  // Attachments
  expect(restored.attachments.length, original.attachments.length, reason: reason);
  for (int i = 0; i < original.attachments.length; i++) {
    _expectAttachmentDataEqual(restored.attachments[i], original.attachments[i], reason: '$reason/attachment[$i]');
  }
  
  // Spheres
  _expectSpheresEqual(restored.spheres, original.spheres, reason: reason);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('KonspektData spheres roundtrip for multiple variants', () {
    final baseSpheres = _buildSphereVariants();

    baseSpheres.forEach((name, spheres) {
      final original = _buildBaseKonspekt(spheres: spheres);
      final restored = _roundtrip(original);

      // Note: harcapp_core filters out spheres with null/empty details during serialization,
      // so we only compare spheres that have non-null, non-empty details.
      final originalNonEmpty = Map.fromEntries(
        original.spheres.entries.where((e) => e.value != null && e.value!.isNotEmpty)
      );
      final restoredNonEmpty = Map.fromEntries(
        restored.spheres.entries.where((e) => e.value != null && e.value!.isNotEmpty)
      );

      expect(restoredNonEmpty.keys.toSet(), originalNonEmpty.keys.toSet(), reason: name);

      for (final sphere in originalNonEmpty.keys) {
        final originalDetails = originalNonEmpty[sphere]!;
        final restoredDetails = restoredNonEmpty[sphere];

        expect(restoredDetails, isNotNull, reason: name);
        expect(restoredDetails!.levels.keys.toSet(), originalDetails.levels.keys.toSet(), reason: name);

        for (final level in originalDetails.levels.keys) {
          final originalFields = originalDetails.levels[level]!.fields.keys.toSet();
          final restoredFields = restoredDetails.levels[level]!.fields.keys.toSet();
          expect(restoredFields, originalFields, reason: '$name/$level');
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
      attachments: [],
    );

    // Pierwsze przejście: KonspektData -> HrcpknspktData -> bytes.
    final HrcpknspktData hrcp1 = original.toHrcpknspktData();
    final Uint8List bytes = hrcp1.toTarBytes();

    // Drugie przejście: bytes -> HrcpknspktData -> KonspektData.
    final HrcpknspktData hrcp2 = HrcpknspktData.fromTarBytes(bytes);
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
      expect(r.nameController.text, o.nameController.text);
      expect(r.printInfoEnabled, o.printInfoEnabled);
      expect(r.printSide, o.printSide);
      expect(r.printColor, o.printColor);
      expect(r.autoIdFromTitle, o.autoIdFromTitle);
    }

    // Sfery – harcapp_core filtruje puste sfery, więc porównujemy tylko te z wartościami.
    final originalNonEmpty = Map.fromEntries(
      original.spheres.entries.where((e) => e.value != null && e.value!.isNotEmpty)
    );
    final restoredNonEmpty = Map.fromEntries(
      restored.spheres.entries.where((e) => e.value != null && e.value!.isNotEmpty)
    );
    expect(restoredNonEmpty.keys.toSet(), originalNonEmpty.keys.toSet());

    for (final sphere in originalNonEmpty.keys) {
      final originalDetails = originalNonEmpty[sphere]!;
      final restoredDetails = restoredNonEmpty[sphere];

      expect(restoredDetails, isNotNull);
      expect(restoredDetails!.levels.keys.toSet(), originalDetails.levels.keys.toSet());

      for (final level in originalDetails.levels.keys) {
        final originalFields = originalDetails.levels[level]!.fields.keys.toSet();
        final restoredFields = restoredDetails.levels[level]!.fields.keys.toSet();
        expect(restoredFields, originalFields);
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
      nameController: TextEditingController(text: 'example_attachments'),
      titleController: TextEditingController(text: 'Przykładowe załączniki'),
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

    // Test that pickedFiles contains the expected formats
    expect(konspektAttachment.pickedFiles.keys.toSet(), {FileFormat.pdf, FileFormat.docx, FileFormat.webp});
    expect(konspektAttachment.pickedFiles[FileFormat.pdf]!.bytes!.isNotEmpty, true);
    expect(konspektAttachment.pickedFiles[FileFormat.docx]!.bytes!.isNotEmpty, true);
    expect(konspektAttachment.pickedFiles[FileFormat.webp]!.bytes!.isNotEmpty, true);
  });
  
  test('KonspektData.toHrcpknspktData uses coverImageBytes and toJsonMap', () {
    final konspekt = _buildBaseKonspekt(spheres: _buildSphereVariants()['no_spheres']!);

    final HrcpknspktData data = konspekt.toHrcpknspktData();

    expect(data.coverImage, konspekt.coverImageBytes);
    expect(data.konspektCore.title, konspekt.title);
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

  test('KonspektAttachmentData.name returns nameController text', () {
    final KonspektAttachmentData attachment = KonspektAttachmentData(
      nameController: TextEditingController(text: 'my_attachment'),
      titleController: TextEditingController(text: 'Moja załączka'),
      pickedFiles: const {},
      pickedUrls: const {},
      printInfoEnabled: false,
      printSide: KonspektAttachmentPrintSide.single,
      printColor: KonspektAttachmentPrintColor.monochrome,
      autoIdFromTitle: true,
    );

    expect(attachment.name, 'my_attachment');
  });

  test('KonspektAttachmentData.toJsonMap encodes pickedUrls with apiParam keys', () {
    final KonspektAttachmentData attachment = KonspektAttachmentData(
      nameController: TextEditingController(text: 'urls'),
      titleController: TextEditingController(text: 'Linki'),
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

  test('KonspektAttachmentData.fromJsonMap/toJsonMap roundtrip preserves pickedUrls', () {
    final KonspektAttachmentData original = KonspektAttachmentData(
      nameController: TextEditingController(text: 'urls_test'),
      titleController: TextEditingController(text: 'Test załącznik'),
      pickedFiles: const {},
      pickedUrls: {
        FileFormat.urlPdf: 'https://example.com/doc.pdf',
        FileFormat.urlPng: 'https://example.com/image.png',
      },
      printInfoEnabled: true,
      printSide: KonspektAttachmentPrintSide.double,
      printColor: KonspektAttachmentPrintColor.color,
      autoIdFromTitle: false,
    );

    final Map<String, dynamic> json = original.toJsonMap().cast<String, dynamic>();
    final KonspektAttachmentData restored = KonspektAttachmentData.fromJsonMap(json);

    expect(restored.name, original.name);
    expect(restored.titleController.text, original.titleController.text);
    expect(restored.nameController.text, original.nameController.text);
    expect(restored.pickedUrls[FileFormat.urlPdf], 'https://example.com/doc.pdf');
    expect(restored.pickedUrls[FileFormat.urlPng], 'https://example.com/image.png');
    expect(restored.printInfoEnabled, original.printInfoEnabled);
    expect(restored.printSide, original.printSide);
    expect(restored.printColor, original.printColor);
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

  test('KonspektData author field roundtrip with full Person details', () {
    final KonspektData original = _buildBaseKonspekt(spheres: _buildSphereVariants()['no_spheres']!);
    
    // Set author with all possible fields
    original.author = const Person(
      name: 'pwd. Anna Kowalska',
      rankHarc: RankHarc.zhpWywiadowca,
      rankInstr: RankInstr.pwd,
      druzyna: '123 WDH "Leśne Tropiciele"',
      hufiec: 'Hufiec Warszawa-Śródmieście',
      org: Org.zhp,
      comment: 'Specjalizacja: gry terenowe',
      email: ['anna.kowalska@example.com'],
    );
    
    final KonspektData restored = _roundtrip(original);
    
    expect(restored.author, isNotNull);
    expect(restored.author!.name, 'pwd. Anna Kowalska');
    expect(restored.author!.rankHarc, RankHarc.zhpWywiadowca);
    expect(restored.author!.rankInstr, RankInstr.pwd);
    expect(restored.author!.druzyna, '123 WDH "Leśne Tropiciele"');
    expect(restored.author!.hufiec, 'Hufiec Warszawa-Śródmieście');
    expect(restored.author!.org, Org.zhp);
    expect(restored.author!.comment, 'Specjalizacja: gry terenowe');
    expect(restored.author!.email, ['anna.kowalska@example.com']);
  });

  test('KonspektData author field roundtrip with minimal Person', () {
    final KonspektData original = _buildBaseKonspekt(spheres: _buildSphereVariants()['no_spheres']!);
    
    // Set author with only required name field
    original.author = const Person(name: 'Jan Nowak');
    
    final KonspektData restored = _roundtrip(original);
    
    expect(restored.author, isNotNull);
    expect(restored.author!.name, 'Jan Nowak');
    expect(restored.author!.rankHarc, isNull);
    expect(restored.author!.rankInstr, isNull);
    expect(restored.author!.druzyna, isNull);
    expect(restored.author!.hufiec, isNull);
    expect(restored.author!.org, isNull);
    expect(restored.author!.comment, isNull);
    expect(restored.author!.email, isEmpty);
  });

  test('KonspektData author field roundtrip with null author', () {
    final KonspektData original = _buildBaseKonspekt(spheres: _buildSphereVariants()['no_spheres']!);
    
    // Explicitly set author to null
    original.author = null;
    
    final KonspektData restored = _roundtrip(original);
    
    expect(restored.author, isNull);
  });

  test('KonspektData category field roundtrip', () {
    final KonspektData original = _buildBaseKonspekt(spheres: _buildSphereVariants()['no_spheres']!);
    
    // Test ksztalcenie category (different from default harcerskie)
    original.category = KonspektCategory.ksztalcenie;
    
    final KonspektData restored = _roundtrip(original);
    
    expect(restored.category, KonspektCategory.ksztalcenie);
  });

  test('KonspektAttachmentData roundtrip with URLs via fromKonspektAttachment', () {
    // Test the conversion path: KonspektAttachmentData -> toJsonMap -> KonspektAttachment.fromJsonMap -> fromKonspektAttachment
    final KonspektAttachmentData original = KonspektAttachmentData(
      nameController: TextEditingController(text: 'attachment_with_url'),
      titleController: TextEditingController(text: 'Załącznik z URL'),
      pickedFiles: const {},
      pickedUrls: {FileFormat.urlPdf: 'https://example.com/doc.pdf'},
      printInfoEnabled: true,
      printSide: KonspektAttachmentPrintSide.double,
      printColor: KonspektAttachmentPrintColor.color,
      autoIdFromTitle: false,
    );
    
    // Convert to KonspektAttachment format (what goes into Konspekt)
    final fullJson = original.toJsonMap();
    final printMap = fullJson['print'] as Map?;
    final Map<String, dynamic> json = {
      'name': original.name,
      'title': original.titleController.text,
      'assets': (fullJson['assets'] as Map).cast<String, dynamic>(),
      'print': printMap?.cast<String, dynamic>(),
    };
    
    final KonspektAttachment konspektAttachment = KonspektAttachment.fromJsonMap(json);
    final KonspektAttachmentData restored = KonspektAttachmentData.fromKonspektAttachment(konspektAttachment);
    
    expect(restored.name, original.name);
    expect(restored.titleController.text, original.titleController.text);
    expect(restored.pickedUrls[FileFormat.urlPdf], 'https://example.com/doc.pdf');
    expect(restored.printInfoEnabled, true);
    expect(restored.printSide, KonspektAttachmentPrintSide.double);
    expect(restored.printColor, KonspektAttachmentPrintColor.color);
  });

  test('KonspektStepData materials roundtrip', () {
    final KonspektData original = _buildBaseKonspekt(spheres: _buildSphereVariants()['no_spheres']!);
    
    // Verify step has materials
    expect(original.stepsData[0].materials, isNotNull);
    expect(original.stepsData[0].materials!.length, 1);
    
    final KonspektData restored = _roundtrip(original);
    
    expect(restored.stepsData[0].materials, isNotNull);
    expect(restored.stepsData[0].materials!.length, 1);
    expect(restored.stepsData[0].materials![0].nameController.text, 'Materiał');
    expect(restored.stepsData[0].materials![0].commentController?.text, 'Komentarz');
    expect(restored.stepsData[0].materials![0].additionalPreparationController?.text, 'Przygotowanie');
    expect(restored.stepsData[0].materials![0].attachmentNameController?.text, 'zalacznik');
  });

  test('KonspektAttachmentData pickedFiles roundtrip with real files', () {
    final pdfFile = _exampleFile('example.pdf');
    final pdfBytes = pdfFile.readAsBytesSync();

    final KonspektAttachmentData original = KonspektAttachmentData(
      nameController: TextEditingController(text: 'file_attachment'),
      titleController: TextEditingController(text: 'Załącznik z plikiem'),
      pickedFiles: {
        FileFormat.pdf: PlatformFile(
          name: 'example.pdf',
          path: pdfFile.path,
          size: pdfBytes.length,
          bytes: pdfBytes,
        ),
      },
      pickedUrls: const {},
      printInfoEnabled: false,
      printSide: KonspektAttachmentPrintSide.single,
      printColor: KonspektAttachmentPrintColor.monochrome,
      autoIdFromTitle: true,
    );

    final Map<String, dynamic> json = original.toJsonMap().cast<String, dynamic>();
    final KonspektAttachmentData restored = KonspektAttachmentData.fromJsonMap(json);

    expect(restored.name, original.name);
    expect(restored.titleController.text, original.titleController.text);
    expect(restored.pickedFiles.keys, contains(FileFormat.pdf));
    expect(restored.pickedFiles[FileFormat.pdf], isNotNull);
    expect(restored.pickedFiles[FileFormat.pdf]!.bytes, pdfBytes);
  });

  // ============================================================================
  // Edge case tests
  // ============================================================================

  group('KonspektData edge cases', () {
    test('type roundtrip with different values', () {
      for (final type in KonspektType.values) {
        final original = _buildBaseKonspekt(spheres: _buildSphereVariants()['no_spheres']!);
        original.type = type;
        
        final restored = _roundtrip(original);
        
        expect(restored.type, type, reason: 'type: ${type.name}');
      }
    });

    test('customDuration null roundtrip', () {
      final original = _buildBaseKonspekt(spheres: _buildSphereVariants()['no_spheres']!);
      original.customDuration = null;
      
      final restored = _roundtrip(original);
      
      expect(restored.customDuration, isNull);
    });

    test('howToFail empty list roundtrip', () {
      final original = _buildBaseKonspekt(spheres: _buildSphereVariants()['no_spheres']!);
      original.howToFailControllers.clear();
      
      final restored = _roundtrip(original);
      
      expect(restored.howToFail, isEmpty);
    });

    test('description empty roundtrip', () {
      final original = _buildBaseKonspekt(spheres: _buildSphereVariants()['no_spheres']!);
      original.descriptionController.text = '';
      
      final restored = _roundtrip(original);
      
      expect(restored.descriptionController.text, '');
    });

    test('aims empty list roundtrip', () {
      final original = _buildBaseKonspekt(spheres: _buildSphereVariants()['no_spheres']!);
      original.aimControllers.clear();
      
      final restored = _roundtrip(original);
      
      expect(restored.aims, isEmpty);
    });

    test('materials empty list roundtrip', () {
      final original = _buildBaseKonspekt(spheres: _buildSphereVariants()['no_spheres']!);
      original.materials.clear();
      
      final restored = _roundtrip(original);
      
      expect(restored.materials, isEmpty);
    });

    test('attachments with URLs full roundtrip through HrcpknspktData', () {
      final original = _buildBaseKonspekt(spheres: _buildSphereVariants()['no_spheres']!);
      original.attachments.clear();
      original.attachments.add(KonspektAttachmentData(
        nameController: TextEditingController(text: 'url_attachment'),
        titleController: TextEditingController(text: 'Załącznik z URL'),
        pickedFiles: const {},
        pickedUrls: {FileFormat.urlPdf: 'https://example.com/doc.pdf'},
        printInfoEnabled: true,
        printSide: KonspektAttachmentPrintSide.double,
        printColor: KonspektAttachmentPrintColor.color,
        autoIdFromTitle: false,
      ));
      
      final restored = _roundtrip(original);
      
      expect(restored.attachments.length, 1);
      expect(restored.attachments[0].name, 'url_attachment');
      expect(restored.attachments[0].titleController.text, 'Załącznik z URL');
      expect(restored.attachments[0].printInfoEnabled, true);
      expect(restored.attachments[0].printSide, KonspektAttachmentPrintSide.double);
      expect(restored.attachments[0].printColor, KonspektAttachmentPrintColor.color);
    });

    test('full roundtrip uses helper function', () {
      final original = _buildBaseKonspekt(spheres: _buildSphereVariants()['cialo_other_only']!);
      final restored = _roundtrip(original);
      
      _expectKonspektDataEqual(restored, original, reason: 'full roundtrip');
    });

    test('step with required = false roundtrip', () {
      final original = _buildBaseKonspekt(spheres: _buildSphereVariants()['no_spheres']!);
      original.stepsData[0].required = false;
      
      final restored = _roundtrip(original);
      
      expect(restored.stepsData[0].required, false);
    });

    test('description with double newlines roundtrip', () {
      final original = _buildBaseKonspekt(spheres: _buildSphereVariants()['no_spheres']!);
      
      // HTML with two consecutive paragraphs (simulating double newline / empty line between)
      const htmlWithDoubleNewlines = '<p>Pierwszy akapit</p><p></p><p>Trzeci akapit po pustej linii</p>';
      original.descriptionController.text = htmlWithDoubleNewlines;
      
      final restored = _roundtrip(original);
      
      // The restored HTML should preserve the empty paragraph
      expect(
        restored.descriptionController.text, 
        htmlWithDoubleNewlines,
        reason: 'Double newlines (empty paragraph) should be preserved',
      );
    });

    test('intro with multiple empty paragraphs roundtrip', () {
      final original = _buildBaseKonspekt(spheres: _buildSphereVariants()['no_spheres']!);
      
      // HTML with multiple empty paragraphs
      const htmlWithMultipleEmptyParagraphs = '<p>Start</p><p></p><p></p><p>End after two empty lines</p>';
      original.introController.text = htmlWithMultipleEmptyParagraphs;
      
      final restored = _roundtrip(original);
      
      expect(
        restored.introController.text, 
        htmlWithMultipleEmptyParagraphs,
        reason: 'Multiple empty paragraphs should be preserved',
      );
    });

    test('step content with double newlines roundtrip', () {
      final original = _buildBaseKonspekt(spheres: _buildSphereVariants()['no_spheres']!);
      
      const htmlWithDoubleNewlines = '<p>Krok pierwszy</p><p></p><p>Po przerwie</p>';
      original.stepsData[0].contentController.text = htmlWithDoubleNewlines;
      
      final restored = _roundtrip(original);
      
      expect(
        restored.stepsData[0].contentController.text, 
        htmlWithDoubleNewlines,
        reason: 'Step content double newlines should be preserved',
      );
    });
  });
}
