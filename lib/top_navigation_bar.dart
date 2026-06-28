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
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
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

  /// Stała część szerokości rozwiniętej zakładki (bez tekstu): zewnętrzny
  /// padding poziomy ([Dimen.defMarg]) + wewnętrzny padding poziomy
  /// (2×[Dimen.iconMarg]) + ikona ([Dimen.iconSize]) + odstęp ikona–tekst.
  static const double _navItemFixedWidth =
      Dimen.defMarg + 2 * Dimen.iconMarg + Dimen.iconSize + Dimen.iconMarg;

  /// Prawy margines lustrzany do lewej krawędzi.
  static const double _navTrailingWidth = Dimen.sideMarg - Dimen.defMarg / 2;

  static double _measureTextWidth(String text, TextStyle style, TextScaler textScaler) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textScaler: textScaler,
    )..layout();
    return painter.width;
  }

  /// Czy zakładki z etykietami NIE mieszczą się w [available]? Jeśli tak —
  /// zwijamy je do samych ikon. Każda mierzona w swojej realnej grubości
  /// (zaznaczona = bold), tytuły bywają dwuwierszowe — bierzemy szerszy wiersz.
  static bool _shouldCollapseNav(
      String uri, List<_NavItemData> items, double available, TextScaler textScaler) {
    double needed = _navTrailingWidth;
    for (final item in items) {
      final bool selected =
          item.isSelected != null ? item.isSelected!(uri) : uri == item.path;
      final style = AppTextStyle(
        fontSize: Dimen.textSizeNormal,
        fontWeight: selected ? weightBold : weightHalfBold,
        height: 1.2,
      );
      needed += _navItemFixedWidth + _measureTextWidth(item.title, style, textScaler);
    }
    // Mały zapas, by zaokrąglenia sub-pikselowe nie obcięły ostatniej zakładki.
    return needed + Dimen.defMarg > available;
  }

  @override
  Widget build(BuildContext context) {
    final navItems = <_NavItemData>[
      _NavItemData(
        icon: MdiIcons.music,
        title: 'Warsztat\npiosenki',
        contextInfo: 'Twórz i dodawaj piosenki do HarcAppki!',
        path: pathSong,
      ),
      _NavItemData(
        icon: MdiIcons.textBoxMultiple,
        title: 'Artykuły\nharcerskie',
        contextInfo: 'Bądź na bieżąco z harcerską myślą!',
        path: pathArticles,
      ),
      _NavItemData(
        icon: MdiIcons.notebook,
        title: 'Konspekty\ni formy',
        contextInfo: 'Konspekty dla harcerzy, kształceniowe i edytor',
        path: pathKonspektyHarcerskie,
        isSelected: (uri) => uri.startsWith('/konspekty'),
      ),
      _NavItemData(
        icon: MdiIcons.school,
        title: 'Poradniki\ninstruktorskie',
        contextInfo: 'Dobre rady harcerskie!',
        path: pathPoradnik,
      ),
      _NavItemData(
        icon: MdiIcons.trophy,
        title: 'Sprawności',
        contextInfo: 'Zdobądź sprawności!',
        path: pathSprawnosci,
      ),
      _NavItemData(
        icon: MdiIcons.bookCross,
        title: 'Rozważania\newangeliczne',
        contextInfo: 'Rozważania ewangeliczne na każdą niedzielę (i nie tylko)!',
        path: pathRozwazaniaEwangeliczne,
      ),
    ];

    return Material(
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

            // Zakładki zajmują pozostałą przestrzeń i są dosunięte do prawej.
            // Czy mają etykiety, czy same ikony — decydujemy MIERZĄC, czy pełne
            // wersje mieszczą się w realnie dostępnej szerokości (Expanded +
            // wewnętrzny LayoutBuilder dają dokładny leftover po lewym klastrze),
            // a nie ze sztywnego breakpointu. Poniżej topNavToBottom zakładki
            // przenoszą się na dolny pasek (osobny widget sterowany MediaQuery).
            Expanded(
              child: constraints.maxWidth < ResponsiveBreakpoints.topNavToBottom
                  ? const SizedBox.shrink()
                  : AnimatedBuilder(
                      // Pomiar zależy od metryk czcionki (Ubuntu ładuje się
                      // asynchronicznie) — przelicz próg po jej załadowaniu.
                      animation: PaintingBinding.instance.systemFonts,
                      builder: (context, _) => LayoutBuilder(
                        builder: (context, itemConstraints) {
                          final String uri = GoRouterState.of(context).uri.toString();
                          final TextScaler textScaler = MediaQuery.textScalerOf(context);
                          final bool dense = _shouldCollapseNav(
                              uri, navItems, itemConstraints.maxWidth, textScaler);
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              for (final item in navItems)
                                PageNavItem(
                                  icon: item.icon,
                                  title: item.title,
                                  contextInfo: item.contextInfo,
                                  path: item.path,
                                  dense: dense,
                                  isSelected: item.isSelected,
                                ),
                              const SizedBox(width: _navTrailingWidth),
                            ],
                          );
                        },
                      ),
                    ),
            ),

          ],
        ),
      ),
    );
  }

}

/// Opis pojedynczej zakładki górnej nawigacji — wspólne źródło dla pomiaru
/// szerokości i renderowania.
class _NavItemData {
  final IconData icon;
  final String title;
  final String contextInfo;
  final String path;
  final bool Function(String uri)? isSelected;

  const _NavItemData({
    required this.icon,
    required this.title,
    required this.contextInfo,
    required this.path,
    this.isSelected,
  });
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

    final Color fg = textEnab_(context);
    final FontWeight weight = selected ? weightBold : weightHalfBold;

    return dense
        ? SimpleButton.from(
      padding: EdgeInsets.all((height - Dimen.iconSize) / 2),
      margin: EdgeInsets.zero,
      textColor: fg,
      radius: 0,
      icon: icon,
      color: selected ? hintEnab_(context).withValues(alpha: 0.22) : null,
      onTap: () => context.go(path),
    )
        : Padding(
      padding: EdgeInsets.symmetric(horizontal: Dimen.defMarg / 2, vertical: Dimen.defMarg / 2),
      child: IntrinsicWidth(
        child: Tooltip(
          message: contextInfo,
          child: SizedBox(
            height: height - Dimen.defMarg,
            child: Material(
              color: selected
                  ? hintEnab_(context).withValues(alpha: 0.22)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(AppCard.defRadius),
              child: InkWell(
                borderRadius: BorderRadius.circular(AppCard.defRadius),
                hoverColor: hintEnab_(context).withValues(alpha: 0.08),
                onTap: () => context.go(path),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: Dimen.iconMarg),
                  child: Row(
                    children: [
                      Icon(icon, color: fg),
                      SizedBox(width: Dimen.iconMarg),
                      Text(
                        title,
                        style: AppTextStyle(
                            fontSize: Dimen.textSizeNormal,
                            color: fg,
                            fontWeight: weight,
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
            buildItem(MdiIcons.bookCross, 'Rozważania', pathRozwazaniaEwangeliczne),
          ],
        ),
      ),
    );
  }
}