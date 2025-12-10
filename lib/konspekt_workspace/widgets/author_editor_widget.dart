import 'package:flutter/material.dart';
import 'package:harcapp_core/comm_classes/app_text_style.dart';
import 'package:harcapp_core/comm_classes/color_pack.dart';
import 'package:harcapp_core/comm_widgets/app_card.dart';
import 'package:harcapp_core/comm_widgets/dialog/dialog.dart' as harcapp_dialog;
import 'package:harcapp_core/comm_widgets/person_card.dart';
import 'package:harcapp_core/comm_widgets/simple_button.dart';
import 'package:harcapp_core/values/dimen.dart';
import 'package:harcapp_core/values/people/person.dart';
import 'package:harcapp_core/values/people/person_data_getter.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class AuthorEditorWidget extends StatefulWidget {
  final Person? author;
  final void Function(Person? author) onChanged;

  const AuthorEditorWidget({
    required this.author,
    required this.onChanged,
    super.key,
  });

  @override
  State<AuthorEditorWidget> createState() => _AuthorEditorWidgetState();
}

class _AuthorEditorWidgetState extends State<AuthorEditorWidget> {
  @override
  Widget build(BuildContext context) {
    final hasAuthor = widget.author != null;

    return Material(
      color: cardEnab_(context),
      borderRadius: BorderRadius.circular(AppCard.defRadius),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (hasAuthor) ...[
            Row(
              children: [
                Expanded(
                  child: Padding(
                      padding: const EdgeInsets.all(Dimen.iconMarg),
                      child: PersonCard(widget.author!)
                  ),
                ),
                SimpleButton.from(
                  context: context,
                  margin: EdgeInsets.zero,
                  icon: MdiIcons.pencilOutline,
                  onTap: () => _showEditDialog(context),
                ),
                SimpleButton.from(
                  context: context,
                  margin: EdgeInsets.zero,
                  icon: MdiIcons.close,
                  onTap: () {
                    widget.onChanged(null);
                  },
                ),
              ],
            ),

          ] else
            SimpleButton(
              onTap: () => _showEditDialog(context),
              child: Padding(
                padding: const EdgeInsets.all(Dimen.defMarg),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(MdiIcons.accountPlusOutline, color: hintEnab_(context)),
                    const SizedBox(width: Dimen.iconMarg),
                    Text(
                      'Dodaj autora konspektu',
                      style: AppTextStyle(
                        color: hintEnab_(context),
                        fontSize: Dimen.textSizeBig,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    Navigator.of(context, rootNavigator: true).push(
      harcapp_dialog.DialogRoute(
        builder: (ctx) => PersonDataDialog(
          initialPerson: widget.author,
          onAccepted: (person) {
            widget.onChanged(person);
          },
          title: 'Autor konspektu',
          cancelText: 'Anuluj',
        ),
      ),
    );
  }
}
