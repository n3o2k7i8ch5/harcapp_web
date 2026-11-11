import 'package:harcapp_core/harcthought/harcapp_links.dart';

import '../template.dart';

/// Main pages without data of their own, as the app routes them: each gets its
/// own title, description and canonical URL (instead of the home page's).
const List<(String path, String title, String description)> _sections = [
  (
    HarcappLinks.articleListTemplate,
    'Artykuły harcerskie',
    'Artykuły o harcerstwie z Azymutu, Pojutrza i HarcApp w jednym miejscu.',
  ),
  (
    HarcappLinks.songContributionTemplate,
    'Śpiewnik HarcApp – dodaj piosenkę',
    'Dodaj lub popraw piosenkę w śpiewniku HarcApp: tekst, chwyty i opis.',
  ),
  (
    HarcappLinks.songContributionRulesTemplate,
    'Zasady dodawania piosenek – śpiewnik HarcApp',
    'Jak przygotować piosenkę do śpiewnika HarcApp.',
  ),
  (
    HarcappLinks.konspektWorkspaceTemplate,
    'Warsztat konspektów – HarcApp',
    'Napisz własny konspekt zbiórki lub zajęć w HarcApp.',
  ),
  (
    HarcappLinks.privacyPolicyTemplate,
    'Polityka prywatności – HarcApp',
    'Polityka prywatności aplikacji HarcApp.',
  ),
];

int generateSectionPages({
  required String buildDir,
  required ShareTemplate template,
}) {
  for (final (path, title, description) in _sections) {
    writePage(
      buildDir,
      path,
      template.render(
        pageUrl: '${HarcappLinks.baseUrl}$path',
        pageTitle: title,
        pageDescription: description,
        coverUrl: '${HarcappLinks.baseUrl}/icons/icon-512.png',
      ),
    );
  }
  return _sections.length;
}
