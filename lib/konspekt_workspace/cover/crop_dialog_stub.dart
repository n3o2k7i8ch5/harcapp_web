import 'dart:typed_data';

import 'package:flutter/material.dart';

Future<Uint8List?> showCoverCropDialog(BuildContext context, Uint8List imageBytes) async {
  return imageBytes; // Non-web: skip cropping
}
