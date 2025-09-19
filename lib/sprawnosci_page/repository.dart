part of '_main.dart';

class SprawnosciRepository {
  static const String defaultBookSlug = 'zhr_harc_c_sim_2023';

  // Cache to avoid reloading the same book repeatedly
  static Future<SprawBookData>? _cachedDefaultBook;

  Future<SprawBookData> loadDefaultBook() {
    return _cachedDefaultBook ??= loadBook(defaultBookSlug);
  }

  Future<SprawBookData> loadBook(String bookSlug) async {
    // Read the compiled asset manifest to know what files are available.
    final Set<String> assetPaths = <String>{};
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      assetPaths.addAll(manifest.listAssets());
    } catch (_) {
      // Fallback to legacy JSON name/format
      try {
        final manifestStr = await rootBundle.loadString('AssetManifest.json');
        final dynamic manifestJson = jsonDecode(manifestStr);
        if (manifestJson is Map<String, dynamic>) {
          assetPaths.addAll(manifestJson.keys.cast<String>());
        } else if (manifestJson is List) {
          assetPaths.addAll(manifestJson.cast<String>());
        } else if (manifestJson is Map && manifestJson.containsKey('assets')) {
          final assets = manifestJson['assets'];
          if (assets is List) assetPaths.addAll(assets.cast<String>());
        }
      } catch (_) {}
    }

    final String base = 'packages/harcapp_core/assets/sprawnosci/$bookSlug';

    // Helper: list manifest keys under a directory.
    Iterable<String> under(String dir) => assetPaths.where((k) => k.startsWith(dir));

    // Book data (guard to avoid 404 logs on web)
    final bookDataPath = '$base/_data.yaml';
    final bookYaml = assetPaths.contains(bookDataPath)
        ? await _loadYaml(bookDataPath)
        : null;
    final bookName = (bookYaml?['name'] ?? bookSlug).toString();

    // Attempt discovery via explicit group/family YAMLs
    final List<SprawGroupData> groups = [];

    // Helper that loads items for a given familyDir
    Future<List<SprawItemData>> loadItemsForFamily(String familyDir) async {
      final RegExp itemDataRe = RegExp(r'^' + RegExp.escape('$familyDir/') + r'(\d+)@[^/]+/_data\.yaml$');
      Iterable<String> itemDataFiles = under('$familyDir/').where((k) => itemDataRe.hasMatch(k));
      if (itemDataFiles.isEmpty) {
        final familyDepth = '$familyDir'.split('/').length;
        itemDataFiles = under('$familyDir/').where((k) {
          if (!k.endsWith('/_data.yaml')) return false;
          if (!k.startsWith('$familyDir/')) return false;
          final depth = k.split('/').length;
          return depth == familyDepth + 2;
        });
      }
      // Load items concurrently
      final items = await Future.wait(itemDataFiles.map((itemDataFile) async {
        final itemDir = itemDataFile.substring(0, itemDataFile.length - '/_data.yaml'.length);
        final itemYaml = await _loadYaml(itemDataFile);
        final itemSlug = (itemYaml['id'] ?? _slugFromDir(itemDir)).toString();
        final itemName = (itemYaml['name'] ?? itemSlug).toString();
        final int level = int.tryParse((itemYaml['level'] ?? '1').toString()) ?? 1;
        final dynamic tasksRaw = itemYaml['tasks'];
        final List<String> tasks = tasksRaw == null
            ? const <String>[]
            : (tasksRaw is YamlList
                ? tasksRaw.map((e) => e.toString()).toList().cast<String>()
                : (tasksRaw as List).map((e) => e.toString()).toList().cast<String>());

        String iconPath = '';
        final iconYamlPath = '$itemDir/icon.yaml';
        if (assetPaths.contains(iconYamlPath)) {
          final iconYaml = await _loadYaml(iconYamlPath);
          final link = (iconYaml['link'] ?? '').toString();
          final mapped = _mapIconLinkToAsset(link);
          if (assetPaths.contains(mapped)) {
            iconPath = mapped;
          }
        }
        if (iconPath.isEmpty) {
          final svgPath = '$itemDir/icon.svg';
          final pngPath = '$itemDir/icon.png';
          if (assetPaths.contains(svgPath)) iconPath = svgPath;
          else if (assetPaths.contains(pngPath)) iconPath = pngPath;
        }

        return SprawItemData(
          slug: itemSlug,
          iconPath: iconPath,
          name: itemName,
          level: level,
          tasks: tasks,
        );
      }));
      items.sort((a, b) {
        final byLevel = a.level.compareTo(b.level);
        if (byLevel != 0) return byLevel;
        return a.name.compareTo(b.name);
      });
      return items;
    }

