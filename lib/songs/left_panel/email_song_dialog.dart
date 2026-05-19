import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:harcapp_core/comm_classes/color_pack.dart';
import 'package:harcapp_core/comm_widgets/app_bar.dart';
import 'package:harcapp_core/comm_widgets/app_card.dart';
import 'package:harcapp_core/comm_widgets/app_scaffold.dart';
import 'package:harcapp_core/comm_widgets/app_text.dart';
import 'package:harcapp_core/comm_widgets/simple_button.dart';
import 'package:harcapp_core/song_book/contrib_song_email_legacy.dart';
import 'package:harcapp_core/values/people/contributor_ref.dart';
import 'package:harcapp_core/song_book/parse_contrib_email.dart';
import 'package:harcapp_core/song_book/parse_contrib_email_oldest.dart';
import 'package:harcapp_core/song_book/song_core.dart';
import 'package:harcapp_core/song_book/song_editor/providers.dart';
import 'package:harcapp_core/song_book/song_editor/song_raw.dart';
import 'package:harcapp_core/song_book/widgets/song_widget_template.dart';
import 'package:harcapp_core/values/dimen.dart';
import 'package:harcapp_core/values/people/models.dart';
import 'package:harcapp_core/values/people/utils.dart';
import 'package:harcapp_core/values/srodowiska/hufce.dart';
import 'package:harcapp_core/values/srodowiska/models.dart';
import 'package:harcapp_core/comm_classes/app_text_style.dart';
import 'package:harcapp_web/consts.dart';
import 'package:harcapp_web/songs/left_panel/song_list_view.dart';
import 'package:harcapp_web/songs/providers.dart';
import 'package:harcapp_web/songs/similar_song_viewer.dart';
import 'package:harcapp_web/songs/song_preview_widget.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';

const String _harcappInboxEmail = 'harcapp@gmail.com';

