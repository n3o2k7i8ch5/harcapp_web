import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:harcapp_web/songs/_main.dart';

import 'download_harcapp/_main.dart';
import 'top_navigation_bar.dart';

String pathDownload = '/download';
String pathSong = '/song';

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
          path: pathSong,
          pageBuilder: (context, state) => NoTransitionPage(child: SongsPage())
        ),
      ],
      builder: (context, state, child) => Scaffold(
        appBar: PreferredSize(
            preferredSize: Size(double.infinity, 92),
            child: TopNavigationBar()
        ),
        body: child,
      )
    )

  ]
);