    // First try with explicit group and family YAMLs if present
        {
      final baseDepth = '$base'.split('/').length;
      final groupDataFiles = under('$base/').where((k) => k.endsWith('/_data.yaml') && k.contains('/group') && k.split('/').length == baseDepth + 2);
      for (final groupDataFile in groupDataFiles) {
        final groupDir = groupDataFile.substring(0, groupDataFile.length - '/_data.yaml'.length);
        final groupYaml = await _loadYamlIfExists(groupDataFile);
        final groupSlug = groupYaml != null ? (groupYaml['id'] ?? _slugFromDir(groupDir)).toString() : _slugFromDir(groupDir);
        final groupName = groupYaml != null ? (groupYaml['name'] ?? groupSlug).toString() : _nameFromSlug(groupSlug);

        final groupDepth = '$groupDir'.split('/').length;
        final familyDataFiles = under('$groupDir/').where((k) => k.endsWith('/_data.yaml') && k.contains('/family') && k.split('/').length == groupDepth + 2);
        final List<SprawFamilyData> families = await Future.wait(familyDataFiles.map((familyDataFile) async {
          final familyDir = familyDataFile.substring(0, familyDataFile.length - '/_data.yaml'.length);
          final familySlug = _slugFromDir(familyDir);

          final familyYaml = await _loadYamlIfExists(familyDataFile);
          final familyName = familyYaml != null
              ? (familyYaml['name'] ?? _nameFromSlug(familySlug)).toString()
              : _nameFromSlug(familySlug);
          final dynamic rawTags = familyYaml?['tags'];
          final List<String> tags = rawTags == null
              ? const <String>[]
              : (rawTags is YamlList
                  ? rawTags.map((e) => e.toString()).toList().cast<String>()
                  : rawTags is List
                      ? rawTags.map((e) => e.toString()).toList().cast<String>()
                      : const <String>[]);
          final String fragment = familyYaml == null ? '' : (familyYaml['fragment'] ?? '').toString();
          final String fragmentAuthor = familyYaml == null ? '' : (familyYaml['fragment_author'] ?? familyYaml['fragmentAuthor'] ?? '').toString();

          final items = await loadItemsForFamily(familyDir);
          return SprawFamilyData(slug: familySlug, name: familyName, tags: tags, fragment: fragment, fragmentAuthor: fragmentAuthor, items: items);
        }));
        families.sort((a, b) => a.name.compareTo(b.name));
        groups.add(SprawGroupData(slug: groupSlug, name: groupName, families: families));
      }
    }