final RegExp _emailRe =
    RegExp(r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$');

final RegExp _nonAlnumRe = RegExp(r'[^\p{L}\p{N}]', unicode: true);

/// Porównanie „luźne" pól tekstowych: tylko litery i cyfry (Unicode),
/// lowercase. Ignoruje kropki, spacje, cudzysłowy, myślniki, etc.
String _normText(String? s) =>
    s == null ? '' : s.toLowerCase().replaceAll(_nonAlnumRe, '');

bool _srodowiskoEqLoose(Srodowisko? a, Srodowisko? b){
  if(a == null && b == null) return true;
  if(a == null || b == null) return false;
  return a.hufiecSlug?.toLowerCase() == b.hufiecSlug?.toLowerCase()
      && a.choragiewSlug?.toLowerCase() == b.choragiewSlug?.toLowerCase()
      && a.okregSlug?.toLowerCase() == b.okregSlug?.toLowerCase()
      && a.orgSlug?.toLowerCase() == b.orgSlug?.toLowerCase()
      && _normText(a.custom) == _normText(b.custom);
}

bool _personGotSenderEmailAdded(ParsedContribEmail p, String? senderEmail){
  if(p.registered == null || senderEmail == null) return false;
  return !p.registered!.emails.any((e) => e.toLowerCase() == senderEmail.toLowerCase());
}

bool _isVeteran(String? senderEmail) => senderEmail != null
    && allRegisteredPeopleByEmailMap.containsKey(senderEmail.toLowerCase());

bool _needsUpdate(ParsedContribEmail p, String? senderEmail){
  if(p.registered == null || senderEmail == null) return false;
  final stored = allRegisteredPeopleByEmailMap[senderEmail.toLowerCase()];
  if(stored == null) return false;
  final a = stored.person;
  final b = p.registered!.person;
  return a.rankHarc != b.rankHarc
      || a.rankInstr != b.rankInstr
      || _normText(a.name) != _normText(b.name)
      || _normText(a.druzyna) != _normText(b.druzyna)
      || _normText(a.comment) != _normText(b.comment)
      || !_srodowiskoEqLoose(a.srodowisko, b.srodowisko);
}

class EmailSongDialog extends StatefulWidget{

  final void Function()? onSaved;

  const EmailSongDialog({this.onSaved, super.key});

  @override
  State<StatefulWidget> createState() => EmailSongDialogState();

}

class EmailSongDialogState extends State<EmailSongDialog> {

  late TextEditingController controller;
  ParsedContribEmail? _parsed;
  String? _parseError;
  String _manualSenderEmail = '';

  String? get _effectiveSenderEmail {
    final fromParse = _parsed?.senderEmail;
    if(fromParse != null && fromParse.trim().isNotEmpty) return fromParse;
    final manual = _manualSenderEmail.trim();
    if(manual.isEmpty || !_emailRe.hasMatch(manual)) return null;
    return manual.toLowerCase();
  }

  @override
  void initState() {
    controller = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _onTextChanged(String text){
    if(text.trim().isEmpty){
      setState((){ _parsed = null; _parseError = null; });
      return;
    }
    try {
      final result = parseContribEmail(text);
      setState((){ _parsed = result; _parseError = null; });
    } catch(e){
      setState((){ _parsed = null; _parseError = e.toString(); });
    }
  }

  bool get _willWriteContributorData =>
      _parsed != null
      && _parsed!.acceptedRulesVersion != null
      && _effectiveSenderEmail != null
      && _parsed!.song.contributorData == null;

  RegisteredContributor? get _enrichedRegistered {
    final registered = _parsed?.registered;
    if(registered == null) return null;
    final senderEmail = _effectiveSenderEmail;
    if(senderEmail == null) return registered;
    if(registered.emails.any((e) => e.toLowerCase() == senderEmail.toLowerCase())) return registered;
    return RegisteredContributor(
      person: registered.person,
      emails: [...registered.emails, senderEmail],
      userKey: registered.userKey,
    );
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    height: MediaQuery.of(context).size.height * 0.85,
    child: Column(
      children: [

        AppBarX(title: 'Piosenka z mejla'),

        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [

              SizedBox(
                width: songPreviewWidth + 24,
                child: Padding(
                  padding: EdgeInsets.all(Dimen.defMarg),
                  child: _SectionCard(
                    child: TextField(
                      maxLines: null,
                      expands: true,
                      controller: controller,
                      textAlignVertical: TextAlignVertical.top,
                      onChanged: _onTextChanged,
                      style: TextStyle(color: textEnab_(context), fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Wklej treść mejla z piosenką (włącznie z nagłówkami Gmaila)',
                        hintStyle: TextStyle(color: hintEnab_(context)),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        isCollapsed: true,
                      ),
                    ),
                  ),
                ),
              ),

              SizedBox(
                width: songPreviewWidth + 24,
                child: _PreviewPanel(
                  parsed: _parsed,
                  parseError: _parseError,
                  rawEmpty: controller.text.trim().isEmpty,
                  enrichedRegistered: _enrichedRegistered,
                  willWriteContributorData: _willWriteContributorData,
                  effectiveSenderEmail: _effectiveSenderEmail,
                  onManualSenderEmailChanged: (value) =>
                      setState(() => _manualSenderEmail = value),
                ),
              ),

            ],
          ),
        ),

        Material(
          color: cardEnab_(context),
          child: SimpleButton(
            radius: 0,
            padding: EdgeInsets.all(Dimen.iconMarg),
            onTap: _parsed == null ? null : _save,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(MdiIcons.plus, color: _parsed == null ? iconDisab_(context) : iconEnab_(context)),
                SizedBox(width: Dimen.iconMarg),
                Text(
                  'Dodaj piosenkę',
                  style: AppTextStyle(
                    fontWeight: weightHalfBold,
                    color: _parsed == null ? iconDisab_(context) : iconEnab_(context),
                  ),
                ),
              ],
            ),
          ),
        ),

      ],
    ),
  );

  void _save(){
    if(_parsed == null){
      AppScaffold.showMessage(context, text: 'Najpierw wklej poprawnie sformatowanego mejla.');
      return;
    }

    final parsedSong = _parsed!.song;
    final senderEmail = _effectiveSenderEmail;

    if(_willWriteContributorData){
      parsedSong.contributorData = ContributorData(
        email: senderEmail!,
        contributionDate: DateTime.now(),
        acceptedContributionRulesVersion: _parsed!.acceptedRulesVersion!,
      );
    }

    if(senderEmail != null){
      final alreadyHas = parsedSong.contribRefs.any(
              (c) => (c.emailRef ?? '').toLowerCase() == senderEmail.toLowerCase());
      if(!alreadyHas){
        parsedSong.contribRefs.add(ContributorRef(
          person: _parsed!.registered?.person,
          emailRef: senderEmail,
        ));
      }
    }

    parsedSong.id = 'o!_${parsedSong.generateFileName(
        withPerformer: BindTitleFileNameProvider.of(context).bindPerformer)}';

    TagsProvider.of(context).set(parsedSong.tags);
    AllSongsProvider.of(context).addOff(parsedSong);
    widget.onSaved?.call();
    SongFileNameDupErrProvider.of(context).checkAllDups(context);
    displaySong(context, parsedSong);
    Navigator.pop(context);
  }

}

