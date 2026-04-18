import 'package:flutter/material.dart';
import 'package:harcapp_core/comm_classes/app_text_style.dart';
import 'package:harcapp_core/comm_classes/color_pack.dart';
import 'package:harcapp_core/comm_widgets/app_button.dart';
import 'package:harcapp_core/comm_widgets/app_card.dart';
import 'package:harcapp_core/comm_widgets/sliver_child_builder_separated_delegate.dart';
import 'package:harcapp_core/harcthought/harc_forms/data.dart';
import 'package:harcapp_core/harcthought/harc_forms/harc_form.dart';
import 'package:harcapp_core/harcthought/harc_forms/harc_form_tile_widget.dart';
import 'package:harcapp_core/values/dimen.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class TableOfContentFormyWidget extends StatefulWidget {
  final HarcForm? selectedForm;
  final void Function(HarcForm) onFormTap;

  const TableOfContentFormyWidget({
    required this.selectedForm,
    required this.onFormTap,
    super.key,
  });

  @override
  State<TableOfContentFormyWidget> createState() => _TableOfContentFormyWidgetState();
}

class _TableOfContentFormyWidgetState extends State<TableOfContentFormyWidget> {
  HarcForm? get selectedForm => widget.selectedForm;
  void Function(HarcForm) get onFormTap => widget.onFormTap;

  late TextEditingController _controller;
  late List<HarcForm> _filtered;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _filtered = List.of(allForms);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onSearch(String phrase) {
    final q = phrase.toLowerCase().trim();
    setState(() {
      _filtered = q.isEmpty
          ? List.of(allForms)
          : allForms.where((f) => f.title.toLowerCase().contains(q)).toList();
    });
  }

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Padding(
        padding: const EdgeInsets.only(top: Dimen.iconFootprint / 2),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: EdgeInsets.all(Dimen.defMarg).copyWith(top: Dimen.defMarg + Dimen.iconFootprint / 2),
              sliver: SliverList(
                delegate: SliverChildSeparatedBuilderDelegate(
                  (context, i) {
                    final HarcForm form = _filtered[i];
                    final bool selected = selectedForm?.filename == form.filename;
                    return SizedBox(
                      height: 162,
                      child: Material(
                        borderRadius: BorderRadius.circular(AppCard.defRadius),
                        clipBehavior: Clip.antiAlias,
                        color: background_(context),
                        elevation: selected ? AppCard.bigElevation : 0,
                        child: FormTileWidget(
                          form,
                          radius: 0,
                          onTap: () => onFormTap(form),
                        ),
                      ),
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(height: Dimen.defMarg),
                  count: _filtered.length,
                ),
              ),
            ),
          ],
        ),
      ),

      Positioned(
        top: 0,
        right: 0,
        left: 0,
        child: Material(
          elevation: AppCard.bigElevation,
          borderRadius: BorderRadius.circular(AppCard.bigRadius - 4),
          color: cardEnab_(context),
          child: Row(
            children: [
              if (_controller.text.isNotEmpty)
                AppButton(
                  icon: Icon(MdiIcons.close),
                  onTap: () {
                    _controller.clear();
                    _onSearch('');
                  },
                )
              else
                Padding(
                  padding: const EdgeInsets.all(Dimen.iconMarg),
                  child: Icon(MdiIcons.magnify, color: hintEnab_(context)),
                ),
              Expanded(
                child: TextField(
                  controller: _controller,
                  style: AppTextStyle(),
                  decoration: InputDecoration(
                    hintText: 'Szukaj',
                    hintStyle: AppTextStyle(color: hintEnab_(context)),
                    border: InputBorder.none,
                  ),
                  onChanged: _onSearch,
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}
