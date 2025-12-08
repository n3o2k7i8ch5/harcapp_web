import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

Map platformFileToJsonMap(PlatformFile data) => {
  "path": data.path,
  "name": data.name,
  "size": data.size,
  "bytes": data.bytes?.toList(),
  "identifier": data.identifier
};

PlatformFile platformFileFromJsonMap(Map data) {
  final bytesRaw = data["bytes"];
  final Uint8List? bytes = bytesRaw == null
      ? null
      : Uint8List.fromList((bytesRaw as List).cast<int>());

  return PlatformFile(
    path: data["path"],
    name: data["name"],
    size: data["size"],
    bytes: bytes,
    identifier: data["identifier"],
  );
}