import 'package:flutter/material.dart';
import 'package:harcapp_core/comm_classes/app_navigator.dart';
import 'package:harcapp_core/comm_classes/sha_pref.dart';
import 'package:harcapp_core/song_book/song_contribution_rules.dart';
import 'package:harcapp_core/comm_widgets/dialog/alert_dialog.dart';
import 'package:harcapp_web/common/open_in_new_tab.dart';
import 'package:harcapp_web/common/sha_pref.dart';
import 'package:go_router/go_router.dart';
import 'package:harcapp_web/router.dart';

class SongContributionRulesAcceptanceManager {

  static String? get acceptedRulesVersion => ShaPref.getStringOrNull(SHA_PREF_SONG_CONTRIBUTION_RULES_VERSION);
  static set acceptedRulesVersion(String? value){
    if(value != null)
      ShaPref.setString(SHA_PREF_SONG_CONTRIBUTION_RULES_VERSION, value);
  }

  static bool get isAccepted => acceptedRulesVersion == latestSongContributionRulesVersion;
  static set isAccepted(bool value) => acceptedRulesVersion = value ? latestSongContributionRulesVersion : null;

  // Znam i akceptuję zasady dodawania piosenek do aplikacji HarcApp

  static Future<void> ensureRulesAccepted(BuildContext context) async {

    if (isAccepted)
      return;

    await showAlertDialog(
      context,
      title: 'Kilka formalności...',
      dismissible: false,
      content: 'Znam i akceptuję zasady dodawania piosenek do aplikacji HarcApp.',
      actionBuilder: (context) => [
        AlertDialogButton(
          text: 'Zobacz zasady',
          onTap: () => openPathInNewTab(pathSongContributionRules),
        ),
        AlertDialogButton(
          text: 'Akceptuję',
          onTap: () {
            isAccepted = true;
            popPage(context);
          },
        ),
      ],
    );

    if(!isAccepted)
      context.go(pathHome);

  }
}