class _PreviewPanel extends StatelessWidget {

  final ParsedContribEmail? parsed;
  final String? parseError;
  final bool rawEmpty;
  final RegisteredContributor? enrichedRegistered;
  final bool willWriteContributorData;
  final String? effectiveSenderEmail;
  final ValueChanged<String> onManualSenderEmailChanged;

  const _PreviewPanel({
    required this.parsed,
    required this.parseError,
    required this.rawEmpty,
    required this.enrichedRegistered,
    required this.willWriteContributorData,
    required this.effectiveSenderEmail,
    required this.onManualSenderEmailChanged,
  });

  @override
  Widget build(BuildContext context) {

    if(rawEmpty)
      return Padding(
        padding: EdgeInsets.all(Dimen.defMarg),
        child: Center(
          child: AppText(
            'Wklej treść mejla po lewej, by zobaczyć podgląd piosenki.',
            color: hintEnab_(context),
            textAlign: TextAlign.center,
            selectable: true,
          ),
        ),
      );

    if(parsed == null)
      return Padding(
        padding: EdgeInsets.all(Dimen.defMarg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(MdiIcons.alertCircleOutline, color: Colors.red, size: 48),
            SizedBox(height: Dimen.defMarg),
            AppText(
              'Nie udało się sparsować mejla.',
              color: Colors.red,
              textAlign: TextAlign.center,
              size: Dimen.textSizeBig,
              selectable: true,
            ),
            if(parseError != null) ...[
              SizedBox(height: Dimen.defMarg),
              SelectableText(
                parseError!,
                style: TextStyle(color: hintEnab_(context), fontSize: 12),
              ),
            ],
          ],
        ),
      );

    final p = parsed!;
    return SingleChildScrollView(
      padding: EdgeInsets.all(Dimen.defMarg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [

          if(p.isOldestFormat) ...[
            const _OldestFormatBlock(),
            SizedBox(height: Dimen.defMarg),
          ],

          _ConsentBlock(parsed: p, willWriteContributorData: willWriteContributorData),

          SizedBox(height: Dimen.defMarg),

          _SenderBlock(
            parsedSenderEmail: p.senderEmail,
            effectiveSenderEmail: effectiveSenderEmail,
            onManualChanged: onManualSenderEmailChanged,
          ),

          if(enrichedRegistered != null) ...[
            SizedBox(height: Dimen.defMarg),
            _PersonBlock(
              registered: enrichedRegistered!,
              addedSenderEmail: _personGotSenderEmailAdded(p, effectiveSenderEmail),
              isVeteran: _isVeteran(effectiveSenderEmail),
              hasUpdate: _needsUpdate(p, effectiveSenderEmail),
              parseWarnings: p.personParseWarnings,
            ),
          ],

          if(p.userMessage != null) ...[
            SizedBox(height: Dimen.defMarg),
            _UserMessageBlock(message: p.userMessage!),
          ],

          SizedBox(height: Dimen.defMarg),

          _AlreadyExistsBanner(song: p.song),

          _SongPreviewBlock(song: p.song),

        ],
      ),
    );
  }

}

