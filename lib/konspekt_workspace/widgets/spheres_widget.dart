import 'package:flutter/material.dart';
import 'package:harcapp_core/comm_classes/app_navigator.dart';
import 'package:harcapp_core/comm_classes/app_text_style.dart';
import 'package:harcapp_core/comm_classes/color_pack.dart';
import 'package:harcapp_core/comm_widgets/app_bar.dart';
import 'package:harcapp_core/comm_widgets/app_button.dart';
import 'package:harcapp_core/comm_widgets/app_card.dart';
import 'package:harcapp_core/comm_widgets/app_text_field_hint.dart';
import 'package:harcapp_core/comm_widgets/multi_text_field.dart';
import 'package:harcapp_core/comm_widgets/simple_button.dart';
import 'package:harcapp_core/harcthought/konspekts/konspekt.dart';
import 'package:harcapp_core/harcthought/konspekts/widgets/spheres_widget.dart';
import 'package:harcapp_core/values/dimen.dart';
import 'package:harcapp_web/consts.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import 'multi_text_field_add_button.dart';

class SpheresWidget extends StatefulWidget{

  final Map<KonspektSphere, KonspektSphereDetails?> spheres;

  final void Function(Map<KonspektSphere, KonspektSphereDetails?> spheres) onChanged;

  const SpheresWidget({required this.spheres, required this.onChanged});

  @override
  State<StatefulWidget> createState() => SpheresWidgetState();

}

class SpheresWidgetState extends State<SpheresWidget> {

  Map<KonspektSphere, KonspektSphereDetails?> get spheres => {
    KonspektSphere.cialo: widget.spheres[KonspektSphere.cialo],
    KonspektSphere.umysl: widget.spheres[KonspektSphere.umysl],
    KonspektSphere.duch: widget.spheres[KonspektSphere.duch],
    KonspektSphere.emocje: widget.spheres[KonspektSphere.emocje],
    KonspektSphere.relacje: widget.spheres[KonspektSphere.relacje],
  };

  @override
  Widget build(BuildContext context) => ListView.separated(
    itemBuilder: (context, index) =>
    spheres.keys.elementAt(index) == KonspektSphere.duch?
    SphereDuchWidget(
      spheres.values.elementAt(index),
      onChanged: (details) {
        setState(() => spheres[KonspektSphere.duch] = details);
        widget.onChanged(spheres);
      },
    ):
    SphereNonDuchWidget(
      spheres.keys.elementAt(index),
      spheres.values.elementAt(index),
      onChanged: (details) {
        setState(() => spheres[spheres.keys.elementAt(index)] = details);
        widget.onChanged(spheres);
      },
    ),
    separatorBuilder: (context, index) => SizedBox(height: Dimen.defMarg),
    itemCount: spheres.length,
    shrinkWrap: true,
    physics: NeverScrollableScrollPhysics(),
  );

}

class SphereNonDuchWidget extends StatefulWidget{

  final KonspektSphere sphere;
  final KonspektSphereDetails? details;
  final void Function(KonspektSphereDetails? details)? onChanged;

  const SphereNonDuchWidget(this.sphere, this.details, {this.onChanged, super.key});

  @override
  State<StatefulWidget> createState() => SphereNonDuchWidgetState();

}

class SphereNonDuchWidgetState extends State<SphereNonDuchWidget>{

  KonspektSphere get sphere => widget.sphere;
  KonspektSphereDetails? get details => widget.details;

  late MultiTextFieldController controller;

  @override
  void initState() {
    controller = MultiTextFieldController(
        texts: details?.levels[KonspektSphereLevel.other]?.fields.keys.toList()??[],
        minCount: 0
    );
    super.initState();
  }

  static const Duration _animDuration = Duration(milliseconds: 200);
  static const Curve _animCurve = Curves.easeIn;

