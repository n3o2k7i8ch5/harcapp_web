import 'package:flutter/material.dart';
import 'package:harcapp_core/comm_classes/app_text_style.dart';
import 'package:harcapp_core/comm_classes/color_pack.dart';
import 'package:harcapp_core/comm_widgets/app_card.dart';
import 'package:harcapp_core/comm_widgets/app_text.dart';
import 'package:harcapp_core/comm_widgets/simple_button.dart';
import 'package:harcapp_core/values/dimen.dart';

class DialogRoute extends PageRoute{

  Widget Function(BuildContext context) builder;
  bool dismissible;

  DialogRoute({required this.builder, this.dismissible = true});

  @override
  Color get barrierColor => Colors.black54;

  @override
  String? get barrierLabel => null;

  @override
  bool get opaque => false;

  @override
  bool get barrierDismissible => dismissible;

  @override
  Curve get barrierCurve => Curves.easeInOut;

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) => SafeArea(
      child: builder(context)
  );

  @override
  Widget buildTransitions(
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child
      ) => FadeTransition(
    opacity: animation,
    child: child,
  );

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 230);

}

Future<void> openDialog({
  required BuildContext context,
  required Widget Function(BuildContext context) builder,
  bool dismissible = true
}) => Navigator.push(
    context,
    DialogRoute(
      builder: builder,
      dismissible: dismissible,
    )
);

class AlertDialogButton extends StatelessWidget{

  final String text;
  final Color? textColor;
  final bool enabled;
  final void Function() onTap;

  const AlertDialogButton({required this.text, this.textColor, this.enabled = true, required this.onTap, super.key});

  @override
  Widget build(BuildContext context) => SimpleButton(
      radius: AppCard.bigRadius,
      padding: const EdgeInsets.all(Dimen.iconMarg),
      onTap: enabled?onTap:null,
      child: Text(text, style: AppTextStyle(fontWeight: weightHalfBold, color: textColor??(enabled?textEnab_(context):textDisab_(context)), fontSize: Dimen.textSizeBig))
  );

}

Future<void> showAlertDialog(
    BuildContext context,
    { required String title,
      required String content,
      Widget? leading,
      List<Widget> Function(BuildContext context)? actionBuilder,
      bool dismissible = true,
    }) => openDialog(
  context: context,
  dismissible: dismissible,
  builder: (BuildContext context) => AlertDialog(
    title: Text(title, style: AppTextStyle(fontWeight: weightHalfBold,)),
    content: Row(
      children: [
        if(leading != null) leading,
        Expanded(child: AppText(content, size: Dimen.textSizeBig))
      ],
    ),
    actions: actionBuilder==null?null:actionBuilder(context),
    actionsPadding: const EdgeInsets.only(bottom: Dimen.iconMarg, right: Dimen.iconMarg),
    backgroundColor: cardEnab_(context),
    contentTextStyle: TextStyle(color: textEnab_(context)),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimen.sideMarg)),
  ),
);