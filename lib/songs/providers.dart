import 'dart:async';

import 'package:flutter/material.dart';
import 'package:harcapp_core/comm_classes/sha_pref.dart';
import 'package:harcapp_core/comm_classes/text_utils.dart';
import 'package:harcapp_core/song_book/import_hrcpsng.dart';
import 'package:harcapp_core/song_book/similarity/similarity.dart';
import 'package:harcapp_core/song_book/song_editor/song_raw.dart';
import 'package:harcapp_web/common/sha_pref.dart';
import 'package:harcapp_web/songs/utils/song_loader.dart';
import 'package:harcapp_web/songs/utils/song_search.dart';
import 'package:provider/provider.dart';


class BindTitleFileNameProvider extends ChangeNotifier{

  static BindTitleFileNameProvider of(BuildContext context) => Provider.of<BindTitleFileNameProvider>(context, listen: false);

  static const bool DEF_VAL = true;

  late bool _bindTitle;
  late bool _bindPerformer;

  BindTitleFileNameProvider(){
    _bindTitle = DEF_VAL;
    _bindPerformer = DEF_VAL;
  }

  bool get bindTitle => _bindTitle;
  set bindTitle(bool value){
    _bindTitle = value;
    notifyListeners();
  }

  bool get bindPerformer => _bindPerformer;
  set bindPerformer(bool value){
    _bindPerformer = value;
    notifyListeners();
  }

  void setSetBasedOnSong(SongRaw song){
    bindTitle = song.id.split('@')[0] == song.idFromTitle(withPerformer: false);

    bindPerformer = song.id == song.idFromTitle(withPerformer: true);
    notifyListeners();
  }

}

class AllSongsProvider extends ChangeNotifier{

  static AllSongsProvider of(BuildContext context) => Provider.of<AllSongsProvider>(context, listen: false);

  List<SongRaw> _songs;
  Map<SongRaw, bool> _confMap = {};

  int get length => _songs.length;

  List<SongRaw> get songs => _songs;

  AllSongsProvider(List<SongRaw> songs): _songs = songs, _confMap = {for (SongRaw song in songs) song: song.isConfid};

  void clear(){
    _songs.clear();
    _confMap.clear();
    _cacheSongs();
    notifyListeners();
  }

  void addOff(SongRaw song){
    _songs.add(song);
    _confMap[song] = false;
    _cacheSongs();
    notifyListeners();
  }

  void addConf(SongRaw song){
    _songs.add(song);
    _confMap[song] = true;
    _cacheSongs();
    notifyListeners();
  }

  void remove(SongRaw? song){
    // `removeWhere`, a nie `remove`: gdyby ten sam obiekt trafił na listę
    // więcej niż raz, `remove` zdjęłoby tylko pierwsze wystąpienie i piosenka
    // zostałaby na liście (z fałszywym alarmem o powtórzonej nazwie).
    _songs.removeWhere((s) => identical(s, song));
    _confMap.remove(song);
    _cacheSongs();
    notifyListeners();
  }

  void removeAll(List<SongRaw> songs){
    for(SongRaw song in songs){
      _songs.removeWhere((s) => identical(s, song));
      _confMap.remove(song);
    }
    _cacheSongs();
    notifyListeners();
  }

  void addAll(List<SongRaw> songs, Map<SongRaw, bool> confMap){
    _songs.addAll(songs);
    _confMap.addAll(confMap);
    _cacheSongs();
    notifyListeners();
  }

  /// Ile piosenek faktycznie wchodzi do śpiewnika. Przy przeglądzie
  /// piosenkomatem resztę zgasiłeś przełącznikiem; poza przeglądem
  /// równe [length].
  int get goingInCount =>
      _songs.where((s) => s.piosenkomatData?.rejected != true).length;

  bool? isConf(SongRaw song) => _confMap[song];

  void set(SongRaw song, bool isConf){
    _confMap[song] = isConf;
    _cacheSongs();
    notifyListeners();
  }

  /// Roboczy stan warsztatu — razem z duplikatami, żeby po odświeżeniu dalej
  /// było je widać i dało się je naprawić.
  void _cacheSongs() =>
    ShaPref.setString(SHA_PREF_LAST_EDITED_SONGS, convertAllToCode(allowDuplicateIds: true));

