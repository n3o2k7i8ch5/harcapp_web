import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:harcapp_core/comm_classes/app_text_style.dart';
import 'package:harcapp_core/comm_classes/color_pack.dart';
import 'package:harcapp_core/comm_classes/common.dart';
import 'package:harcapp_core/comm_widgets/app_button.dart';
import 'package:harcapp_core/comm_widgets/app_card.dart';
import 'package:harcapp_core/comm_widgets/bottom_sheet.dart';
import 'package:harcapp_core/comm_widgets/search_field.dart';
import 'package:harcapp_core/song_book/song_tags.dart';
import 'package:harcapp_core/song_book/widgets/song_tile.dart';
import 'package:harcapp_core/tag/tag.dart';
import 'package:harcapp_core/tag/tags_widget.dart';
import 'package:harcapp_core/values/dimen.dart';

import 'song_book_search_controller.dart';
import 'song_book_song.dart';

/// Spis treści śpiewnika — te same widoki co w apce: pole szukania
/// z opcjami (tagi) i kafelki piosenek.
class TableOfContentSongBookWidget extends StatefulWidget{

  final SongBookSearchController searchController;
  final SongBookSong? selectedSong;
  final void Function(SongBookSong song) onSongTap;

  const TableOfContentSongBookWidget({
    required this.searchController,
    required this.selectedSong,
    required this.onSongTap,
    super.key,
  });

  @override
  State<TableOfContentSongBookWidget> createState() => _TableOfContentSongBookWidgetState();

}

class _TableOfContentSongBookWidgetState extends State<TableOfContentSongBookWidget>{

  static const double _itemSep = Dimen.sideMarg;
  static const double _itemExtent = SongTile.height + _itemSep;

  SongBookSearchController get searchController => widget.searchController;

  late ScrollController scrollController;

  void _onSearchChanged(){
    if(!mounted) return;
    setState((){});
    if(scrollController.hasClients) scrollController.jumpTo(0);
  }

  @override
  void initState() {
    searchController.addListener(_onSearchChanged);

    // Otwarty spis (np. w szufladzie) od razu przy wybranej piosence.
    final int selectedIndex = widget.selectedSong == null ? -1 : searchController.results.indexOf(widget.selectedSong!);
    scrollController = ScrollController(
      initialScrollOffset: selectedIndex <= 2 ? 0 : (selectedIndex - 2)*_itemExtent,
    );
    super.initState();
  }

  @override
  void didUpdateWidget(covariant TableOfContentSongBookWidget oldWidget) {
    if(oldWidget.searchController != searchController){
      oldWidget.searchController.removeListener(_onSearchChanged);
      searchController.addListener(_onSearchChanged);
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    searchController.removeListener(_onSearchChanged);
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<SongBookSong> songs = searchController.results;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [

        _SongBookSearchField(searchController),

        Expanded(
          child: songs.isEmpty?
          Center(
            child: Text(
              'Brak piosenek\no zadanych kryteriach',
              textAlign: TextAlign.center,
              style: AppTextStyle(color: hintEnab_(context), fontWeight: weightHalfBold),
            ),
          ):
          ListView.builder(
            controller: scrollController,
            padding: const EdgeInsets.all(Dimen.sideMarg),
            itemExtent: _itemExtent,
            itemCount: songs.length,
            itemBuilder: (context, index) {
              final SongBookSong song = songs[index];
              final bool selected = song == widget.selectedSong;
              return Padding(
                padding: const EdgeInsets.only(bottom: _itemSep),
                // Obwódka na wierzchu — nie zmienia wysokości kafelka.
                child: Container(
                  foregroundDecoration: selected ? BoxDecoration(
                    border: Border.all(color: iconEnab_(context), width: 2),
                    borderRadius: BorderRadius.circular(AppCard.bigRadius),
                  ) : null,
                  child: SongTile<SongBookSong>(
                    song,
                    onTap: widget.onSongTap,
                  ),
                ),
              );
            },
          ),
        ),

      ],
    );
  }

}

/// Pole szukania jak w spisie treści apki: fraza, opcje pod zębatką (albo
/// po wpisaniu „#”) i zaznaczone tagi pod polem.
class _SongBookSearchField extends StatelessWidget{

  final SongBookSearchController searchController;

  const _SongBookSearchField(this.searchController);

  Future<void> showOptions(BuildContext context) => showScrollBottomSheet(
    context: context,
    builder: (_) => _SongBookSearchOptions(searchController),
  );

  @override
  Widget build(BuildContext context) => SearchField(
    hint: 'Tytuł, autor, wykonawca, słowa',
    controller: searchController.textController,
    margin: SearchField.normMargin,
    background: background_(context),

    onChanged: (text) {
      if(text == '#') {
        // Jak w apce: „#” otwiera opcje. W `post`, bo inaczej `onChanged`
        // wołane jest dwa razy.
        post(() => searchController.textController.text = '');
        showOptions(context);
      } else
        searchController.onPhraseChanged();
    },

    canClearText: () => searchController.isNotEmpty,
    onTextCleared: searchController.clear,

    trailing: AppButton(
      icon: Icon(MdiIcons.cogOutline, color: iconEnab_(context)),
      onTap: () => showOptions(context),
    ),

    bottom: searchController.checkedTags.isEmpty?
    null:
    SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(bottom: 6, left: Dimen.iconMarg, right: Dimen.iconMarg),
      child: SizedBox(
        height: 2*Dimen.defMarg + Dimen.textSizeNormal + 3,
        child: Row(
          children: [
            for(final (i, tag) in searchController.checkedTags.indexed) ...[
              if(i > 0) const SizedBox(width: Dimen.iconMarg),
              Center(
                child: Tag(
                  tag,
                  clipBehavior: Clip.none,
                  padding: EdgeInsets.zero,
                  fontSize: Dimen.textSizeSmall,
                  bold: true,
                  elevation: 0,
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );

}

class _SongBookSearchOptions extends StatefulWidget{

  final SongBookSearchController searchController;

  const _SongBookSearchOptions(this.searchController);

  @override
  State<_SongBookSearchOptions> createState() => _SongBookSearchOptionsState();

}

class _SongBookSearchOptionsState extends State<_SongBookSearchOptions>{

  @override
  Widget build(BuildContext context) => BottomSheetDef(
    childMargin: const EdgeInsets.all(Dimen.defMarg/2),
    title: 'Opcje wyszukiwania',
    builder: (context) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [

        const SizedBox(height: Dimen.BOTTOM_SHEET_MARG),

        TagsWidget.wrap<String>(
          allTags: SongTag.ALL,
          checkedTags: widget.searchController.checkedTags,
          separator: Dimen.defMarg,
          onTagTap: (String tag, bool checked){
            widget.searchController.toggleTag(tag);
            setState((){});
          },
        ),

        const SizedBox(height: Dimen.BOTTOM_SHEET_MARG),

      ],
    ),
  );

}
