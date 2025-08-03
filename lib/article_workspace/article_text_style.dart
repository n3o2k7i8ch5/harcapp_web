import 'package:flutter/material.dart';

import 'package:harcapp_core/values/colors.dart';
import 'package:harcapp_core/comm_classes/app_text_style.dart';

class ArticleTextStyle extends TextStyle{

  const ArticleTextStyle({Color color = AppColors.textDefEnab, FontWeight fontWeight = weightNormal, fontSize, bool? shadow, FontStyle? fontStyle, double height = 1.0}):super(
      fontFamily: 'Gentium',
      color: color,
      fontStyle: fontStyle,
      fontWeight: fontWeight,
      fontSize: fontSize,
      height: height,
      shadows: shadow==true?
      const [Shadow(
        offset: const Offset(1.0, 1.0),
        blurRadius: 3.0,
        color: const Color.fromARGB(64, 0, 0, 0),
      )
      ]:null
  );
}