import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:harcapp_core/values/dimen.dart';
import 'package:harcapp_core/values/store_urls.dart';
import 'package:harcapp_core/harcthought/articles/model/article_source.dart';
import 'package:harcapp_core/harcthought/konspekts/data/harcerskie/all.dart';
import 'package:harcapp_core/harcthought/konspekts/data/ksztalcenie/all.dart';
import 'package:harcapp_core/harcthought/konspekts/konspekt.dart';
import 'package:harcapp_core/harcthought/poradnik/data.dart';
import 'package:harcapp_core/harcthought/poradnik/poradnik.dart';
import 'package:harcapp_web/article_workspace/_main.dart';
import 'package:harcapp_web/konspekts/_main.dart';
import 'package:harcapp_web/poradniks/_main.dart';
import 'package:harcapp_web/poradniks/table_of_content_poradnik_widget.dart';
import 'package:harcapp_web/privacy_policy/_main.dart';
import 'package:harcapp_web/songs/_main.dart';
import 'package:harcapp_web/songs/song_contribution_rules_page.dart';
import 'package:harcapp_web/sprawnosci_page/_main.dart';
import 'package:harcapp_web/sprawnosci_page/family_page.dart';

import 'articles/_main.dart';
import 'articles/article_page.dart';
import 'home/_main.dart';
import 'konspekt_workspace/_main.dart';
import 'konspekts/table_of_content_harcerskie_widget.dart';
import 'konspekts/table_of_content_ksztalcenie_widget.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>();

String pathHome = '/';
String pathWarsztatKonspektow = '/konspekty/warsztat';
String pathKonspektyHarcerskie = '/konspekty/harcerskie';
String pathKonspektyHarcerskieItem = '/konspekty/harcerskie/:name';
String pathKonspektyKsztalcenie = '/konspekty/ksztalcenie';
String pathKonspektyKsztalcenieItem = '/konspekty/ksztalcenie/:name';
String pathPoradnik = '/poradnik';
String pathPoradnikItem = '/poradnik/:name';
String pathArticlesWorkspace = '/article_workspace';
String pathArticles = '/articles';
String pathArticlesSource = '/articles/:source';
String pathArticlesSourceItem = '/articles/:source/:localId';
String pathSong = '/song';
String pathSongContributionRules = '/song_contribution_rules';
String pathPrivacyPolicy = '/privacy_policy';
String pathSprawnosci = '/sprawnosci';
String pathSprawnosciBook = '/sprawnosci/:bookId';
String pathSprawnosciBookFamily = '/sprawnosci/:bookId/:familyId';
 String pathDownload = '/download';

// Removed pathSprawnosciFamily

TableOfContentHarcerskieWidget tableOfContentHarcerskieWidget(BuildContext context, bool isDrawer, Konspekt? selectedKonspekt) => TableOfContentHarcerskieWidget(
  selectedKonspekt: selectedKonspekt,
  padding: const EdgeInsets.all(Dimen.defMarg),
  onItemTap: (Konspekt konspekt){
    context.go(pathKonspektyHarcerskieItem.replaceAll(":name", konspekt.name));
  },
  withBackButton: isDrawer,
);

TableOfContentKsztalcenieWidget tableOfContentKsztalcenieWidget(BuildContext context, bool isDrawer, Konspekt? selectedKonspekt) => TableOfContentKsztalcenieWidget(
  selectedKonspekt: selectedKonspekt,
  padding: const EdgeInsets.all(Dimen.defMarg),
  onItemTap: (Konspekt konspekt){
    context.go(pathKonspektyKsztalcenieItem.replaceAll(":name", konspekt.name));
  },
  withBackButton: isDrawer,
);

TableOfContentPoradnikWidget tableOfContentPoradnikWidget(BuildContext context, bool isDrawer, Poradnik? selectedPoradnik) => TableOfContentPoradnikWidget(
  selectedPoradnik: selectedPoradnik,
  padding: const EdgeInsets.all(Dimen.defMarg),
  onItemTap: (Poradnik poradnik){
    context.go(pathPoradnikItem.replaceAll(":name", poradnik.name));
  },
  withBackButton: isDrawer,
);

class DownloadRedirectPage extends StatelessWidget {
  const DownloadRedirectPage({super.key});

