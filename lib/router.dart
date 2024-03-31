import 'package:go_router/go_router.dart';
import 'package:harcapp_web/konspekts/_main.dart';
import 'package:harcapp_web/privacy_policy/_main.dart';
import 'package:harcapp_web/songs/_main.dart';

import 'download_harcapp/_main.dart';

String pathDownload = '/download';
String pathKonspekty = '/konspekty';
String pathSong = '/song';
String pathPrivacyPolicy = '/privacy_policy';

GoRouter router = GoRouter(
  initialLocation: pathDownload,
  routes: [
    ShellRoute(
      routes: [
        GoRoute(
          path: pathDownload,
          pageBuilder: (context, state) => NoTransitionPage(child: DownloadHarcAppPage())
        ),
        GoRoute(
          path: pathKonspekty,
          pageBuilder: (context, state) => NoTransitionPage(child: KonspektsPage())
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