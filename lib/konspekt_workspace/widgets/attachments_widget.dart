import 'dart:ui';

import 'package:animated_reorderable_list/animated_reorderable_list.dart';
import 'package:flutter/material.dart';
import 'package:harcapp_core/comm_classes/color_pack.dart';
import 'package:harcapp_core/comm_widgets/app_card.dart';
import 'package:harcapp_core/comm_widgets/simple_button.dart';
import 'package:harcapp_core/values/dimen.dart';
import 'package:harcapp_web/konspekt_workspace/models/konspekt_attachment_data.dart';
import 'package:harcapp_web/konspekt_workspace/widgets/attachment_widget.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class AttachmentsWidget extends StatefulWidget {
  final List<KonspektAttachmentData> attachments;
  final void Function(String attachmentId)? onRemoveAttachment;
  const AttachmentsWidget(this.attachments, {super.key, this.onRemoveAttachment});

  @override
  State<AttachmentsWidget> createState() => _AttachmentsWidgetState();
}

class _AttachmentsWidgetState extends State<AttachmentsWidget> {
  // final List<int> _ids = [DateTime.now().microsecondsSinceEpoch];

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AnimatedReorderableListView(
            buildDefaultDragHandles: false,
            proxyDecorator: proxyDecorator,
            physics: const NeverScrollableScrollPhysics(),
            items: widget.attachments,
            clipBehavior: Clip.none,
            dragStartDelay: Duration(milliseconds: 300),
            isSameItem: (oldItem, newItem) => oldItem == newItem,
            onReorder: (int oldIndex, int newIndex) {
              final KonspektAttachmentData attachment = widget.attachments.removeAt(oldIndex);
              widget.attachments.insert(newIndex, attachment);
              setState(() {});
            },
            itemBuilder: (BuildContext context, int index) => Padding(
              key: ValueKey("attachment_${widget.attachments[index].name}"),
              padding: EdgeInsets.only(bottom: index < widget.attachments.length - 1 ? Dimen.defMarg : 0),
              child: AttachmentWidget(
                  data: widget.attachments[index],
                  onChange: () => setState(() {}),
                  onRemove: () {
                    final removedId = widget.attachments[index].name;
                    setState(() => widget.attachments.removeAt(index));
                    widget.onRemoveAttachment?.call(removedId);
                  }
              ),
            ),
            shrinkWrap: true,
            enterTransition: [FadeIn()],
            exitTransition: [SlideInDown(), FadeIn()],
          ),

          const SizedBox(height: Dimen.defMarg),

          SimpleButton.from(
            context: context,
            radius: AppCard.defRadius,
            color: backgroundIcon_(context),
            icon: MdiIcons.plus,
            margin: EdgeInsets.zero,
            text: 'Dodaj załącznik',
            onTap: () => setState(() =>
                widget.attachments.add(KonspektAttachmentData.empty())),
          )
        ],
      );

  Widget proxyDecorator(
    Widget child,
    int index,
    Animation<double> animation,
  ) =>
      AnimatedBuilder(
        animation: animation,
        builder: (BuildContext context, Widget? child) {
          final double animValue = Curves.easeInOut.transform(animation.value);
          return Material(
            borderRadius: BorderRadius.circular(AppCard.defRadius),
            elevation: lerpDouble(0, AppCard.bigElevation, animValue)!,
            color: Color.lerp(background_(context), cardEnab_(context), animValue),
            child: child,
          );
        },
        child: child,
      );
}