class _SectionCard extends StatelessWidget {

  final Widget child;
  final Color? color;

  const _SectionCard({required this.child, this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.all(Dimen.defMarg),
    decoration: BoxDecoration(
      color: color ?? backgroundIcon_(context),
      borderRadius: BorderRadius.circular(AppCard.bigRadius),
    ),
    child: child,
  );

}

/// Wspólny układ: ikona po lewej, główna treść, opcjonalny "trailing".
class _IconRow extends StatelessWidget {

  final IconData icon;
  final Color? iconColor;
  final Widget child;
  final Widget? trailing;
  final CrossAxisAlignment crossAxisAlignment;

  const _IconRow({
    required this.icon,
    required this.child,
    this.iconColor,
    this.trailing,
    this.crossAxisAlignment = CrossAxisAlignment.center,
  });

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: crossAxisAlignment,
    children: [
      Padding(
        padding: EdgeInsets.symmetric(horizontal: Dimen.defMarg),
        child: Icon(icon, color: iconColor ?? hintEnab_(context)),
      ),
      SizedBox(width: Dimen.defMarg),
      Expanded(child: child),
      if(trailing != null) trailing!,
    ],
  );

}

class _ConsentBlock extends StatelessWidget {

  final ParsedContribEmail parsed;
  final bool willWriteContributorData;

  const _ConsentBlock({required this.parsed, required this.willWriteContributorData});

  @override
  Widget build(BuildContext context) {

    final willBeSaved = parsed.song.contributorData != null || willWriteContributorData;
    final consentInEmail = parsed.acceptedRulesVersion != null;
    final detectedButLost = consentInEmail && !willBeSaved;

    final Color color;
    final IconData icon;
    final String message;
    if(willBeSaved){
      color = Colors.green;
      icon = MdiIcons.checkCircleOutline;
      message = 'Zgoda autora zapisana w piosence';
    } else if(detectedButLost){
      color = Colors.orange;
      icon = MdiIcons.alertCircleOutline;
      message = parsed.senderEmail == null
          ? 'Wykryto zgodę bez adresu nadawcy — nie zostanie zapisana w piosence.'
          : 'Wykryto zgodę, ale nie zostanie zapisana w piosence.';
    } else {
      color = Colors.red;
      icon = MdiIcons.closeCircleOutline;
      message = 'Autor NIE wyraził zgody na zasady.';
    }

    return _SectionCard(
      color: color.withValues(alpha: 0.08),
      child: _IconRow(
        icon: icon,
        iconColor: color,
        child: AppText(message, size: Dimen.textSizeBig, selectable: true),
        trailing: consentInEmail
            ? Padding(
                padding: EdgeInsets.only(left: Dimen.defMarg),
                child: willBeSaved
                    ? _Pill.green(parsed.acceptedRulesVersion!)
                    : _Pill.amber(parsed.acceptedRulesVersion!),
              )
            : null,
      ),
    );
  }

}

class _SenderBlock extends StatefulWidget {

  /// Adres wyciągnięty przez parser z treści mejla — `null`, jeśli parser
  /// nic nie znalazł.
  final String? parsedSenderEmail;
  /// Wybrany ostatecznie adres (z parsera lub z ręcznego wpisania).
  final String? effectiveSenderEmail;
  /// Wywoływane, gdy użytkownik zmienia ręczny wpis.
  final ValueChanged<String> onManualChanged;

  const _SenderBlock({
    required this.parsedSenderEmail,
    required this.effectiveSenderEmail,
    required this.onManualChanged,
  });

