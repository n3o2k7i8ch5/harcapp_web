import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:harcapp_core/comm_classes/color_pack.dart';
import 'package:harcapp_core/comm_widgets/app_bar.dart';
import 'package:harcapp_core/comm_widgets/app_card.dart';
import 'package:harcapp_core/comm_widgets/app_scaffold.dart';
import 'package:harcapp_core/comm_widgets/app_text.dart';
import 'package:harcapp_core/comm_widgets/simple_button.dart';
import 'package:harcapp_core/song_book/contrib_song_legacy.dart';
import 'package:harcapp_core/song_book/contributor_identity.dart';
import 'package:harcapp_core/song_book/contributor_identity_resolver.dart';
import 'package:harcapp_core/song_book/parse_contrib_email.dart';
import 'package:harcapp_core/song_book/song_core.dart';
import 'package:harcapp_core/song_book/song_editor/providers.dart';
import 'package:harcapp_core/song_book/song_editor/song_raw.dart';
import 'package:harcapp_core/song_book/widgets/song_widget_template.dart';
import 'package:harcapp_core/values/dimen.dart';
import 'package:harcapp_core/values/people/person.dart';
import 'package:harcapp_core/values/people/utils.dart';
import 'package:harcapp_core/comm_classes/app_text_style.dart';
import 'package:harcapp_web/consts.dart';
import 'package:harcapp_web/songs/left_panel/song_list_view.dart';
import 'package:harcapp_web/songs/providers.dart';
import 'package:harcapp_web/songs/similar_song_viewer.dart';
import 'package:harcapp_web/songs/song_preview_widget.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';

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
      setState((){
        _parsed = null;
        _parseError = null;
      });
      return;
    }
    try {
      ParsedContribEmail result = parseContribEmail(text);
      setState((){
        _parsed = result;
        _parseError = null;
      });
    } catch(e){
      setState((){
        _parsed = null;
        _parseError = e.toString();
      });
    }
  }

  bool get _willWriteContributorData {
    if(_parsed == null) return false;
    if(_parsed!.acceptedRulesVersion == null) return false;
    if(_parsed!.senderEmail == null) return false;
    if(_parsed!.song.contributorData != null) return false;
    return true;
  }

  Person? get _enrichedPerson {
    if(_parsed?.person == null) return null;
    Person p = _parsed!.person!;
    String? senderEmail = _parsed!.senderEmail;
    if(senderEmail == null) return p;
    if(p.email.any((e) => e.toLowerCase() == senderEmail.toLowerCase())) return p;
    return Person(
      name: p.name,
      rankHarc: p.rankHarc,
      rankInstr: p.rankInstr,
      druzyna: p.druzyna,
      srodowisko: p.srodowisko,
      org: p.org,
      comment: p.comment,
      email: [...p.email, senderEmail],
    );
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    height: MediaQuery.of(context).size.height * 0.85,
    child: Column(
      children: [

        AppBarX(
          title: 'Piosenka z mejla',
        ),

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
                  enrichedPerson: _enrichedPerson,
                  willWriteContributorData: _willWriteContributorData,
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
                Icon(
                  MdiIcons.plus,
                  color: _parsed == null ? iconDisab_(context) : iconEnab_(context),
                ),
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

    SongRaw parsedSong = _parsed!.song;

    if(_willWriteContributorData){
      parsedSong.contributorData = ContributorData(
        email: _parsed!.senderEmail!,
        contributionDate: DateTime.now(),
        acceptedContributionRulesVersion: _parsed!.acceptedRulesVersion!,
      );
    }

    String? senderEmail = _parsed!.senderEmail;
    if(senderEmail != null){
      bool alreadyHas = parsedSong.contribId.any(
              (c) => (c.emailRef ?? '').toLowerCase() == senderEmail.toLowerCase());
      if(!alreadyHas){
        parsedSong.contribId.add(ContributorIdentity(
          name: _parsed!.person?.name,
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
  final Person? enrichedPerson;
  final bool willWriteContributorData;

  const _PreviewPanel({
    required this.parsed,
    required this.parseError,
    required this.rawEmpty,
    required this.enrichedPerson,
    required this.willWriteContributorData,
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

    return SingleChildScrollView(
      padding: EdgeInsets.all(Dimen.defMarg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [

          _ConsentBlock(
            parsed: parsed!,
            willWriteContributorData: willWriteContributorData,
          ),

          SizedBox(height: Dimen.defMarg),

          _SenderBlock(
            senderEmail: parsed!.senderEmail,
          ),

          if(enrichedPerson != null) ...[
            SizedBox(height: Dimen.defMarg),
            _PersonBlock(
              person: enrichedPerson!,
              addedSenderEmail: _personGotSenderEmailAdded(parsed!),
              isVeteran: _isVeteran(parsed!.senderEmail),
            ),
          ],

          if(parsed!.userMessage != null) ...[
            SizedBox(height: Dimen.defMarg),
            _UserMessageBlock(message: parsed!.userMessage!),
          ],

          SizedBox(height: Dimen.defMarg),

          _AlreadyExistsBanner(song: parsed!.song),

          _SongPreviewBlock(song: parsed!.song),

        ],
      ),
    );
  }

  bool _personGotSenderEmailAdded(ParsedContribEmail p){
    if(p.person == null || p.senderEmail == null) return false;
    return !p.person!.email.any(
            (e) => e.toLowerCase() == p.senderEmail!.toLowerCase());
  }

  bool _isVeteran(String? senderEmail){
    if(senderEmail == null) return false;
    return allPeopleByEmailMap.containsKey(senderEmail.toLowerCase());
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

class _ConsentBlock extends StatelessWidget {

  final ParsedContribEmail parsed;
  final bool willWriteContributorData;

  const _ConsentBlock({
    required this.parsed,
    required this.willWriteContributorData,
  });

  @override
  Widget build(BuildContext context) {

    bool consented = parsed.acceptedRulesVersion != null;

    Color iconColor = consented ? Colors.green : Colors.red;
    IconData icon = consented ? MdiIcons.checkCircleOutline : MdiIcons.closeCircleOutline;

    return _SectionCard(
      color: consented
          ? Colors.green.withValues(alpha: 0.08)
          : Colors.red.withValues(alpha: 0.08),
      child: Row(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: Dimen.defMarg),
            child: Icon(icon, color: iconColor),
          ),
          SizedBox(width: Dimen.defMarg),
          Expanded(
            child: AppText(
              consented
                  ? 'Zgoda autora zapisana w piosence'
                  : 'Autor NIE wyraził zgody na zasady.',
              size: Dimen.textSizeBig,
              selectable: true,
            ),
          ),
          if(consented)
            Padding(
              padding: EdgeInsets.only(left: Dimen.defMarg),
              child: _Pill.green(parsed.acceptedRulesVersion!),
            ),
        ],
      ),
    );
  }

}

class _SenderBlock extends StatelessWidget {

  final String? senderEmail;

  const _SenderBlock({required this.senderEmail});

  @override
  Widget build(BuildContext context) => _SectionCard(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: Dimen.defMarg),
          child: Icon(MdiIcons.emailOutline, color: hintEnab_(context)),
        ),
        SizedBox(width: Dimen.defMarg),
        Expanded(
          child: senderEmail == null
              ? AppText(
                  'Nie znaleziono adresu nadawcy.',
                  size: Dimen.textSizeBig,
                  color: hintEnab_(context),
                  selectable: true,
                )
              : AppText(
                  senderEmail!,
                  size: Dimen.textSizeBig,
                  selectable: true,
                ),
        ),
        if(senderEmail != null)
          SimpleButton.from(
            context: context,
            margin: EdgeInsets.zero,
            padding: EdgeInsets.all(Dimen.defMarg),
            iconSize: Dimen.iconSmallSize,
            icon: MdiIcons.contentCopy,
            onTap: () {
              Clipboard.setData(ClipboardData(text: senderEmail!));
              AppScaffold.showMessage(context, text: 'Skopiowano!');
            },
          ),
      ],
    ),
  );

}

class _PersonBlock extends StatefulWidget {

  final Person person;
  final bool addedSenderEmail;
  final bool isVeteran;

  const _PersonBlock({
    required this.person,
    required this.addedSenderEmail,
    required this.isVeteran,
  });

  @override
  State<_PersonBlock> createState() => _PersonBlockState();

}

class _PersonBlockState extends State<_PersonBlock> with SingleTickerProviderStateMixin {

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String get _dartCode => personToObjectStringLegacy(widget.person);
  String get _jsonCode => const JsonEncoder.withIndent('  ').convert(widget.person.toApiJsonMap());

  String get _activeCode => _tabController.index == 0 ? _dartCode : _jsonCode;

  Color _contentBg(BuildContext context) => backgroundIcon_(context);

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: Dimen.defMarg),
                child: Icon(MdiIcons.accountOutline, color: hintEnab_(context)),
              ),
              SizedBox(width: Dimen.defMarg),
              Expanded(
                child: AppText(
                  'Osoba dodająca',
                  size: Dimen.textSizeBig,
                  selectable: true,
                ),
              ),
              _VeteranBadge(isVeteran: widget.isVeteran),
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
          SizedBox(height: Dimen.defMarg),
          _FolderTabs(
            activeIndex: _tabController.index,
            contentBg: _contentBg(context),
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
              color: _contentBg(context),
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
  Widget build(BuildContext context) => SongWidgetTemplate<SongRaw, ContributorIdentitySimpleResolver>(
    song,
    SongBaseSettings(),
    cacheSizes: false,
    scrollController: ScrollController(),
    key: ValueKey(song.title + song.songParts.length.toString()),
    contribIdResolver: ContributorIdentitySimpleResolver(),
  );

}

class _AlreadyExistsBanner extends StatelessWidget {

  final SongRaw song;

  const _AlreadyExistsBanner({required this.song});

  @override
  Widget build(BuildContext context) => Consumer<SimilarSongProvider>(
    builder: (context, prov, _){
      if(prov.allSongs == null) return const SizedBox.shrink();
      if(!prov.hasSimilarSong(song.title)) return const SizedBox.shrink();

      return Padding(
        padding: EdgeInsets.only(bottom: Dimen.defMarg),
        child: Material(
          borderRadius: BorderRadius.circular(AppCard.bigRadius),
          color: Colors.red.withValues(alpha: 0.12),
          clipBehavior: Clip.hardEdge,
          child: InkWell(
            onTap: () => showDialog(
              context: context,
              builder: (context) => Padding(
                padding: EdgeInsets.all(Dimen.sideMarg),
                child: SimilarSongViewerDialog(songTitle: song.title),
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

class _UserMessageBlock extends StatelessWidget {

  final String message;

  const _UserMessageBlock({required this.message});

  @override
  Widget build(BuildContext context) => _SectionCard(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: Dimen.defMarg),
          child: Icon(MdiIcons.messageOutline, color: hintEnab_(context)),
        ),
        SizedBox(width: Dimen.defMarg),
        Expanded(
          child: AppText(
            message,
            size: Dimen.textSizeNormal,
            selectable: true,
          ),
        ),
      ],
    ),
  );

}

class _Pill extends StatelessWidget {

  final String label;
  final Color bgColor;
  final Color textColor;

  const _Pill({
    required this.label,
    required this.bgColor,
    required this.textColor,
  });

  factory _Pill.green(String label) => _Pill(
    label: label,
    bgColor: Colors.green.withValues(alpha: 0.18),
    textColor: Colors.green.shade800,
  );

  factory _Pill.amber(String label) => _Pill(
    label: label,
    bgColor: Colors.amber.withValues(alpha: 0.18),
    textColor: Colors.orange.shade900,
  );

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(
      horizontal: Dimen.defMarg + 2,
      vertical: 2,
    ),
    decoration: BoxDecoration(
      color: bgColor,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(
      label,
      style: TextStyle(
        color: textColor,
        fontWeight: FontWeight.w600,
        fontSize: Dimen.textSizeSmall,
      ),
    ),
  );

}

class _VeteranBadge extends StatelessWidget {

  final bool isVeteran;

  const _VeteranBadge({required this.isVeteran});

  @override
  Widget build(BuildContext context) => isVeteran
      ? _Pill.green('weteran')
      : _Pill.amber('świeżak');

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
              padding: EdgeInsets.symmetric(
                horizontal: Dimen.defMarg + 4,
                vertical: 4,
              ),
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
