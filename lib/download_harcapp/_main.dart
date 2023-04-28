import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:harcapp_core/comm_classes/app_text_style.dart';
import 'package:harcapp_core/comm_classes/color_pack.dart';
import 'package:harcapp_core/comm_classes/common.dart';
import 'package:harcapp_core/comm_widgets/app_card.dart';
import 'package:harcapp_core/comm_widgets/app_text.dart';
import 'package:harcapp_core/comm_widgets/simple_button.dart';
import 'package:harcapp_core/dimen.dart';
import 'package:harcapp_web/main.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../consts.dart';

class DownloadHarcAppPage extends StatelessWidget{

  const DownloadHarcAppPage();

  @override
  Widget build(BuildContext context) => Container(
    color: background_(context),
    child: Align(
      alignment: Alignment.topCenter,
      child: Container(
        constraints: BoxConstraints(maxWidth: defPageWidth),
        child: Padding(
          padding: const EdgeInsets.all(Dimen.SIDE_MARG),
          child: ListView(
            clipBehavior: Clip.none,
            physics: BouncingScrollPhysics(),
            children: [

              SizedBox(height: 24.0),

              Text(
                  'Że co?'
                  '\nNie masz jeszcze HarcAppki?!',
                  style: TextStyle(
                    fontSize: 24.0,
                    fontWeight: FontWeight.w700,
                    color: iconEnab_(context),
                  )
              ),

              SizedBox(height: 36.0),

              Text(
                'Bo jeśli nie, to czas to zmienić! HarcApp dostępny jest na Androida i iOSa.',
                style: TextStyle(
                  fontSize: Dimen.TEXT_SIZE_BIG,
                  color: iconEnab_(context),
                ),
                textAlign: TextAlign.justify,
              ),

              SizedBox(height: 2*36.0),

              Text(
                  'Pobierz na iOS',
                  style: TextStyle(
                    fontSize: 24.0,
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

              SizedBox(height: 2*36.0),

              Text(
                  'Pobierz na Androida',
                  style: TextStyle(
                    fontSize: 24.0,
                    fontWeight: FontWeight.w700,
                    color: iconEnab_(context),
                  )
              ),

              SizedBox(height: 36.0),

              Align(
                alignment: Alignment.centerLeft,
                child: DownloadButton(
                  title: 'HarcApp (.apk)',
                  image: Image.asset(
                    'assets/images/harcapp_app_icon.png',
                    isAntiAlias: true,
                  ),
                  url: MyAppState.availableAppApkSource!,
                ),
              ),

              SizedBox(height: 36.0),

              Align(
                alignment: Alignment.centerLeft,
                child: DownloadButton(
                  title: 'HarcApp (Google Play)',
                  image: Image.asset(
                    'assets/images/google_play_icon.jpg',
                    isAntiAlias: true,
                  ),
                  url: 'https://play.google.com/store/apps/details?id=zhp.harc.app',
                ),
              ),

              SizedBox(height: 36.0),

              Text(
                'Którą wersję wybrać na Androida?',
                style: TextStyle(
                  fontSize: Dimen.TEXT_SIZE_BIG,
                  fontWeight: FontWeight.w700,
                  color: iconEnab_(context),
                ),
                textAlign: TextAlign.justify,
              ),

              AppText(
                '\nJeśli jest dostępna - najlepiej wybrać <b>wersję z Google Play</b>.',
                size: Dimen.TEXT_SIZE_BIG,
                color: iconEnab_(context),
                textAlign: TextAlign.justify,
              ),

              AppText(
                '\nCzasami jednak zdarza się, że HarcAppka znika ze sklepu Google Play. Dlaczego? Otóż regulamin sklepu często jest zmieniany, i trudno za tym nadążyć - HarcAppki bowiem nie rozwija stado informatyków, tylko jedna osoba.',
                size: Dimen.TEXT_SIZE_BIG,
                color: iconEnab_(context),
                textAlign: TextAlign.justify,
              ),

              AppText(
                '\nNiestety, Google Play nie ma w zwyczaju informowania, gdy coś w apce wymaga poprawy. Zamiast tego apka jest blokowana, a żeby poznać przyczynę problemu, trzeba się odwołać, odczekać swoje aż Google uraczy odwołanie odpowiedzią (a i ta nie zawsze jest pomocna), wprowadzić zmiany i dopiero wówczas się dowiedzieć, czy w istocie o to chodziło.',
                size: Dimen.TEXT_SIZE_BIG,
                color: iconEnab_(context),
                textAlign: TextAlign.justify,
              ),

              AppText(
                '\nCzy to duży problem? Otóż nie ma powodów do obaw! <b>Ta sama HarcAppka</b> jest dostępna również w formie pliku instalacyjnego. Wystarczy pobrać na telefon, kliknąć odpowiednie uprawnienia - i zainstalować.',
                size: Dimen.TEXT_SIZE_BIG,
                color: iconEnab_(context),
                textAlign: TextAlign.justify,
              ),

              SizedBox(height: 36.0),

            ],
          ),
        ),
      ),
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
                padding: EdgeInsets.all(24.0),
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