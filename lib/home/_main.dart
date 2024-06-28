import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:harcapp_core/comm_classes/app_navigator.dart';
import 'package:harcapp_core/comm_classes/app_text_style.dart';
import 'package:harcapp_core/comm_classes/color_pack.dart';
import 'package:harcapp_core/comm_classes/common.dart';
import 'package:harcapp_core/comm_widgets/app_card.dart';
import 'package:harcapp_core/comm_widgets/app_text.dart';
import 'package:harcapp_core/comm_widgets/simple_button.dart';
import 'package:harcapp_core/dimen.dart';
import 'package:harcapp_web/common/alert_dialog.dart';
import 'package:harcapp_web/common/base_scaffold.dart';
import 'package:harcapp_web/main.dart';
import 'package:harcapp_web/router.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../consts.dart';

class HomePage extends StatelessWidget{

  const HomePage();

  @override
  Widget build(BuildContext context) => BaseScaffold(
    body: ListView(
      children: [

        SizedBox(height: Dimen.sideMarg),

        SizedBox(
          height: 500,
          child: SingleChildScrollView(
            clipBehavior: Clip.none,
            scrollDirection: Axis.horizontal,
            physics: BouncingScrollPhysics(),
            child: Row(
              children: [
                SizedBox(width: Dimen.sideMarg),
                ScreenshotWidget('kuchnia_harcerska'),
                SizedBox(width: Dimen.sideMarg),
                ScreenshotWidget('las'),
                SizedBox(width: Dimen.sideMarg),
                ScreenshotWidget('mysl_i_inspiracje'),
                SizedBox(width: Dimen.sideMarg),
                ScreenshotWidget('prawo_i_przyrzeczenie'),
                SizedBox(width: Dimen.sideMarg),
                ScreenshotWidget('spiewnik'),
                SizedBox(width: Dimen.sideMarg),
                ScreenshotWidget('strefa_ducha'),
                SizedBox(width: Dimen.sideMarg),
                ScreenshotWidget('symbolika'),
                SizedBox(width: Dimen.sideMarg),
                ScreenshotWidget('tajniki_harcow'),
                SizedBox(width: Dimen.sideMarg),
              ],
            ),
          ),
        ),

        SizedBox(height: 24.0),

        Align(
          alignment: Alignment.topCenter,
          child: Container(
            constraints: BoxConstraints(maxWidth: defPageWidth),
            child: Padding(
              padding: const EdgeInsets.all(Dimen.sideMarg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [

                  Text(
                    'Że co? Nie masz jeszcze HarcAppki?!',
                    style: TextStyle(
                      fontSize: 24.0,
                      fontWeight: FontWeight.w900,
                      color: iconEnab_(context),
                    ),
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: Dimen.defMarg),

                  Text(
                    'Jeśli nie, czas to zmienić! HarcApp dostępny jest na Androida i iOSa.',
                    style: TextStyle(
                      fontSize: Dimen.textSizeBig,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: 36.0),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      Expanded(
                        child: Material(
                          borderRadius: BorderRadius.circular(AppCard.bigRadius),
                          color: cardEnab_(context),
                          child: Padding(
                            padding: const EdgeInsets.all(Dimen.defMarg),
                            child: Column(
                              children: [

                                SizedBox(height: 36.0),

                                Text(
                                    'Pobierz na iOS',
                                    style: TextStyle(
                                      fontSize: 20.0,
                                      fontWeight: FontWeight.w700,
                                      color: iconEnab_(context),
                                    )
                                ),

                                SizedBox(height: 36.0),

                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: DownloadButton(
                                    title: 'HarcApp (App Store)',
                                    image: SvgPicture.asset(
                                      'assets/images/app_store_icon.svg',
                                    ),
                                    url: 'https://apps.apple.com/id/app/harcapp/id1486296998',
                                  ),
                                ),

                              ],
                            ),
                          ),
                        )
                      ),

                      SizedBox(width: Dimen.sideMarg),

                      Expanded(
                          child: Material(
                            borderRadius: BorderRadius.circular(AppCard.bigRadius),
                            color: cardEnab_(context),
                            child: Padding(
                              padding: const EdgeInsets.all(Dimen.defMarg),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [

                                  SizedBox(height: 36.0),

                                  Text(
                                      'Pobierz na Androida',
                                      style: TextStyle(
                                        fontSize: 20.0,
                                        fontWeight: FontWeight.w700,
                                        color: iconEnab_(context),
                                      ),
                                    textAlign: TextAlign.center,
                                  ),

                                  SizedBox(height: 36.0),

                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: DownloadButton(
                                      title: 'HarcApp (Play Store)',
                                      image: Image.asset(
                                        'assets/images/google_play_icon.jpg',
                                        isAntiAlias: true,
                                        filterQuality: FilterQuality.high,
                                      ),
                                      url: 'https://play.google.com/store/apps/details?id=zhp.harc.app',
                                    ),
                                  ),

                                  SizedBox(height: Dimen.defMarg),

                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: DownloadButton(
                                      title: 'HarcApp (.apk)',
                                      image: Image.asset(
                                        'assets/images/harcapp_app_icon.png',
                                        isAntiAlias: true,
                                        filterQuality: FilterQuality.high,
                                      ),
                                      url: MyAppState.availableAppApkSource!,
                                    ),
                                  ),

                                  SizedBox(height: Dimen.defMarg),

                                  SimpleButton(
                                    color: backgroundIcon_(context),
                                    radius: AppCard.bigRadius,
                                    padding: EdgeInsets.all(24.0),
                                    child: Text(
                                      'Którą wersję wybrać na Androida?',
                                      style: TextStyle(
                                        fontSize: Dimen.textSizeBig,
                                        fontWeight: FontWeight.w700,
                                        color: iconEnab_(context),
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    onTap: () => openDialog(
                                        context: context,
                                        builder: (context) => Center(
                                          child: SizedBox(
                                            width: 400,
                                            child: Material(
                                              clipBehavior: Clip.hardEdge,
                                              borderRadius: BorderRadius.circular(AppCard.bigRadius),
                                              child: Column(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [

                                                    AppBar(
                                                        leading: IconButton(
                                                          icon: Icon(MdiIcons.arrowLeft, color: iconEnab_(context)),
                                                          onPressed: () => popPage(context),
                                                        ),
                                                        title: Text(
                                                          'Którą wersję wybrać na Androida?',
                                                          style: AppTextStyle(color: iconEnab_(context)),
                                                        )
                                                    ),

                                                    Padding(
                                                      padding: EdgeInsets.only(
                                                        left: 24.0,
                                                        right: 24.0,
                                                        bottom: 24.0,
                                                      ),
                                                      child: Column(
                                                        children: [

                                                          AppText(
                                                            '\nJeśli jest dostępna - najlepiej wybrać <b>wersję z Google Play</b>.',
                                                            size: Dimen.textSizeBig,
                                                            textAlign: TextAlign.justify,
                                                          ),

                                                          AppText(
                                                            '\nCzasami jednak zdarza się, że HarcAppka znika ze sklepu Google Play. Dlaczego? Otóż regulamin sklepu często jest zmieniany, i trudno za tym nadążyć - HarcAppki bowiem nie rozwija stado informatyków, tylko jedna osoba.',
                                                            size: Dimen.textSizeBig,
                                                            textAlign: TextAlign.justify,
                                                          ),

                                                          AppText(
                                                            '\nNiestety, Google Play nie ma w zwyczaju informowania, gdy coś w apce wymaga poprawy. Zamiast tego apka jest blokowana, a żeby poznać przyczynę problemu, trzeba się odwołać, odczekać swoje aż Google uraczy odwołanie odpowiedzią (a i ta nie zawsze jest pomocna), wprowadzić zmiany i dopiero wówczas się dowiedzieć, czy w istocie o to chodziło.',
                                                            size: Dimen.textSizeBig,
                                                            textAlign: TextAlign.justify,
                                                          ),

                                                          AppText(
                                                            '\nCzy to duży problem? Otóż nie ma powodów do obaw! <b>Ta sama HarcAppka</b> jest dostępna również w formie pliku instalacyjnego. Wystarczy pobrać na telefon, kliknąć odpowiednie uprawnienia - i zainstalować.',
                                                            size: Dimen.textSizeBig,
                                                            textAlign: TextAlign.justify,
                                                          ),

                                                        ],
                                                      ),
                                                    )

                                                  ],
                                                ),
                                            ),
                                          ),
                                        )
                                    ),
                                  ),
                                  
                                ],
                              ),
                            ),
                          )
                      )

                    ],
                  ),

                  SizedBox(height: Dimen.sideMarg),

                  SimpleButton(
                      radius: AppCard.bigRadius,
                      color: cardEnab_(context),
                      padding: EdgeInsets.all(24.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [

                          Icon(MdiIcons.dominoMask, size: 36.0),
                          SizedBox(width: 24.0),
                          Text(
                              'Polityka prywatności',
                              style: AppTextStyle(
                                  fontSize: Dimen.textSizeAppBar,
                                  color: iconEnab_(context),
                                  fontWeight: weight.halfBold
                              )
                          ),

                          SizedBox(width: Dimen.iconSize + 24.0),

                        ],
                      ),
                      onTap: () => context.go(pathPrivacyPolicy)
                  ),

                  SizedBox(height: 2*36.0),

                ],
              ),
            ),
          ),
        ),

      ],
    ),
  );

}

