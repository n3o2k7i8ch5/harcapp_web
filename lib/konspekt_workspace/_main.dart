import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:harcapp_web/idb.dart';
import 'package:harcapp_core/comm_classes/app_text_style.dart';
import 'package:harcapp_core/comm_classes/color_pack.dart';
import 'package:harcapp_core/comm_classes/meto.dart';
import 'package:harcapp_core/comm_widgets/app_card.dart';
import 'package:file_picker/file_picker.dart';
import 'package:harcapp_core/comm_widgets/app_scaffold.dart';
import 'package:harcapp_core/comm_widgets/app_text_field_hint.dart';
import 'package:harcapp_core/comm_widgets/simple_button.dart';
import 'package:harcapp_core/comm_widgets/title_show_row_widget.dart';
import 'package:harcapp_core/harcthought/konspekts/hrcpknspkt_data.dart';
import 'package:harcapp_core/harcthought/konspekts/konspekt.dart';
import 'package:harcapp_core/harcthought/konspekts/widgets/base_konspekt_widget.dart';
import 'package:harcapp_core/harcthought/konspekts/widgets/level_selectable_grid_widget.dart';
import 'package:harcapp_core/values/dimen.dart';
import 'package:harcapp_web/common/base_scaffold.dart';
import 'package:harcapp_web/common/download_file.dart';
import 'package:harcapp_web/konspekts/konspekty_tabs_row.dart';
import 'package:harcapp_web/konspekts/_main.dart' show KonspektsPage;
import 'package:harcapp_web/konspekt_workspace/models/konspekt_data.dart';
import 'package:harcapp_web/konspekt_workspace/widgets/materials_widget.dart';
import 'package:harcapp_web/konspekt_workspace/widgets/select_time_button.dart';
import 'package:harcapp_web/konspekt_workspace/widgets/spheres_widget.dart';
import 'package:harcapp_web/konspekt_workspace/widgets/steps_widget.dart';
import 'package:harcapp_web/konspekt_workspace/widgets/attachments_widget.dart';
import 'package:harcapp_web/konspekt_workspace/widgets/opis_html_editor.dart';
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

  bool _hasScrolled = false;
  bool _hasUnsavedChanges = false;
  late final ScrollController _scrollController;
  Timer? _debounceSaveTimer;
  static const _debounceDuration = Duration(seconds: 2);

  @override
  void initState() {
    if(widget.konspektData == null)
      _konspektData = KonspektData.empty();

    _scrollController = ScrollController();
    _scrollController.addListener(_handleScrollChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) => _checkForDraft());

    super.initState();
  }

  void _markUnsaved() {
    if (!_hasUnsavedChanges) {
      setState(() => _hasUnsavedChanges = true);
    }
    _scheduleSaveDraft();
  }

  void _scheduleSaveDraft() {
    _debounceSaveTimer?.cancel();
    _debounceSaveTimer = Timer(_debounceDuration, _saveDraft);
  }

  void _setStateAndSave(VoidCallback fn) {
    setState(fn);
    _markUnsaved();
  }

  Future<void> _saveDraft() async {
    try {
      final bytes = konspektData.toHrcpknspktData().toBytes();
      await IDB.saveKonspektDraft(bytes);
    } catch (_) {}
  }

  Future<void> _checkForDraft() async {
    final draftBytes = await IDB.getKonspektDraft();
    if (draftBytes == null || draftBytes.isEmpty) return;
    if (!mounted) return;

    try {
      final draftData = HrcpknspktData.fromBytes(draftBytes);
      final draftKonspekt = KonspektData.fromHrcpknspktData(draftData);
      
      // Sprawdź czy draft ma jakąś treść (np. tytuł)
      if (draftKonspekt.title.isEmpty) {
        await IDB.clearKonspektDraft();
        return;
      }

      if (!mounted) return;
      _showDraftRecoveryDialog(draftData, draftKonspekt);
    } catch (e) {
      debugPrint('Error loading draft: $e');
      await IDB.clearKonspektDraft();
    }
  }

  void _showDraftRecoveryDialog(HrcpknspktData draftData, KonspektData draftKonspekt) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _DraftRecoveryDialog(
        draftKonspekt: draftKonspekt,
        onRestore: () {
          setState(() => _konspektData = draftKonspekt);
          Navigator.of(context).pop();
        },
        onDiscard: () async {
          await IDB.clearKonspektDraft();
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _handleScrollChanged() {
    final scrolled = _scrollController.hasClients && _scrollController.position.pixels > 0;
    if (scrolled != _hasScrolled) {
      setState(() => _hasScrolled = scrolled);
    }
  }

  @override
  void dispose() {
    _debounceSaveTimer?.cancel();
    _scrollController.removeListener(_handleScrollChanged);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BaseScaffold(
      backgroundColor: cardEnab_(context),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [

          // Trzy główne przyciski konspektów – tak samo jak na stronach listy konspektów
          Padding(
            padding: EdgeInsets.only(
              top: Dimen.defMarg,
              left: KonspektsPage.defPaddingVal,
              right: KonspektsPage.defPaddingVal,
            ),
            child: const KonspektyTabsRow(),
          ),

          // Reszta treści przewijana poniżej, z treścią edytora
          Expanded(
            child: Stack(
              children: [
                // Biały panel z edytorem
                Material(
                  color: background_(context),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(AppCard.defRadius),
                    topRight: Radius.circular(AppCard.defRadius),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Center(
                    child: Container(
                      constraints: BoxConstraints(maxWidth: defPageWidth),
                      child: CustomScrollView(
                        controller: _scrollController,
                        clipBehavior: Clip.none,
                        physics: BouncingScrollPhysics(),
                        slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: Dimen.sideMarg,
                          ),
                          child: _TopActions(
                            konspektData: konspektData,
                            hasUnsavedChanges: _hasUnsavedChanges,
                            onLoaded: (data) => setState(
                                    () => _konspektData =
                                    KonspektData.fromHrcpknspktData(data)),
                            onSaved: () => setState(() => _hasUnsavedChanges = false),
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: EdgeInsets.only(
                          top: Dimen.sideMarg,
                          left: Dimen.sideMarg,
                          right: Dimen.sideMarg,
                        ),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([

                            // Cover image picker + preview + author
                            _CoverWidget(konspektData: konspektData, onChanged: _markUnsaved),

                            SizedBox(height: Dimen.sideMarg),

                            AppTextFieldHint(
                              hint: 'Nazwa konspektu:',
                              style: TitleShortcutRowWidget.style,
                              hintStyle: TitleShortcutRowWidget.style.copyWith(color: hintEnab_(context)),
                              textCapitalization: TextCapitalization.sentences,
                              controller: konspektData.titleController,
                              onChanged: (_, __) => _markUnsaved(),
                            ),

                            const SizedBox(height: Dimen.sideMarg),

                            AppTextFieldHint(
                              hint: 'W skrócie:',
                              textCapitalization: TextCapitalization.sentences,
                              controller: konspektData.summaryController,
                              maxLines: null,
                              onChanged: (_, __) => _markUnsaved(),
                            ),

                            const SizedBox(height: Dimen.defMarg),

                            TitleShortcutRowWidget(
                              title: 'Kategoria:',
                              textAlign: TextAlign.left,
                            ),
                            Row(
                              children: [
                                _CategoryToggleButton(
                                  label: 'Harcerski',
                                  isSelected: konspektData.category == KonspektCategory.harcerskie,
                                  onTap: () => _setStateAndSave(() {
                                    konspektData.category = KonspektCategory.harcerskie;
                                    konspektData.metos.clear();
                                  }),
                                ),
                                const SizedBox(width: Dimen.defMarg),
                                _CategoryToggleButton(
                                  label: 'Kształceniowy',
                                  isSelected: konspektData.category == KonspektCategory.ksztalcenie,
                                  onTap: () => _setStateAndSave(() {
                                    konspektData.category = KonspektCategory.ksztalcenie;
                                    konspektData.metos.clear();
                                  }),
                                ),
                              ],
                            ),

                            const SizedBox(height: Dimen.sideMarg),

                            TitleShortcutRowWidget(
                              title: konspektData.category == KonspektCategory.harcerskie ? 'Metodyki' : 'Poziom',
                              textAlign: TextAlign.left,
                            ),

                          ]),
                        ),
                      ),

                      // Metodyki - osobny sliver bez zewnętrznego paddingu
                      SliverToBoxAdapter(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          padding: EdgeInsets.symmetric(horizontal: Dimen.sideMarg),
                          child: LevelSelectableGridWidget(
                            konspektData.category == KonspektCategory.harcerskie
                                ? {Meto.zuch, Meto.harc, Meto.hs, Meto.wedro}
                                : {Meto.kadra},
                            konspektData.metos.toSet(),
                            oneLine: true,
                            onLevelTap: (Meto meto, bool checked) {
                              _setStateAndSave(() {
                                if (checked) konspektData.metos.remove(meto);
                                else konspektData.metos.add(meto);
                              });
                            },
                          ),
                        ),
                      ),

                      // Kontynuacja listy z paddingiem
                      SliverPadding(
                        padding: EdgeInsets.all(Dimen.sideMarg),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([

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
                                      _setStateAndSave(() => konspektData.type = type);
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
                                _setStateAndSave((){});
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
                                  onChanged: (Duration? newDuration) => _setStateAndSave(() => konspektData.customDuration = newDuration),
                                  fontSize: TitleShortcutRowWidget.style.fontSize,
                                )
                              ],
                            ),

                            const SizedBox(height: Dimen.sideMarg),

                            TitleShortcutRowWidget(
                              title: 'Cele',
                              textAlign: TextAlign.left,
                            ),

                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                ...List.generate(konspektData.aimControllers.length, (index) {
                                  final controller = konspektData.aimControllers[index];
                                  return Padding(
                                    padding: EdgeInsets.only(
                                      bottom: index < konspektData.aimControllers.length - 1
                                          ? Dimen.defMarg
                                          : 0,
                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        SizedBox(height: Dimen.iconFootprint),

                                        SizedBox(width: Dimen.iconMarg),
                                        Icon(MdiIcons.circleMedium),
                                        SizedBox(width: Dimen.iconMarg),

                                        Expanded(
                                          child: AppTextFieldHint(
                                            hint: 'Cel:',
                                            controller: controller,
                                            textCapitalization: TextCapitalization.sentences,
                                            onChanged: (_, __) => _markUnsaved(),
                                          ),
                                        ),

                                        SizedBox(width: Dimen.defMarg),

                                        SimpleButton.from(
                                          context: context,
                                          radius: AppCard.defRadius,
                                          padding: EdgeInsets.symmetric(
                                            horizontal: Dimen.defMarg * 1.5,
                                            vertical: Dimen.defMarg,
                                          ),
                                          color: Colors.red.withValues(alpha: 0.3),
                                          margin: EdgeInsets.zero,
                                          text: 'Usuń',
                                          textColor: Colors.red,
                                          icon: MdiIcons.trashCanOutline,
                                          iconColor: Colors.red,
                                          onTap: () => _setStateAndSave(() {
                                            konspektData.aimControllers.removeAt(index);
                                          }),
                                        ),
                                      ],
                                    ),
                                  );
                                }),

                                SizedBox(height: Dimen.defMarg),

                                SimpleButton.from(
                                  color: backgroundIcon_(context),
                                  radius: AppCard.defRadius,
                                  context: context,
                                  icon: MdiIcons.plus,
                                  margin: EdgeInsets.zero,
                                  textColor: iconEnab_(context),
                                  text: 'Dodaj cel',
                                  onTap: () => _setStateAndSave(() {
                                    konspektData.aimControllers.add(TextEditingController());
                                  }),
                                ),
                              ],
                            ),

                            const SizedBox(height: Dimen.sideMarg),

                            TitleShortcutRowWidget(
                              title: 'Załączniki',
                              textAlign: TextAlign.left,
                            ),
                            AttachmentsWidget(konspektData.attachments),

                            const SizedBox(height: Dimen.sideMarg),

                            TitleShortcutRowWidget(
                              title: 'Materiały',
                              textAlign: TextAlign.left,
                            ),
                            MaterialsWidget(
                              materials: konspektData.materials,
                              attachments: konspektData.attachments,
                            ),

                            const SizedBox(height: Dimen.sideMarg),

                            TitleShortcutRowWidget(
                              title: 'Opis',
                              textAlign: TextAlign.left,
                            ),

                            OpisHtmlEditor(
                              controller: konspektData.descriptionController,
                              attachments: konspektData.attachments,
                            ),

                            const SizedBox(height: Dimen.sideMarg),

                            TitleShortcutRowWidget(
                              title: 'Plan',
                              textAlign: TextAlign.left,
                            ),
                            StepsWidget(
                              steps: konspektData.stepsData,
                              attachments: konspektData.attachments,
                            ),

                          ]),
                        ),
                      ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Cień pod tabami – widoczny tylko gdy przewinięto
                if (_hasScrolled)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.15),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ));

}

