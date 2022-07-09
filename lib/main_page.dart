import 'package:flutter/material.dart';
import 'package:harcapp_core/comm_classes/app_text_style.dart';
import 'package:harcapp_core/comm_classes/color_pack.dart';
import 'package:harcapp_core/comm_widgets/harc_app.dart';
import 'package:harcapp_core/dimen.dart';
import 'package:harcapp_web/songs/_main.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';


class MainPage extends StatefulWidget{

  @override
  State<StatefulWidget> createState() => MainPageState();

}

class MainPageState extends State<MainPage>{

  Widget? body;
  String? version;
  void establishVersion() async {
    version = (await PackageInfo.fromPlatform()).version;
    setState(() {});
  }

  @override
  void initState() {
    establishVersion();
    body = SongsPage();
    super.initState();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: PreferredSize(
      preferredSize: Size(double.infinity, 92),
      child: Material(
        color: cardEnab_(context),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 10.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [

              PageNavItem(
                icon: MdiIcons.bookmarkMusicOutline,
                title: 'Warsztat piosenki',
                onTap: () => setState(() => body = SongsPage()),
              ),


              /*
              PageNavItem(
                icon: MdiIcons.feather,
                title: 'Warsztat artykułów',
                onTap: () => setState(() => body = ArticlePage()),
              )
               */

              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    HarcApp(size: 28.0),
                    Text(
                        ' platforma twórców',
                        style: AppTextStyle(
                            fontSize: 28.0,
                            fontWeight: weight.bold,
                            color: hintEnab_(context)
                        )
                    ),

                    Text(version??'x.x.x', style: AppTextStyle(fontSize: Dimen.TEXT_SIZE_NORMAL, fontWeight: weight.halfBold)),
                  ],
                ),
              ),

              SizedBox(width: PageNavItem.width),

            ],
          ),
        )
      ),
    ),
    body: body,
  );

}

class PageNavItem extends StatelessWidget{

  static const double width = 300;

  final IconData icon;
  final String title;
  final void Function() onTap;
  const PageNavItem({
    required this.icon,
    required this.title,
    required this.onTap
  });

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: ListTile(
      onTap: onTap,
      leading: Icon(icon),
      title: Text(
        title,
        style: AppTextStyle(),
      ),
    ),
  );

}