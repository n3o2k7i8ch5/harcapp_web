import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:harcapp_core/comm_classes/app_text_style.dart';
import 'package:harcapp_core/comm_classes/color_pack.dart';
import 'package:harcapp_core/comm_classes/meto.dart';
import 'package:harcapp_core/comm_widgets/app_card.dart';
import 'package:file_picker/file_picker.dart';
import 'package:harcapp_core/comm_widgets/app_scaffold.dart';
import 'package:harcapp_core/comm_widgets/app_text_field_hint.dart';
import 'package:harcapp_core/comm_widgets/floating_container.dart';
import 'package:harcapp_core/comm_widgets/multi_text_field.dart';
import 'package:harcapp_core/comm_widgets/simple_button.dart';
import 'package:harcapp_core/comm_widgets/title_show_row_widget.dart';
import 'package:harcapp_core/harcthought/konspekts/hrcpknspkt_data.dart';
import 'package:harcapp_core/harcthought/konspekts/konspekt.dart';
import 'package:harcapp_core/harcthought/konspekts/widgets/base_konspekt_widget.dart';
import 'package:harcapp_core/harcthought/konspekts/widgets/level_selectable_grid_widget.dart';
import 'package:harcapp_core/values/dimen.dart';
import 'package:harcapp_web/common/base_scaffold.dart';
import 'package:harcapp_web/common/download_file.dart';
import 'package:harcapp_web/konspekt_workspace/models/konspekt_data.dart';
import 'package:harcapp_web/konspekt_workspace/widgets/materials_widget.dart';
import 'package:harcapp_web/konspekt_workspace/widgets/select_time_button.dart';
import 'package:harcapp_web/konspekt_workspace/widgets/spheres_widget.dart';
import 'package:harcapp_web/konspekt_workspace/widgets/steps_widget.dart';
import 'package:harcapp_web/konspekt_workspace/widgets/attachments_widget.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../consts.dart';


class KonspektWorkspacePage extends StatefulWidget{

  final KonspektData? konspektData;

