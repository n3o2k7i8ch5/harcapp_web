import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:harcapp_core/comm_classes/color_pack.dart';
import 'package:harcapp_core/comm_widgets/app_toast.dart';

import '../top_navigation_bar.dart';

class BaseScaffold extends StatelessWidget{

  final GlobalKey? scaffoldKey;
  final Widget? drawer;
  final Widget body;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final Color? backgroundColor;
  final bool avoidKeyboard;
  final bool extendBody;

  const BaseScaffold({
    this.scaffoldKey,
    this.drawer,
    required this.body,
    this.backgroundColor,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.avoidKeyboard = true,
    this.extendBody = false,
    super.key
  });

  @override
  Widget build(BuildContext context) => MediaQuery.removePadding(
      context: context,
      child: Scaffold(
        key: scaffoldKey,
        appBar: TopNavigationBar(withMenuIcon: drawer!=null),
        drawer: drawer,
        body: body,
        backgroundColor: backgroundColor ?? background_(context),
        bottomNavigationBar: bottomNavigationBar,
        floatingActionButton: floatingActionButton,
        resizeToAvoidBottomInset: avoidKeyboard,
        extendBody: extendBody,
      )
  );

  static void showMessage(
      BuildContext context,
      String text,
      { String? buttonText,
        void Function()? onButtonPressed,
        Color? backgroundColor,
        Color? textColor,
        Duration duration = const Duration(seconds: 3)
      }){

    if(kIsWeb){
      Fluttertoast.showToast(
        msg: text,
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.CENTER,
        backgroundColor: backgroundColor,
        textColor: textColor,
        fontSize: 16.0,
        webPosition: 'center',
        timeInSecForIosWeb: duration.inSeconds,
        webShowClose: true,
      );
      return;
    }

    showAppToast(
        context,
        text: text,
        background: backgroundColor,
        textColor: textColor,
        duration: duration,

        buttonText: buttonText,
        onButtonPressed: () => onButtonPressed==null?null:onButtonPressed()
    );

  }

}
