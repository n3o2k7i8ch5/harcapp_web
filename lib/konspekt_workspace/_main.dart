import 'package:flutter/material.dart';
import 'package:harcapp_core/comm_classes/color_pack.dart';
import 'package:harcapp_core/comm_classes/meto.dart';
import 'package:harcapp_core/comm_widgets/app_card.dart';
import 'package:harcapp_core/comm_widgets/app_text_field_hint.dart';
import 'package:harcapp_core/comm_widgets/multi_text_field.dart';
import 'package:harcapp_core/comm_widgets/simple_button.dart';
import 'package:harcapp_core/comm_widgets/title_show_row_widget.dart';
import 'package:harcapp_core/harcthought/konspekts/widgets/level_selectable_grid_widget.dart';
import 'package:harcapp_core/values/dimen.dart';
import 'package:harcapp_web/common/base_scaffold.dart';
import 'package:harcapp_web/konspekt_workspace/widgets/select_time_button.dart';
import 'package:harcapp_web/konspekt_workspace/widgets/step_widget.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../consts.dart';



class KonspektWorkspacePage extends StatefulWidget{

  const KonspektWorkspacePage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => KonspektWorkspacePageState();

}

class KonspektWorkspacePageState extends State<KonspektWorkspacePage>{

  late Set<Meto> selectedMetos;
  Duration? duration;

  @override
  void initState() {
    selectedMetos = Set.from(Meto.values);
    super.initState();
  }

  @override
  Widget build(BuildContext context) => BaseScaffold(
      backgroundColor: background_(context),
      body: Center(
          child: Container(
              constraints: BoxConstraints(maxWidth: defPageWidth),
              child: ListView(
                padding: EdgeInsets.all(Dimen.sideMarg),
                physics: BouncingScrollPhysics(),
                children: [

                  Material(
                    borderRadius: BorderRadius.circular(AppCard.bigRadius),
                    color: backgroundIcon_(context),
                    child: Container(height: 300, width: double.infinity),
                  ),

                  const SizedBox(height: Dimen.sideMarg),

                  AppTextFieldHint(
                    hint: 'Nazwa konspektu:',
                    style: TitleShortcutRowWidget.style,
                    hintStyle: TitleShortcutRowWidget.style.copyWith(color: hintEnab_(context)),
                    textCapitalization: TextCapitalization.sentences,
                  ),

                  const SizedBox(height: Dimen.sideMarg),

                  TitleShortcutRowWidget(
                    title: 'W skrócie',
                    textAlign: TextAlign.left,
                  ),
                  AppTextFieldHint(
                    hint: 'W skrócie:',
                    textCapitalization: TextCapitalization.sentences,
                    maxLines: null,
                  ),

                  const SizedBox(height: Dimen.sideMarg),

                  TitleShortcutRowWidget(
                    title: 'Metodyki',
                    textAlign: TextAlign.left,
                  ),

                  LevelSelectableGridWidget(
                    Set.from(Meto.values),
                    selectedMetos,
                    oneLine: true,
                    onLevelTap: (Meto meto, bool checked) {
                      setState(() {
                        if (checked) selectedMetos.remove(meto);
                        else selectedMetos.add(meto);
                      });
                    },
                  ),

                  const SizedBox(height: Dimen.sideMarg),

                  Row(
                    children: [
                      IntrinsicWidth(
                        child: TitleShortcutRowWidget(
                          title: 'Rodzaj',
                          textAlign: TextAlign.left,
                        ),
                      ),

                      Text('<tutaj selektor>')

                    ],
                  ),

                  const SizedBox(height: Dimen.sideMarg),

                  TitleShortcutRowWidget(
                    title: 'Sfery rozwoju',
                    textAlign: TextAlign.left,
                  ),
                  Text('<tutaj sfery rozwoju>'),

                  const SizedBox(height: Dimen.sideMarg),

                  Row(
                    children: [
                      IntrinsicWidth(
                        child: TitleShortcutRowWidget(
                          title: 'Czas:',
                          textAlign: TextAlign.left,
                        ),
                      ),

                      SizedBox(width: Dimen.defMarg),

                      SelectTimeButton(
                        duration,
                        onChanged: (Duration? newDuration) => setState(() => duration = newDuration),
                        fontSize: TitleShortcutRowWidget.style.fontSize,
                      )
                    ],
                  ),

                  const SizedBox(height: Dimen.sideMarg),

                  TitleShortcutRowWidget(
                    title: 'Cele',
                    textAlign: TextAlign.left,
                  ),

                  AppTextFieldHint(
                    hint: 'Cele:',
                    multi: true,
                    multiAllowZeroFields: true,
                    multiLayout: LayoutMode.column,
                    multiItemBuilder: (index, key, widget) => Row(
                      key: key,
                      children: [
                        // Because when having more than one item, the close button appears adding height.
                        SizedBox(height: Dimen.iconFootprint),

                        SizedBox(width: Dimen.iconMarg),
                        Icon(MdiIcons.circleMedium),
                        SizedBox(width: Dimen.iconMarg),
                        Expanded(child: widget)
                      ],
                    ),
                    multiAddButtonBuilder: (bool tappable, void Function() onTap) => SimpleButton.from(
                      context: context,
                      icon: MdiIcons.plus,
                      margin: EdgeInsets.zero,
                      textColor: tappable? iconEnab_(context) : iconDisab_(context),
                      text: 'Dodaj cel',
                      onTap: tappable? onTap: null,
                    ),
                    multiIsCollapsed: true,
                  ),

                  const SizedBox(height: Dimen.sideMarg),

                  TitleShortcutRowWidget(
                    title: 'Materiały',
                    textAlign: TextAlign.left,
                  ),
                  Text('<tutaj materiały>'),

                  const SizedBox(height: Dimen.sideMarg),

                  TitleShortcutRowWidget(
                    title: 'Opis',
                    textAlign: TextAlign.left,
                  ),

                  AppTextFieldHint(
                    hint: 'Opis:',
                    textAlignVertical: TextAlignVertical.top,
                    textCapitalization: TextCapitalization.sentences,
                    maxLines: null,
                  ),

                  TitleShortcutRowWidget(
                    title: 'Plan',
                    textAlign: TextAlign.left,
                  ),
                  StepWidget(
                    index: 0,
                  ),

                ],
              )
          )
      )
  );


}