  @override
  Widget build(BuildContext context) => AnimatedSize(
    duration: _animDuration,
    curve: _animCurve,
    alignment: Alignment.topCenter,
    child: Material(
      borderRadius: BorderRadius.circular(AppCard.defRadius),
      color: cardEnab_(context),
      child: Row(
        children: [
          Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  top: Dimen.iconMarg,
                  bottom: Dimen.iconMarg,
                  left: Dimen.iconMarg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    KonspektSphereTitleWidget(sphere),

                    if (controller.length > 0)
                      AppTextFieldHint(
                        multiController: controller,
                        hint: 'Elemenet sfery ${sphere.displayNameDopelniacz.toLowerCase()}:',
                        hintTop: '',
                        multiHintTop: '',
                        textFieldHintPadding: EdgeInsets.zero,
                        animationDuration: _animDuration,
                        onAnyChanged: (values) => widget.onChanged?.call(
                            (values.isEmpty)? null : KonspektSphereDetails(
                                levels: {
                                  KonspektSphereLevel.other: KonspektSphereFields(
                                      fields: { for(var v in values) v: null }
                                  )
                                }
                            )
                        ),
                        multi: true,
                        multiAllowZeroFields: true,
                        multiLayout: LayoutMode.column,
                        multiItemBuilder: (index, key, widget) => Row(
                          key: key,
                          children: [
                            // Because when having more than one item, the close button appears adding height.
                            SizedBox(height: Dimen.iconFootprint),

                            SizedBox(width: Dimen.iconSize + Dimen.iconMarg),
                            Icon(MdiIcons.circleMedium),
                            SizedBox(width: Dimen.iconMarg),
                            Expanded(child: widget)
                          ],
                        ),
                        multiAddButtonBuilder: (bool tappable, void Function() onTap) => Padding(
                          padding: EdgeInsets.only(
                              right: Dimen.iconMarg,
                              left: Dimen.iconSize + Dimen.iconMarg
                          ),
                          child: MultiTextFieldAddButton(
                            tappable: tappable,
                            text: 'Element rozwoju ${sphere.displayNameDopelniacz.toLowerCase()}',
                            onTap: onTap,
                          ),
                        ),
                        multiIsCollapsed: true,
                      ),

                  ],
                ),
              )
          ),
          if (controller.length == 0)
            AppButton(
              icon: Icon(MdiIcons.plus),
              onTap: () => setState(() => controller.texts = ['']),
            ),
        ],
      ),
    ),
  );

}

class SphereDuchWidget extends StatefulWidget{

  final KonspektSphereDetails? details;
  final void Function(KonspektSphereDetails? details)? onChanged;

  const SphereDuchWidget(
      this.details,
      { super.key,
        this.onChanged,
      });

  @override
  State<StatefulWidget> createState() => SphereDuchWidgetState();

}

typedef _DuchLevelController = (MultiTextFieldController, List<Set<KonspektSphereFactor>?>);

class SphereDuchWidgetState extends State<SphereDuchWidget>{

  KonspektSphereDetails? get details => widget.details;
  void Function(KonspektSphereDetails? details)? get onChanged => widget.onChanged;

  bool _isExpanded = false;

  late _DuchLevelController postawyController;
  late _DuchLevelController wartosciController;
  late _DuchLevelController aksjomatyController;
  late _DuchLevelController silaCharakteruController;
  late _DuchLevelController zdolnoscRefleksyjnaController;

  @override
  void initState() {
    postawyController = (
    MultiTextFieldController(
        texts: details?.levels[KonspektSphereLevel.duchPostawy]?.fields.keys.toList()??[],
        minCount: 0
    ),
    details?.levels[KonspektSphereLevel.duchPostawy]?.fields.values.toList()??[{}]
    );
    wartosciController = (
    MultiTextFieldController(
        texts: details?.levels[KonspektSphereLevel.duchWartosci]?.fields.keys.toList()??[],
        minCount: 0
    ),
    details?.levels[KonspektSphereLevel.duchWartosci]?.fields.values.toList()??[{}]
    );

    aksjomatyController = (
    MultiTextFieldController(
        texts: details?.levels[KonspektSphereLevel.duchAksjomaty]?.fields.keys.toList()??[],
        minCount: 0
    ),
    details?.levels[KonspektSphereLevel.duchAksjomaty]?.fields.values.toList()??[{}]
    );

    silaCharakteruController = (
    MultiTextFieldController(
        texts: details?.levels[KonspektSphereLevel.duchSilaCharakteru]?.fields.keys.toList()??[],
        minCount: 0
    ),
    details?.levels[KonspektSphereLevel.duchSilaCharakteru]?.fields.values.toList()??[{}]
    );

    zdolnoscRefleksyjnaController = (
    MultiTextFieldController(
        texts: details?.levels[KonspektSphereLevel.duchZdolnoscRefleksyjna]?.fields.keys.toList()??[],
        minCount: 0
    ),
    details?.levels[KonspektSphereLevel.duchZdolnoscRefleksyjna]?.fields.values.toList()??[{}]
    );

    super.initState();
  }

