import 'package:flutter/material.dart';
import 'package:harcapp_core/comm_classes/color_pack.dart';
import 'package:harcapp_core/song_book/song_contribution_widget.dart';
import 'package:harcapp_web/common/base_scaffold.dart';

class SongContributionRulesPage extends StatelessWidget {
  const SongContributionRulesPage({super.key});

  @override
  Widget build(BuildContext context) => BaseScaffold(
    backgroundColor: background_(context),
    body: Align(
      alignment: Alignment.topCenter,
      child: Container(
          constraints: BoxConstraints(
            maxWidth: 900,
          ),
          child: SongContributionWidget()
      ),
    ),
  );
}