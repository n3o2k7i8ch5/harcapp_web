class SprawBookData {
  final String slug;
  final String name;
  final List<SprawGroupData> groups;
  SprawBookData({required this.slug, required this.name, required this.groups});
}

class SprawGroupData {
  final String slug;
  final String name;
  final List<SprawFamilyData> families;
  SprawGroupData({required this.slug, required this.name, required this.families});
}

class SprawFamilyData {
  final String slug;
  final String name;
  final List<String> tags;
  final String fragment;
  final String fragmentAuthor;
  final List<SprawItemData> items;
  SprawFamilyData({
    required this.slug,
    required this.name,
    required this.tags,
    required this.fragment,
    required this.fragmentAuthor,
    required this.items,
  });
}

class SprawItemData {
  final String slug;
  final String iconPath;
  final String name;
  final int level;
  final List<String> tasks;
  SprawItemData({
    required this.slug,
    required this.iconPath,
    required this.name,
    required this.level,
    required this.tasks,
  });
}