  @override
  State<_SenderBlock> createState() => _SenderBlockState();
}

class _SenderBlockState extends State<_SenderBlock> {

  late TextEditingController _manualController;

  @override
  void initState() {
    super.initState();
    _manualController = TextEditingController();
  }

  @override
  void dispose() {
    _manualController.dispose();
    super.dispose();
  }

  Widget _warningIcon(String message) => Tooltip(
    message: message,
    child: Icon(
      MdiIcons.alertCircle,
      color: Colors.orange.shade800,
      size: Dimen.textSizeBig + 2,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final parsed = widget.parsedSenderEmail;
    final isHarcappInbox = parsed != null && parsed.toLowerCase() == _harcappInboxEmail;

    final Widget body;
    final Widget? trailing;

    if(parsed != null){
      body = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(child: AppText(parsed, size: Dimen.textSizeBig, selectable: true)),
          if(isHarcappInbox) ...[
            SizedBox(width: Dimen.defMarg),
            _warningIcon('To adres skrzynki HarcAppa — najpewniej parser '
                'wyciągnął zły adres z cytowanej odpowiedzi.'),
          ],
        ],
      );
      trailing = SimpleButton.from(
        context: context,
        margin: EdgeInsets.zero,
        padding: EdgeInsets.all(Dimen.defMarg),
        iconSize: Dimen.iconSmallSize,
        icon: MdiIcons.contentCopy,
        onTap: () {
          Clipboard.setData(ClipboardData(text: parsed));
          AppScaffold.showMessage(context, text: 'Skopiowano!');
        },
      );
    } else {
      // Brak wykrytego adresu — pozwalamy wpisać ręcznie.
      final manualEmpty = widget.effectiveSenderEmail == null;
      body = TextField(
        controller: _manualController,
        onChanged: widget.onManualChanged,
        style: AppTextStyle(fontSize: Dimen.textSizeBig, color: textEnab_(context)),
        decoration: InputDecoration(
          hintText: 'Wpisz adres nadawcy',
          hintStyle: AppTextStyle(fontSize: Dimen.textSizeBig, color: hintEnab_(context)),
          border: InputBorder.none,
          isCollapsed: true,
        ),
      );
      trailing = manualEmpty
          ? Padding(
              padding: EdgeInsets.symmetric(horizontal: Dimen.defMarg),
              child: _warningIcon('Parser nie znalazł adresu nadawcy — wpisz go ręcznie, '
                  'inaczej zgoda nie zostanie zapisana w piosence.'),
            )
          : null;
    }

    return _SectionCard(
      child: _IconRow(icon: MdiIcons.emailOutline, child: body, trailing: trailing),
    );
  }
}

class _PersonBlock extends StatefulWidget {

  final RegisteredContributor registered;
  final bool addedSenderEmail;
  final bool isVeteran;
  final bool hasUpdate;
  final List<String> parseWarnings;

  const _PersonBlock({
    required this.registered,
    required this.addedSenderEmail,
    required this.isVeteran,
    required this.hasUpdate,
    this.parseWarnings = const [],
  });

  @override
  State<_PersonBlock> createState() => _PersonBlockState();

}

class _PersonBlockState extends State<_PersonBlock> with SingleTickerProviderStateMixin {

  late TabController _tabController;

  /// Hufiec zastosowany z sugestii — null jeśli nie zastosowano.
  Hufiec? _appliedHufiec;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _appliedHufiec = _detectHufiec(widget.registered.person.srodowisko);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  RegisteredContributor get _effective {
    if(_appliedHufiec == null) return widget.registered;
    final p = widget.registered.person;
    return RegisteredContributor(
      person: Person(
        name: p.name,
        rankHarc: p.rankHarc,
        rankInstr: p.rankInstr,
        druzyna: p.druzyna,
        srodowisko: Srodowisko.hufiec(
          _appliedHufiec!.slug,
          showChoragiew: false,
          showOkreg: false,
        ),
        comment: p.comment,
      ),
      emails: widget.registered.emails,
      userKey: widget.registered.userKey,
    );
  }

