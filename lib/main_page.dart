import 'package:flutter/material.dart';
import 'package:harcapp_core/comm_classes/app_text_style.dart';
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size(double.infinity, 72),
        child: Material(
          color: Colors.white,
          elevation: 6.0,
          child: Row(
            children: [

              Padding(
                padding: EdgeInsets.only(left: 64.0, right: 64.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    HarcApp(size: 32.0),
                    Text(version??'x.x.x', style: AppTextStyle(fontSize: Dimen.TEXT_SIZE_SMALL, fontWeight: weight.halfBold)),
                  ],
                )
              ),
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
            ],
          ),
        ),
      ),
      body: body,
    );
  }


}

class PageNavItem extends StatelessWidget{

  final IconData icon;
  final String title;
  final Function onTap;
  const PageNavItem({
    required this.icon,
    required this.title,
    required this.onTap
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      child: ListTile(
        onTap: onTap as void Function()?,
        leading: Icon(icon),
        title: Text(
          title,
          style: AppTextStyle(),
        ),
      ),
    );
  }

}