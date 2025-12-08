import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:harcapp_core/comm_classes/color_pack.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

const String attachmentEmbedType = 'attachment';

class AttachmentEmbed {
  final String id;
  final String title;

  const AttachmentEmbed({required this.id, required this.title});

  Embeddable toEmbeddable() => Embeddable(
        attachmentEmbedType,
        {'id': id, 'title': title},
      );

  static AttachmentEmbed? fromEmbeddable(Embeddable embeddable) {
    if (embeddable.type != attachmentEmbedType) return null;
    final data = embeddable.data as Map<String, dynamic>?;
    if (data == null) return null;
    return AttachmentEmbed(
      id: data['id'] as String? ?? '',
      title: data['title'] as String? ?? '',
    );
  }
}

class AttachmentEmbedBuilder extends EmbedBuilder {
  @override
  String get key => attachmentEmbedType;

  @override
  bool get expanded => false;

  @override
  Widget build(
    BuildContext context,
    EmbedContext embedContext,
  ) {
    final embed = AttachmentEmbed.fromEmbeddable(embedContext.node.value);
    if (embed == null) {
      return const SizedBox.shrink();
    }

    return _AttachmentEmbedWidget(embed: embed);
  }
}

class _AttachmentEmbedWidget extends StatelessWidget {
  final AttachmentEmbed embed;

  const _AttachmentEmbedWidget({required this.embed});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
        decoration: BoxDecoration(
          color: iconEnab_(context).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(3),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              MdiIcons.paperclip,
              size: 12,
              color: iconEnab_(context),
            ),
            const SizedBox(width: 3),
            Text(
              embed.title,
              style: TextStyle(
                color: iconEnab_(context),
                fontSize: 13,
                height: 1.2,
              ),
            ),
          ],
        ),
      );
}
