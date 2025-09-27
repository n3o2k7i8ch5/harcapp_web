import 'package:file_picker/file_picker.dart';

Map platformFileToJsonMap(PlatformFile data) => {
  "path": data.path,
  "name": data.name,
  "size": data.size,
  "bytes": data.bytes,
  "identifier": data.identifier
};

PlatformFile platformFileFromJsonMap(Map data) => PlatformFile(
  path: data["path"],
  name: data["name"],
  size: data["size"],
  bytes: data["bytes"],
  identifier: data["identifier"],
);