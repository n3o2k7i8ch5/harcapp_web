import 'package:flutter/material.dart';
import 'package:harcapp_core/comm_classes/app_navigator.dart';
import 'package:harcapp_core/comm_classes/app_text_style.dart';
import 'package:harcapp_core/comm_classes/color_pack.dart';
import 'package:harcapp_core/comm_classes/date_to_str.dart';
import 'package:harcapp_core/comm_classes/regexp_email.dart';
import 'package:harcapp_core/comm_widgets/app_bar.dart';
import 'package:harcapp_core/comm_widgets/app_button.dart';
import 'package:harcapp_core/comm_widgets/app_card.dart';
import 'package:harcapp_core/comm_widgets/app_text_field_hint.dart';
import 'package:harcapp_core/comm_widgets/simple_button.dart';
import 'package:harcapp_core/song_book/song_contribution_rules.dart';
import 'package:harcapp_core/song_book/song_core.dart';
import 'package:harcapp_core/song_book/song_editor/providers.dart';
import 'package:harcapp_core/song_book/song_editor/song_raw.dart';
import 'package:harcapp_core/values/dimen.dart';
import 'package:harcapp_web/consts.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class ContribRulesDialog extends StatefulWidget {

  final SongRaw song;

  const ContribRulesDialog({super.key, required this.song});

  @override
  State<StatefulWidget> createState() => ContribRulesDialogState();

}

class ContribRulesDialogState extends State<ContribRulesDialog> {

  SongRaw get song => widget.song;

  late TextEditingController emailController;
  late DateTime contributionDate;
  late String? acceptedRulesVersion;

  @override
  void initState() {
    emailController = TextEditingController(text: song.contributorData?.email);
    contributionDate = song.contributorData?.contributionDate ?? DateTime.now();
    acceptedRulesVersion = song.contributorData?.acceptedContributionRulesVersion;
    super.initState();
  }

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      constraints: BoxConstraints(maxWidth: songDialogWidth),
      child: Padding(
        padding: EdgeInsets.all(Dimen.sideMarg),
        child: Material(
          elevation: 6.0,
          clipBehavior: Clip.hardEdge,
          borderRadius: BorderRadius.circular(AppCard.bigRadius),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              AppBarX(
                title: 'Potwierdź regulamin',
                clipBehavior: Clip.none,
                actions: [
                  AppButton(
                    icon: Icon(
                      MdiIcons.check,
                      color: acceptedRulesVersion==null || !regExpEmail.hasMatch(emailController.text)?iconDisab_(context):iconEnab_(context),
                    ),
                    onTap: acceptedRulesVersion==null || !regExpEmail.hasMatch(emailController.text)?null:(){
                      song.contributorData = ContributorData(
                        email: emailController.text.trim(),
                        contributionDate: contributionDate,
                        acceptedContributionRulesVersion: acceptedRulesVersion!,
                      );
                      CurrentItemProvider.notify_(context);
                      popPage(context);
                    },
                  )
                ],
              ),

              Padding(
                padding: EdgeInsets.all(Dimen.sideMarg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    Row(
                      children: [
                        Expanded(
                          child: AppTextFieldHint(
                            hint: 'Email:',
                            controller: emailController,
                            onChanged: (_, text) => setState(() {}),
                            keyboardType: TextInputType.emailAddress,
                          ),
                        ),
                        if(emailController.text.isNotEmpty && !regExpEmail.hasMatch(emailController.text))
                          Tooltip(
                            child: Icon(MdiIcons.alertCircleOutline, color: Colors.red),
                            message: 'Podaj poprawny adres email.',
                          )
                      ],
                    ),

                    SizedBox(height: Dimen.defMarg),

                    Row(
                      children: [

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Wersja regulaminu',
                                  style: AppTextStyle(
                                    fontSize: AppTextFieldHint.topHintFontSize,
                                    fontWeight: AppTextFieldHint.topHintFontWeight,
                                    color: AppTextFieldHint.topHintColor(context)
                                  )
                              ),
                              SizedBox(height: Dimen.defMarg),
                              PopupMenuButton<String>(
                                  position: PopupMenuPosition.under,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(AppCard.bigRadius),
                                  ),
                                  borderRadius: BorderRadius.circular(AppCard.bigRadius),
                                  menuPadding: EdgeInsets.zero,
                                  padding: EdgeInsets.zero,
                                  clipBehavior: Clip.hardEdge,
                                  color: cardEnab_(context),
                                  tooltip: 'Wybierz wersję regulaminu',
                                  child: SimpleButton.from(
                                    color: cardEnab_(context),
                                    textColor: acceptedRulesVersion==null?iconDisab_(context):iconEnab_(context),
                                    onTap: null,
                                    text: acceptedRulesVersion??'Wersja regulaminu',
                                    margin: EdgeInsets.zero,
                                  ),
                                  onSelected: (acceptedRulesVersion) => setState(() => this.acceptedRulesVersion = acceptedRulesVersion),
                                  itemBuilder: (BuildContext context) => songContributionRules.keys.map((rulesVersion) => PopupMenuItem<String>(
                                    value: rulesVersion,
                                    padding: EdgeInsets.zero,
                                    child: SimpleButton.from(
                                      context: context,
                                      color: Colors.transparent,
                                      onTap: null,
                                      text: rulesVersion,
                                      margin: EdgeInsets.zero,
                                    ),
                                  )).toList()
                              )
                            ],
                          ),
                        ),

                        SizedBox(width: Dimen.defMarg),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Data przesłania',
                                style: AppTextStyle(
                                  fontSize: AppTextFieldHint.topHintFontSize,
                                  fontWeight: AppTextFieldHint.topHintFontWeight,
                                  color: AppTextFieldHint.topHintColor(context)
                                )
                              ),
                              SizedBox(height: Dimen.defMarg),
                              SimpleButton.from(
                                context: context,
                                color: cardEnab_(context),
                                onTap: () async {
                                  DateTime? _contributionDate = await showDatePicker(
                                    context: context,
                                    initialDate: DateTime.now(),
                                    firstDate: DateTime(966),
                                    lastDate: DateTime.now(),
                                  );
                                  if(_contributionDate != null)
                                    setState(() => contributionDate = _contributionDate);
                                },
                                text: dateToString(contributionDate),
                                margin: EdgeInsets.zero,
                              )
                            ],
                          ),
                        )

                      ],
                    )
                  ],
                )
              )
            ],
          )
        ),
      ),
    ),
  );

}


void showContribRulesDialog(BuildContext context, SongRaw song) => showDialog(
    context: context,
    builder: (context) => ContribRulesDialog(song: song)
);