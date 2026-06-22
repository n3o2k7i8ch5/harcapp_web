import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:harcapp_core/comm_classes/app_text_style.dart';
import 'package:harcapp_core/comm_classes/color_pack.dart';
import 'package:harcapp_core/comm_widgets/app_scaffold.dart';
import 'package:harcapp_core/comm_widgets/simple_button.dart';
import 'package:harcapp_core/values/dimen.dart';
import 'package:harcapp_web/konspekt_workspace/content_check/on_device_text_checker.dart';
import 'package:harcapp_web/konspekt_workspace/content_check/narration_check.dart';
import 'package:harcapp_web/konspekt_workspace/content_check/check_controller.dart';

/// Single global "check correctness" floating action button. Triggers the
/// on-device checks across all konspekt fields via [KonspektCheckController]
/// (downloading the model on first use), then shows a summary dialog. Reflects
/// download / checking state. [buildTargets] supplies the fields to check.
class KonspektCheckFab extends StatelessWidget {
  final KonspektCheckController controller;
  final List<CheckTarget> Function() buildTargets;

  const KonspektCheckFab({
    super.key,
    required this.controller,
    required this.buildTargets,
  });

  Future<bool> _confirmDownload(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: background_(dialogContext),
        title: const Text('Sprawdzanie poprawności'),
        content: Text(
          'Aby sprawdzić teksty, trzeba jednorazowo pobrać model językowy '
          '(${OnDeviceTextChecker.modelSizeLabel}). Po pobraniu działa w '
          'przeglądarce i pozwala wykryć proste błędy językowe.',
          style: AppTextStyle(
            fontSize: Dimen.textSizeNormal,
            color: textEnab_(dialogContext),
          ),
        ),
        actions: [
          SimpleButton.from(
            context: dialogContext,
            text: 'Anuluj',
            onTap: () => Navigator.of(dialogContext).pop(false),
          ),
          SimpleButton.from(
            context: dialogContext,
            textColor: background_(dialogContext),
            color: iconEnab_(dialogContext),
            text: 'Pobierz (${OnDeviceTextChecker.modelSizeLabel})',
            onTap: () => Navigator.of(dialogContext).pop(true),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  Future<void> _onTap(BuildContext context) async {
    final result = await controller.run(
      targets: buildTargets(),
      confirmDownload: () => _confirmDownload(context),
    );
    if (!context.mounted) return;
    if (result.error != null) {
      AppScaffold.showMessage(context, text: result.error!);
      return;
    }
    await _showResultsDialog(context, result.outcomes);
  }

  Future<void> _showResultsDialog(
    BuildContext context,
    List<CheckOutcome> outcomes,
  ) =>
      showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: background_(dialogContext),
          title: const Text('Wyniki sprawdzania'),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final o in outcomes) _OutcomeTile(o),
                ],
              ),
            ),
          ),
          actions: [
            SimpleButton.from(
              context: dialogContext,
              textColor: background_(dialogContext),
              color: iconEnab_(dialogContext),
              text: 'OK',
              onTap: () => Navigator.of(dialogContext).pop(),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          if (controller.downloading) {
            final pct = controller.downloadProgress == null
                ? null
                : (controller.downloadProgress! * 100).round();
            return FloatingActionButton.extended(
              heroTag: null,
              onPressed: null,
              backgroundColor: iconEnab_(context),
              icon: _spinner(context, value: controller.downloadProgress),
              label: Text(
                pct == null ? 'Pobieranie…' : 'Pobieranie $pct%',
                style: AppTextStyle(color: background_(context)),
              ),
            );
          }

          if (controller.checking) {
            return FloatingActionButton.extended(
              heroTag: null,
              onPressed: null,
              backgroundColor: iconEnab_(context),
              icon: _spinner(context),
              label: Text(
                'Sprawdzanie…',
                style: AppTextStyle(color: background_(context)),
              ),
            );
          }

          return FloatingActionButton.extended(
            heroTag: null,
            onPressed: () => _onTap(context),
            backgroundColor: iconEnab_(context),
            foregroundColor: background_(context),
            icon: Icon(MdiIcons.spellcheck, color: background_(context)),
            label: Text(
              'Sprawdź',
              style: AppTextStyle(color: background_(context)),
            ),
          );
        },
      );

  Widget _spinner(BuildContext context, {double? value}) => SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          value: value,
          color: background_(context),
        ),
      );
}

/// One field's result in the summary dialog: a bold label plus a status line
/// per check that ran.
class _OutcomeTile extends StatelessWidget {
  final CheckOutcome outcome;

  const _OutcomeTile(this.outcome);

  @override
  Widget build(BuildContext context) {
    final lines = <Widget>[];
    final lang = outcome.lang;
    if (lang != null) {
      lines.add(switch (lang) {
        LangCheckResult.polish =>
          _line(context, Icons.check_circle_outline, Colors.green, 'Po polsku'),
        LangCheckResult.notPolish => _line(context, MdiIcons.alertOutline,
            Colors.orange, 'Nie wygląda na napisane po polsku'),
        LangCheckResult.unknown => _line(context, Icons.help_outline,
            hintEnab_(context), 'Nie udało się ocenić języka'),
      });
    }
    final narr = outcome.narration;
    if (narr != null) {
      lines.add(switch (narr) {
        NarrationCheckResult.rolesBased => _line(context,
            Icons.check_circle_outline, Colors.green, 'Styl: prowadzący–uczestnicy'),
        NarrationCheckResult.personalForm => _line(context, MdiIcons.alertOutline,
            Colors.orange, 'Styl: forma „robimy"/„zróbcie" — opisz przez role'),
        NarrationCheckResult.unknown => _line(
            context, Icons.help_outline, hintEnab_(context), 'Nie udało się ocenić stylu'),
      });
    }

    return Padding(
      padding: EdgeInsets.only(bottom: Dimen.sideMarg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                outcome.hasIssue ? MdiIcons.alertOutline : Icons.check_circle_outline,
                size: 18,
                color: outcome.hasIssue ? Colors.orange : Colors.green,
              ),
              const SizedBox(width: Dimen.defMarg),
              Expanded(
                child: Text(
                  outcome.label,
                  style: AppTextStyle(
                    fontSize: Dimen.textSizeNormal,
                    fontWeight: weightHalfBold,
                    color: textEnab_(context),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 18 + Dimen.defMarg, top: 2),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: lines),
          ),
        ],
      ),
    );
  }

  Widget _line(BuildContext context, IconData icon, Color color, String text) =>
      Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                text,
                style: AppTextStyle(fontSize: Dimen.textSizeSmall, color: color),
              ),
            ),
          ],
        ),
      );
}
