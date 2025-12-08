import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:harcapp_core/comm_classes/app_text_style.dart';
import 'package:harcapp_core/comm_classes/color_pack.dart';
import 'package:harcapp_core/comm_classes/common.dart';
import 'package:harcapp_core/comm_widgets/app_card.dart';
import 'package:harcapp_core/comm_widgets/simple_button.dart';
import 'package:harcapp_core/values/dimen.dart';
import 'package:harcapp_web/common/base_scaffold.dart';
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

                  if(MediaQuery.of(context).size.width > 1.5*DownloadButton.width)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        Expanded(
                            child: PlayStoreDownloadButton()
                        ),

                        SizedBox(width: Dimen.sideMarg),

                        Expanded(
                          child: AppStoreDownloadButton()
                        ),

                      ],
                    )
                  else
                    Column(
                      children: [

                        PlayStoreDownloadButton(),

                        SizedBox(height: Dimen.sideMarg),

                        AppStoreDownloadButton(),

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
                                  fontWeight: weightHalfBold,
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
  final String subTitle;
  final Widget image;
  final String url;

  const DownloadButton({
    required this.title,
    required this.subTitle,
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
                                fontWeight: weightHalfBold,
                                color: iconEnab_(context),
                              )
                          ),

                          Text(
                              '$subTitle',
                              style: AppTextStyle(
                                fontSize: 14.0,
                                fontWeight: weightHalfBold,
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

class PlayStoreDownloadButton extends StatelessWidget{

  @override
  Widget build(BuildContext context) => Material(
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

          DownloadButton(
            title: 'HarcApp',
            subTitle: '(Play Store)',
            image: Image.asset(
              'assets/images/google_play_icon.jpg',
              isAntiAlias: true,
              filterQuality: FilterQuality.high,
            ),
            url: 'https://play.google.com/store/apps/details?id=com.daniwan.harcapp',
          ),

          SizedBox(height: Dimen.defMarg),

        ],
      ),
    ),
  );

}

class AppStoreDownloadButton extends StatelessWidget {

  @override
  Widget build(BuildContext context) => Material(
    borderRadius: BorderRadius.circular(AppCard.bigRadius),
    color: cardEnab_(context),
    child: Padding(
      padding: const EdgeInsets.all(Dimen.defMarg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [

          SizedBox(height: 36.0),

          Text(
              'Pobierz na iOS',
              style: TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.w700,
                color: iconEnab_(context),
              ),
              textAlign: TextAlign.center,
          ),

          SizedBox(height: 36.0),

          DownloadButton(
            title: 'HarcApp',
            subTitle: '(App Store)',
            image: SvgPicture.asset(
              'assets/images/app_store_icon.svg',
            ),
            url: 'https://apps.apple.com/us/app/harcapp/id6754627071',
          ),

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