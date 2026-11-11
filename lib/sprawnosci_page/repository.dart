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

/// Each book is read once per session and kept: the list, its book tabs and
/// the family pages share one read.
class SprawnosciRepositoryNew {
  static Future<Set<String>>? _assets;
  static final Map<String, Future<SprawBook>> _books = {};
  static final Map<String, SprawBook> _loaded = {};

  /// The web's books if all are already read — to show them without a
  /// loading frame when coming back to the page.
  List<SprawBook>? get loadedWebBooks =>
      sprawWebBookSlugs.every(_loaded.containsKey)
          ? [for (final slug in sprawWebBookSlugs) _loaded[slug]!]
          : null;

  Future<SprawBook> loadBook(String bookSlug) =>
      _books.putIfAbsent(bookSlug, () async {
        try {
          final assets = await (_assets ??= _loadAssetManifest());
          return _loaded[bookSlug] =
              await SprawAssets(assets, rootBundle.loadString).loadBook(bookSlug);
        } catch (_) {
          _books.remove(bookSlug); // Retry on the next visit.
          rethrow;
        }
      });

  /// All the books the web shows, in their order.
  Future<List<SprawBook>> loadWebBooks() =>
      Future.wait(sprawWebBookSlugs.map(loadBook));
}
