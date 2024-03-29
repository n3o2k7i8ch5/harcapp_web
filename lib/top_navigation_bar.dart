import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:harcapp_core/comm_classes/app_text_style.dart';
import 'package:harcapp_core/comm_classes/color_pack.dart';
import 'package:harcapp_core/comm_widgets/app_card.dart';
import 'package:harcapp_core/comm_widgets/harc_app.dart';
import 'package:harcapp_core/comm_widgets/simple_button.dart';
import 'package:harcapp_core/dimen.dart';
import 'package:harcapp_web/router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import 'main.dart';

class TopNavigationBar extends StatefulWidget{

  static const denseMaxWidth = 1040;

  @override
  State<StatefulWidget> createState() => TopNavigationBarState();

}

class TopNavigationBarState extends State<TopNavigationBar>{

  Widget? body;
  String? version;
  void establishVersion() async {
    version = (await PackageInfo.fromPlatform()).version;
    setState(() {});
  }

  @override
  void initState() {
    establishVersion();
    super.initState();
  }

  @override
  Widget build(BuildContext context) => Material(
    elevation: AppCard.bigElevation,
      color: cardEnab_(context),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) => Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [

            if(constraints.maxWidth >= TopNavigationBar.denseMaxWidth)
              SizedBox(width: 24.0),

            if(constraints.maxWidth >= TopNavigationBar.denseMaxWidth)
              HarcApp(size: 24.0),

            if(constraints.maxWidth >= TopNavigationBar.denseMaxWidth)
              SizedBox(width: 24.0),

            Expanded(child: Container()),

            PageNavItem(
              icon: MdiIcons.dominoMask,
              title: 'Polityka prywatności',
              subtitle: 'Czyli nic interesującego',
              path: pathPrivacyPolicy,
              dense: constraints.maxWidth < TopNavigationBar.denseMaxWidth,
            ),

            PageNavItem(
              icon: MdiIcons.notebookOutline,
              title: 'Konspekty',
              subtitle: 'Inspiracje na pracę harcerską!',
              path: pathKonspekty,
              dense: constraints.maxWidth < TopNavigationBar.denseMaxWidth,
            ),

            PageNavItem(
              icon: MdiIcons.music,
              title: 'Warsztat piosenki',
              subtitle: 'Twórz i dodawaj!',
              path: pathSong,
              dense: constraints.maxWidth < TopNavigationBar.denseMaxWidth,
            ),

            PageNavItem(
              icon: MdiIcons.trayArrowDown,
              title: 'Pobierz HarcAppkę',
              subtitle: MyAppState.availableAppVersion,
              path: pathDownload,
              dense: constraints.maxWidth < TopNavigationBar.denseMaxWidth,
            ),

            SizedBox(width: 12.0),

          ],
        ),
      )
  );

}

class PageNavItem extends StatelessWidget{

  static const double height = 58;

  final IconData icon;
  final String title;
  final String? subtitle;
  final String path;
  final bool dense;

  const PageNavItem({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.path,
    required this.dense,
  });

  @override
  Widget build(BuildContext context) =>
  dense?
  SimpleButton.from(
    padding: EdgeInsets.all((height - Dimen.iconSize)/2),
    margin: EdgeInsets.zero,
    textColor: textEnab_(context),
    radius: 0,
    icon: icon,
    color: GoRouterState.of(context).uri.toString() == path?backgroundIcon_(context):null,
    onTap: () => context.go(path),
  ):
  IntrinsicWidth(
      child: ListTile(
        dense: true,
        tileColor: GoRouterState.of(context).uri.toString() == path?backgroundIcon_(context):null,
        selectedColor: backgroundIcon_(context),
        onTap: () => context.go(path),
        leading: Icon(icon),
        title: Text(
          '$title   ',
          style: AppTextStyle(),
          maxLines: 1,
        ),
        subtitle: subtitle==null?null:Text(
          subtitle!,
          style: AppTextStyle(),
          maxLines: 1,
        ),
      ),
  );

}