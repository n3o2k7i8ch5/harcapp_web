import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:harcapp_web/common/app_text_style.dart';
import 'package:harcapp_web/common/colors.dart';
import 'package:harcapp_web/common/dimen.dart';
import 'package:harcapp_web/common/simple_button.dart';
import 'package:implicitly_animated_reorderable_list/implicitly_animated_reorderable_list.dart';
import 'package:implicitly_animated_reorderable_list/transitions.dart';

import 'article_editor.dart';

class ArticlesOther extends StatefulWidget{

  final ArticleEditorPageState parent;

  const ArticlesOther(this.parent);

  @override
  State<StatefulWidget> createState() => ArticlesOtherState();

}

class ArticlesOtherState extends State<ArticlesOther>{

  List<OtherArtItem> get otherArts => widget.parent.otherArts;

  @override
  Widget build(BuildContext context) {
    return Card(
        child: Padding(
          padding: EdgeInsets.all(10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [

              Padding(
                padding: EdgeInsets.only(top: Dimen.MARG_ICON, right: Dimen.MARG_ICON, left: Dimen.MARG_ICON),
                child: Text(
                  'Odnośniki do innych artykułów:',
                  style: AppTextStyle(
                      fontSize: FONT_SIZE_NORM,
                      fontWeight: weight.halfBold,
                      color: AppColors.text_hint_enab
                  ),
                ),
              ),

              SizedBox(height: MARGIN,),

              ImplicitlyAnimatedReorderableList<OtherArtItem>(
                  items: otherArts,
                  areItemsTheSame: (oldItem, newItem) => oldItem.hashCode == newItem.hashCode,
                  onReorderFinished: (item, from, to, newItems) {
                    // Remember to update the underlying data when the list has been
                    // reordered.

                    widget.parent.setState(() {
                      otherArts
                        ..clear()
                        ..addAll(newItems);
                    });

                    print(otherArts.length);

                  },
                  itemBuilder: (context, itemAnimation, item, index) {

                    return Reorderable(
                      key: ValueKey(item.hashCode),
                      builder: (context, dragAnimation, inDrag) {
                        final t = dragAnimation.value;
                        final elevation = ui.lerpDouble(0, 8, t);
                        final color = Color.lerp(Colors.white, Colors.white.withOpacity(0.8), t);

                        return SizeFadeTransition(
                          sizeFraction: 0.7,
                          curve: Curves.easeInOut,
                          animation: itemAnimation,
                          child: Material(
                              color: color,
                              elevation: elevation,
                              type: MaterialType.transparency,
                              child: Row(
                                children: [

                                  Handle(
                                    child: Padding(
                                      padding: EdgeInsets.all(Dimen.MARG_ICON),
                                      child: Icon(
                                        Icons.list,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),

                                  IconButton(
                                    icon: Icon(Icons.close),
                                    onPressed: () =>
                                    widget.parent.setState(() =>
                                      widget.parent.otherArts.removeAt(index)
                                    ),
                                  ),

                                  Expanded(
                                    child: TextField(
                                      controller: TextEditingController(text: item.string),
                                      decoration: InputDecoration(
                                          hintText: 'Kod artykułu...',
                                          hintStyle: AppTextStyle(
                                              fontSize: FONT_SIZE_NORM,
                                              color: AppColors.text_hint_enab
                                          ),
                                          border: InputBorder.none
                                      ),
                                      style: AppTextStyle(fontSize: FONT_SIZE_NORM),
                                      onChanged: (text) => otherArts[index].string = text,
                                    ),
                                  )

                                ],
                              )
                          ),
                        );
                      },
                    );
                  },
                  shrinkWrap: true,
                  footer: Row(
                    children: [

                      SimpleButton(
                        onTap: (){
                          widget.parent.setState(() {
                            otherArts.add(OtherArtItem(''));
                          });
                        },
                        padding: EdgeInsets.zero,
                        child: Row(
                          children: [
                            Padding(
                              padding: EdgeInsets.all(Dimen.MARG_ICON),
                              child: Icon(Icons.add),
                            ),

                            Text(
                              'Dodaj artykuł',
                              style: AppTextStyle(
                                  fontSize: FONT_SIZE_NORM,
                                  fontWeight: weight.halfBold,
                                color: Colors.black
                              ),
                            ),

                            SizedBox(width: 2*Dimen.MARG_ICON,)

                          ],
                        ),
                      ),

                      Expanded(child: Container()),
                    ],
                  )
              ),

              //SizedBox(height: Dimen.icon_margin,)

            ],
          ),
        )
    );
  }

}

class OtherArtItem{

  static int id = 0;

  int _id;

  String string;

  OtherArtItem(this.string){
    _id = id++;
  }

  @override
  int get hashCode => _id.hashCode;

  @override
  bool operator == (Object other) => other is OtherArtItem && other.hashCode == hashCode;


}