  static Future<List<SongRaw>> loadCachedSongs() async {
    String? code = ShaPref.getStringOrNull(SHA_PREF_LAST_EDITED_SONGS);
    if(code == null) return [];

    // Cache jest pisany przez `convertAllToCode()`, czyli w formacie hrcpsng —
    // i tak samo go czytamy. `decodeSongs()` to indeks tytuł -> piosenki (dla
    // szukania podobnych) i wrzuca ten sam obiekt raz na tytuł i raz na każdy
    // tytuł ukryty, więc piosenka z `hidTitles` lądowała na liście kilka razy
    // (fałszywy alarm o powtórzonej nazwie, a usunięcie zdejmowało tylko jedno
    // wystąpienie).
    try {
      (List<SongRaw>, List<SongRaw>) songsResult = importHrcpsng(code);
      return songsResult.$2.cast<SongRaw>() + songsResult.$1.cast<SongRaw>();
    } catch(e){
      // Stary/nadgryziony cache (np. pomieszane indeksy) — wtedy ratujemy, co
      // się da, starą drogą, ale z odsiewaniem powtórzonych wystąpień.
      Map<String, List<SongRaw>> decodedSongs = decodeSongs(code);

      Set<SongRaw> seen = Set.identity();
      List<SongRaw> result = [];
      for (List<SongRaw> songs in decodedSongs.values)
        for (SongRaw song in songs)
          if(seen.add(song)) result.add(song);

      return result;
    }
  }

  static void clearCachedSongs() =>
      ShaPref.remove(SHA_PREF_LAST_EDITED_SONGS);
  
  /// Plik piosenek z całego warsztatu. Zdublowane id to
  /// [HrcpsngDuplicateIdError] — pliku z duplikatami nie zapisujemy; tylko
  /// roboczy cache ([allowDuplicateIds]) je przenosi.
  String convertAllToCode({bool allowDuplicateIds = false}){

    _songs.sort((a, b) => compareText(a.title, b.title));

    // Z uwagami piosenkomatu: to ten plik wraca do narzędzia jako
    // `reviewed-*.hrcpsng` i po nich poznaje, co zostało ogarnięte.
    (String, Map) entryOf(SongRaw song) =>
        (song.id, song.toApiJsonMap(withId: false, withPiosenkomatData: true));

    return encodeHrcpsngEntries(
      official: [for(SongRaw song in _songs) if(!isConf(song)!) entryOf(song)],
      conf: [for(SongRaw song in _songs) if(isConf(song)!) entryOf(song)],
      allowDuplicateIds: allowDuplicateIds,
    );
  }

}

class SongFileNameDupErrProvider extends ChangeNotifier{

  static SongFileNameDupErrProvider of(BuildContext context) => Provider.of<SongFileNameDupErrProvider>(context, listen: false);
  static notify_(BuildContext context) => of(context).notify();

  late Map<String, List<SongRaw>> _map;

  SongFileNameDupErrProvider(){
    _map = {};
  }

  get lclIds => _map.keys.toList();
  get dupLclIds => lclIds.where((lclId) => _map[lclId]!.length > 1).toList();

  List<SongRaw> get(SongRaw song) => _map[song.id]??[];

  int get count{
    int num = 0;
    for(String songFileName in _map.keys)
      if(_map[songFileName]!.length > 1)
        num += _map[songFileName]!.length;

    return num;
  }

  bool hasDup(SongRaw song) => _map[song.id] != null && _map[song.id]!.length > 1;

  void checkAllDups(BuildContext context){
    _map.clear();

    for(SongRaw song in AllSongsProvider.of(context).songs) {
      if(_map[song.id] == null) _map[song.id] = [];
      _map[song.id]!.add(song);
    }

    notifyListeners();
  }

  void notify() => notifyListeners();

}

class SongPreviewProvider extends ChangeNotifier{

  static SongPreviewProvider of(BuildContext context) => Provider.of<SongPreviewProvider>(context, listen: false);

  late bool _code;
  late bool _showSong;

