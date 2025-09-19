part of '_main.dart';

/// Repository for loading sprawności (scout badges) data from assets.
class SprawnosciRepository {
  static const String defaultBookSlug = 'zhr_harc_c_sim_2023';
  static const String _assetsBasePath = 'packages/harcapp_core/assets/sprawnosci';
  
  // Cache to avoid reloading the same book repeatedly
  static Future<SprawBookData>? _cachedDefaultBook;

  /// Loads the default book of sprawności.
  Future<SprawBookData> loadDefaultBook() {
    return _cachedDefaultBook ??= loadBook(defaultBookSlug);
  }

  /// Loads a specific book of sprawności by its slug.
  Future<SprawBookData> loadBook(String bookSlug) async {
    final assetPaths = await _loadAssetManifest();
    final String base = '$_assetsBasePath/$bookSlug';

    // Load book metadata
    final bookYaml = await _loadYamlIfExists(assetPaths, '$base/_data.yaml');
    final bookName = (bookYaml?['name'] ?? bookSlug).toString();

    // Try to load groups with explicit YAML structure first
    var groups = await _loadExplicitGroups(assetPaths, base);
    
    // Fall back to inferring structure from directory layout if no explicit groups found
    if (groups.isEmpty) {
      groups = await _loadGroupsFromDirectoryStructure(assetPaths, base);
    }

    if (groups.isEmpty) {
      final underBase = assetPaths.where((k) => k.startsWith('$base/')).take(10).toList();
      throw StateError('No groups found in $base. Found ${underBase.length} assets under base (showing up to 10):\n' + underBase.join('\n'));
    }

    // Sort groups by name
    groups.sort((a, b) => a.name.compareTo(b.name));
    return SprawBookData(slug: bookSlug, name: bookName, groups: groups);
  }

