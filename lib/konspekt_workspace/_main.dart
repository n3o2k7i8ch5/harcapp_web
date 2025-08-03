import 'package:flutter/material.dart';
import 'package:harcapp_core/comm_classes/color_pack.dart';
import 'package:harcapp_core/comm_classes/meto.dart';
import 'package:harcapp_core/comm_widgets/app_text_field_hint.dart';
import 'package:harcapp_core/comm_widgets/multi_text_field.dart';
import 'package:harcapp_core/comm_widgets/simple_button.dart';
import 'package:harcapp_core/comm_widgets/title_show_row_widget.dart';
import 'package:harcapp_core/harcthought/konspekts/widgets/level_selectable_grid_widget.dart';
import 'package:harcapp_core/values/dimen.dart';
import 'package:harcapp_web/common/base_scaffold.dart';
import 'package:harcapp_web/konspekt_workspace/widgets/select_time_button.dart';
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
                        onChanged: (Duration? newDuration) => setState(() => duration = newDuration)
                      )
                    ],
                  ),

                  const SizedBox(height: Dimen.sideMarg),

                  TitleShortcutRowWidget(
                    title: 'Cele',
                    textAlign: TextAlign.left,
                  ),

                  MultiTextField(
                    hint: 'Row test',
                    layout: LayoutMode.row,
                  ),

                  Container(
                    height: 100,
                    width: 100,
                    color: backgroundIcon_(context),
                  ),

                  MultiTextField(
                    hint: 'Column test',
                    layout: LayoutMode.column,
                    addButtonBuilder: (bool tappable, void Function() onTap) => SimpleButton.from(
                      context: context,
                      icon: MdiIcons.plus,
                      textColor: tappable? iconEnab_(context) : iconDisab_(context),
                      text: 'Dodaj nowy',
                      onTap: tappable? onTap: null,
                    )
                  ),

                  Container(
                    height: 100,
                    width: 100,
                    color: backgroundIcon_(context),
                  ),

                  MultiTextField(
                    hint: 'Row test',
                    layout: LayoutMode.wrap,
                  ),

                  Container(
                    height: 100,
                    width: 100,
                    color: backgroundIcon_(context),
                  ),

                  MultiTextField(
                    hint: 'Row expanded test',
                    layout: LayoutMode.row,
                    expanded: true,
                  ),

                  Container(
                    height: 100,
                    width: 100,
                    color: backgroundIcon_(context),
                  )

                ],
              )
          )
      )
  );


}