  @override
  Widget build(BuildContext context) => Material(
    borderRadius: BorderRadius.circular(AppCard.defRadius),
    color: cardEnab_(context),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [

        Row(
          children: [
            Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    top: Dimen.iconMarg,
                    bottom: Dimen.iconMarg,
                    left: Dimen.iconMarg,
                  ),
                  child: KonspektSphereTitleWidget(KonspektSphere.duch),
                )
            ),
            AppButton(
              icon: AnimatedRotation(
                turns: _isExpanded ? 0 : -0.5,
                duration: SphereNonDuchWidgetState._animDuration,
                curve: SphereNonDuchWidgetState._animCurve,
                child: Icon(MdiIcons.chevronDown),
              ),
              onTap: () => setState(() => _isExpanded = !_isExpanded),
            ),
          ],
        ),

        Padding(
          padding: EdgeInsets.only(
            left: Dimen.sideMarg,
          ),
          child: AnimatedSize(
            duration: SphereNonDuchWidgetState._animDuration,
            curve: SphereNonDuchWidgetState._animCurve,
            alignment: Alignment.topCenter,
            child: _isExpanded
                ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildLevelSection(
                  context,
                  level: KonspektSphereLevel.duchPostawy,
                  controller: postawyController,
                  hint: 'Postawa:',
                  addButtonText: 'Dodaj postawę',
                ),

                _buildLevelSection(
                  context,
                  level: KonspektSphereLevel.duchWartosci,
                  controller: wartosciController,
                  hint: 'Wartość:',
                  addButtonText: 'Dodaj wartość',
                ),

                _buildLevelSection(
                  context,
                  level: KonspektSphereLevel.duchAksjomaty,
                  controller: aksjomatyController,
                  hint: 'Aksjomat:',
                  addButtonText: 'Dodaj aksjomat',
                ),

                _buildLevelSection(
                  context,
                  level: KonspektSphereLevel.duchSilaCharakteru,
                  controller: silaCharakteruController,
                  hint: 'Siła charakteru:',
                  addButtonText: 'Dodaj siłę charakteru',
                ),

                _buildLevelSection(
                  context,
                  level: KonspektSphereLevel.duchZdolnoscRefleksyjna,
                  controller: zdolnoscRefleksyjnaController,
                  hint: 'Zdolność refleksyjna:',
                  addButtonText: 'Dodaj zdolność refleksyjną',
                ),
              ],
            )
            : const SizedBox.shrink(),
          ),
        ),

      ],
    ),
  );

  Widget _buildLevelSection(
      BuildContext context, {
        required KonspektSphereLevel level,
        required _DuchLevelController controller,
        required String hint,
        required String addButtonText,
      }) {
    final isEmpty = controller.$1.length == 0;

    return AnimatedSize(
      duration: SphereNonDuchWidgetState._animDuration,
      curve: SphereNonDuchWidgetState._animCurve,
      alignment: Alignment.topCenter,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(height: Dimen.iconFootprint),
              Expanded(
                  child: Row(
                    children: [

                      SizedBox(width: Dimen.iconSize + Dimen.iconMarg),

                      Container(
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(AppCard.defRadius),
                            color: level.color.withValues(alpha: 0.1)
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(
                            Dimen.defMarg,
                          ),
                          child: level.getTextWidget(Dimen.textSizeBig),
                        ),
                      ),

                    ],
                  )

              ),
              if (isEmpty)
                AppButton(
                  icon: Icon(MdiIcons.plus),
                  onTap: () => setState(() {
                    controller.$1.texts = [''];
                    controller.$2.add({});
                  }),
                ),
            ],
          ),

          if (!isEmpty)
            Padding(
              padding: EdgeInsets.only(bottom: Dimen.iconMarg),
              child: AppTextFieldHint(
                multiController: controller.$1,
                hint: hint,
                hintTop: '',
                multiHintTop: '',
                textFieldHintPadding: EdgeInsets.zero,
                animationDuration: SphereNonDuchWidgetState._animDuration,
                onAnyChanged: (values) => callUpdate(level, values),
                multi: true,
                multiAllowZeroFields: true,
                multiLayout: LayoutMode.column,
                multiItemBuilder: (index, key, widget) => DuchLevelItemWidget(
                  index,
                  widget,
                  onChanged: (selectedKeywords) {
                    setState(() => controller.$2[index] = Set.of(selectedKeywords));
                    callUpdate(level, controller.$1.texts);
                  },
                  factors: controller.$2[index],
                  key: key,
                ),
                multiAddButtonBuilder: (bool tappable, void Function() onTap) => Padding(
                  padding: EdgeInsets.only(
                    right: Dimen.iconMarg,
                    left: Dimen.iconSize + Dimen.iconMarg,
                  ),
                  child: MultiTextFieldAddButton(
                    tappable: tappable,
                    text: addButtonText,
                    onTap: () {
                      onTap.call();
                      controller.$2.add({});
                    },
                  ),
                ),
                multiOnRemoved: (int index) => controller.$2.removeAt(index),
                multiIsCollapsed: true,
              ),
            ),
        ],
      ),

    );
  }

  void callUpdate(KonspektSphereLevel level, List<String> values){

    if(values.isEmpty)
      widget.onChanged?.call(null);
    else if (details == null){
      KonspektSphereDetails newSphereDetails = KonspektSphereDetails(
          levels: {
            level: KonspektSphereFields(
                fields: { for(var v in values) v: null}
            )
          }
      );
      widget.onChanged?.call(newSphereDetails);

    } else {
      KonspektSphereDetails? _details = details!.copy();

      _details.levels[level] = KonspektSphereFields(
          fields: { for(var v in values) v: null }
      );

      widget.onChanged?.call(_details);
    }

  }

}

