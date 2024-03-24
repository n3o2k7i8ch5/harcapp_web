import 'package:flutter/material.dart';
import 'package:harcapp_core/comm_widgets/sliver_child_builder_separated_delegate.dart';
import 'package:harcapp_core/dimen.dart';
import 'package:harcapp_core/konspekts/data.dart';
import 'package:harcapp_core/konspekts/konspekt_thumbnail_widget.dart';

class TableOfContentWidget extends StatelessWidget{

  final void Function(int)? onItemTap;

  const TableOfContentWidget({this.onItemTap});

  @override
  Widget build(BuildContext context) => CustomScrollView(
    slivers: [

      SliverList(
        delegate: SliverChildSeparatedBuilderDelegate(
          (BuildContext context, int index) => SizedBox(
              height: 140,
              child: KonspektThumbnailWidget(
                allKonspekts[index],
                onTap: () => onItemTap?.call(index),
              )
          ),
          separatorBuilder: (BuildContext context, int index) => SizedBox(height: Dimen.defMarg),
          count: allKonspekts.length,
        ),
      ),

    ],
  );

}