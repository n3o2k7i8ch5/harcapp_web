import 'package:flutter/material.dart';
import 'package:harcapp_core/comm_classes/app_text_style.dart';
import 'package:harcapp_core/comm_classes/color_pack.dart';
import 'package:harcapp_core/comm_widgets/app_card.dart';
import 'package:harcapp_core/comm_widgets/simple_button.dart';
import 'package:harcapp_core/dimen.dart';
import 'package:harcapp_web/songs/providers.dart';
import 'package:harcapp_web/songs/song_editor_panel.dart';
import 'package:harcapp_web/songs/song_preview_widget.dart';
import 'package:harcapp_web/songs/workspace/workspace_part.dart';
import 'package:harcapp_web/songs/workspace/workspace_title_widget.dart';
import 'package:provider/provider.dart';

class SongsPage extends StatelessWidget{

  const SongsPage();

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (BuildContext context, BoxConstraints constraints) => Scaffold(
      backgroundColor: background_(context),
      drawer: constraints.maxWidth>900?
      null:
      Drawer(
        backgroundColor: background_(context),
        child: WorkspacePart(
          onItemTap: (index) => Navigator.pop(context),
        ),
        width: 450,
      ),
      body: Builder(
        builder: (context) => Stack(
            children: [

              Row(
                children: [

                  if(constraints.maxWidth>900)
                    SizedBox(
                        width: 450,
                        child: Padding(
                          padding: EdgeInsets.only(left: 32, right: 32, bottom: 32),
                          child: WorkspacePart(),
                        )
                    ),

                  Expanded(
                      child: Padding(
                          padding: constraints.maxWidth>900?
                          EdgeInsets.only(right: 32, bottom: 32):
                          EdgeInsets.zero,

                          child: Stack(
                            children: [

                                Padding(
                                  padding: constraints.maxWidth <= 900?
                                  EdgeInsets.only(top: WorkspaceTitleWidget.height + Dimen.defMarg):
                                  EdgeInsets.zero,
                                  child: SongEditorPanel(),
                                ),

                              if(constraints.maxWidth <= 900)
                                SimpleButton(
                                  onTap: () => Scaffold.of(context).openDrawer(),
                                  color: cardEnab_(context),
                                  radius: AppCard.bigRadius,
                                  child: IgnorePointer(child: WorkspaceTitleWidget(textAlign: TextAlign.center, showDuplicated: false)),
                                  margin: EdgeInsets.only(
                                    top: Dimen.defMarg,
                                    left: Dimen.defMarg,
                                    right: Dimen.defMarg,
                                  ),
                                  elevation: 6.0,
                                ),

                            ],
                          )
                      )
                  ),

                  if(constraints.maxWidth>1280)
                    SizedBox(
                      width: 400,
                      child: Padding(
                          padding: EdgeInsets.only(bottom: 32, right: 32),
                          child:
                          SongPreviewWidget()
                      ),
                    )
                ],
              ),

              Consumer<LoadingProvider>(
                child: AppCard(
                  elevation: AppCard.bigElevation,
                  padding: EdgeInsets.all(Dimen.ICON_MARG),
                  child: Text('Ładowanie...', style: AppTextStyle(fontSize: Dimen.TEXT_SIZE_APPBAR)),
                ),
                builder: (context, prov, child) => AnimatedOpacity(
                  opacity: prov.loading!?1:0,
                  duration: Duration(milliseconds: 0),
                  child: AbsorbPointer(
                    absorbing: prov.loading!,
                    child: Center(child: child),
                  ),
                ),
              ),

            ],
          )
      ),
    )
  );

}