  /// Loads the asset manifest and returns a set of all available asset paths.
  Future<Set<String>> _loadAssetManifest() async {
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      return manifest.listAssets().toSet();
    } catch (_) {
      // Fallback to legacy JSON manifest
      try {
        final manifestStr = await rootBundle.loadString('AssetManifest.json');
        final dynamic manifestJson = jsonDecode(manifestStr);
        
        if (manifestJson is Map<String, dynamic>) {
          return manifestJson.keys.toSet();
        } else if (manifestJson is List) {
          return manifestJson.cast<String>().toSet();
        } else if (manifestJson is Map && manifestJson.containsKey('assets')) {
          final assets = manifestJson['assets'] as List?;
          return assets?.cast<String>().toSet() ?? <String>{};
        }
      } catch (e) {
        debugPrint('Failed to load asset manifest: $e');
      }
      return <String>{};
    }
  }

  /// Loads groups using explicit YAML structure if available.
  Future<List<SprawGroupData>> _loadExplicitGroups(
    Set<String> assetPaths, 
    String basePath,
  ) async {
    final groups = <SprawGroupData>[];
    final baseDepth = basePath.split('/').length;
    
    // Find all group data files
    final groupDataFiles = assetPaths.where((path) => 
      path.startsWith('$basePath/') && 
      path.endsWith('/_data.yaml') && 
      path.contains('/group') && 
      path.split('/').length == baseDepth + 2
    );

    // Load each group and its families
    for (final groupDataFile in groupDataFiles) {
      final groupDir = groupDataFile.replaceAll('/_data.yaml', '');
      final groupYaml = await _loadYamlIfExists(assetPaths, groupDataFile);
      final groupSlug = _extractSlugFromPath(groupDir, groupYaml?['id']);
      final groupName = (groupYaml?['name'] ?? _formatNameFromSlug(groupSlug)).toString();

      // Load families for this group
      final families = await _loadFamiliesInDirectory(assetPaths, groupDir);
      groups.add(SprawGroupData(
        slug: groupSlug, 
        name: groupName, 
        families: families,
      ));
    }

    return groups;
  }

  /// Loads groups by inferring structure from directory layout.
  Future<List<SprawGroupData>> _loadGroupsFromDirectoryStructure(
    Set<String> assetPaths, 
    String basePath,
  ) async {
    final groups = <SprawGroupData>[];
    final itemDataRe = RegExp(
      r'^' + RegExp.escape('$basePath/') + r'group[^/]+/family[^/]+/\d+@[^/]+/_data\.yaml$'
    );

    // Find all item data files
    final itemFiles = assetPaths.where((path) => itemDataRe.hasMatch(path));

    // Group by group and family directories
    final groupMap = <String, Map<String, List<String>>>{};
    for (final path in itemFiles) {
      final parts = path.split('/');
      final groupDir = parts.sublist(0, parts.length - 3).join('/');
      final familyDir = parts.sublist(0, parts.length - 2).join('/');
      
      groupMap.putIfAbsent(groupDir, () => {});
      groupMap[groupDir]!.putIfAbsent(familyDir, () => []).add(path);
    }

    // Convert directory structure to group/family hierarchy
    for (final groupEntry in groupMap.entries) {
      final groupDir = groupEntry.key;
      final groupSlug = _extractSlugFromPath(groupDir);
      final groupName = _formatNameFromSlug(groupSlug);
      
      final families = await _loadFamiliesInDirectory(assetPaths, groupDir);
      groups.add(SprawGroupData(
        slug: groupSlug,
        name: groupName,
        families: families,
      ));
    }

    return groups;
  }

  /// Loads all families in a directory.
  Future<List<SprawFamilyData>> _loadFamiliesInDirectory(
    Set<String> assetPaths, 
    String dirPath,
  ) async {
    final familyDirs = assetPaths
        .where((path) => 
          path.startsWith('$dirPath/') && 
          path.contains('/family') && 
          path.endsWith('/_data.yaml')
        )
        .map((path) => path.replaceAll('/_data.yaml', ''))
        .toList();

    final families = await Future.wait(
      familyDirs.map((familyDir) => _loadFamily(assetPaths, familyDir))
    );
    
    families.sort((a, b) => a.name.compareTo(b.name));
    return families;
  }

  /// Loads a single family from a directory.
  Future<SprawFamilyData> _loadFamily(
    Set<String> assetPaths, 
    String familyDir,
  ) async {
    final familyYaml = await _loadYamlIfExists(assetPaths, '$familyDir/_data.yaml');
    final familySlug = _extractSlugFromPath(familyDir);
    final familyName = (familyYaml?['name'] ?? _formatNameFromSlug(familySlug)).toString();
    
    final tags = _parseStringList(familyYaml?['tags']);
    final fragment = (familyYaml?['fragment'] ?? '').toString();
    final fragmentAuthor = (familyYaml?['fragment_author'] ?? familyYaml?['fragmentAuthor'] ?? '').toString();
    
    final items = await _loadItemsForFamily(assetPaths, familyDir);
    
    return SprawFamilyData(
      slug: familySlug,
      name: familyName,
      tags: tags,
      fragment: fragment,
      fragmentAuthor: fragmentAuthor,
      items: items,
    );
  }

  /// Loads all items for a family.
  Future<List<SprawItemData>> _loadItemsForFamily(
    Set<String> assetPaths, 
    String familyDir,
  ) async {
    // Find all item data files in the family directory
    final itemDataFiles = assetPaths.where((path) {
      if (!path.startsWith('$familyDir/') || !path.endsWith('/_data.yaml')) {
        return false;
      }
      final parts = path.split('/');
      final familyDepth = familyDir.split('/').length;
      return parts.length == familyDepth + 2; // family/item/_data.yaml
    });

    // Load items concurrently
    final items = await Future.wait(
      itemDataFiles.map((path) => _loadItem(assetPaths, path))
    );
    
    // Sort items by level and name
    items.sort((a, b) {
      final levelCompare = a.level.compareTo(b.level);
      return levelCompare != 0 ? levelCompare : a.name.compareTo(b.name);
    });
    
    return items;
  }

  /// Loads a single item from a data file.
  Future<SprawItemData> _loadItem(
    Set<String> assetPaths, 
    String itemDataPath,
  ) async {
    final itemDir = itemDataPath.replaceAll('/_data.yaml', '');
    final itemYaml = await _loadYaml(assetPaths, itemDataPath);
    
    final itemSlug = _extractSlugFromPath(itemDir, itemYaml['id']);
    final itemName = (itemYaml['name'] ?? itemSlug).toString();
    final level = int.tryParse((itemYaml['level'] ?? '1').toString()) ?? 1;
    final tasks = _parseStringList(itemYaml['tasks']);
    
    // Find and load icon
    final iconPath = await _findItemIcon(assetPaths, itemDir, itemYaml);
    
    return SprawItemData(
      slug: itemSlug,
      iconPath: iconPath,
      name: itemName,
      level: level,
      tasks: tasks,
    );
  }

  /// Finds the appropriate icon for an item.
  Future<String> _findItemIcon(
    Set<String> assetPaths, 
    String itemDir, 
    dynamic itemYaml,
  ) async {
    // Check for icon defined in YAML
    final iconYamlPath = '$itemDir/icon.yaml';
    if (assetPaths.contains(iconYamlPath)) {
      try {
        final iconYaml = await _loadYaml(assetPaths, iconYamlPath);
        final link = (iconYaml['link'] ?? '').toString();
        if (link.isNotEmpty) {
          final mappedPath = _mapIconLinkToAsset(link);
          if (assetPaths.contains(mappedPath)) {
            return mappedPath;
          }
        }
      } catch (e) {
        debugPrint('Failed to load icon YAML at $iconYamlPath: $e');
      }
    }
    
    // Fall back to standard icon locations
    final svgPath = '$itemDir/icon.svg';
    final pngPath = '$itemDir/icon.png';
    
    if (assetPaths.contains(svgPath)) return svgPath;
    if (assetPaths.contains(pngPath)) return pngPath;
    
    return ''; // No icon found
  }

  /// Parses a YAML list or dynamic value into a list of strings.
  List<String> _parseStringList(dynamic value) {
    if (value == null) return const [];
    if (value is YamlList) return value.map((e) => e.toString()).toList().cast<String>();
    if (value is List) return value.map((e) => e.toString()).toList().cast<String>();
    return [];
  }

  /// Extracts a slug from a path, with an optional override value.
  String _extractSlugFromPath(String path, [dynamic overrideValue]) {
    if (overrideValue != null) return overrideValue.toString();
    
    // Takes last path segment, then returns substring after '@' and before '$' if present.
    final last = path.split('/').last;
    final atIdx = last.indexOf('@');
    String slug = atIdx >= 0 ? last.substring(atIdx + 1) : last;
    final dollarIdx = slug.indexOf(r'$');
    if (dollarIdx >= 0) slug = slug.substring(0, dollarIdx);
    return slug;
  }

  /// Formats a slug into a human-readable name.
  String _formatNameFromSlug(String slug) {
    return slug
        .replaceAll('_', ' ')
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + (w.length > 1 ? w.substring(1) : ''))
        .join(' ');
  }

  /// Maps an icon link to an asset path.
  String _mapIconLinkToAsset(String link) {
    if (link.isEmpty) return '';
    // Convert common_new/... paths to common/...
    final mapped = link.replaceFirst('common_new/', 'common/');
    return '$_assetsBasePath/$mapped';
  }

  /// Loads a YAML file if it exists in the asset paths.
  Future<YamlMap?> _loadYamlIfExists(Set<String> assetPaths, String path) async {
    if (!assetPaths.contains(path)) return null;
    try {
      return await _loadYaml(assetPaths, path);
    } catch (e) {
      debugPrint('Failed to load YAML at $path: $e');
      return null;
    }
  }

  /// Loads and parses a YAML file from assets.
  Future<YamlMap> _loadYaml(Set<String> assetPaths, String path) async {
    if (!assetPaths.contains(path)) {
      throw StateError('Asset not found: $path');
    }
    
    try {
      final content = await rootBundle.loadString(path);
      return loadYaml(content) as YamlMap;
    } catch (e) {
      throw StateError('Failed to parse YAML at $path: $e');
    }
  }
}
