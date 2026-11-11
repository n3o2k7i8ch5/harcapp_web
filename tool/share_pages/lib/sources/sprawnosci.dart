import 'dart:io';

import 'package:harcapp_core/harcthought/harcapp_links.dart';
import 'package:sprawnosci_data/sprawnosci_assets.dart';

import '../template.dart';

/// The sprawności list (/sprawnosci), a page per book the web app shows and
/// per family of badges, with the badges' requirements as text. Read with the
/// same reader and at the same paths as the app, from the built assets.
Future<int> generateSprawnosciPages({
  required String buildDir,
  required ShareTemplate template,
}) async {
  final coverUrl = '${HarcappLinks.baseUrl}/icons/icon-512.png';
  final reader = _readerOfBuild(buildDir);
  final listText = HtmlText()..h1('Sprawności harcerskie');
  int count = 0;

  for (final bookSlug in sprawWebBookSlugs) {
    final book = await reader.loadBook(bookSlug);
    final bookPath = HarcappLinks.sprawnosciBookPath(book.slug);
    final bookText = HtmlText()
      ..h1(book.name)
      ..p(book.source);

    for (final group in book.groups) {
      bookText.h2(group.name);
      for (final family in group.families) {
        final familyPath = HarcappLinks.sprawnosciFamilyPath(
            book.slug, group.slug, family.slug);
        final items = family.itemsByLevel;
        final names = items.map((i) => i.name).join(', ');

        final text = HtmlText()
          ..h1('${family.name} – sprawności')
          ..p(book.name)
          ..p(family.fragment)
          ..p(family.fragmentAuthor);
        for (final item in items) {
          text
            ..h2(item.name)
            ..list(item.tasks, ordered: true);
        }
        text.link(bookPath, book.name);

        writePage(
          buildDir,
          familyPath,
          template.render(
            pageUrl: '${HarcappLinks.baseUrl}$familyPath',
            pageTitle: '${family.name}: $names – wymagania sprawności',
            pageDescription: 'Wymagania sprawności $names '
                '(„${family.name}”, ${book.name}) w HarcApp.',
            coverUrl: coverUrl,
            content: text.toString(),
          ),
        );
        count++;
        bookText.link(familyPath, '${family.name}: $names');
      }
    }

    writePage(
      buildDir,
      bookPath,
      template.render(
        pageUrl: '${HarcappLinks.baseUrl}$bookPath',
        pageTitle: book.name,
        pageDescription:
            '${book.name} – wszystkie sprawności i ich wymagania w HarcApp.',
        coverUrl: coverUrl,
        content: bookText.toString(),
      ),
    );
    count++;
    listText.link(bookPath, book.name);
  }

  writePage(
    buildDir,
    HarcappLinks.sprawnosciListTemplate,
    template.render(
      pageUrl: HarcappLinks.sprawnosciList(),
      pageTitle: 'Sprawności harcerskie – wymagania',
      pageDescription:
          'Sprawności harcerskie z wymaganiami na każdy stopień, w HarcApp.',
      coverUrl: coverUrl,
      content: listText.toString(),
    ),
  );
  return count + 1;
}

/// The sprawności assets of `flutter build web`, named as the app's asset
/// manifest names them.
SprawAssets _readerOfBuild(String buildDir) {
  final assetsDir = '$buildDir/assets';
  final root = Directory('$assetsDir/$sprawAssetsBase');
  if (!root.existsSync()) {
    throw StateError('Sprawności assets not found at ${root.path}');
  }
  final assets = root
      .listSync(recursive: true)
      .whereType<File>()
      .map((f) => f.path.substring(assetsDir.length + 1))
      .toSet();
  return SprawAssets(
      assets, (path) => File('$assetsDir/$path').readAsString());
}
