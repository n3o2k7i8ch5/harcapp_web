import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:harcapp_core/comm_classes/app_text_style.dart';
import 'package:harcapp_core/comm_classes/color_pack.dart';
import 'package:harcapp_core/comm_classes/common.dart';
import 'package:harcapp_core/comm_widgets/app_card.dart';
import 'package:harcapp_core/comm_widgets/simple_button.dart';
import 'package:harcapp_core/song_book/playback/widgets/song_playback_bar.dart';
import 'package:harcapp_core/song_book/providers.dart';
import 'package:harcapp_core/song_book/widgets/song_widget_template.dart';
import 'package:harcapp_core/values/dimen.dart';
import 'package:harcapp_web/common/base_scaffold.dart';
import 'package:harcapp_web/consts.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';

import 'song_book_loader.dart';
import 'song_book_search_controller.dart';
import 'song_book_song.dart';
import 'table_of_content_song_book_widget.dart';

const String pathSongBook = '/song_book';
const String pathSongBookItem = '/song_book/:song';

String songBookPathOf(SongBookSong song) => '$pathSongBook/${Uri.encodeComponent(song.slug)}';

/// Śpiewnik: spis treści z boku, otwarta piosenka po prawej. Na wąskim
/// ekranie spis chowa się do szuflady.
class SongBookPage extends StatefulWidget{

  /// Fragment adresu wybranej piosenki ([SongBookSong.slug]).
  final String? songSlug;

  const SongBookPage({this.songSlug, super.key});

  @override
  State<SongBookPage> createState() => _SongBookPageState();

}

class _SongBookPageState extends State<SongBookPage>{

  static const double collapseWidth = AppLayout.collapseWidth;
  static const double songMaxWidth = 800;

  late GlobalKey<ScaffoldState> scaffoldKey;
  late Future<List<SongBookSong>> songsFuture;
  SongBookSearchController? searchController;

  bool get tocAlwaysVisible => MediaQuery.of(context).size.width > collapseWidth;

  SongBookSong? selectedSong(List<SongBookSong> songs){
    final String? slug = widget.songSlug;
    if(slug == null) return null;
    for(final song in songs)
      if(song.slug == slug || song.id == slug) return song;
    return null;
  }

  void openSong(SongBookSong song){
    scaffoldKey.currentState?.closeDrawer();
    context.go(songBookPathOf(song));
  }

  /// Kliknięty autor, wykonawca, tag… w piosence — jak w apce: spis
  /// treści z tym wyszukaniem.
  void searchInToc(void Function(SongBookSearchController controller) apply){
    final controller = searchController;
    if(controller == null) return;
    apply(controller);
    if(!tocAlwaysVisible) scaffoldKey.currentState?.openDrawer();
  }

  @override
  void initState() {
    scaffoldKey = GlobalKey();
    songsFuture = SongBookLoader.load();

    // Wąski ekran, nic nie wybrane — od razu spis treści.
    // Szuflada istnieje dopiero po przebudowie z wczytanymi piosenkami.
    songsFuture.then((_) => post(() {
      if(!mounted || widget.songSlug != null) return;
      if(tocAlwaysVisible) return;
      scaffoldKey.currentState?.openDrawer();
    }));
    super.initState();
  }

  @override
  void dispose() {
    searchController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final bool tocAlwaysVisible = constraints.maxWidth > collapseWidth;

      return FutureBuilder<List<SongBookSong>>(
        future: songsFuture,
        initialData: SongBookLoader.loaded,
        builder: (context, snapshot) {
          final List<SongBookSong>? songs = snapshot.data;
          final SongBookSong? song = songs == null ? null : selectedSong(songs);
          if(songs != null) searchController ??= SongBookSearchController(songs);

          Widget toc() => TableOfContentSongBookWidget(
            searchController: searchController!,
            selectedSong: song,
            onSongTap: openSong,
          );

          Widget body;
          if(snapshot.hasError)
            body = _MessageWidget('Nie udało się wczytać śpiewnika', icon: MdiIcons.alertCircleOutline);
          else if(songs == null)
            body = const Center(child: CircularProgressIndicator());
          else
            body = Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [

                if(tocAlwaysVisible)
                  Padding(
                    // Spis ma własne marginesy (jak w apce) — dopełniamy do marginesu strony.
                    padding: EdgeInsets.only(top: pageMargin(context) - Dimen.defMarg, left: pageMargin(context) - Dimen.sideMarg),
                    child: SizedBox(width: drawerWidth, child: toc()),
                  ),

                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(top: pageMargin(context), left: pageMargin(context), right: pageMargin(context)),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: songMaxWidth),
                        child: song != null?
                        _SongBookSongWidget(
                          song,
                          onSearch: searchInToc,
                          key: ValueKey(song.id),
                        ):
                        widget.songSlug != null?
                        _MessageWidget('Nie ma takiej piosenki', icon: MdiIcons.musicNoteOff):
                        _MessageWidget(
                          tocAlwaysVisible ? 'Wybierz piosenkę ze spisu' : 'Otwórz spis piosenek',
                          icon: tocAlwaysVisible ? MdiIcons.arrowLeft : MdiIcons.formatListBulleted,
                          onTap: tocAlwaysVisible ? null : () => scaffoldKey.currentState?.openDrawer(),
                        ),
                      ),
                    ),
                  ),
                ),

              ],
            );

          return BaseScaffold(
            scaffoldKey: scaffoldKey,
            drawer: tocAlwaysVisible || songs == null ? null : Drawer(
              backgroundColor: background_(context),
              width: drawerWidth,
              child: SafeArea(child: toc()),
            ),
            body: body,
          );
        },
      );
    },
  );

}