  const KonspektWorkspacePage({this.konspektData, Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => KonspektWorkspacePageState();

}

class KonspektWorkspacePageState extends State<KonspektWorkspacePage>{

  KonspektData? _konspektData;

  KonspektData get konspektData => widget.konspektData??_konspektData!;

  @override
  void initState() {
    if(widget.konspektData == null)
      _konspektData = KonspektData.empty();

    super.initState();
  }

  @override
  Widget build(BuildContext context) => BaseScaffold(
      backgroundColor: background_(context),
      body: Center(
          child: Container(
              constraints: BoxConstraints(maxWidth: defPageWidth),
              child: CustomScrollView(
                clipBehavior: Clip.none,
                physics: BouncingScrollPhysics(),
                slivers: [

                  FloatingContainer.child(
                    child: Padding(
                      padding: EdgeInsets.only(top: Dimen.defMarg),
                      child: _TopActions(
                        konspektData: konspektData,
                        onLoaded: (data) => setState(() => _konspektData = KonspektData.fromHrcpknspktData(data)),
                      ),
                    ),
                    height: Dimen.iconFootprint + Dimen.defMarg, // kToolbarHeight
                  ),

                  SliverPadding(
                    padding: EdgeInsets.all(Dimen.sideMarg),
                    sliver: SliverList(delegate: SliverChildListDelegate([

                      Container(
                        height: 50,
                        width: double.infinity,
                        color: Colors.red[700]!,
                        child: Center(
                          child: Text(
                            'To jeszcze nie działa. W budowie. Prosze sobie pójść gdzie indziej :)',
                            style: AppTextStyle(
                              fontSize: Dimen.textSizeAppBar,
                              color: background_(context),
                              fontWeight: weightBold,
                            ),
                          ),
                        )
                      ),

                      SizedBox(height: Dimen.sideMarg),

                      // Cover image picker + preview
                      _CoverWidget(konspektData: konspektData),

                      const SizedBox(height: Dimen.sideMarg),

                      // Cover author
                      TitleShortcutRowWidget(
                        title: 'Autor okładki',
                        textAlign: TextAlign.left,
                      ),
                      AppTextFieldHint(
                        hint: 'Autor okładki (jeśli dotyczy):',
                        textCapitalization: TextCapitalization.sentences,
                        controller: konspektData.coverAuthorController,
                      ),

                      AppTextFieldHint(
                        hint: 'Nazwa konspektu:',
                        style: TitleShortcutRowWidget.style,
                        hintStyle: TitleShortcutRowWidget.style.copyWith(color: hintEnab_(context)),
                        textCapitalization: TextCapitalization.sentences,
                        controller: konspektData.titleController,
                      ),

                      const SizedBox(height: Dimen.sideMarg),

                      TitleShortcutRowWidget(
                        title: 'W skrócie',
                        textAlign: TextAlign.left,
                      ),
                      AppTextFieldHint(
                        hint: 'W skrócie:',
                        textCapitalization: TextCapitalization.sentences,
                        controller: konspektData.summaryController,
                        maxLines: null,
                      ),

                      const SizedBox(height: Dimen.sideMarg),

                      TitleShortcutRowWidget(
                        title: 'Metodyki',
                        textAlign: TextAlign.left,
                      ),

                      LevelSelectableGridWidget(
                        Set.from(Meto.values),
                        konspektData.metos.toSet(),
                        oneLine: true,
                        onLevelTap: (Meto meto, bool checked) {
                          setState(() {
                            if (checked) konspektData.metos.remove(meto);
                            else konspektData.metos.add(meto);
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

                          SizedBox(width: Dimen.defMarg),

                          _KonspektTypeButton(
                              type: konspektData.type,
                              onChanged: (KonspektType? type) {
                                if(type == null) return;
                                setState(() => konspektData.type = type);
                              }
                          ),

                        ],
                      ),

                      const SizedBox(height: Dimen.sideMarg),

                      TitleShortcutRowWidget(
                        title: 'Sfery rozwoju',
                        textAlign: TextAlign.left,
                      ),
                      SpheresWidget(
                        spheres: konspektData.spheres,
                        onChanged: (Map<KonspektSphere, KonspektSphereDetails?> newSpheres){
                          konspektData.spheres.clear();
                          konspektData.spheres.addAll(newSpheres);
                          setState((){});
                        },
                      ),

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
                            konspektData.customDuration,
                            onChanged: (Duration? newDuration) => setState(() => konspektData.customDuration = newDuration),
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
                          color: backgroundIcon_(context),
                          radius: AppCard.defRadius,
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
                      MaterialsWidget(materials: konspektData.materials),

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
                        controller: konspektData.descriptionController,
                      ),

                      TitleShortcutRowWidget(
                        title: 'Plan',
                        textAlign: TextAlign.left,
                      ),
                      StepsWidget(
                        steps: konspektData.stepsData,
                      ),

                      const SizedBox(height: Dimen.sideMarg),

                      TitleShortcutRowWidget(
                        title: 'Załączniki',
                        textAlign: TextAlign.left,
                      ),

                      AttachmentsWidget(konspektData.attachments),

                    ])),
                  )

                ],
              )
          )
      )
  );

}

class _TopActions extends StatelessWidget {
  final KonspektData konspektData;
  final void Function(HrcpknspktData data) onLoaded;

  const _TopActions({super.key, required this.konspektData, required this.onLoaded});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: SimpleButton.from(
            elevation: AppCard.bigElevation,
            context: context,
            color: cardEnab_(context),
            margin: EdgeInsets.zero,
            icon: MdiIcons.eyeOutline,
            text: 'Podgląd',
            onTap: () {
              Map json = konspektData.toJsonMap();
              Konspekt konspekt = Konspekt.fromJsonMap(json);
              showDialog(
                  context: context,
                  builder: (context) => Center(
                    child: Container(
                      constraints:
                      BoxConstraints(maxWidth: defPageWidth),
                      child: Padding(
                        padding: EdgeInsets.all(Dimen.sideMarg),
                        child: Material(
                          child: BaseKonspektWidget(
                            konspekt,
                            onDuchLevelInfoTap: null,
                          ),
                        ),
                      ),
                    ),
                  ));
            }),
      ),

      SizedBox(width: Dimen.defMarg),

      Expanded(
        child: SimpleButton.from(
            elevation: AppCard.bigElevation,
            context: context,
            color: cardEnab_(context),
            margin: EdgeInsets.zero,
            icon: MdiIcons.folderOpenOutline,
            text: 'Wczytaj',
            onTap: () async {

              FilePickerResult? result = await FilePicker.platform.pickFiles(
                type: FileType.custom,
                allowedExtensions: ['hrcpknspkt'],
              );

              if(result == null)
                return;

              final Uint8List? bytes = result.files.single.bytes!;

              if(bytes == null){
                AppScaffold.showMessage(context, text: 'Coś poszło nie tak.');
                return;
              }

              HrcpknspktData hrcpknspktData = HrcpknspktData.fromBytes(bytes);

              onLoaded(hrcpknspktData);
            }
        ),
      ),

      SizedBox(width: Dimen.defMarg),

      Expanded(
        child: SimpleButton.from(
            elevation: AppCard.bigElevation,
            context: context,
            color: cardEnab_(context),
            margin: EdgeInsets.zero,
            icon: MdiIcons.contentSave,
            text: 'Zapisz',
            onTap: () => downloadFileFromBytes(
              fileName: '${konspektData.titleAsFileName}.hrcpknspkt',
              bytes: konspektData.toHrcpknspktData().toBytes()
            )),
      ),
    ],
  );
}

