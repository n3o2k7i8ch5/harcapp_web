import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:implicitly_animated_reorderable_list_2/implicitly_animated_reorderable_list_2.dart';
import 'package:implicitly_animated_reorderable_list_2/transitions.dart';

import 'article_editor.dart';
import 'common.dart';
import 'widgets.dart';

class ArticleElementListWidget extends StatefulWidget{

  List<ArticleElement?>? get articleElements => page.articleElements;

  final ArticleEditorPageState page;

  final Widget? header;
  final Widget? footer;

  final ScrollController? scrollController;

  const ArticleElementListWidget({required this.page, this.header, this.footer, this.scrollController});

  @override
  State<StatefulWidget> createState() => ArticleElementListWidgetState();

}

class ArticleElementListWidgetState extends State<ArticleElementListWidget>{

  List<ArticleElement?>? get articleElements => widget.articleElements;

  @override
  Widget build(BuildContext context) {
    return ImplicitlyAnimatedReorderableList<ArticleElement>(
      items: articleElements as List<ArticleElement>,
      controller: widget.scrollController,
      areItemsTheSame: (oldItem, newItem) => oldItem.hashCode == newItem.hashCode,
      onReorderFinished: (item, from, to, newItems) {
        // Remember to update the underlying data when the list has been
        // reordered.

        setState(() {
          articleElements
            ?..clear()
            ..addAll(newItems);
        });
      },
      itemBuilder: (context, itemAnimation, item, index) {

        Widget? child;
        if(item is Paragraph)
          child = ParagraphWidget(
              widget.page,
              item
          );
        else if (item is Header)
          child = HeaderWidget(
              widget.page,
              item
          );

        return Reorderable(
          key: ValueKey(item.hashCode),
          builder: (context, dragAnimation, inDrag) {
            final t = dragAnimation.value;
            final elevation = ui.lerpDouble(0, 8, t)!;
            final color = Color.lerp(Colors.white, Colors.white.withValues(alpha: 0.8), t);

            return SizeFadeTransition(
              sizeFraction: 0.7,
              curve: Curves.easeInOut,
              animation: itemAnimation,
              child: Material(
                  color: color,
                  elevation: elevation,
                  type: MaterialType.transparency,
                  child: child
              ),
            );
          },
        );
      },
      header: widget.header??Container(),
      footer: widget.footer??Container(),
      shrinkWrap: true,
      padding: EdgeInsets.all(MARGIN),
    );
  }

}
