
import 'package:flutter/material.dart';

import 'colors.dart';

enum weight{thin, normal, halfBold, bold}

class AppTextStyle extends TextStyle{

  const AppTextStyle({Color color: AppColors.text_def_enab, weight fontWeight:weight.normal, fontSize, bool shadow, FontStyle fontStyle, double height: 1.0}):super(
      fontFamily: 'Ubuntu',
      color: color,
      fontStyle: fontStyle,
      fontWeight:
      fontWeight == weight.thin?FontWeight.w100:
      (fontWeight == weight.normal?FontWeight.w300:
      (fontWeight == weight.halfBold?FontWeight.w500:
      /*fontWeight == weight.bold?*/FontWeight.w700)),
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

class ArticleTextStyle extends TextStyle{

  const ArticleTextStyle({Color color: AppColors.text_def_enab, weight fontWeight:weight.normal, fontSize, bool shadow, FontStyle fontStyle, double height: 1.0}):super(
      fontFamily: 'Gentium',
      color: color,
      fontStyle: fontStyle,
      fontWeight:
      fontWeight == weight.thin?FontWeight.w100:
      (fontWeight == weight.normal?FontWeight.w300:
      (fontWeight == weight.halfBold?FontWeight.w500:
      /*fontWeight == weight.bold?*/FontWeight.w700)),
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