  /// Szuka hufca pasującego do `custom` w danym [Srodowisko]. Zwraca `null`,
  /// jeśli struktura nie jest pusta lub `custom` < 3 znaki.
  static Hufiec? _detectHufiec(Srodowisko? s){
    if(s == null) return null;
    if(s.hufiecSlug != null || s.choragiewSlug != null || s.okregSlug != null || s.orgSlug != null) return null;
    final t = (s.custom ?? '').trim().toLowerCase();
    if(t.length < 3) return null;
    for(final h in hufce){
      final n = h.name.toLowerCase();
      if(n.contains(t) || t.contains(n)) return h;
    }
    return null;
  }

  String get _dartCode => registeredPersonToObjectStringLegacy(_effective);
  String get _jsonCode => const JsonEncoder.withIndent('  ').convert({
    ..._effective.person.toApiJsonMap(),
    'email': _effective.emails,
  });

  String get _activeCode => _tabController.index == 0 ? _dartCode : _jsonCode;

  Widget _hufiecSuggestionBanner() {
    final applied = _appliedHufiec;
    if(applied != null)
      return Padding(
        padding: EdgeInsets.only(top: Dimen.defMarg),
        child: Align(
          alignment: Alignment.centerLeft,
          child: _Pill.green(
            'Wykryto i użyto: ${applied.name}',
            trailingIcon: MdiIcons.undoVariant,
            onTap: () => setState(() => _appliedHufiec = null),
          ),
        ),
      );

    final suggested = _detectHufiec(widget.registered.person.srodowisko);
    if(suggested == null) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.only(top: Dimen.defMarg),
      child: Align(
        alignment: Alignment.centerLeft,
        child: _Pill.amber(
          'Wykryto: ${suggested.name}',
          trailingIcon: MdiIcons.chevronRight,
          onTap: () => setState(() => _appliedHufiec = suggested),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final contentBg = backgroundIcon_(context);
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _IconRow(
            icon: MdiIcons.accountOutline,
            child: AppText('Osoba dodająca', size: Dimen.textSizeBig, selectable: true),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _VeteranBadge(isVeteran: widget.isVeteran, hasUpdate: widget.hasUpdate),
                SizedBox(width: Dimen.defMarg),
                SimpleButton.from(
                  context: context,
                  margin: EdgeInsets.zero,
                  padding: EdgeInsets.all(Dimen.defMarg),
                  iconSize: Dimen.iconSmallSize,
                  icon: MdiIcons.contentCopy,
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: _activeCode));
                    AppScaffold.showMessage(context, text: 'Skopiowano!');
                  },
                ),
              ],
            ),
          ),
          SizedBox(height: Dimen.defMarg),
          _FolderTabs(
            activeIndex: _tabController.index,
            contentBg: contentBg,
            labels: const ['Dart', 'JSON'],
            onTap: (i) {
              _tabController.animateTo(i);
              setState((){});
            },
          ),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(Dimen.defMarg + 2),
            decoration: BoxDecoration(
              color: contentBg,
              borderRadius: BorderRadius.only(
                topLeft: _tabController.index == 0 ? Radius.zero : Radius.circular(6),
                topRight: Radius.circular(6),
                bottomLeft: Radius.circular(6),
                bottomRight: Radius.circular(6),
              ),
            ),
            child: SelectableText(
              _activeCode,
              style: TextStyle(
                color: textEnab_(context),
                fontFamily: 'monospace',
                fontSize: 12,
              ),
            ),
          ),
          _hufiecSuggestionBanner(),
          if(widget.parseWarnings.isNotEmpty) ...[
            SizedBox(height: Dimen.defMarg),
            _ParseWarningsBlock(warnings: widget.parseWarnings),
          ],
          if(widget.addedSenderEmail) ...[
            SizedBox(height: Dimen.defMarg),
            Center(
              child: AppText(
                'Adres nadawcy dodany automatycznie.',
                color: hintEnab_(context),
                textAlign: TextAlign.center,
                selectable: true,
              ),
            ),
          ],
        ],
      ),
    );
  }

}

