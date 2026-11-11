import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:sprawnosci_data/sprawnosci_assets.dart';

/// Sprawności from sprawnosci_data's YAML assets, read by the shared reader —
/// the deploy-time page generator (tool/share_pages) reads them the same way.

typedef SprawBook = SprawAssetBook;
typedef SprawGroup = SprawAssetGroup;
typedef SprawFamily = SprawAssetFamily;
typedef SprawItem = SprawAssetItem;

class SprawnosciBooks {
  static const String bookCHarcC = sprawBookZhrHarcC2023;
  static const String bookCHarcD = sprawBookZhrHarcD2023;
  static final String defaultBookSlug = sprawWebBookSlugs.first;
}

Future<Set<String>> _loadAssetManifest() async {
  try {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    return manifest.listAssets().toSet();
  } catch (_) {
    try {
      final manifestStr = await rootBundle.loadString('AssetManifest.json');
      final dynamic manifestJson = jsonDecode(manifestStr);
      if (manifestJson is Map<String, dynamic>)
        return manifestJson.keys.toSet();

      if (manifestJson is List)
        return manifestJson.cast<String>().toSet();

    } catch (_) {}
    return <String>{};
  }
}

class SprawnosciRepositoryNew {
  Future<SprawBook> loadBook(String bookSlug) async {
    final assets = await _loadAssetManifest();
    return SprawAssets(assets, rootBundle.loadString).loadBook(bookSlug);
  }
}