  @override
  Widget build(BuildContext context) {
    final String ua = html.window.navigator.userAgent.toLowerCase();
    final bool isAndroid = ua.contains('android');
    final bool isIos = ua.contains('iphone') || ua.contains('ipad') || ua.contains('ipod');

    if (isAndroid) {
      html.window.location.assign(playStoreUrl);
    } else if (isIos) {
      html.window.location.assign(appStoreUrl);
    }

    final bool redirected = isAndroid || isIos;

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(Dimen.defMarg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                redirected ? 'Przekierowywanie...' : 'Wybierz sklep:',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Dimen.defMarg),
              Wrap(
                spacing: Dimen.defMarg,
                runSpacing: Dimen.defMarg,
                alignment: WrapAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () => html.window.location.assign(playStoreUrl),
                    child: const Text('Google Play'),
                  ),
                  ElevatedButton(
                    onPressed: () => html.window.location.assign(appStoreUrl),
                    child: const Text('App Store'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

List<RouteBase> _buildKonspektyRoutes({
  required String listPath,
  required String itemPath,
  required List<Konspekt> allKonspekts,
  required String keyBase,
  required Widget Function(BuildContext context, bool isDrawer, Konspekt? selectedKonspekt) tableOfContentBuilder,
}) => [
  GoRoute(
    path: listPath,
    pageBuilder: (context, state) => NoTransitionPage(
      child: KonspektsPage(
        itemPath,
        allKonspekts,
        tableOfContentBuilder: (bool isDrawer, Konspekt? selectedKonspekt) =>
            tableOfContentBuilder(context, isDrawer, selectedKonspekt),
        key: ValueKey(keyBase),
      ),
    ),
  ),
  GoRoute(
    path: itemPath,
    pageBuilder: (context, state) {
      final name = state.pathParameters['name'];

      Konspekt? selectedKonspekt;
      try {
        selectedKonspekt = allKonspekts.firstWhere((konspekt) => konspekt.name == name);
      } on StateError {}

      return NoTransitionPage(
        child: KonspektsPage(
          itemPath,
          allKonspekts,
          selectedKonspekt: selectedKonspekt,
          tableOfContentBuilder: (bool isDrawer, Konspekt? selectedKonspekt) =>
              tableOfContentBuilder(context, isDrawer, selectedKonspekt),
          key: ValueKey('$keyBase $name'),
        ),
      );
    },
  ),
];

List<RouteBase> _buildPoradnikRoutes({
  required String listPath,
  required String itemPath,
  required List<Poradnik> allPoradniks,
  required String keyBase,
  required Widget Function(BuildContext context, bool isDrawer, Poradnik? selectedPoradnik) tableOfContentBuilder,
}) => [
  GoRoute(
    path: listPath,
    pageBuilder: (context, state) => NoTransitionPage(
      child: PoradniksPage(
        itemPath,
        allPoradniks,
        tableOfContentBuilder: (bool isDrawer, Poradnik? selectedPoradnik) =>
            tableOfContentBuilder(context, isDrawer, selectedPoradnik),
        key: ValueKey(keyBase),
      ),
    ),
  ),
  GoRoute(
    path: itemPath,
    pageBuilder: (context, state) {
      final name = state.pathParameters['name'];

      Poradnik? selectedPoradnik;
      try {
        selectedPoradnik = allPoradniks.firstWhere((poradnik) => poradnik.name == name);
      } on StateError {}

      return NoTransitionPage(
        child: PoradniksPage(
          itemPath,
          allPoradniks,
          selectedPoradnik: selectedPoradnik,
          tableOfContentBuilder: (bool isDrawer, Poradnik? selectedPoradnik) =>
              tableOfContentBuilder(context, isDrawer, selectedPoradnik),
          key: ValueKey('$keyBase $name'),
        ),
      );
    },
  ),
];

GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: pathHome,
    routes: [
      ShellRoute(
          navigatorKey: _shellNavigatorKey,
          routes: [
            GoRoute(
                path: pathHome,
                pageBuilder: (context, state) => NoTransitionPage(child: HomePage())
            ),
            GoRoute(
                name: 'konspektWorkspace',
                path: pathWarsztatKonspektow,
                pageBuilder: (context, state) => NoTransitionPage(
                    child: KonspektWorkspacePage(
                        key: ValueKey('warsztat konspektów')
                    )
                ),
                routes: [
                  GoRoute(
                    name: 'konspektWorkspacePreview',
                    path: 'preview',
                    parentNavigatorKey: _rootNavigatorKey,
                    pageBuilder: (context, state) {
                      final Konspekt? konspekt = state.extra as Konspekt?;

                      return CustomTransitionPage(
                        opaque: false,
                        barrierDismissible: true,
                        barrierColor: Colors.black54,
                        child: konspekt == null
                            ? const SizedBox.shrink()
                            : KonspektPreviewRoutePage(konspekt: konspekt),
                        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
                            FadeTransition(opacity: animation, child: child),
                      );
                    },
                  ),
                ],
            ),
            ..._buildKonspektyRoutes(
              listPath: pathKonspektyHarcerskie,
              itemPath: pathKonspektyHarcerskieItem,
              allKonspekts: allHarcerskieKonspekts,
              keyBase: 'konspekty harcerskie',
              tableOfContentBuilder: tableOfContentHarcerskieWidget,
            ),

            ..._buildKonspektyRoutes(
              listPath: pathKonspektyKsztalcenie,
              itemPath: pathKonspektyKsztalcenieItem,
              allKonspekts: allKsztalcenieKonspekts,
              keyBase: 'konspekty ksztalcenie',
              tableOfContentBuilder: tableOfContentKsztalcenieWidget,
            ),

            ..._buildPoradnikRoutes(
              listPath: pathPoradnik,
              itemPath: pathPoradnikItem,
              allPoradniks: allPoradniks,
              keyBase: 'poradnik',
              tableOfContentBuilder: tableOfContentPoradnikWidget,
            ),

            GoRoute(
                path: pathArticles,
                pageBuilder: (context, state) => NoTransitionPage(child: ArticlesPage())
            ),
            GoRoute(
                path: pathArticlesSource,
                pageBuilder: (context, state){
                  final String sourceName = state.pathParameters['source']!;
                  ArticleSource? source = ArticleSource.fromName(sourceName);
                  return NoTransitionPage(child: ArticlesPage(source: source));
                }
            ),
            GoRoute(
                path: pathArticlesSourceItem,
                pageBuilder: (context, state){
                  final String sourceName = state.pathParameters['source']!;
                  final String localId = state.pathParameters['localId']!;
                  ArticleSource? source = ArticleSource.fromName(sourceName);
                  if(source == null) return NoTransitionPage(child: ArticlesPage());

                  // Get current path
                  return NoTransitionPage(
                      child: ArticlePage(source: source, localId: localId)
                  );
                }
            ),


            GoRoute(
                path: pathArticlesWorkspace,
                pageBuilder: (context, state) => NoTransitionPage(child: ArticleWorkspacePage())
            ),

            GoRoute(
                path: pathSong,
                pageBuilder: (context, state) => NoTransitionPage(child: SongsPage())
            ),
            GoRoute(
                path: pathSongContributionRules,
                pageBuilder: (context, state) => NoTransitionPage(child: SongContributionRulesPage())
            ),
            GoRoute(
                path: pathSprawnosci,
                pageBuilder: (context, state) => NoTransitionPage(
                  child: SprawnosciPage(),
                )
            ),
            GoRoute(
              path: pathDownload,
              pageBuilder: (context, state) => const NoTransitionPage(
                child: DownloadRedirectPage(),
              ),
            ),
            GoRoute(
              path: pathSprawnosciBook,
              pageBuilder: (context, state) => NoTransitionPage(
                child: SprawnosciPage(
                  initialBookSlug: state.pathParameters['bookId'],
                ),
              ),
              routes: [
                GoRoute(
                  path: ':group/:family',
                  pageBuilder: (context, state) {
                    return NoTransitionPage(
                      child: SprawnosciFamilyPage(
                        bookSlug: state.pathParameters['bookId']!,
                        groupSlug: state.pathParameters['group']!,
                        familySlug: state.pathParameters['family']!,
                      ),
                    );
                  },
                ),
              ],
            ),
            GoRoute(
                path: pathPrivacyPolicy,
                pageBuilder: (context, state) => NoTransitionPage(child: PrivacyPolicyPage())
            ),
          ],
          builder: (context, state, child) => child
      )

    ]
);