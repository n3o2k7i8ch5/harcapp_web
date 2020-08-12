import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

void showToast(String text){

  Fluttertoast.showToast(
    msg: text,
    toastLength: Toast.LENGTH_LONG,
    gravity: ToastGravity.CENTER,
    backgroundColor: Colors.black,
    textColor: Colors.white,
    fontSize: 16.0,
    webPosition: 'center',
    timeInSecForIosWeb: 3,
    webShowClose: true,
  );

}