class DownloadButton extends StatelessWidget{

  static const double height = 112.0;
  static const double width = 3.8*height;

  final String title;
  final Widget image;
  final String url;

  const DownloadButton({
    required this.title,
    required this.image,
    required this.url,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
      height: height,
      width: width,
      child: SimpleButton(
        elevation: 6.0,
        color: background_(context),
        onTap: () => launchURL(url),
        borderRadius: BorderRadius.circular(AppCard.bigRadius),
        child: Row(
          children: [

            AspectRatio(
              aspectRatio: 1,
              child: image,
            ),

            Expanded(
              child: Padding(
                padding: EdgeInsets.all(18.0),
                child: Row(
                  children: [

                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          SizedBox(height: 14.0),

                          Text(
                              title,
                              style: AppTextStyle(
                                fontSize: 20.0,
                                fontWeight: weight.halfBold,
                                color: iconEnab_(context),
                              )
                          ),

                          Text(
                              'Wersja: ${MyAppState.availableAppVersion}',
                              style: AppTextStyle(
                                fontSize: 14.0,
                                fontWeight: weight.halfBold,
                                color: iconEnab_(context),
                              )
                          ),

                        ],
                      ),
                    ),

                    Icon(MdiIcons.trayArrowDown),

                  ],
                ),
              ),
            )

          ],
        ),
      ),
  );

}

class ScreenshotWidget extends StatelessWidget{

  final String imageName;

  const ScreenshotWidget(this.imageName);

  @override
  Widget build(BuildContext context) => Material(
    clipBehavior: Clip.hardEdge,
    borderRadius: BorderRadius.circular(AppCard.bigRadius),
    elevation: AppCard.bigElevation,
    child: Image.asset(
      'assets/images/screenshots/$imageName.webp',
      isAntiAlias: true,
      filterQuality: FilterQuality.high,
    ),
  );

}