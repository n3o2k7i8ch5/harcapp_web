import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'resizer_stub.dart' if (dart.library.js_interop) 'resizer_web.dart';
import 'crop_dialog_stub.dart' if (dart.library.js_interop) 'crop_dialog_web.dart';

const int coverMaxWidth = 1500;
const int coverMaxHeight = 1000;
const double coverAspectRatio = coverMaxWidth / coverMaxHeight; // 3:2

Future<Uint8List?> processCoverImage(BuildContext context, Uint8List inputBytes) async {
  final cropped = await showCoverCropDialog(context, inputBytes);
  if (cropped == null) return null;
  return resizeCoverImage(cropped);
}
