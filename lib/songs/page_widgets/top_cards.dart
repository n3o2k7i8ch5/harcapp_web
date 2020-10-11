import 'package:flutter/material.dart';
import 'package:harcapp_web/common/app_text_style.dart';
import 'package:harcapp_web/common/color_pack.dart';
import 'package:harcapp_web/common/core_comm_widgets/animated_child_slider.dart';
import 'package:harcapp_web/common/core_comm_widgets/app_text_field_hint.dart';
import 'package:harcapp_web/common/core_comm_widgets/simple_button.dart';
import 'package:harcapp_web/common/dimen.dart';
import 'package:implicitly_animated_reorderable_list/implicitly_animated_reorderable_list.dart';
import 'package:implicitly_animated_reorderable_list/transitions.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';

import '../core_own_song/providers.dart';


class TopCards extends StatelessWidget{

  final Function(String) onChangedTitle;
  final Function(String) onChangedAuthor;
  final Function(String) onChangedPerformer;
  final Function(String) onChangedYT;
  final Function(String) onChangedAddPers;

  const TopCards({
    this.onChangedTitle,
    this.onChangedAuthor,
    this.onChangedPerformer,
    this.onChangedYT,
    this.onChangedAddPers,
  });

  @override
  Widget build(BuildContext context) {

    return Padding(
      padding: EdgeInsets.all(Dimen.DEF_MARG),
      child: Column(
        children: <Widget>[

          Row(
            children: [
              Expanded(
                child: Consumer<TitleCtrlProvider>(
                    builder: (context, prov, child) => AppTextFieldHint(
                      controller: prov.controller,
                      hint: 'Tytuł:',
                      style: AppTextStyle(
                        fontSize: Dimen.TEXT_SIZE_BIG,
                        fontWeight: weight.halfBold,
                        color: textEnabled(context),
                      ),
                      hintStyle: AppTextStyle(
                        fontSize: Dimen.TEXT_SIZE_NORMAL,
                        color: hintEnabled(context),
                      ),
                      onChanged: onChangedTitle,
                    )
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
            builder: (context, provider, child) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [

                ImplicitlyAnimatedList<TextEditingController>(
                  items: provider.controllers,
                  areItemsTheSame: (a, b) => a.hashCode == b.hashCode,
                  itemBuilder: (context, animation, item, index) {
                    return SizeFadeTransition(
                      sizeFraction: 0.7,
                      curve: Curves.easeInOut,
                      animation: animation,
                      child: AddTextWidget(item),
                    );
                  },
                  removeItemBuilder: (context, animation, oldItem) {
                    return SizeFadeTransition(
                      sizeFraction: 0.7,
                      curve: Curves.easeInOut,
                      animation: animation,
                      child: AddTextWidget(oldItem),
                    );
                  },
                  shrinkWrap: true,
                ),

                AnimatedContainer(
                    duration: Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                    height: provider.hasAny?2*Dimen.MARG_ICON+Dimen.ICON_FOOTPRINT:0,
                    child: AnimatedOpacity(
                      opacity: provider.hasAny?1:0,
                      duration: Duration(milliseconds: 500),
                      curve: Curves.easeInOut,
                      child: SimpleButton(
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
                      ),
                    )
                ),

              ],
            ),
          ),

          Consumer<AuthorCtrlProvider>(
            builder: (context, prov, child) => AppTextFieldHint(
              controller: prov.controller,
              hint: 'Autor słów:',
              style: AppTextStyle(
                fontSize: Dimen.TEXT_SIZE_BIG,
                fontWeight: weight.halfBold,
                color: textEnabled(context),
              ),
              hintStyle: AppTextStyle(
                fontSize: Dimen.TEXT_SIZE_NORMAL,
                color: hintEnabled(context),
              ),
              onChanged: onChangedAuthor,
            ),
          ),

          Consumer<PerformerCtrlProvider>(
            builder: (context, prov, child) => AppTextFieldHint(
                controller: prov.controller,
                hint: 'Wykonawca:',
                style: AppTextStyle(
                  fontSize: Dimen.TEXT_SIZE_BIG,
                  fontWeight: weight.halfBold,
                  color: textEnabled(context),
                ),
                hintStyle: AppTextStyle(
                  fontSize: Dimen.TEXT_SIZE_NORMAL,
                  color: hintEnabled(context),
                ),
                onChanged: onChangedPerformer
            ),
          ),

          Consumer<YTCtrlProvider>(
            builder: (context, prov, child) => AppTextFieldHint(
              controller: prov.controller,
              hint: 'Link YouTube:',
              style: AppTextStyle(
                fontSize: Dimen.TEXT_SIZE_BIG,
                fontWeight: weight.halfBold,
                color: textEnabled(context),
              ),
              hintStyle: AppTextStyle(
                fontSize: Dimen.TEXT_SIZE_NORMAL,
                color: hintEnabled(context),
              ),
              onChanged: onChangedYT,
            ),
          ),

          Consumer<AddPersCtrlProvider>(
            builder: (context, prov, child) => AppTextFieldHint(
              controller: prov.controller,
              hint: 'Os. dodająca:',
              style: AppTextStyle(
                fontSize: Dimen.TEXT_SIZE_BIG,
                fontWeight: weight.halfBold,
                color: textEnabled(context),
              ),
              hintStyle: AppTextStyle(
                fontSize: Dimen.TEXT_SIZE_NORMAL,
                color: hintEnabled(context),
              ),
              onChanged: onChangedAddPers,
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
          icon: Icon(MdiIcons.close),
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