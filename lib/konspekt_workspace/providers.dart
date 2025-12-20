import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AttachmentsProvider extends ChangeNotifier{

  static AttachmentsProvider of(BuildContext context) => Provider.of<AttachmentsProvider>(context, listen: false);
  static void notify_(BuildContext context) => of(context).notifyListeners();

}

class KonspektEditorApp extends StatelessWidget{

  final Widget Function(BuildContext context, Widget? child) builder;

  const KonspektEditorApp({super.key, required this.builder});

  @override
  Widget build(BuildContext context) => MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (context) => AttachmentsProvider()),
    ],
    builder: builder,
  );

}