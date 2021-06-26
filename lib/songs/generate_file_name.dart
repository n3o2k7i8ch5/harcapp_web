import 'package:flutter/cupertino.dart';
import 'package:harcapp_core/comm_classes/common.dart';

String generateFileName({bool isConf: false, required String title}){
  return (isConf?'oc!_':'o!_') + remPolChars(title)
      .replaceAll(' ', '_')
      .replaceAll(',', '')
      .replaceAll('.', '')
      .replaceAll('(', '')
      .replaceAll(')', '')
      .replaceAll(':', '')
      .replaceAll(';', '')
      .replaceAll('"', '');
}