

import 'package:flutter/material.dart';
import 'package:harcapp_core/comm_classes/app_text_style.dart';
import 'package:harcapp_core/dimen.dart';

class FloatingButton extends StatelessWidget{

  IconData iconData;
  Color color;
  String text;
  Function? onPressed;
  bool? saving;

  FloatingButton(this.iconData, this.color, this.text, this.onPressed, {this.saving: false});

  @override
  Widget build(BuildContext context) {

    return RawMaterialButton(
        fillColor: color,
        padding: EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(100))),
        elevation: 6.0,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            saving!?
            SizedBox(
              width: Dimen.ICON_SIZE,
              height: Dimen.ICON_SIZE,
              child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  backgroundColor: Colors.transparent
              ),
            ):
            Icon(
              iconData,
              color: Colors.white,
            ),

            SizedBox(width: 16),

            Text(
                text,
                style: AppTextStyle(
                    fontWeight: weight.bold,
                    fontSize: 16,
                    color: Colors.white
                )
            ),
            SizedBox(width: 10),
          ],
        ),
        onPressed: onPressed as void Function()?
    );
  }

}
