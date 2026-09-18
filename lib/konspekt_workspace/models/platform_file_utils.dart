import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

/// A file the user picked, held in memory.
///
/// `file_picker`'s [PlatformFile] is abstract and hands out its bytes
/// asynchronously, so picked files are read into this value object right at the
/// picker boundary. Everything downstream (JSON round-tripping, the .hrcpknspkt
/// archive, the attachment widgets) then stays synchronous.
class PickedFile {
  final String name;
  final Uint8List bytes;
  final String? path;

  const PickedFile({required this.name, required this.bytes, this.path});

  int get size => bytes.length;

  static Future<PickedFile> read(PlatformFile file) async => PickedFile(
    name: file.name,
    bytes: await file.readAsBytes(),
    path: file.path,
  );
}

Map pickedFileToJsonMap(PickedFile data) => {
  "path": data.path,
  "name": data.name,
  "size": data.size,
  "bytes": data.bytes.toList(),
};

PickedFile pickedFileFromJsonMap(Map data) {
  final bytesRaw = data["bytes"];

  return PickedFile(
    path: data["path"],
    name: data["name"],
    bytes: bytesRaw == null
        ? Uint8List(0)
        : Uint8List.fromList((bytesRaw as List).cast<int>()),
  );
}
