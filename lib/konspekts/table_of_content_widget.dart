import 'package:flutter/material.dart';
import 'package:harcapp_core/comm_widgets/app_card.dart';
import 'package:harcapp_core/comm_widgets/sliver_child_builder_separated_delegate.dart';
import 'package:harcapp_core/dimen.dart';
import 'package:harcapp_core/konspekts/data.dart';
import 'package:harcapp_core/konspekts/konspekt.dart';
import 'package:harcapp_core/konspekts/konspekt_thumbnail_widget.dart';

class TableOfContentWidget extends StatelessWidget{

  final Konspekt? selectedKonspekt;
  final EdgeInsets? padding;
  final void Function(int)? onItemTap;

  const TableOfContentWidget({required this.selectedKonspekt, this.padding, this.onItemTap});

  @override
  Widget build(BuildContext context) => CustomScrollView(
    physics: BouncingScrollPhysics(),
    slivers: [

      SliverPadding(
        padding: padding??EdgeInsets.zero,
        sliver: SliverList(
          delegate: SliverChildSeparatedBuilderDelegate(
            (BuildContext context, int index) => SizedBox(
                height: 140,
                child: KonspektThumbnailWidget(
                  allKonspekts[index],
                  elevation: allKonspekts[index] == selectedKonspekt?AppCard.bigElevation:0,
                  onTap: () => onItemTap?.call(index),
                )
            ),
            separatorBuilder: (BuildContext context, int index) => SizedBox(height: Dimen.defMarg),
            count: allKonspekts.length,
          ),
        ),
      ),

    ],
  );

}