  SongPreviewProvider(){
    _code = false;
    _showSong = false;
  }

  bool get code => _code;
  set code(bool value){
    _code = value;
    notifyListeners();
  }

  bool get showSong => _showSong;
  set showSong(bool value){
    if(_showSong == value) return;
    _showSong = value;
    notifyListeners();
  }

}

class EmailSongUnlockProvider extends ChangeNotifier{

  static EmailSongUnlockProvider of(BuildContext context) => Provider.of<EmailSongUnlockProvider>(context, listen: false);

  static const int _unlockClickCount = 4;
  static const Duration _resetTimeout = Duration(seconds: 2);

  int _clickCount = 0;
  DateTime? _lastClickTime;
  bool _unlocked = false;

  bool get unlocked => _unlocked;

  void registerClick(){
    if(_unlocked) return;

    DateTime now = DateTime.now();
    if(_lastClickTime != null && now.difference(_lastClickTime!) > _resetTimeout)
      _clickCount = 0;

    _lastClickTime = now;
    _clickCount++;

    if(_clickCount >= _unlockClickCount){
      _unlocked = true;
      notifyListeners();
    }
  }

}

class SongEditorPanelProvider extends ChangeNotifier{

  static SongEditorPanelProvider of(BuildContext context) => Provider.of<SongEditorPanelProvider>(context, listen: false);
  static void notify_(BuildContext context) => of(context).notify();

  void notify() => notifyListeners();

}

/// Podobne piosenki dla edytora: śpiewnik apki (raz, porcjami w tle) plus
/// warsztat (przebudowywany, gdy zmieni się cokolwiek, co profil czyta).
///
/// Wyniki są cache'owane po **tożsamości** piosenki i sygnaturze jej treści:
/// o to samo pyta kilku konsumentów naraz (belka, padding edytora, lista),
/// a `CurrentItemProvider.notify()` leci z każdym znakiem. Sygnatura, nie
/// `hashCode` — `SongRaw` jest mutowalny i nie nadpisuje `==`.
///
/// Dwie części osobno: porównanie ze śpiewnikiem apki zależy **tylko** od
/// samej piosenki, więc znak wpisany w innej piosence warsztatu go nie
/// unieważnia — liczy się od nowa tylko mała część „warsztat”. Inaczej każdy
/// znak kazałby wszystkim widocznym kafelkom przeszukiwać cały śpiewnik.
///
/// Przy pisaniu nie liczymy z każdym znakiem: dopóki piosenka albo warsztat
/// zmieniły się mniej niż [settle] temu, oddajemy poprzedni wynik, a po
/// chwili ciszy liczymy od nowa i dajemy znać słuchaczom. Pierwszy wynik dla
/// piosenki liczy się od razu.
class SimilarSongProvider extends ChangeNotifier{

  static SimilarSongProvider of(BuildContext context) => Provider.of<SimilarSongProvider>(context, listen: false);

  SongIndex<SongRaw>? _app;

  /// Ile ciszy po ostatniej zmianie, zanim policzymy od nowa.
  final Duration settle;

  SimilarSongProvider({this.settle = const Duration(milliseconds: 300)});

  /// Do testów: gotowy indeks zamiast ładowania z assetów; domyślnie bez
  /// czekania na ciszę, żeby każda zmiana od razu dawała nowy wynik.
  @visibleForTesting
  SimilarSongProvider.withIndex(SongIndex<SongRaw> app, {this.settle = Duration.zero}): _app = app;

  /// Czy śpiewnik apki już jest. Przed tym nic nie porównujemy — lepiej
  /// przez chwilę nie ostrzegać, niż ostrzegać „nic nie znaleziono”.
  bool get loaded => _app != null;

  SongIndex<SongRaw>? _workspace;
  String? _workspaceSig;

  /// Po tożsamości piosenki; `Expando`, żeby usunięte z warsztatu nie
  /// wisiały w pamięci.
  final Expando<_SimilarCache> _cache = Expando();
  final Expando<_AppPart> _appCache = Expando();

  /// Ostatnio widziany stan piosenki (jej sygnatura + sygnatura warsztatu)
  /// — po nim poznajemy, że właśnie coś się zmieniło.
  final Expando<String> _seen = Expando();
  Timer? _settleTimer;
  bool _settling = false;