class _TopActions extends StatelessWidget {
  final KonspektData konspektData;
  final bool hasUnsavedChanges;
  final void Function(HrcpknspktData data) onLoaded;
  final VoidCallback onSaved;

  const _TopActions({
    super.key,
    required this.konspektData,
    required this.hasUnsavedChanges,
    required this.onLoaded,
    required this.onSaved,
  });

  @override
  Widget build(BuildContext context) => Material(
    elevation: AppCard.bigElevation,
    borderRadius: BorderRadius.circular(AppCard.bigRadius),
    clipBehavior: Clip.hardEdge,
    child: Row(
      children: [
        Expanded(
          child: SimpleButton(
              radius: 0,
              color: cardEnab_(context),
              margin: EdgeInsets.zero,
              onTap: () {
                downloadFileFromBytes(
                    fileName: '${konspektData.titleAsFileName}.hrcpknspkt',
                    bytes: konspektData.toHrcpknspktData().toBytes()
                );
                onSaved();
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: Dimen.iconFootprint),
                  Icon(MdiIcons.contentSave, color: iconEnab_(context)),
                  SizedBox(width: Dimen.iconMarg),
                  Text('Zapisz', style: AppTextStyle(color: textEnab_(context))),
                  if (hasUnsavedChanges) ...[
                    SizedBox(width: 6),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              )),
        ),

        Expanded(
          child: SimpleButton.from(
              radius: 0,
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

        Expanded(
          child: SimpleButton.from(
              radius: 0,
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
      ],
    ),
  );
}

class _CoverWidget extends StatelessWidget {
  final KonspektData konspektData;
  final VoidCallback onChanged;

  const _CoverWidget({super.key, required this.konspektData, required this.onChanged});

  @override
  Widget build(BuildContext context) => StatefulBuilder(
    builder: (context, setState) => Material(
      borderRadius: BorderRadius.circular(AppCard.defRadius),
      color: cardEnab_(context),
      clipBehavior: Clip.hardEdge,
      child: SizedBox(
        height: 400,
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

            // Przyciski góra-prawo
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
                        onChanged();
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
                      onTap: () {
                        setState(() => konspektData.coverImageBytes = null);
                        onChanged();
                      },
                    ),
                ],
              ),
            ),

            // Autor okładki - dół
            Positioned(
              bottom: Dimen.defMarg,
              right: Dimen.defMarg,
              left: Dimen.defMarg,
              child: Material(
                color: background_(context),
                borderRadius: BorderRadius.circular(AppCard.defRadius),
                child: AppTextFieldHint(
                  hint: 'Autor okładki:',
                  hintTop: 'Autor okładki',
                  textCapitalization: TextCapitalization.sentences,
                  controller: konspektData.coverAuthorController,
                  onChanged: (_, __) => onChanged(),
                  leading: Padding(
                    padding: EdgeInsets.all(Dimen.iconMarg),
                    child: Icon(MdiIcons.account, color: hintEnab_(context)),
                  ),
                ),
              ),
            ),
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

class _CategoryToggleButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryToggleButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => SimpleButton.from(
    context: context,
    radius: AppCard.defRadius,
    padding: EdgeInsets.symmetric(horizontal: Dimen.defMarg * 1.5, vertical: Dimen.defMarg),
    color: isSelected ? iconEnab_(context) : backgroundIcon_(context),
    textColor: isSelected ? background_(context) : hintEnab_(context),
    fontWeight: isSelected ? weightBold : weightNormal,
    margin: EdgeInsets.zero,
    text: label,
    onTap: onTap,
  );
}

class _DraftRecoveryDialog extends StatelessWidget {
  final KonspektData draftKonspekt;
  final VoidCallback onRestore;
  final VoidCallback onDiscard;

  const _DraftRecoveryDialog({
    required this.draftKonspekt,
    required this.onRestore,
    required this.onDiscard,
  });

  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      constraints: BoxConstraints(maxWidth: 500),
      margin: EdgeInsets.all(Dimen.sideMarg),
      child: Material(
        borderRadius: BorderRadius.circular(AppCard.bigRadius),
        color: cardEnab_(context),
        clipBehavior: Clip.hardEdge,
        child: Padding(
          padding: EdgeInsets.all(Dimen.sideMarg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(MdiIcons.fileRestoreOutline, color: iconEnab_(context), size: 32),
                  SizedBox(width: Dimen.defMarg),
                  Expanded(
                    child: Text(
                      'Niezapisane zmiany',
                      style: AppTextStyle(
                        fontSize: Dimen.textSizeAppBar,
                        fontWeight: weightBold,
                        color: textEnab_(context),
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: Dimen.sideMarg),

              Text(
                'Widzę, że masz tu jakieś niezapisane zmiany. Czy chcesz je przywrócić?',
                style: AppTextStyle(color: textEnab_(context)),
              ),

              SizedBox(height: Dimen.sideMarg),

              Material(
                borderRadius: BorderRadius.circular(AppCard.defRadius),
                color: backgroundIcon_(context),
                child: Padding(
                  padding: EdgeInsets.all(Dimen.iconMarg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tytuł: ${draftKonspekt.title.isNotEmpty ? draftKonspekt.title : "(brak)"}',
                        style: AppTextStyle(
                          fontWeight: weightBold,
                          color: textEnab_(context),
                        ),
                      ),
                      if (draftKonspekt.summary.isNotEmpty) ...[
                        SizedBox(height: Dimen.defMarg / 2),
                        Text(
                          draftKonspekt.summary,
                          style: AppTextStyle(color: hintEnab_(context)),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      SizedBox(height: Dimen.defMarg / 2),
                      Text(
                        'Kategoria: ${draftKonspekt.category.displayName}',
                        style: AppTextStyle(color: hintEnab_(context), fontSize: Dimen.textSizeSmall),
                      ),
                      Text(
                        'Kroki: ${draftKonspekt.stepsData.length}',
                        style: AppTextStyle(color: hintEnab_(context), fontSize: Dimen.textSizeSmall),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: Dimen.sideMarg),

              Row(
                children: [
                  Expanded(
                    child: SimpleButton.from(
                      context: context,
                      color: backgroundIcon_(context),
                      textColor: textEnab_(context),
                      margin: EdgeInsets.zero,
                      text: 'Odrzuć',
                      icon: MdiIcons.deleteOutline,
                      onTap: onDiscard,
                    ),
                  ),
                  SizedBox(width: Dimen.defMarg),
                  Expanded(
                    child: SimpleButton.from(
                      context: context,
                      color: iconEnab_(context),
                      textColor: background_(context),
                      fontWeight: weightBold,
                      margin: EdgeInsets.zero,
                      text: 'Przywróć',
                      icon: MdiIcons.check,
                      onTap: onRestore,
                    ),
                  ),
                ],
              ),

              SizedBox(height: Dimen.defMarg),

              SimpleButton.from(
                context: context,
                color: backgroundIcon_(context),
                textColor: hintEnab_(context),
                margin: EdgeInsets.zero,
                text: 'Podgląd',
                icon: MdiIcons.eyeOutline,
                onTap: () {
                  Map json = draftKonspekt.toJsonMap();
                  Konspekt konspekt = Konspekt.fromJsonMap(json);
                  showDialog(
                    context: context,
                    builder: (ctx) => Center(
                      child: Container(
                        constraints: BoxConstraints(maxWidth: defPageWidth),
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
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    ),
  );
}