import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:harcapp_core/comm_classes/app_text_style.dart';
import 'package:harcapp_core/comm_classes/color_pack.dart';
import 'package:harcapp_core/comm_widgets/app_card.dart';
import 'package:harcapp_core/comm_widgets/harc_app.dart';
import 'package:harcapp_core/comm_widgets/simple_button.dart';
import 'package:harcapp_web/router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import 'main.dart';

class TopNavigationBar extends StatefulWidget{

  @override
  State<StatefulWidget> createState() => TopNavigationBarState();

}

class TopNavigationBarState extends State<TopNavigationBar>{

  static const denseMaxWidth = 640;

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
      color: cardEnab_(context),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12.0),
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) => Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [

              if(constraints.maxWidth >= denseMaxWidth)
                SizedBox(width: 24.0),

              if(constraints.maxWidth >= denseMaxWidth)
                HarcApp(size: 24.0),

              if(constraints.maxWidth >= denseMaxWidth)
                SizedBox(width: 24.0),

              Expanded(child: Container()),

              PageNavItem(
                icon: MdiIcons.music,
                title: 'Warsztat piosenki',
                subtitle: 'Twój i dodawaj!',
                path: pathSong, //setState(() => body = SongsPage()),
                dense: constraints.maxWidth < denseMaxWidth,
              ),

              SizedBox(width: 12.0),
              
              PageNavItem(
                icon: MdiIcons.trayArrowDown,
                title: 'Pobierz HarcAppkę',
                subtitle: MyAppState.availableAppVersion,
                path: pathDownload,
                dense: constraints.maxWidth < denseMaxWidth,
              ),

              SizedBox(width: 12.0),

              /*
              PageNavItem(
                icon: MdiIcons.feather,
                title: 'Warsztat artykułów',
                onTap: () => setState(() => body = ArticlePage()),
              )
               */

              // Expanded(
              //   child: Row(
              //     crossAxisAlignment: CrossAxisAlignment.end,
              //     mainAxisAlignment: MainAxisAlignment.center,
              //     children: [
              //       HarcApp(size: 28.0),
              //       Text(
              //         ' platforma twórców',
              //         style: AppTextStyle(
              //             fontSize: 28.0,
              //             fontWeight: weight.bold,
              //             color: hintEnab_(context)
              //         )
              //       ),
              //
              //       Text(version??'x.x.x', style: AppTextStyle(fontSize: Dimen.TEXT_SIZE_NORMAL, fontWeight: weight.halfBold)),
              //     ],
              //   ),
              // ),

            ],
          ),
        )
      )
  );

}

class PageNavItem extends StatelessWidget{

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
    textColor: textEnab_(context),
    icon: icon,
    color: GoRouter.of(context).location == path?backgroundIcon_(context):null,
    onTap: () => context.go(path),
  ):
  IntrinsicWidth(
      child: ListTile(
        shape: RoundedRectangleBorder(
          side: BorderSide(color: backgroundIcon_(context), width: 4.0),
          borderRadius: BorderRadius.circular(AppCard.bigRadius),
        ),
        tileColor: GoRouter.of(context).location == path?backgroundIcon_(context):null,
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