  /// Czy stan [key] piosenki [song] jest świeży, a więc trzeba jeszcze
  /// poczekać. Każda nowa zmiana odsuwa przeliczenie o [settle].
  bool _stillChanging(SongRaw song, String key){
    if(settle == Duration.zero) return false;
    if(_seen[song] != key){
      _seen[song] = key;
      _settling = true;
      _settleTimer?.cancel();
      _settleTimer = Timer(settle, (){
        _settling = false;
        notifyListeners();
      });
    }
    return _settling;
  }

  @override
  void dispose(){
    _settleTimer?.cancel();
    super.dispose();
  }

  /// Czemu śpiewnik apki się nie wczytał — np. zdublowane id w `all_songs`.
  /// Wtedy nic nie porównujemy, a lista piosenek pokazuje ten błąd.
  String? appError;

  void init() async {
    try {
      _app = await loadAppSongIndex();
    } on HrcpsngDuplicateIdError catch(e){
      appError = 'W all_songs są zdublowane id: ${e.ids.join(', ')}. '
          'Napraw plik — pod każdym id ma być jedna piosenka. Do tego czasu '
          'śpiewnik apki się nie wczyta i nie ma porównań.';
    }
    notifyListeners();
  }

  /// Piosenka z apki po `lclId` (także bez członu `@wykonawca`).
  SongRaw? byId(String id) => _app?.byId(id);

  /// Wszystko, co [SongProfile] czyta — zmiana czegokolwiek z tego
  /// unieważnia cache. Tekst i chwyty w całości: to one decydują.
  static String _signature(SongRaw s) => [
    s.id, s.title, s.hidTitles.join('\x00'), s.authors.join('\x00'),
    s.composers.join('\x00'), s.performers.join('\x00'),
    s.releaseDate?.toIso8601String() ?? '', s.youtubeVideoId ?? '',
    s.tags.join('\x00'), s.chords, s.text,
  ].join('\x01');

  static String _workspaceSignature(List<SongRaw> songs) => songs.map(_signature).join('\x02');

  SongIndex<SongRaw> _workspaceIndex(List<SongRaw> songs, String sig){
    if(_workspace == null || sig != _workspaceSig){
      _workspace = SongIndex(songs);
      _workspaceSig = sig;
    }
    return _workspace!;
  }

  /// Wszystko, co zależy tylko od [song] i śpiewnika apki: odcisk, pierwowzór
  /// w apce i trafienia w apce.
  _AppPart _appPartOf(SongRaw song, String sig, SongIndex<SongRaw> app){
    _AppPart? cached = _appCache[song];
    if(cached != null && cached.signature == sig) return cached;

    SongProfile profile = SongProfile(song);
    final target = correctionTargetLookupOf(song, app);
    SongRaw? original = target?.song;
    _AppPart result = _AppPart(
      signature: sig,
      profile: profile,
      original: target == null? null: OriginalMatch(
        SongMatch(
          song: target.song,
          source: MatchSource.app,
          similarities: compare(profile, SongProfile(target.song)),
        ),
        guessed: target.guessed,
      ),
      matches: app.matches(profile, source: MatchSource.app, exclude: (s) => identical(s, song) || identical(s, original)),
    );
    _appCache[song] = result;
    return result;
  }

  /// Pierwowzór poprawki jako trafienie z dowodami, albo `null`, gdy [song]
  /// niczego nie poprawia albo pierwowzoru nie ma ani w apce, ani w warsztacie.
  OriginalMatch? originalMatchOf(SongRaw song, {List<SongRaw> workspace = const []}) =>
      _compute(song, workspace).original;

  /// Wszystkie podobne piosenki z apki i z warsztatu, od najsilniejszej.
  /// Bez samej [song] i bez jej pierwowzoru — ten idzie osobno,
  /// przez [originalMatchOf].
  List<SongMatch<SongRaw>> matchesFor(SongRaw song, {List<SongRaw> workspace = const []}) =>
      _compute(song, workspace).matches;

