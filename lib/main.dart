import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:harcapp_core/comm_classes/app_text_style.dart';
import 'package:harcapp_core/comm_classes/color_pack.dart';
import 'package:harcapp_core/comm_widgets/app_card.dart';
import 'package:harcapp_core/dimen.dart';

import 'main_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {

  @override
  Widget build(BuildContext context) {

    ColorPack _realColorPack = ColorPackGraphite();

    return MaterialApp(
      title: 'HarcApp Web',
      theme: ThemeData(
        appBarTheme: AppBarTheme(
            color: _realColorPack.appBar,
            textTheme: TextTheme(
              headline6: AppTextStyle(fontSize: Dimen.TEXT_SIZE_APPBAR, color: _realColorPack.appBarTextEnabled),
              headline5: AppTextStyle(fontSize: Dimen.TEXT_SIZE_APPBAR, color: _realColorPack.appBarTextDisabled),
            ),
            actionsIconTheme: IconThemeData(color: _realColorPack.appBarTextEnabled),
            iconTheme: IconThemeData(color: _realColorPack.appBarTextEnabled)
        ),
        textTheme: TextTheme(
            bodyText1: TextStyle(color: _realColorPack.textEnabled),
            bodyText2: TextStyle(color: _realColorPack.textEnabled),
            subtitle1: TextStyle(color: _realColorPack.hintEnabled),
            subtitle2: TextStyle(color: _realColorPack.hintEnabled)
        ).apply(
          //bodyColor: _realColorPack.textEnabled,
          //displayColor: _realColorPack.textEnabled,
        ),
        timePickerTheme: TimePickerThemeData(
          backgroundColor: _realColorPack.background,
          //hourMinuteColor: _realColorPack.accentColor.withOpacity(0.3),
          //hourMinuteTextColor: _realColorPack.accentColor,
          dialHandColor: _realColorPack.accentColor,
          helpTextStyle: AppTextStyle(color: _realColorPack.hintEnabled),
          dayPeriodTextStyle: AppTextStyle(),
          hourMinuteTextStyle: TextStyle(
            fontSize: 48,
          ),
          hourMinuteShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(10.0))
          ),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(AppCard.defRadius))
          ),
        ),
        textSelectionHandleColor: _realColorPack.accentColor,
        textSelectionColor: _realColorPack.accentColor.withOpacity(0.5),

        primaryTextTheme: TextTheme(
          bodyText1: TextStyle(color: _realColorPack.textDrawer),
          bodyText2: TextStyle(color: _realColorPack.textDrawer),
          subtitle1: TextStyle(color: _realColorPack.hintDrawer),
          subtitle2: TextStyle(color: _realColorPack.hintDrawer),
        ),
        backgroundColor: _realColorPack.background,
        scaffoldBackgroundColor: _realColorPack.background,

        toggleableActiveColor: _realColorPack.accentColor,
        unselectedWidgetColor: _realColorPack.hintEnabled,

        bottomSheetTheme: BottomSheetThemeData(
          backgroundColor: _realColorPack.background,
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          selectedIconTheme: IconThemeData(color: _realColorPack.iconEnabledColor),
          unselectedIconTheme: IconThemeData(color: _realColorPack.iconDisabledColor),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: _realColorPack.accentColor,
          foregroundColor: _realColorPack.accentIconColor,
        ),

        cardColor: _realColorPack.defCardEnabled,
        cardTheme: CardTheme(
            color: _realColorPack.defCardEnabled,
            shadowColor: _realColorPack.defCardElevation
        ),

        disabledColor: _realColorPack.disabled,
        inputDecorationTheme: InputDecorationTheme(
            fillColor: _realColorPack.textEnabled
        ),

        //primarySwatch: _realColorPack.mainColor,
        primaryColor: _realColorPack.mainColor,
        primaryColorDark: _realColorPack.darkColor,
        primaryColorLight: _realColorPack.lightColor,
        accentColor: _realColorPack.accentColor,
        accentIconTheme: IconThemeData(
            color: _realColorPack.accentIconColor
        ),
        accentTextTheme: TextTheme().apply(
            displayColor: _realColorPack.accentIconColor,
            bodyColor: _realColorPack.accentIconColor
        ),
        selectedRowColor: _realColorPack.accentColor.withOpacity(0.3),
        iconTheme: IconThemeData(
            color: _realColorPack.iconEnabledColor
        ),
      ),
      home: MainPage(),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate, // ONLY if it's a RTL language
      ],
      supportedLocales: const [
        Locale('pl', 'PL'), // include country code too
      ],
    );
  }
}