class _SongPreviewBlock extends StatelessWidget {

  final SongRaw song;

  const _SongPreviewBlock({required this.song});

  @override
  Widget build(BuildContext context) => SongWidgetTemplate<SongRaw>(
    song,
    SongBaseSettings(),
    cacheSizes: false,
    scrollController: ScrollController(),
    key: ValueKey(song.title + song.songParts.length.toString()),
  );

}

class _AlreadyExistsBanner extends StatelessWidget {

  final SongRaw song;

  const _AlreadyExistsBanner({required this.song});

  @override
  Widget build(BuildContext context) => Consumer<SimilarSongProvider>(
    builder: (context, prov, _){
      if(prov.allSongs == null || !prov.hasSimilarSong(song.title))
        return const SizedBox.shrink();

      return Padding(
        padding: EdgeInsets.only(top: Dimen.defMarg),
        child: Material(
          borderRadius: BorderRadius.circular(AppCard.bigRadius),
          color: Colors.red.withValues(alpha: 0.12),
          clipBehavior: Clip.hardEdge,
          child: InkWell(
            onTap: () => showDialog(
              context: context,
              builder: (context) => Padding(
                padding: EdgeInsets.all(Dimen.sideMarg),
                child: SimilarSongViewerDialog(currentSong: song),
              ),
            ),
            child: Row(
              children: [
                Padding(
                  padding: EdgeInsets.all(Dimen.iconMarg),
                  child: Icon(MdiIcons.musicBoxMultiple, color: Colors.red),
                ),
                Expanded(
                  child: Text(
                    'Piosenka o takim tytule już jest!',
                    style: AppTextStyle(
                      color: Colors.red,
                      fontWeight: weightHalfBold,
                      fontSize: Dimen.textSizeBig,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(Dimen.iconMarg),
                  child: Icon(MdiIcons.eye, color: Colors.red),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );

}

class _OldestFormatBlock extends StatelessWidget {

  const _OldestFormatBlock();

  @override
  Widget build(BuildContext context) {
    const iconSize = Dimen.textSizeBig + 2;
    const iconGap = Dimen.defMarg;
    final color = Colors.orange.shade900;
    return _SectionCard(
      color: Colors.orange.withValues(alpha: 0.08),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(MdiIcons.alertCircle, color: color, size: iconSize),
              SizedBox(width: iconGap),
              Expanded(
                child: SelectableText(
                  'Mejl ze starej apki — odpisz autorowi:',
                  style: AppTextStyle(
                    color: color,
                    fontWeight: weightHalfBold,
                    fontSize: Dimen.textSizeBig,
                  ),
                ),
              ),
              SimpleButton.from(
                context: context,
                margin: EdgeInsets.zero,
                padding: EdgeInsets.all(Dimen.defMarg),
                iconSize: Dimen.iconSmallSize,
                icon: MdiIcons.contentCopy,
                onTap: () {
                  Clipboard.setData(const ClipboardData(text: oldestFormatReplyMessage));
                  AppScaffold.showMessage(context, text: 'Skopiowano treść odpowiedzi!');
                },
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.only(left: iconSize + iconGap, top: Dimen.defMarg / 2),
            child: SelectableText(
              oldestFormatReplyMessage,
              style: TextStyle(color: textEnab_(context), fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

}

class _ParseWarningsBlock extends StatelessWidget {

  final List<String> warnings;

  const _ParseWarningsBlock({required this.warnings});

  @override
  Widget build(BuildContext context) {
    const iconSize = Dimen.textSizeBig + 2;
    const iconGap = Dimen.defMarg;
    final color = Colors.orange.shade900;
    return _SectionCard(
      color: Colors.orange.withValues(alpha: 0.08),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(MdiIcons.alertCircle, color: color, size: iconSize),
              SizedBox(width: iconGap),
              Flexible(
                child: SelectableText(
                  'Pola nierozpoznane - popraw ręcznie:',
                  style: AppTextStyle(
                    color: color,
                    fontWeight: weightHalfBold,
                    fontSize: Dimen.textSizeBig,
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.only(left: iconSize + iconGap, top: Dimen.defMarg / 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for(final w in warnings)
                  Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: SelectableText(
                      '• $w',
                      style: TextStyle(
                        color: textEnab_(context),
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

}

class _UserMessageBlock extends StatelessWidget {

  final String message;

  const _UserMessageBlock({required this.message});

  @override
  Widget build(BuildContext context) => _SectionCard(
    child: _IconRow(
      icon: MdiIcons.messageOutline,
      crossAxisAlignment: CrossAxisAlignment.start,
      child: AppText(message, size: Dimen.textSizeNormal, selectable: true),
    ),
  );

}

class _Pill extends StatelessWidget {

  final String label;
  final Color bgColor;
  final Color textColor;
  final IconData? trailingIcon;
  final VoidCallback? onTap;

  const _Pill({
    required this.label,
    required this.bgColor,
    required this.textColor,
    this.trailingIcon,
    this.onTap,
  });

  factory _Pill.green(String label, {IconData? trailingIcon, VoidCallback? onTap}) => _Pill(
    label: label,
    bgColor: Colors.green.withValues(alpha: 0.18),
    textColor: Colors.green.shade800,
    trailingIcon: trailingIcon,
    onTap: onTap,
  );

  factory _Pill.amber(String label, {IconData? trailingIcon, VoidCallback? onTap}) => _Pill(
    label: label,
    bgColor: Colors.amber.withValues(alpha: 0.18),
    textColor: Colors.orange.shade900,
    trailingIcon: trailingIcon,
    onTap: onTap,
  );

  @override
  Widget build(BuildContext context) {
    final inner = Padding(
      padding: EdgeInsets.symmetric(horizontal: Dimen.defMarg + 2, vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w600,
              fontSize: Dimen.textSizeSmall,
            ),
          ),
          if(trailingIcon != null) ...[
            SizedBox(width: Dimen.iconMarg / 2),
            Icon(trailingIcon, color: textColor, size: Dimen.textSizeSmall + 4),
          ],
        ],
      ),
    );

    final radius = BorderRadius.circular(10);
    if(onTap == null)
      return Container(
        decoration: BoxDecoration(color: bgColor, borderRadius: radius),
        child: inner,
      );
    return Material(
      color: bgColor,
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(onTap: onTap, child: inner),
    );
  }

}

class _VeteranBadge extends StatelessWidget {

  final bool isVeteran;
  final bool hasUpdate;

  const _VeteranBadge({required this.isVeteran, this.hasUpdate = false});

  @override
  Widget build(BuildContext context) {
    final base = isVeteran ? _Pill.green('weteran') : _Pill.amber('świeżak');
    if(!isVeteran || !hasUpdate) return base;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        base,
        SizedBox(width: Dimen.defMarg),
        _Pill.amber('aktualizacja'),
      ],
    );
  }

}

class _FolderTabs extends StatelessWidget {

  final int activeIndex;
  final Color contentBg;
  final List<String> labels;
  final void Function(int) onTap;

  const _FolderTabs({
    required this.activeIndex,
    required this.contentBg,
    required this.labels,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      for(int i = 0; i < labels.length; i++)
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onTap(i),
            borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: Dimen.defMarg + 4, vertical: 4),
              decoration: BoxDecoration(
                color: i == activeIndex ? contentBg : Colors.transparent,
                borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
              ),
              child: Text(
                labels[i],
                style: TextStyle(
                  color: i == activeIndex ? textEnab_(context) : hintEnab_(context),
                  fontSize: Dimen.textSizeSmall,
                  fontWeight: i == activeIndex ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ),
        ),
    ],
  );

}
