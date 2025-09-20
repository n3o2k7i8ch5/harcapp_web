import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:yaml/yaml.dart';

/// Alternative repository with a clean, directory-like model structure
/// that works with assets (no dart:io). It mirrors the "fromDir" style by
/// scanning AssetManifest for logical directories.

const String _assetsLocalBase = 'assets/sprawnosci';
const String _assetsPackageBase = 'packages/harcapp_core/assets/sprawnosci';

class SprawnosciBooks {
  static const String bookCHarcC = 'zhr_harc_c_sim_2023';
  static const String bookCHarcD = 'zhr_harc_d_sim_2023';
  static const String defaultBookSlug = bookCHarcC;
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

Future<YamlMap> _loadYaml(String path, Set<String> assets) async {
  if (!assets.contains(path))
    throw StateError('Asset not found: $path');

  final content = await rootBundle.loadString(path);
  final parsed = loadYaml(content);
  if (parsed is YamlMap) return parsed;
  throw StateError('YAML at $path is not a map');
}

String _resolveBaseForBook(String bookSlug, Set<String> assets) {
  final localBase = '$_assetsLocalBase/$bookSlug';
  final pkgBase = '$_assetsPackageBase/$bookSlug';
  if (assets.any((p) => p.startsWith('$localBase/'))) return localBase;
  if (assets.any((p) => p.startsWith('$pkgBase/'))) return pkgBase;
  // Prefer package base by default to match current project layout
  return pkgBase;
}

String _stripSuffix(String s, String suffix) => s.endsWith(suffix) ? s.substring(0, s.length - suffix.length) : s;

class SprawBook {
  final String slug;
  final String name;
  final List<SprawGroup> groups;

  SprawBook({required this.slug, required this.name, required this.groups});

  static Future<SprawBook> fromAssets(Set<String> assets, String baseDir) async {
    final baseDepth = baseDir.split('/').length;
    final dataPath = '$baseDir/_data.yaml';
    final data = await _loadYaml(dataPath, assets);

    final slug = data['id'] ?? (throw StateError('Missing id in: $baseDir'));
    final name = data['name'] ?? (throw StateError('Missing name in: $baseDir'));

    // Find group directories: <baseDir>/groupX/_data.yaml
    final groupDirs = assets
        .where((p) {
          if (!p.startsWith('$baseDir/') || !p.endsWith('/_data.yaml')) return false;
          final parts = p.split('/');
          if (parts.length != baseDepth + 2) return false;
          final seg = parts[baseDepth];
          return seg.startsWith('group');
        })
        .map((p) => _stripSuffix(p, '/_data.yaml'))
        .toList()
      ..sort();

    final groups = await Future.wait(
      groupDirs.map((gdir) => SprawGroup.fromAssets(assets, gdir))
    );

    return SprawBook(slug: slug, name: name, groups: groups);
  }
}

class SprawGroup {
  final String slug;
  final String name;
  final List<SprawFamily> families;

  SprawGroup({required this.slug, required this.name, required this.families});

  static Future<SprawGroup> fromAssets(Set<String> assets, String groupDir) async {
    final data = await _loadYaml('$groupDir/_data.yaml', assets);

    final slug = data['id'] ?? (throw StateError('Missing id in: $groupDir'));
    final name = data['name'] ?? (throw StateError('Missing name in: $groupDir'));

    final dirDepth = groupDir.split('/').length;
    // Find family directories: <groupDir>/familyX/_data.yaml
    final familyDirs = assets
        .where((p) {
          if (!p.startsWith('$groupDir/') || !p.endsWith('/_data.yaml')) return false;
          final parts = p.split('/');
          if (parts.length != dirDepth + 2) return false;
          final seg = parts[dirDepth];
          return seg.startsWith('family');
        })
        .map((p) => _stripSuffix(p, '/_data.yaml'))
        .toList()
      ..sort();

    final families = await Future.wait(
      familyDirs.map((fdir) => SprawFamily.fromAssets(assets, fdir))
    );

    return SprawGroup(slug: slug, name: name, families: families);
  }
}

class SprawFamily {
  final String slug;
  final String name;
  final List<String> tags;
  final String fragment;
  final String fragmentAuthor;
  final List<SprawItem> items;

