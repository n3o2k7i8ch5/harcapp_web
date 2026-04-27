import 'package:flutter/material.dart';
import 'package:harcapp_core/comm_classes/app_text_style.dart';
import 'package:harcapp_core/comm_classes/color_pack.dart';
import 'package:harcapp_core/comm_classes/common.dart';
import 'package:harcapp_core/comm_classes/storage.dart';
import 'package:harcapp_core/comm_widgets/app_card.dart';
import 'package:harcapp_core/comm_widgets/gradient_icon.dart';
import 'package:harcapp_core/harcthought/harc_forms/base_harc_form_widget.dart';
import 'package:harcapp_core/harcthought/harc_forms/harc_form.dart';
import 'package:harcapp_core/harcthought/harcapp_links.dart';
import 'package:harcapp_core/harcthought/harcapp_share_button.dart';
import 'package:harcapp_core/values/dimen.dart';
import 'package:harcapp_web/common/base_scaffold.dart';
import 'package:harcapp_web/consts.dart';
import 'package:harcapp_web/konspekts/konspekty_tabs_row.dart';
import 'package:harcapp_web/konspekts/table_of_content_formy_widget.dart';

const double _defPaddingVal = 32.0;

class HarcFormyPage extends StatefulWidget {

  const HarcFormyPage({super.key});

  @override
  State<HarcFormyPage> createState() => _HarcFormyPageState();

}

class _HarcFormyPageState extends State<HarcFormyPage> {
  static const double collapseWidth = 920;

  HarcForm? selectedForm;
  late GlobalKey<ScaffoldState> scaffoldKey;

  @override
  void initState() {
    scaffoldKey = GlobalKey();
    post(tryOpenDrawerIfCollapsed);
    super.initState();
  }

  Future<void> tryOpenDrawerIfCollapsed() async {
    if (MediaQuery.of(context).size.width > collapseWidth) return;
    await Future.delayed(Duration.zero);
    scaffoldKey.currentState?.openDrawer();
  }

  void _selectForm(HarcForm form, {required bool closeDrawer}) {
    setState(() => selectedForm = form);
    if (closeDrawer) scaffoldKey.currentState?.closeDrawer();
  }

  Widget _buildFormList(BuildContext context, {bool isDrawer = false}) =>
      TableOfContentFormyWidget(
        selectedForm: selectedForm,
        onFormTap: (form) => _selectForm(form, closeDrawer: isDrawer),
      );

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final bool workspaceAlwaysVisible = constraints.maxWidth > collapseWidth;

      return BaseScaffold(
        scaffoldKey: scaffoldKey,
        backgroundColor: cardEnab_(context),
        drawer: workspaceAlwaysVisible
            ? null
            : Drawer(
                backgroundColor: background_(context),
                width: drawerWidth,
                child: _buildFormList(context, isDrawer: true),
              ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const KonspektyTabsRow(),
            Expanded(
              child: Material(
                color: background_(context),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppCard.defRadius),
                  topRight: Radius.circular(AppCard.defRadius),
                ),
                clipBehavior: Clip.antiAlias,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (workspaceAlwaysVisible)
                      Padding(
                        padding: const EdgeInsets.only(
                          top: _defPaddingVal,
                          left: _defPaddingVal,
                        ),
                        child: SizedBox(
                          width: drawerWidth,
                          child: _buildFormList(context),
                        ),
                      ),
                    Expanded(
                      child: selectedForm == null
                          ? Center(
                              child: Text(
                                'Wybierz formę z listy',
                                style: AppTextStyle(
                                  fontSize: Dimen.textSizeBig,
                                  color: textDisab_(context),
                                ),
                              ),
                            )
                          : _FormDetailWidget(
                              selectedForm!,
                              key: ValueKey(selectedForm!.filename),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _FormDetailWidget extends StatefulWidget {
  final HarcForm form;

  const _FormDetailWidget(this.form, {super.key});

  @override
  State<_FormDetailWidget> createState() => _FormDetailWidgetState();
}

class _FormDetailWidgetState extends State<_FormDetailWidget> {
  HarcForm get form => widget.form;
  String? text;

  @override
  void initState() {
    super.initState();
    _loadText();
  }

  void _loadText() async {
    final loaded = await readStringFromAssets(
        'packages/harcapp_core/assets/forms/${form.filename}');
    if (mounted) setState(() => text = loaded);
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(Dimen.sideMarg),
    physics: const BouncingScrollPhysics(),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: defPageWidth),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            const SizedBox(height: 2 * Dimen.sideMarg),

            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GradientIcon(
                  form.icon,
                  colorStart: form.colorStart,
                  colorEnd: form.colorEnd,
                  size: 72,
                ),
                const SizedBox(width: Dimen.sideMarg),
                Expanded(
                  child: Text(
                    form.title,
                    style: const AppTextStyle(
                      fontSize: 26.0,
                      fontWeight: weightBold,
                    ),
                  ),
                ),
                HarcappShareButton(
                  url: HarcappLinks.formaOf(form),
                  subject: form.title,
                ),
              ],
            ),

            const SizedBox(height: 2 * Dimen.sideMarg),

            Wrap(
              spacing: Dimen.defMarg,
              runSpacing: Dimen.defMarg,
              children: [
                for (final tag in form.tags)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(tag.icon),
                      const SizedBox(width: Dimen.iconMarg),
                      Text(
                        tag.text,
                        style: const AppTextStyle(
                          fontWeight: weightHalfBold,
                          fontSize: Dimen.textSizeNormal,
                        ),
                      ),
                    ],
                  ),
              ],
            ),

            const SizedBox(height: 2 * Dimen.sideMarg),

            if (text != null)
              Material(
                color: cardEnab_(context),
                borderRadius: BorderRadius.circular(AppCard.defRadius),
                child: Padding(
                  padding: const EdgeInsets.all(Dimen.sideMarg),
                  child: Text(
                    text!,
                    style: const AppTextStyle(fontSize: Dimen.textSizeBig),
                    textAlign: TextAlign.justify,
                  ),
                ),
              ),

            const SizedBox(height: 2 * Dimen.sideMarg),

            MetoResponsiveWidget(form),

            const SizedBox(height: Dimen.sideMarg),

          ],
        ),
      ),
    ),
  );
}
