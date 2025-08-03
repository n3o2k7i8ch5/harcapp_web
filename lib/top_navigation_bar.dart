import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:harcapp_core/comm_classes/app_text_style.dart';
import 'package:harcapp_core/comm_classes/color_pack.dart';
import 'package:harcapp_core/comm_widgets/app_card.dart';
import 'package:harcapp_core/comm_widgets/harc_app.dart';
import 'package:harcapp_core/comm_widgets/simple_button.dart';
import 'package:harcapp_core/values/dimen.dart';
import 'package:harcapp_web/router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class TopNavigationBar extends StatefulWidget implements PreferredSizeWidget{

  static const denseMaxWidth = 1074;

  final bool withMenuIcon;

  const TopNavigationBar({this.withMenuIcon = true});

  @override
  State<StatefulWidget> createState() => TopNavigationBarState();

  @override
  Size get preferredSize => Size(double.infinity, PageNavItem.height);

}

class TopNavigationBarState extends State<TopNavigationBar>{

  bool get withMenuIcon => widget.withMenuIcon;

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
    // elevation: AppCard.bigElevation,
      color: cardEnab_(context),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) => Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [

            if(withMenuIcon && constraints.maxWidth < TopNavigationBar.denseMaxWidth)
              SimpleButton.from(
                padding: EdgeInsets.all((PageNavItem.height - Dimen.iconSize)/2),
                margin: EdgeInsets.zero,
                textColor: textEnab_(context),
                radius: 0,
                icon: MdiIcons.menu,
                onTap: () => Scaffold.of(context).openDrawer(),
              ),

            if(withMenuIcon && constraints.maxWidth < TopNavigationBar.denseMaxWidth)
              InkWell(
                child: HarcApp(size: 24.0),
                hoverColor: Colors.transparent,
                splashColor: Colors.transparent,
                onTap: () => context.go(pathHome),
              )
            else
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('', style: AppTextStyle(fontSize: Dimen.textSizeSmall)),
                    InkWell(
                      child: HarcApp(size: 24.0),
                      hoverColor: Colors.transparent,
                      splashColor: Colors.transparent,
                      onTap: () => context.go(pathHome),
                    ),
                    Text(version??'', style: AppTextStyle(fontSize: Dimen.textSizeSmall)),
                  ],
                ),
              ),

            Expanded(child: Container()),

            PageNavItem(
              icon: MdiIcons.music,
              title: 'Warsztat\npiosenki',
              contextInfo: 'Twórz i dodawaj piosenki do HarcAppki!',
              path: pathSong,
              dense: constraints.maxWidth < TopNavigationBar.denseMaxWidth,
            ),

            // PageNavItem(
            //   icon: MdiIcons.textBoxEditOutline,
            //   title: 'Warsztat\nartykułów',
            //   contextInfo: 'Twórz i dodawaj artykuły do HarcAppki!',
            //   path: pathArticlesWorkspace,
            //   dense: constraints.maxWidth < TopNavigationBar.denseMaxWidth,
            // ),

            PageNavItem(
              icon: MdiIcons.textBoxMultiple,
              title: 'Artykuły\nharcerskie',
              contextInfo: 'Bądź na bieżąco z harcerską myślą!',
              path: pathArticles,
              dense: constraints.maxWidth < TopNavigationBar.denseMaxWidth,
            ),

            PageNavItem(
              icon: MdiIcons.notebookEditOutline,
              title: 'Warsztat\nkonspektów',
              contextInfo: 'Twórz i dodawaj konspekty do HarcAppki!',
              path: pathWarsztatKonspektow,
              dense: constraints.maxWidth < TopNavigationBar.denseMaxWidth,
            ),

            PageNavItem(
              icon: MdiIcons.notebookOutline,
              title: 'Konspekty\ndla harcerzy',
              contextInfo: 'Inspiracje na pracę harcerską',
              path: pathKonspektyHarcerskie,
              dense: constraints.maxWidth < TopNavigationBar.denseMaxWidth,
            ),

            PageNavItem(
              icon: MdiIcons.notebook,
              title: 'Konspekty\nkształceniowe',
              contextInfo: 'Inspiracje na kształcenie kadry',
              path: pathKonspektyKsztalcenie,
              dense: constraints.maxWidth < TopNavigationBar.denseMaxWidth,
            ),

            PageNavItem(
              icon: MdiIcons.school,
              title: 'Poradniki\ninstruktorskie',
              contextInfo: 'Dobre rady harcerskie!',
              path: pathPoradnik,
              dense: constraints.maxWidth < TopNavigationBar.denseMaxWidth,
            ),

          ],
        ),
      )
  );

}

class PageNavItem extends StatelessWidget{

  static const double height = 56;

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? contextInfo;
  final String path;
  final bool dense;

  const PageNavItem({
    required this.icon,
    required this.title,
    this.subtitle,
    this.contextInfo,
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
  Padding(
    padding: EdgeInsets.symmetric(horizontal: 1),
    child: IntrinsicWidth(
      child: Tooltip(
        message: contextInfo,
        child: ListTile(
          dense: true,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppCard.defRadius)),
          tileColor: GoRouterState.of(context).uri.toString() == path?backgroundIcon_(context):null,
          selectedColor: backgroundIcon_(context),
          onTap: () => context.go(path),
          leading: Icon(icon, color: iconEnab_(context)),
          title: Text(
            title,
            style: AppTextStyle(
              fontSize: Dimen.textSizeNormal,
              color: iconEnab_(context),
              height: 1.2
            ),
          ),
        ),
      ),
    ),
  );

}