  /// Najsilniejsze trafienie — do ikonki na liście i koloru belki.
  MatchLevel? strongestLevelFor(SongRaw song, {List<SongRaw> workspace = const []}) =>
      matchesFor(song, workspace: workspace).firstOrNull?.level;

  _SimilarCache _compute(SongRaw song, List<SongRaw> workspaceSongs){
    SongIndex<SongRaw>? app = _app;
    if(app == null) return const _SimilarCache.empty();

    String workspaceSig = _workspaceSignature(workspaceSongs);
    String sig = _signature(song);
    _SimilarCache? cached = _cache[song];
    if(cached != null && cached.signature == sig && cached.workspaceSignature == workspaceSig)
      return cached;
    // Właśnie piszesz: poprzedni wynik, przeliczenie po chwili ciszy.
    if(cached != null && _stillChanging(song, '$sig\x03$workspaceSig'))
      return cached;

    SongIndex<SongRaw> workspace = _workspaceIndex(workspaceSongs, workspaceSig);

    _AppPart appPart = _appPartOf(song, sig, app);
    SongProfile profile = appPart.profile;

    // Pierwowzór, który [song] **deklaruje**, że poprawia — najpierw w apce,
    // potem w warsztacie (po „zachowaj obie” oryginał leży obok poprawki).
    OriginalMatch? originalMatch = appPart.original;
    if(originalMatch == null)
      if(correctionTargetLookupOf(song, workspace) case final found?)
        originalMatch = OriginalMatch(
          SongMatch(
            song: found.song,
            source: MatchSource.workspace,
            similarities: compare(profile, SongProfile(found.song)),
          ),
          guessed: found.guessed,
        );

    SongRaw? original = originalMatch?.match.song;
    bool skip(SongRaw s) => identical(s, song) || identical(s, original);
    List<SongMatch<SongRaw>> matches = [
      ...appPart.matches,
      ...workspace.matches(profile, source: MatchSource.workspace, exclude: skip),
    ]..sort(compareSongMatches);

    _SimilarCache result = _SimilarCache(sig, _workspaceSig, originalMatch, matches);
    _cache[song] = result;
    return result;
  }

}

/// Pierwowzór poprawki. [guessed]: id pasuje dopiero bez członu
/// `@wykonawca` — ta sama piosenka po zmianie wykonawcy, ale to domysł.
class OriginalMatch{

  final SongMatch<SongRaw> match;
  final bool guessed;

  const OriginalMatch(this.match, {required this.guessed});

  /// Dopisek do podpisu, gdy [guessed].
  static const String guessedText = 'zgadnięta, inny wykonawca';

}

class _AppPart{

  final String signature;
  final SongProfile profile;
  final OriginalMatch? original;
  final List<SongMatch<SongRaw>> matches;

  const _AppPart({required this.signature, required this.profile, required this.original, required this.matches});

}

class _SimilarCache{

  final String? signature;
  final String? workspaceSignature;
  final OriginalMatch? original;
  final List<SongMatch<SongRaw>> matches;

  const _SimilarCache(this.signature, this.workspaceSignature, this.original, this.matches);
  const _SimilarCache.empty(): this(null, null, null, const []);

}

class SearchListProvider extends ChangeNotifier{

  static SearchListProvider of(BuildContext context) => Provider.of<SearchListProvider>(context, listen: false);

  late bool anySearchPhrase;

  late List<SongRaw> currSongList;

  late String searchPhrase;

  List<SongRaw> _allSongs;

  List<SongRaw> get allSongs => _allSongs;

  SearchListProvider(this._allSongs){
    searchPhrase = '';
    anySearchPhrase = false;
    currSongList = [];
  }

  void changeSearchPhrase(String text){
    searchPhrase = text;
    anySearchPhrase = text.length!=0;
    currSongList = searchSongs(allSongs, text);

    notifyListeners();

  }

  void research() => changeSearchPhrase(searchPhrase);

  int get length{
    if(anySearchPhrase)
      return currSongList.length;
    else
      return allSongs.length;
  }

  SongRaw? get(int index){
    if(anySearchPhrase)
      return currSongList[index];
    else
      return allSongs[index];
  }

}