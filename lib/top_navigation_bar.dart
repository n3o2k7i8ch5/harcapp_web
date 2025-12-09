import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:harcapp_core/comm_classes/app_text_style.dart';
import 'package:harcapp_core/comm_classes/color_pack.dart';
import 'package:harcapp_core/comm_widgets/app_card.dart';
import 'package:harcapp_core/comm_widgets/harc_app.dart';
import 'package:harcapp_core/comm_widgets/simple_button.dart';
import 'package:harcapp_core/values/dimen.dart';
import 'package:harcapp_web/common/responsive_breakpoints.dart';
import 'package:harcapp_web/router.dart';
import 'package:harcapp_web/theme_mode_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';

class TopNavigationBar extends StatefulWidget implements PreferredSizeWidget{

  static const denseMaxWidth = ResponsiveBreakpoints.topNavDense;

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
              )
            else
              SizedBox(width: Dimen.sideMarg - Dimen.iconMarg),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: Dimen.iconMarg),
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

            const _ThemeModeButton(),

            Expanded(child: Container()),

            if (constraints.maxWidth >= ResponsiveBreakpoints.topNavToBottom) ...[
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
                icon: MdiIcons.notebook,
                title: 'Konspekty',
                contextInfo: 'Konspekty dla harcerzy, kształceniowe i edytor',
                path: pathKonspektyHarcerskie,
                dense: constraints.maxWidth < TopNavigationBar.denseMaxWidth,
                isSelected: (uri) => uri.startsWith('/konspekty'),
              ),

              PageNavItem(
                icon: MdiIcons.school,
                title: 'Poradniki\ninstruktorskie',
                contextInfo: 'Dobre rady harcerskie!',
                path: pathPoradnik,
                dense: constraints.maxWidth < TopNavigationBar.denseMaxWidth,
              ),

              PageNavItem(
                icon: MdiIcons.trophy,
                title: 'Sprawności',
                contextInfo: 'Zdobądź sprawności!',
                path: pathSprawnosci,
                dense: constraints.maxWidth < TopNavigationBar.denseMaxWidth,
              ),
            ],

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
  final bool Function(String uri)? isSelected;

  const PageNavItem({
    required this.icon,
    required this.title,
    this.subtitle,
    this.contextInfo,
    required this.path,
    required this.dense,
    this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    final String uri = GoRouterState
        .of(context)
        .uri
        .toString();
    final bool selected = isSelected != null ? isSelected!(uri) : uri == path;

    return dense
        ? SimpleButton.from(
      padding: EdgeInsets.all((height - Dimen.iconSize) / 2),
      margin: EdgeInsets.zero,
      textColor: textEnab_(context),
      radius: 0,
      icon: icon,
      color: selected ? backgroundIcon_(context) : null,
      onTap: () => context.go(path),
    )
        : Padding(
      padding: EdgeInsets.symmetric(horizontal: 1, vertical: Dimen.defMarg / 2),
      child: IntrinsicWidth(
        child: Tooltip(
          message: contextInfo,
          child: SizedBox(
            height: height - Dimen.defMarg,
            child: Material(
              color: selected ? backgroundIcon_(context) : Colors.transparent,
              borderRadius: BorderRadius.circular(AppCard.defRadius),
              child: InkWell(
                borderRadius: BorderRadius.circular(AppCard.defRadius),
                onTap: () => context.go(path),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: Dimen.iconMarg),
                  child: Row(
                    children: [
                      Icon(icon, color: iconEnab_(context)),
                      SizedBox(width: Dimen.iconMarg),
                      Text(
                        title,
                        style: AppTextStyle(
                            fontSize: Dimen.textSizeNormal,
                            color: iconEnab_(context),
                            height: 1.2
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ThemeModeButton extends StatelessWidget {
  const _ThemeModeButton();

  @override
  Widget build(BuildContext context) {
    final themeProv = context.watch<ThemeModeProvider>();
    final IconData icon;
    final String tooltip;

    switch (themeProv.mode) {
      case AppThemeMode.system:
        icon = MdiIcons.themeLightDark;
        tooltip = 'Tryb systemowy';
        break;
      case AppThemeMode.light:
        icon = MdiIcons.weatherSunny;
        tooltip = 'Tryb jasny';
        break;
      case AppThemeMode.dark:
        icon = MdiIcons.weatherNight;
        tooltip = 'Tryb ciemny';
        break;
    }

    return Tooltip(
      message: tooltip,
      child: IconButton(
        icon: Icon(icon, color: iconEnab_(context)),
        onPressed: themeProv.toggle,
      ),
    );
  }
}

class MainBottomNavBar extends StatelessWidget {
  const MainBottomNavBar({super.key});

  static bool shouldShow(BuildContext context) =>
      ResponsiveBreakpoints.shouldShowTopNavAtBottom(context);

  @override
  Widget build(BuildContext context) {
    if (!shouldShow(context)) {
      return const SizedBox.shrink();
    }

    final String uri = GoRouterState.of(context).uri.toString();

    Widget buildItem(IconData icon, String label, String path, {bool Function(String)? isSelected}) {
      final bool selected = isSelected != null ? isSelected(uri) : uri == path;
      return Expanded(
        child: GestureDetector(
          onTap: () => context.go(path),
          child: Container(
            color: selected ? backgroundIcon_(context) : Colors.transparent,
            padding: EdgeInsets.symmetric(vertical: Dimen.defMarg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: Dimen.iconSize,
                  color: selected ? iconEnab_(context) : hintEnab_(context),
                ),
                SizedBox(height: 4),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: AppTextStyle(
                    fontSize: Dimen.textSizeSmall,
                    color: selected ? iconEnab_(context) : hintEnab_(context),
                    fontWeight: selected ? weightBold : weightHalfBold,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Material(
      color: cardEnab_(context),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            buildItem(MdiIcons.music, 'Piosenki', pathSong),
            buildItem(MdiIcons.textBoxMultiple, 'Artykuły', pathArticles),
            buildItem(MdiIcons.notebook, 'Konspekty', pathKonspektyHarcerskie, isSelected: (uri) => uri.startsWith('/konspekty')),
            buildItem(MdiIcons.school, 'Poradniki', pathPoradnik),
            buildItem(MdiIcons.trophy, 'Sprawności', pathSprawnosci),
          ],
        ),
      ),
    );
  }
}