class DuchLevelItemWidget extends StatelessWidget{

  final int index;
  final Widget textFieldWidget;
  final void Function(List<KonspektSphereFactor> selectedKeywords)? onChanged;
  final Set<KonspektSphereFactor>? factors;

  DuchLevelItemWidget(
      this.index,
      this.textFieldWidget,
      { this.onChanged,
        this.factors,
        super.key
      }
      );

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Because when having more than one item, the close button appears adding height.
      SizedBox(width: Dimen.iconSize + Dimen.iconMarg),
      SizedBox(
          child: Icon(MdiIcons.circleMedium),
          height: Dimen.iconFootprint
      ),
      SizedBox(width: Dimen.iconMarg),
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: Dimen.iconMarg),
          textFieldWidget,
          SizedBox(height: Dimen.iconMarg),
          KeywordSelectorWidget<KonspektSphereFactor>(
            selectedKeywords: factors??[],
            childBuilder: (context, factor) => Text(
              factor.displayName,
              style: AppTextStyle(
                  decoration: TextDecoration.underline,
                  fontSize: Dimen.textSizeBig
              ),
            ),
            leadingChildBuilder: (context) => Text(
              'Metody:',
              style: AppTextStyle(fontSize: Dimen.textSizeBig),
            ),
          ),
          SizedBox(height: Dimen.defMarg),

          Align(
            alignment: Alignment.centerLeft,
            child: SimpleButton.from(
                context: context,
                radius: AppCard.defRadius,
                padding: EdgeInsets.symmetric(
                    horizontal: Dimen.iconMarg,
                    vertical: Dimen.defMarg
                ),
                color: backgroundIcon_(context),
                margin: EdgeInsets.zero,
                icon: MdiIcons.pencilOutline,
                iconSize: 20.0,
                text: 'Edytuj metody',
                onTap: () => showDialog(
                    context: context,
                    builder: (context) =>
                        Center(
                          child: KeywordSelectorDialog<KonspektSphereFactor>(
                            maxDialogWidth: songDialogWidth,
                            allKeywords: KonspektSphereFactor.values,
                            selectedKeywords: factors??[],
                            childBuilder: (context, index, selected, toggle) => ListTile(
                              onTap: toggle,
                              leading: Icon(
                                  selected? MdiIcons.checkboxMarkedCircleOutline : MdiIcons.checkboxBlankCircleOutline
                              ),
                              title: Text(
                                KonspektSphereFactor.values[index].displayName,
                                style: AppTextStyle(
                                    decoration: TextDecoration.underline,
                                    fontSize: Dimen.textSizeBig
                                ),
                              ),
                            ),
                            separatorBuilder: (context, index) => SizedBox(height: Dimen.defMarg),
                            title: 'Wybierz metody',
                            onSaved: onChanged,
                          ),
                        )
                )
            ),
          ),

          SizedBox(height: Dimen.iconMarg),

        ],
      ))
    ],
  );

}