    // If no explicit group YAMLs found, infer structure from item paths present in manifest
    if (groups.isEmpty) {
      // Collect all item _data.yaml under base
      final itemDataRe = RegExp(r'^' + RegExp.escape('$base/') + r'group[^/]+/family[^/]+/\d+@[^/]+/_data\.yaml$');
      final itemFiles = under('$base/').where((p) => itemDataRe.hasMatch(p)).toList()..sort();
      // Derive families and groups
      final Map<String, Map<String, List<String>>> grouped = {};
      for (final path in itemFiles) {
        final parts = path.split('/');
        // indices: ... base group family item _data.yaml
        final groupDir = parts.sublist(0, parts.length - 3).join('/'); // up to group dir
        final familyDir = parts.sublist(0, parts.length - 2).join('/'); // up to family dir
        grouped.putIfAbsent(groupDir, () => {});
        grouped[groupDir]!.putIfAbsent(familyDir, () => []);
        grouped[groupDir]![familyDir]!.add(path);
      }
      for (final entry in grouped.entries) {
        final groupDir = entry.key;
        final groupSlug = _slugFromDir(groupDir);
        final groupName = _nameFromSlug(groupSlug);
        final List<SprawFamilyData> families = await Future.wait(entry.value.entries.map((fEntry) async {
          final familyDir = fEntry.key;
          final familySlug = _slugFromDir(familyDir);

          final familyYamlPath = '$familyDir/_data.yaml';
          final familyYaml = assetPaths.contains(familyYamlPath)
              ? await _loadYaml(familyYamlPath)
              : null;
          final familyName = familyYaml != null
              ? (familyYaml['name'] ?? _nameFromSlug(familySlug)).toString()
              : _nameFromSlug(familySlug);
          final dynamic rawTags = familyYaml?['tags'];
          final List<String> tags = rawTags == null
              ? const <String>[]
              : (rawTags is YamlList
                  ? rawTags.map((e) => e.toString()).toList().cast<String>()
                  : rawTags is List
                      ? rawTags.map((e) => e.toString()).toList().cast<String>()
                      : const <String>[]);
          final String fragment = familyYaml == null ? '' : (familyYaml['fragment'] ?? '').toString();
          final String fragmentAuthor = familyYaml == null ? '' : (familyYaml['fragment_author'] ?? familyYaml['fragmentAuthor'] ?? '').toString();

          final items = await loadItemsForFamily(familyDir);
          return SprawFamilyData(slug: familySlug, name: familyName, tags: tags, fragment: fragment, fragmentAuthor: fragmentAuthor, items: items);
        }));
        families.sort((a, b) => a.name.compareTo(b.name));
        groups.add(SprawGroupData(slug: groupSlug, name: groupName, families: families));
      }
    }

    // If still nothing, surface a helpful error for diagnostics
    if (groups.isEmpty) {
      final underBase = assetPaths.where((k) => k.startsWith('$base/')).take(10).toList();
      throw StateError('No groups found in $base. Found ${underBase.length} assets under base (showing up to 10):\n' + underBase.join('\n'));
    }

    // Sort groups by name
    groups.sort((a, b) => a.name.compareTo(b.name));

    return SprawBookData(slug: bookSlug, name: bookName, groups: groups);
  }

  Future<YamlMap?> _loadYamlIfExists(String path) async {
    try {
      final content = await rootBundle.loadString(path);
      return loadYaml(content) as YamlMap;
    } catch (_) {
      return null;
    }
  }

  Future<YamlMap> _loadYaml(String path) async {
    final content = await rootBundle.loadString(path);
    return loadYaml(content) as YamlMap;
  }

  String _slugFromDir(String dir) {
    // Takes last path segment, then returns substring after '@' and before '$' if present.
    final last = dir.split('/').last;
    final atIdx = last.indexOf('@');
    String s = atIdx >= 0 ? last.substring(atIdx + 1) : last;
    final dollarIdx = s.indexOf(r'$');
    if (dollarIdx >= 0) s = s.substring(0, dollarIdx);
    return s;
  }

  String _mapIconLinkToAsset(String link) {
    if (link.isEmpty) return '';
    // Links look like: common_new/zhr_common/.../file.svg
    // Our assets contain: assets/sprawnosci/common/zhr_common/.../file.svg
    String mapped = link.replaceFirst('common_new/', 'common/');
    return 'packages/harcapp_core/assets/sprawnosci/$mapped';
  }

  String _nameFromSlug(String slug) {
    // Simple prettifier: replace underscores with spaces and title-case words
    return slug
        .replaceAll('_', ' ')
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + (w.length > 1 ? w.substring(1) : ''))
        .join(' ');
  }
}
