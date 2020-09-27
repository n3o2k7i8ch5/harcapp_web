import 'package:flutter/cupertino.dart';
import 'package:harcapp_web/common/core_comm_classes/common.dart';

scrollToBottom(ScrollController controller) async {
  await Future.delayed(Duration(milliseconds: 240));
  await controller.animateTo(
      controller.position.maxScrollExtent,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut);
}