class KeywordSelectorWidget<T> extends StatelessWidget {

  final Iterable<T> selectedKeywords;
  final Widget Function(BuildContext context, T keyword) childBuilder;
  final Widget Function(BuildContext context)? leadingChildBuilder;
  final Widget Function(BuildContext context)? trailingChildBuilder;
  final void Function(List<T> selectedKeywords)? onChanged;

  const KeywordSelectorWidget({
    super.key,
    required this.selectedKeywords,
    required this.childBuilder,
    this.leadingChildBuilder,
    this.trailingChildBuilder,
    this.onChanged
  });

  @override
  Widget build(BuildContext context) =>
      Wrap(
        spacing: Dimen.defMarg,
        runSpacing: Dimen.defMarg,
        children: [
          if(leadingChildBuilder != null)
            leadingChildBuilder!.call(context),

          ...selectedKeywords.map((keyword) => childBuilder.call(
            context,
            keyword,
          )),

          if(trailingChildBuilder != null)
            trailingChildBuilder!.call(context),

        ],
      );

}

class KeywordSelectorDialog<T> extends StatefulWidget {

  final List<T> allKeywords;
  final Iterable<T> selectedKeywords;
  final Widget Function(BuildContext context, int index, bool selected, bool Function()) childBuilder;
  final Widget Function(BuildContext context, int index)? separatorBuilder;
  final String title;
  final double? maxDialogWidth;
  final void Function(List<T> selectedKeywords)? onSaved;

  const KeywordSelectorDialog({
    super.key,
    required this.allKeywords,
    required this.selectedKeywords,
    required this.childBuilder,
    this.separatorBuilder,
    required this.title,
    this.maxDialogWidth,
    this.onSaved
  });

  @override
  State<StatefulWidget> createState() => KeywordSelectorDialogState<T>();

}

class KeywordSelectorDialogState<T> extends State<KeywordSelectorDialog<T>>{

  late Set<T> selectedKeywords;

  @override
  void initState() {
    selectedKeywords = Set.of(widget.selectedKeywords);
    super.initState();
  }

  @override
  Widget build(BuildContext context) => Container(
    constraints: BoxConstraints(
      maxWidth: widget.maxDialogWidth??double.infinity,
    ),
    child: Dialog(
      backgroundColor: background_(context),
      clipBehavior: Clip.hardEdge,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppBarX(
            title: widget.title,
            actions: [
              AppButton(
                icon: Icon(MdiIcons.check),
                tooltip: 'Zapisz',
                onTap: (){
                  widget.onSaved?.call(selectedKeywords.toList());
                  popPage(context);
                },
              )
            ],
          ),
          Flexible(
              child: ListView.separated(
                itemBuilder: (context, index) =>
                    widget.childBuilder.call(
                        context,
                        index,
                        selectedKeywords.contains(widget.allKeywords[index]),
                        getOnSelected(index)
                    ),
                shrinkWrap: true,
                separatorBuilder: (context, index) => widget.separatorBuilder?.call(context, index)??Container(),
                itemCount: widget.allKeywords.length,
              )
          )
        ],
      ),
    ),
  );

  bool Function() getOnSelected(int index){
    bool onSelected() {
      bool selectedBefore = selectedKeywords.contains(
          widget.allKeywords[index]);
      if (selectedBefore)
        selectedKeywords.remove(widget.allKeywords[index]);
      else
        selectedKeywords.add(widget.allKeywords[index]);
      setState(() {});
      return !selectedBefore;
    }

    return onSelected;
  }

}

class FactorWidget extends StatelessWidget{

  final String keyword;

  const FactorWidget(this.keyword, {super.key});

  @override
  Widget build(BuildContext context) => Material(
      borderRadius: BorderRadius.circular(AppCard.defRadius),
      // color: backgroundIcon_(context),
      child: Padding(
        padding: EdgeInsets.all(0), // Dimen.defMarg),
        child: Text(
          keyword,
          style: AppTextStyle(
            decoration: TextDecoration.underline,
          ),
        ),
      )
  );

}