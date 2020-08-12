import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'main_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HarcApp Web',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
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
