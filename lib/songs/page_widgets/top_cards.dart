import 'package:flutter/material.dart';
import 'package:harcapp_web/common/app_text_style.dart';
import 'package:harcapp_web/common/color_pack.dart';
import 'package:harcapp_web/common/core_comm_widgets/animated_child_slider.dart';
import 'package:harcapp_web/common/core_comm_widgets/app_text_field_hint.dart';
import 'package:harcapp_web/common/core_comm_widgets/simple_button.dart';
import 'package:harcapp_web/common/dimen.dart';
import 'package:harcapp_web/songs/core_own_song/providers.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';

class TopCards extends StatelessWidget{

  const TopCards();

  @override
  Widget build(BuildContext context) {

    TextCtrlsProvider prov = Provider.of<TextCtrlsProvider>(context);

    return Padding(
      padding: EdgeInsets.all(Dimen.DEF_MARG),
      child: Column(
        children: <Widget>[

          Row(
            children: [
              Expanded(
                child: AppTextFieldHint(
                  hint: 'Tytuł:',
                  controller: prov.controllerTitle,
                  style: AppTextStyle(
                    fontSize: Dimen.TEXT_SIZE_BIG,
                    fontWeight: weight.halfBold,
                    color: textEnabled(context),
                  ),
                  hintStyle: AppTextStyle(
                    fontSize: Dimen.TEXT_SIZE_NORMAL,
                    color: hintEnabled(context),
                  ),
                ),
              ),
              Consumer<HidTitlesProvider>(
                builder: (context, provider, child) =>
                  AnimatedChildSlider(
                    index: provider.hasAny?1:0,
                    children: [
                      IconButton(
                        icon: Icon(MdiIcons.plus),
                        onPressed: (){
                          HidTitlesProvider prov = Provider.of<HidTitlesProvider>(context, listen: false);
                          prov.add();
                        },
                      ),

                      IconButton(
                        icon: Icon(MdiIcons.informationOutline),
                        onPressed: (){
                          //AppScaffold.showSnackBar(context, 'Tytuły ukryte są dodatkowymi kluczami wyszukwiania piosneki.');
                        },
                      )
                    ],
                  )
              )
            ],
          ),

          Consumer<HidTitlesProvider>(
            builder: (context, provider, child) => !provider.hasAny?Container():Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [

                Column(
                  children: provider.controllers.map((controller) => AddTextWidget(controller)).toList(),
                ),

                SimpleButton(
                  margin: EdgeInsets.zero,
                  padding: EdgeInsets.all(Dimen.MARG_ICON),
                  onTap: provider.isLastEmpty?null:() => provider.add(),
                  child: Row(
                    children: [
                      Icon(MdiIcons.plus, color: provider.isLastEmpty?iconDisabledColor(context):iconEnabledColor(context)),
                      SizedBox(width: Dimen.MARG_ICON),
                      Text(
                        'Dodaj tytuł ukryty',
                        style: AppTextStyle(color: provider.isLastEmpty?iconDisabledColor(context):iconEnabledColor(context)),
                      )

                    ],
                  ),
                )

              ],
            ),
          ),

          AppTextFieldHint(
            hint: 'Autor słów:',
            controller: prov.controllerAuthor,
            style: AppTextStyle(
              fontSize: Dimen.TEXT_SIZE_BIG,
              fontWeight: weight.halfBold,
              color: textEnabled(context),
            ),
            hintStyle: AppTextStyle(
              fontSize: Dimen.TEXT_SIZE_NORMAL,
              color: hintEnabled(context),
            ),
          ),

          AppTextFieldHint(
            hint: 'Wykonawca:',
            controller: prov.controllerPerformer,
            style: AppTextStyle(
              fontSize: Dimen.TEXT_SIZE_BIG,
              fontWeight: weight.halfBold,
              color: textEnabled(context),
            ),
            hintStyle: AppTextStyle(
              fontSize: Dimen.TEXT_SIZE_NORMAL,
              color: hintEnabled(context),
            ),
          ),

          AppTextFieldHint(
            hint: 'Link YouTube:',
            controller: prov.controllerYT,
            style: AppTextStyle(
              fontSize: Dimen.TEXT_SIZE_BIG,
              fontWeight: weight.halfBold,
              color: textEnabled(context),
            ),
            hintStyle: AppTextStyle(
              fontSize: Dimen.TEXT_SIZE_NORMAL,
              color: hintEnabled(context),
            ),
          ),

          AppTextFieldHint(
            hint: 'Os. dodająca:',
            controller: prov.controllerAddPers,
            style: AppTextStyle(
              fontSize: Dimen.TEXT_SIZE_BIG,
              fontWeight: weight.halfBold,
              color: textEnabled(context),
            ),
            hintStyle: AppTextStyle(
              fontSize: Dimen.TEXT_SIZE_NORMAL,
              color: hintEnabled(context),
            ),
          ),

        ],
      ),
    );
  }

}

class AddTextWidget extends StatelessWidget{

  final TextEditingController controller;
  const AddTextWidget(this.controller);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [

        IconButton(
          icon: Icon(MdiIcons.close, size: Dimen.ICON_SIZE/2),
          onPressed: (){
            HidTitlesProvider prov = Provider.of<HidTitlesProvider>(context, listen: false);
            prov.remove(controller);
          },
        ),

        Expanded(child: AppTextFieldHint(
          hint: 'Tytuł ukryty:',
          hintTop: '',
          controller: controller,
          style: AppTextStyle(
            fontSize: Dimen.TEXT_SIZE_BIG,
            //fontWeight: weight.halfBold,
            color: textEnabled(context),
          ),
          hintStyle: AppTextStyle(
            fontSize: Dimen.TEXT_SIZE_NORMAL,
            color: hintEnabled(context),
          ),
        )),

      ],
    );
  }

}