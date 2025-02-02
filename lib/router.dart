import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:harcapp_core/dimen.dart';
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

import 'articles/_main.dart';
import 'articles/article_page.dart';
import 'home/_main.dart';
import 'konspekts/table_of_content_harcerskie_widget.dart';
import 'konspekts/table_of_content_ksztalcenie_widget.dart';

String pathHome = '/';
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
String pathPrivacyPolicy = '/privacy_policy';

TableOfContentHarcerskieWidget tableOfContentHarcerskieWidget(BuildContext context, bool isDrawer, Konspekt? selectedKonspekt) => TableOfContentHarcerskieWidget(
    selectedKonspekt: selectedKonspekt,
    padding: const EdgeInsets.all(Dimen.defMarg),
    onItemTap: (Konspekt konspekt){
        context.go(pathKonspektyHarcerskieItem.replaceAll(":name", konspekt.name));
        if(isDrawer) Navigator.pop(context);
    },
    withBackButton: isDrawer,
);

TableOfContentKsztalcenieWidget tableOfContentKsztalcenieWidget(BuildContext context, bool isDrawer, Konspekt? selectedKonspekt) => TableOfContentKsztalcenieWidget(
  selectedKonspekt: selectedKonspekt,
  padding: const EdgeInsets.all(Dimen.defMarg),
  onItemTap: (Konspekt konspekt){
    context.go(pathKonspektyKsztalcenieItem.replaceAll(":name", konspekt.name));
    if(isDrawer) Navigator.pop(context);
  },
  withBackButton: isDrawer,
);

TableOfContentPoradnikWidget tableOfContentPoradnikWidget(BuildContext context, bool isDrawer, Poradnik? selectedPoradnik) => TableOfContentPoradnikWidget(
    selectedPoradnik: selectedPoradnik,
    padding: const EdgeInsets.all(Dimen.defMarg),
    onItemTap: (Poradnik poradnik){
        context.go(pathPoradnikItem.replaceAll(":name", poradnik.name));
        if(isDrawer) Navigator.pop(context);
    },
    withBackButton: isDrawer,
);

GoRouter router = GoRouter(
    initialLocation: pathHome,
    routes: [
        ShellRoute(
            routes: [
                GoRoute(
                    path: pathHome,
                    pageBuilder: (context, state) => NoTransitionPage(child: HomePage())
                ),
                GoRoute(
                    path: pathKonspektyHarcerskie,
                    pageBuilder: (context, state) => NoTransitionPage(
                        child: KonspektsPage(
                            pathKonspektyHarcerskieItem,
                            allHarcerskieKonspekts,
                            tableOfContentBuilder: (bool isDrawer, Konspekt? selectedKonspekt) => tableOfContentHarcerskieWidget(
                              context,
                              isDrawer,
                              selectedKonspekt,
                            ),
                            key: ValueKey('konspekty harcerskie')
                        )
                    )
                ),
                GoRoute(
                    path: pathKonspektyHarcerskieItem,
                    pageBuilder: (context, state){
                        final name = state.pathParameters['name'];

                        Konspekt? selectedKonspekt = null;
                        try {
                          selectedKonspekt = allHarcerskieKonspekts.firstWhere((konspekt) => konspekt.name == name);
                        } on StateError {}
                        return NoTransitionPage(
                            child: KonspektsPage(
                                pathKonspektyHarcerskieItem,
                                allHarcerskieKonspekts,
                                selectedKonspekt: selectedKonspekt,
                                tableOfContentBuilder: (bool isDrawer, Konspekt? selectedKonspekt) => tableOfContentHarcerskieWidget(
                                  context,
                                  isDrawer,
                                  selectedKonspekt
                                ),
                                key: ValueKey('konspekty harcerskie')
                            )
                        );
                    }
                ),

                GoRoute(
                    path: pathKonspektyKsztalcenie,
                    pageBuilder: (context, state) => NoTransitionPage(
                        child: KonspektsPage(
                            pathKonspektyKsztalcenieItem,
                            allKsztalcenieKonspekts,
                            tableOfContentBuilder: (bool isDrawer, Konspekt? selectedKonspekt) => tableOfContentKsztalcenieWidget(
                              context,
                              isDrawer,
                              selectedKonspekt
                            ),
                            key: ValueKey('konspekty ksztalcenie')
                        )
                    )
                ),
                GoRoute(
                    path: pathKonspektyKsztalcenieItem,
                    pageBuilder: (context, state){
                        final name = state.pathParameters['name'];

                        Konspekt? selectedKonspekt = null;
                        try {
                          selectedKonspekt = allKsztalcenieKonspekts.firstWhere((konspekt) => konspekt.name == name);
                        } on StateError {}
                        return NoTransitionPage(
                            child: KonspektsPage(
                                pathKonspektyKsztalcenieItem,
                                allKsztalcenieKonspekts,
                                selectedKonspekt: selectedKonspekt,
                                tableOfContentBuilder: (bool isDrawer, Konspekt? selectedKonspekt) => tableOfContentKsztalcenieWidget(
                                  context,
                                  isDrawer,
                                  selectedKonspekt
                                ),
                                key: ValueKey('konspekty ksztalcenie')
                            )
                        );
                    }
                ),

                GoRoute(
                    path: pathPoradnik,
                    pageBuilder: (context, state) => NoTransitionPage(
                        child: PoradniksPage(
                            pathPoradnikItem,
                            allPoradniks,
                            tableOfContentBuilder: (bool isDrawer, Poradnik? selectedPoradnik) => tableOfContentPoradnikWidget(
                                context,
                                isDrawer,
                                selectedPoradnik
                            ),
                            key: ValueKey('poradnik')
                        )
                    )
                ),
                GoRoute(
                  path: pathPoradnikItem,
                  pageBuilder: (context, state){
                    final name = state.pathParameters['name'];

                    Poradnik? selectedPoradnik = null;
                    try {
                      selectedPoradnik = allPoradniks.firstWhere((poradnik) => poradnik.name == name);
                    } on StateError {}
                    return NoTransitionPage(
                        child: PoradniksPage(
                            pathKonspektyKsztalcenieItem,
                            allPoradniks,
                            selectedPoradnik: selectedPoradnik,
                            tableOfContentBuilder: (bool isDrawer, Poradnik? selectedPoradnik) => tableOfContentPoradnikWidget(
                                context,
                                isDrawer,
                                selectedPoradnik
                            ),
                            key: ValueKey('poradnik')
                        )
                    );
                  }
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
                    path: pathPrivacyPolicy,
                    pageBuilder: (context, state) => NoTransitionPage(child: PrivacyPolicyPage())
                ),
            ],
            builder: (context, state, child) => child
        )

    ]
);