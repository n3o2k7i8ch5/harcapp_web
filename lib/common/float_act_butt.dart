import 'package:flutter/material.dart';
import 'package:harcapp_core/comm_classes/app_text_style.dart';
import 'package:harcapp_core/values/dimen.dart';

class FloatingButton extends StatelessWidget{

  final IconData iconData;
  final Color color;
  final String text;
  final void Function()? onPressed;
  final bool? saving;

  const FloatingButton(this.iconData, this.color, this.text, this.onPressed, {this.saving = false});

  @override
  Widget build(BuildContext context) => RawMaterialButton(
      fillColor: color,
      padding: EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
      elevation: 6.0,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          saving!?
          SizedBox(
            width: Dimen.iconSize,
            height: Dimen.iconSize,
            child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                backgroundColor: Colors.transparent
            ),
          ):
          Icon(iconData, color: Colors.white),

          SizedBox(width: 16),

          Text(
              text,
              style: AppTextStyle(
                  fontWeight: weightBold,
                  fontSize: 16,
                  color: Colors.white
              )
          ),
          SizedBox(width: 10),
        ],
      ),
      onPressed: onPressed
  );

}
