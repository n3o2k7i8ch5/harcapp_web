import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:harcapp_web/common/app_card.dart';
import 'package:harcapp_web/common/app_text_style.dart';
import 'package:harcapp_web/common/color_pack.dart';
import 'package:harcapp_web/common/dimen.dart';
import 'package:harcapp_web/songs/core_own_song/common.dart';
import 'package:harcapp_web/songs/core_own_song/providers.dart';
import 'package:harcapp_web/songs/core_own_song/song_part_card.dart';
import 'package:harcapp_web/songs/page_widgets/scroll_to_bottom.dart';
import 'package:implicitly_animated_reorderable_list/implicitly_animated_reorderable_list.dart';
import 'package:implicitly_animated_reorderable_list/transitions.dart';
import 'package:provider/provider.dart';

class SongPartsListWidget extends StatelessWidget{

  final ScrollController controller;
  final Widget header;
  final Widget footer;
  final bool refrenTapable;
  final Function(SongPart, SongPartProvider) onPartTap;
  final bool shrinkWrap;
  final Function() onChanged;

  const SongPartsListWidget({
    this.controller,
    this.header,
    this.footer,
    this.refrenTapable: false,
    this.onPartTap,
    this.shrinkWrap: false,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<CurrentItemProvider>(
      builder: (context, prov, _) => ImplicitlyAnimatedReorderableList<SongPart>(
        physics: BouncingScrollPhysics(),
        controller: controller,
        items: prov.song.songParts,
        insertDuration: Duration(milliseconds: prov.song.songParts.length<=1?0:200),
        removeDuration: Duration(milliseconds: prov.song.songParts.length==0?0:500),
        areItemsTheSame: (oldItem, newItem) => oldItem.hashCode == newItem.hashCode,
        onReorderFinished: (item, from, to, newItems){
          //prov.copyWidth(songParts: newItems);
          prov.song.songParts = newItems;
        },
        itemBuilder: (context, itemAnimation, item, index) {

          return Reorderable(
            key: ValueKey(item.hashCode),
            builder: (context, dragAnimation, inDrag) {
              final t = dragAnimation.value;
              final elevation = ui.lerpDouble(0, AppCard.bigElevation, t);
              final color = Color.lerp(background(context), defCardEnabled(context), t);

              bool isRefren = item.isRefren(context);

              Widget child;

              if(isRefren)
                child = Consumer<RefrenPartProvider>(
                    builder: (context, prov, child) => getSongPartCard<RefrenPartProvider>(item, item.isRefren(context), prov)
                );

              else
                child = ChangeNotifierProvider<SongPartProvider>(
                  create: (context) => SongPartProvider(item),
                  builder: (context, child) => Consumer<SongPartProvider>(
                      builder: (context, prov, child) => getSongPartCard<SongPartProvider>(item, item.isRefren(context), prov)
                  ),
                );


              return SizeFadeTransition(
                  sizeFraction: 0.7,
                  curve: Curves.easeInOut,
                  animation: itemAnimation,
                  child: AppCard(
                      padding: EdgeInsets.only(left: Dimen.DEF_MARG/2, right: Dimen.DEF_MARG/2, bottom: Dimen.DEF_MARG/2),
                      margin: AppCard.defMargin.copyWith(bottom: 12),//AppCard.defMargin.copyWith(bottom: 2*elevation),
                      elevation: elevation,
                      color: color,
                      child: child
                  )
              );
            },
          );
        },
        padding: EdgeInsets.only(bottom: Dimen.DEF_MARG/2),
        shrinkWrap: shrinkWrap,
        header: header,
        footer: Column(
          children: [

            AnimatedContainer(
              duration: Duration(milliseconds: 1),
              height:
              prov.song.songParts.length==0?
              SongPartCard.EMPTY_HEIGHT + Dimen.ICON_FOOTPRINT + 4*Dimen.DEF_MARG
                  :0,
              child: AnimatedOpacity(
                opacity: prov.song.songParts.length==0?1:0,
                duration: Duration(milliseconds: 300),
                child: Center(
                  child: Text(
                    'Pusto! Dodaj coś.\n',
                    style: AppTextStyle(color: hintEnabled(context)),
                  ),
                ),
              ),
            ),

            if(footer!=null) footer,

          ],
        ),
      ),
    );
  }

  getSongPartCard<T extends SongPartProvider>(SongPart part, bool isRefren, T prov) => SongPartCard.from(
    type: isRefren?SongPartType.REFREN:SongPartType.ZWROTKA,
    songPart: part,
    topBuilder: (context, part){
      if(part.isRefren(context))
        return TopRefrenButtons(
          part,
          onDelete: (songPart){
            if(onChanged!=null) onChanged();
          },
        );
      else
        return TopZwrotkaButtons(
          part,
          onDuplicate: (SongPart part){
            scrollToBottom(controller);
            if(onChanged!=null) onChanged();
          },
          onDelete: (SongPart part){
            if(onChanged!=null) onChanged();
          },
        );
    },
    onTap: !refrenTapable && isRefren?null:() => onPartTap(part, prov),
  );

}