class _CoverWidget extends StatelessWidget {
  final KonspektData konspektData;

  const _CoverWidget({super.key, required this.konspektData});

  @override
  Widget build(BuildContext context) => StatefulBuilder(
        builder: (context, setState) => Material(
          borderRadius: BorderRadius.circular(AppCard.defRadius),
          color: backgroundIcon_(context),
          clipBehavior: Clip.hardEdge,
          child: SizedBox(
            height: 300,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (konspektData.coverImageBytes != null)
                  Image.memory(
                    konspektData.coverImageBytes!,
                    fit: BoxFit.cover,
                  )
                else
                  Center(
                    child: Text(
                      'Brak okładki',
                      style: AppTextStyle(color: hintEnab_(context)),
                    ),
                  ),

                Positioned(
                  top: Dimen.defMarg,
                  right: Dimen.defMarg,
                  child: Row(
                    children: [
                      SimpleButton.from(
                        context: context,
                        color: background_(context),
                        margin: EdgeInsets.zero,
                        radius: AppCard.defRadius,
                        padding: EdgeInsets.symmetric(horizontal: Dimen.defMarg, vertical: 8),
                        icon: MdiIcons.imagePlus,
                        text: konspektData.coverImageBytes == null ? 'Dodaj obraz' : 'Zmień obraz',
                        onTap: () async {
                          FilePickerResult? result = await FilePicker.platform.pickFiles(
                            type: FileType.custom,
                            allowedExtensions: ['png', 'jpg', 'jpeg', 'webp'],
                            withData: true,
                          );
                          if (result != null && result.files.isNotEmpty) {
                            setState(() => konspektData.coverImageBytes = result.files.first.bytes);
                          }
                        },
                      ),

                      if (konspektData.coverImageBytes != null)
                        SizedBox(width: Dimen.defMarg),
                      if (konspektData.coverImageBytes != null)
                        SimpleButton.from(
                          context: context,
                          color: background_(context),
                          margin: EdgeInsets.zero,
                          radius: AppCard.defRadius,
                          padding: EdgeInsets.symmetric(horizontal: Dimen.defMarg, vertical: 8),
                          icon: MdiIcons.delete,
                          text: 'Usuń',
                          onTap: () => setState(() => konspektData.coverImageBytes = null),
                        ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      );
}

class _KonspektTypeButton extends StatelessWidget{

  final KonspektType type;
  final void Function(KonspektType type)? onChanged;

  const _KonspektTypeButton({required this.type, this.onChanged, super.key});

  @override
  Widget build(BuildContext context) => PopupMenuButton<KonspektType>(
    splashRadius: AppCard.defRadius,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppCard.defRadius)),
    borderRadius: BorderRadius.circular(AppCard.defRadius),
    clipBehavior: Clip.hardEdge,
    menuPadding: EdgeInsets.zero,
    padding: EdgeInsets.zero,
    child: SimpleButton.from(
      context: context,
      radius: AppCard.defRadius,
      padding: EdgeInsets.all(Dimen.defMarg),
      textColor: iconEnab_(context),
      color: backgroundIcon_(context),
      margin: EdgeInsets.zero,
      text: type.displayName,
      onTap: null,
      icon: MdiIcons.circleMedium,
      iconColor: type.color(context),
      iconLeading: false,
    ),
    onSelected: onChanged,
    color: background_(context),
    constraints: BoxConstraints(),
    elevation: AppCard.bigElevation,
    itemBuilder: (BuildContext context) => KonspektType.values.map(
        (value) => PopupMenuItem<KonspektType>(
          value: value,
          padding: EdgeInsets.zero,
          child: SimpleButton.from(
            padding: EdgeInsets.all(Dimen.defMarg),
            context: context,
            textColor: iconEnab_(context),
            text: value.displayName,
            margin: EdgeInsets.zero,
            onTap: null,
            icon: MdiIcons.circleMedium,
            iconColor: value.color(context),
            iconLeading: false,
          ),
        )
    ).toList()
  );

}