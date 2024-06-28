import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:harcapp_core/harcthought/konspekts/data/basic.dart';
import 'package:harcapp_core/harcthought/konspekts/data/ksztalcenie/all.dart';
import 'package:harcapp_core/harcthought/konspekts/konspekt.dart';
import 'package:harcapp_web/konspekts/_main.dart';
import 'package:harcapp_web/privacy_policy/_main.dart';
import 'package:harcapp_web/songs/_main.dart';

import 'home/_main.dart';

String pathHome = '/';
String pathKonspektyHarcerskie = '/konspekty/harcerskie';
String pathKonspektyHarcerskieItem = '/konspekty/harcerskie/:name';
String pathKonspektyKsztalcenie = '/konspekty/ksztalcenie';
String pathKonspektyKsztalcenieItem = '/konspekty/ksztalcenie/:name';
String pathSong = '/song';
String pathPrivacyPolicy = '/privacy_policy';

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
                        child: KonspektsPage(pathKonspektyHarcerskieItem, allBasicKonspekts, key: ValueKey('harcerskie'))
                    )
                ),
                GoRoute(
                    path: pathKonspektyHarcerskieItem,
                    pageBuilder: (context, state){
                        final name = state.pathParameters['name'];

                        Konspekt? selectedKonspekt = null;
                        try {
                          selectedKonspekt = allBasicKonspekts.firstWhere((konspekt) => konspekt.name == name);
                        } on StateError {}
                        return NoTransitionPage(
                            child: KonspektsPage(
                                pathKonspektyHarcerskieItem,
                                allBasicKonspekts,
                                selectedKonspekt: selectedKonspekt,
                                key: ValueKey('harcerskie')
                            )
                        );
                    }
                ),
                GoRoute(
                    path: pathKonspektyKsztalcenie,
                    pageBuilder: (context, state) => NoTransitionPage(
                        child: KonspektsPage(pathKonspektyKsztalcenieItem, allKsztalcenieKonspekts, key: ValueKey('ksztalcenie')
                        )
                    )
                ),
                GoRoute(
                    path: pathKonspektyHarcerskieItem,
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
                                key: ValueKey('ksztalcenie')
                            )
                        );
                    }
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