class _SongBookSongWidget extends StatefulWidget{

  final SongBookSong song;
  final void Function(void Function(SongBookSearchController controller) apply) onSearch;

  const _SongBookSongWidget(this.song, {required this.onSearch, super.key});

  @override
  State<_SongBookSongWidget> createState() => _SongBookSongWidgetState();

}

class _SongBookSongWidgetState extends State<_SongBookSongWidget>{

  SongBookSong get song => widget.song;

  late ScrollController scrollController;

  void shift(BuildContext context, TextSizeProvider textSizeProv, {required bool up}){
    if(up) song.shiftChordsUp();
    else song.shiftChordsDown();
    _afterShift(context, textSizeProv);
  }

  // Inne chwyty bywają szersze — tekst trzeba przemierzyć na nowo.
  void _afterShift(BuildContext context, TextSizeProvider textSizeProv){
    textSizeProv.recalculate(
      song,
      chordsVisible: ShowChordsProvider.of(context).showChords,
      textScaler: MediaQuery.textScalerOf(context),
    );
    ChordShiftProvider.of(context).notify();
  }

  void onTextSizeChanged(BuildContext context, bool changedSize){
    if(!changedSize) BaseScaffold.showMessage(context, 'Osiągnięto limit');
  }

  @override
  void initState() {
    scrollController = ScrollController();
    super.initState();
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SongWidgetTemplate<SongBookSong>(
    song,
    ShowChordsProvider.of(context).settings,
    scrollController: scrollController,
    topScreenPadding: 0,
    playbackBar: PlaybackBarMode.preview,

    onAuthorTap: (author) => widget.onSearch((c) => c.setPhrase(author)),
    onComposerTap: (composer) => widget.onSearch((c) => c.setPhrase(composer)),
    onPerformerTap: (performer) => widget.onSearch((c) => c.setPhrase(performer)),
    onTagTap: (tag) => widget.onSearch((c) => c.showTag(tag)),

    onCopyTap: () async {
      await Clipboard.setData(ClipboardData(text: '${song.title}\n\n${song.text}'));
      if(!context.mounted) return;
      BaseScaffold.showMessage(context, 'Skopiowano tekst piosenki');
    },

    // Jak w apce. Chwytów na stronie schować się nie da, więc zamiast
    // „Schowaj chwyty, by powiększyć” zostaje sam komunikat o limicie.
    onMinusTap: onTextSizeChanged,
    onPlusTap: onTextSizeChanged,

    onChordsTap: (prov) => shift(context, prov, up: true),
    onChordsLongPress: (prov) => shift(context, prov, up: false),

    footer: (context, _) => const SizedBox(height: 4*Dimen.sideMarg),
  );

}

class _MessageWidget extends StatelessWidget{

  final String text;
  final IconData icon;
  final void Function()? onTap;

  const _MessageWidget(this.text, {required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) => Center(
    child: SimpleButton(
      radius: AppCard.bigRadius,
      padding: const EdgeInsets.all(40),
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: textDisab_(context), size: 24),
          const SizedBox(width: Dimen.iconMarg),
          Text(
            text,
            style: AppTextStyle(fontSize: 20, color: textDisab_(context), fontWeight: weightHalfBold),
          ),
        ],
      ),
    ),
  );

}