  SprawFamily({
    required this.slug,
    required this.name,
    required this.tags,
    required this.fragment,
    required this.fragmentAuthor,
    required this.items,
  });

  static Future<SprawFamily> fromAssets(Set<String> assets, String familyDir) async {
    final data = await _loadYaml('$familyDir/_data.yaml', assets);

    final slug = data['id'];
    final name = data['name'];
    final tags = data['tags'].toList().cast<String>();
    final fragment = data['fragment'] ?? '';
    final fragmentAuthor = data['fragmentAuthor'] ?? '';

    final dirDepth = familyDir.split('/').length;
    // Find item directories: <familyDir>/N@slug/_data.yaml
    final itemDirs = assets
        .where((p) {
          if (!p.startsWith('$familyDir/') || !p.endsWith('/_data.yaml')) return false;
          final parts = p.split('/');
          if (parts.length != dirDepth + 2) return false; // family/item/_data.yaml
          return RegExp(r'^\d+@').hasMatch(parts[dirDepth]);
        })
        .map((p) => _stripSuffix(p, '/_data.yaml'))
        .toList()
      ..sort();

    final items = await Future.wait(
      itemDirs.map((idir) => SprawItem.fromAssets(assets, idir))
    );

    return SprawFamily(
      slug: slug,
      name: name,
      tags: tags,
      fragment: fragment,
      fragmentAuthor: fragmentAuthor,
      items: items,
    );
  }
}

class SprawItem {
  final String slug;
  final String iconPath; // absolute asset path
  final String name;
  final int level;
  final List<String> tasks;

  SprawItem({
    required this.slug,
    required this.iconPath,
    required this.name,
    required this.level,
    required this.tasks,
  });

  static Future<SprawItem> fromAssets(Set<String> assets, String itemDir) async {
    final data = await _loadYaml('$itemDir/_data.yaml', assets);

    // icon can come from icon.yaml -> link or icon.svg file
    final iconYamlPath = '$itemDir/icon.yaml';
    final iconSvgPath = '$itemDir/icon.svg';

    String iconPath = '';
    if (assets.contains(iconYamlPath)) {
      final iconYaml = await _loadYaml(iconYamlPath, assets);
      final link = (iconYaml['link'] ?? '').toString();
      iconPath = _normalizeIconLink(link);
    } else if (assets.contains(iconSvgPath)) {
      iconPath = iconSvgPath;
    } else {
      throw StateError('Missing icon file in: $itemDir');
    }

    final slug = data['id'] ?? (throw StateError('Missing id in: $itemDir'));
    final name = data['name'] ?? (throw StateError('Missing name in: $itemDir'));
    final level = data['level'];
    final tasks = data['tasks'].toList().cast<String>();

    return SprawItem(
      slug: slug,
      iconPath: iconPath,
      name: name,
      level: level,
      tasks: tasks,
    );
  }
}

String _normalizeIconLink(String link) {
  if (link.isEmpty) return '';
  // some content may use common_new/ -> normalize to common/
  if (link.startsWith('common_new/')) {
    link = link.replaceFirst('common_new/', 'common/');
  }
  // if already an absolute asset path, leave it
  if (link.startsWith('packages/')) return link;
  if (link.startsWith('assets/')) return link;
  // otherwise assume relative to sprawnosci/ root (package base)
  return '$_assetsPackageBase/$link';
}

class SprawnosciRepositoryNew {
  Future<SprawBook> loadBook(String bookSlug) async {
    final assets = await _loadAssetManifest();
    final base = _resolveBaseForBook(bookSlug, assets);
    return SprawBook.fromAssets(assets, base);
  }
}
