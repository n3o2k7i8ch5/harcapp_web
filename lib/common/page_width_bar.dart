import 'package:flutter/material.dart';
import 'package:harcapp_web/consts.dart';

/// Pasek (np. TabBar/toolbar) z tłem rozciągniętym od brzegu do brzegu ekranu,
/// którego zawartość ma minimalną szerokość [defPageWidth] i jest centrowana.
///
/// Gdy zawartość mieści się w [defPageWidth], strefa zawartości ma dokładnie
/// tę szerokość (czyli pokrywa się ze strefą głównego widoku poniżej), więc
/// `tabAlignment: TabAlignment.start` ustawia ją przy lewej krawędzi tej strefy.
/// Gdy zawartość jest szersza niż [defPageWidth], strefa rośnie razem z nią
/// (do szerokości ekranu) i całość jest centrowana.
class PageWidthBar extends StatelessWidget {

  final Color backgroundColor;
  final Widget child;

  const PageWidthBar({
    required this.backgroundColor,
    required this.child,
    super.key,
  });

  @override
  Widget build(BuildContext context) => Material(
    color: backgroundColor,
    child: LayoutBuilder(
      builder: (context, constraints) {
        final double minWidth = constraints.maxWidth < defPageWidth
            ? constraints.maxWidth
            : defPageWidth;
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: minWidth,
              maxWidth: constraints.maxWidth,
            ),
            child: child,
          ),
        );
      },
    ),
  );
}
