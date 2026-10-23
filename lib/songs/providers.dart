import 'dart:async';

import 'package:flutter/material.dart';
import 'package:harcapp_core/comm_classes/sha_pref.dart';
import 'package:harcapp_core/comm_classes/text_utils.dart';
import 'package:harcapp_core/song_book/import_hrcpsng.dart';
import 'package:harcapp_core/song_book/similarity/similarity.dart';
import 'package:harcapp_core/song_book/song_editor/providers.dart';
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

/// Wszystko, co czyta `SongProfile` — po tym poznajemy, że piosenka
/// zmieniła się naprawdę, a nie tylko ktoś coś powiadomił.
String songContentSignature(SongRaw s) => [
  s.id, s.title, s.hidTitles.join('\x00'), s.origins.map((o) => o.text).join('\x00'),
  s.authors.join('\x00'), s.composers.join('\x00'), s.performers.join('\x00'),
  s.releaseDate?.toIso8601String() ?? '', s.youtubeVideoId ?? '',
  s.tags.join('\x00'), s.chords, s.text,
].join('\x01');

/// Warsztat — i **jedyne źródło wiadomości o tym, że coś się w nim
/// zmieniło**. Każda zmiana składu i każda zmiana treści piosenki podbija
/// [revision]; zmiana treści dodatkowo [revisionOf] tej jednej piosenki.
/// Kto liczy coś z warsztatu (indeks podobnych), porównuje numery zamiast
/// czytać teksty — i przelicza tylko piosenki, które się zmieniły.
///
/// Zmiany treści przychodzą dwiema drogami:
/// * z edytora — [followEditor] patrzy na [CurrentItemProvider], przez który
///   idzie każda edycja w edytorze;
/// * spoza edytora (id, kod piosenki, oficjalna/niejawna) — przez [set]
///   albo [edited].
class AllSongsProvider extends ChangeNotifier{

  static AllSongsProvider of(BuildContext context) => Provider.of<AllSongsProvider>(context, listen: false);

  List<SongRaw> _songs;
  Map<SongRaw, bool> _confMap = {};

  int _revision = 0;
  final Expando<int> _songRevisions = Expando();

  /// Rośnie przy każdej zmianie warsztatu: składu albo treści którejś piosenki.
  int get revision => _revision;

  /// Rośnie przy każdej zmianie treści tej jednej piosenki.
  int revisionOf(SongRaw song) => _songRevisions[song] ?? 0;

  int get length => _songs.length;

  List<SongRaw> get songs => _songs;

  AllSongsProvider(List<SongRaw> songs): _songs = songs, _confMap = {for (SongRaw song in songs) song: song.isConfid};

  /// Skład się zmienił. Zapis do pamięci po turze ([_cacheSongs]).
  void _changed(){
    _revision++;
    _cacheSongs();
    notifyListeners();
  }

  /// Treść [song] zmieniła się w miejscu. Bez zapisu do pamięci — tak jak
  /// dotąd przy pisaniu w edytorze: przy każdym znaku to byłby cały śpiewnik.
  void edited(SongRaw song){
    _songRevisions[song] = revisionOf(song) + 1;
    _editorSeen[song] = songContentSignature(song);
    _revision++;
    notifyListeners();
  }

  void clear(){
    _songs.clear();
    _confMap.clear();
    _changed();
  }

  void addOff(SongRaw song){
    _songs.add(song);
    _confMap[song] = false;
    _changed();
  }

  void addConf(SongRaw song){
    _songs.add(song);
    _confMap[song] = true;
    _changed();
  }

  void remove(SongRaw? song){
    // `removeWhere`, a nie `remove`: gdyby ten sam obiekt trafił na listę
    // więcej niż raz, `remove` zdjęłoby tylko pierwsze wystąpienie i piosenka
    // zostałaby na liście (z fałszywym alarmem o powtórzonej nazwie).
    _songs.removeWhere((s) => identical(s, song));
    _confMap.remove(song);
    _changed();
  }

  void removeAll(List<SongRaw> songs){
    for(SongRaw song in songs){
      _songs.removeWhere((s) => identical(s, song));
      _confMap.remove(song);
    }
    _changed();
  }

  void addAll(List<SongRaw> songs, Map<SongRaw, bool> confMap){
    _songs.addAll(songs);
    _confMap.addAll(confMap);
    _changed();
  }

  /// Ile piosenek faktycznie wchodzi do śpiewnika. Przy przeglądzie
  /// piosenkomatem resztę zgasiłeś przełącznikiem; poza przeglądem
  /// równe [length].
  int get goingInCount =>
      _songs.where((s) => s.piosenkomatData?.rejected != true).length;

  bool? isConf(SongRaw song) => _confMap[song];

  /// [song] zmieniła się w miejscu (kod piosenki, przełącznik oficjalna/
  /// niejawna) i należy do [isConf]. Z zapisem do pamięci — to pojedyncza,
  /// zamknięta czynność, a nie pisanie.
  void set(SongRaw song, bool isConf){
    _confMap[song] = isConf;
    _songRevisions[song] = revisionOf(song) + 1;
    _editorSeen[song] = songContentSignature(song);
    _changed();
  }

  CurrentItemProvider? _editor;

  /// Ostatnio widziana treść piosenki w edytorze — po niej odróżniamy
  /// edycję od samego powiadomienia (przełączenie piosenki, odświeżenie
  /// widoku), które niczego nie zmienia.
  final Expando<String> _editorSeen = Expando();

  /// Edytor zmienia piosenkę w miejscu i daje znać tylko przez
  /// [CurrentItemProvider]. Tu tłumaczymy to na [edited] — wyłącznie wtedy,
  /// gdy treść naprawdę się zmieniła. Przełączenie na inną piosenkę to nie
  /// edycja i niczego nie unieważnia.
  void followEditor(CurrentItemProvider editor){
    _editor?.removeListener(_onEditorChanged);
    _editor = editor;
    _editorSeen[editor.song] = songContentSignature(editor.song);
    editor.addListener(_onEditorChanged);
  }

  void _onEditorChanged(){
    SongRaw song = _editor!.song;
    String signature = songContentSignature(song);
    String? seen = _editorSeen[song];
    _editorSeen[song] = signature;
    if(seen != null && seen != signature) edited(song);
  }

  Timer? _cacheTimer;

  /// Zapis roboczego stanu warsztatu — odłożony do końca tury. Serializacja
  /// całego śpiewnika nie jest darmowa (1,3 MB przy 600 piosenkach), a jedna
  /// czynność potrafi ruszyć listę kilka razy (import zdejmuje podmieniane
  /// i dokłada nowe). Po turze stan jest już ustalony i wystarczy jeden zapis.
  void _cacheSongs(){
    _cacheTimer?.cancel();
    _cacheTimer = Timer(Duration.zero, writeCacheNow);
  }

  /// Zapis bez czekania na koniec tury — dla tego, kto sam wie, że właśnie
  /// skończył (import robi to pod oknem postępu, żeby nie zacięło się już
  /// po jego zamknięciu).
  void writeCacheNow(){
    _cacheTimer?.cancel();
    _cacheTimer = null;
    ShaPref.setString(SHA_PREF_LAST_EDITED_SONGS, convertAllToCode(allowDuplicateIds: true));
  }

  @override
  void dispose(){
    _cacheTimer?.cancel();
    _editor?.removeListener(_onEditorChanged);
    super.dispose();
  }

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
      try {
        Map<String, List<SongRaw>> decodedSongs = decodeSongs(code);

        Set<SongRaw> seen = Set.identity();
        List<SongRaw> result = [];
        for (List<SongRaw> songs in decodedSongs.values)
          for (SongRaw song in songs)
            if(seen.add(song)) result.add(song);

        return result;
      } catch(e){
        // Cache z warsztatu w innej wersji (np. ślad piosenkomatu sprzed
        // zmiany kluczy). Nie udajemy, że go rozumiemy: zaczynamy pusto,
        // a przegląd wraca z pliku, który i tak jest źródłem prawdy.
        debugPrint('Nie udało się wczytać roboczego stanu warsztatu: $e');
        return [];
      }
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

  /// Warsztat, z którym porównujemy. O jego zmianach mówi nam on sam
  /// ([AllSongsProvider.revision]) — nie czytamy jego tekstów, żeby je wykryć.
  final AllSongsProvider workspace;

  /// Ile ciszy po ostatniej zmianie, zanim policzymy od nowa.
  final Duration settle;

  /// Zmiana warsztatu to możliwa zmiana wyników — dajemy znać dalej, więc
  /// słuchającym wystarcza ten provider, bez osobnego słuchania warsztatu.
  SimilarSongProvider({required this.workspace, this.settle = const Duration(milliseconds: 300)}){
    workspace.addListener(notifyListeners);
  }

  /// Do testów: gotowy indeks zamiast ładowania z assetów; domyślnie bez
  /// czekania na ciszę, żeby każda zmiana od razu dawała nowy wynik.
  @visibleForTesting
  SimilarSongProvider.withIndex(SongIndex<SongRaw> app, {AllSongsProvider? workspace, this.settle = Duration.zero}):
        _app = app,
        workspace = workspace ?? AllSongsProvider([]){
    this.workspace.addListener(notifyListeners);
  }

  /// Czy śpiewnik apki już jest. Przed tym nic nie porównujemy — lepiej
  /// przez chwilę nie ostrzegać, niż ostrzegać „nic nie znaleziono”.
  bool get loaded => _app != null;

  SongIndex<SongRaw>? _workspaceIndex;
  int? _workspaceIndexRevision;

  /// Odciski piosenek z warsztatu, każdy z numerem wersji piosenki, z której
  /// powstał. To one są prawie całym kosztem indeksu — trzymamy je między
  /// odbudowami, więc po zmianie jednej piosenki liczy się jeden odcisk.
  final Expando<(int, SongProfile)> _profiles = Expando();

  /// Po tożsamości piosenki; `Expando`, żeby usunięte z warsztatu nie
  /// wisiały w pamięci.
  final Expando<_SimilarCache> _cache = Expando();
  final Expando<_AppPart> _appCache = Expando();

  /// Ostatnio widziany stan piosenki (jej sygnatura + wersja warsztatu)
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
    workspace.removeListener(notifyListeners);
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

  /// Indeks warsztatu w jego obecnej wersji. Odbudowa tylko po zmianie
  /// [AllSongsProvider.revision], a i wtedy liczą się odciski wyłącznie
  /// tych piosenek, które się zmieniły — reszta przychodzi z [_profiles].
  ///
  /// Na kopii listy: warsztat zmienia swoją w miejscu, a numery w indeksie
  /// muszą wskazywać te piosenki, z których indeks powstał.
  SongIndex<SongRaw> _currentWorkspaceIndex(){
    if(_workspaceIndex == null || _workspaceIndexRevision != workspace.revision){
      _workspaceIndex = SongIndex(List.of(workspace.songs), profileOf: _profileOf);
      _workspaceIndexRevision = workspace.revision;
    }
    return _workspaceIndex!;
  }

  /// Odcisk [song] w indeksie warsztatu w jego obecnej wersji.
  @visibleForTesting
  SongProfile workspaceProfileOf(SongRaw song){
    SongIndex<SongRaw> index = _currentWorkspaceIndex();
    return index.profiles[index.songs.indexWhere((s) => identical(s, song))];
  }

  SongProfile _profileOf(SongRaw song){
    int revision = workspace.revisionOf(song);
    if(_profiles[song] case (final cachedRevision, final profile) when cachedRevision == revision)
      return profile;

    SongProfile profile = SongProfile(song);
    _profiles[song] = (revision, profile);
    return profile;
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
  OriginalMatch? originalMatchOf(SongRaw song) => _compute(song).original;

  /// Wszystkie podobne piosenki z apki i z warsztatu, od najsilniejszej.
  /// Bez samej [song] i bez jej pierwowzoru — ten idzie osobno,
  /// przez [originalMatchOf].
  List<SongMatch<SongRaw>> matchesFor(SongRaw song) => _compute(song).matches;

  /// Najsilniejsze trafienie — do ikonki na liście i koloru belki.
  MatchLevel? strongestLevelFor(SongRaw song) => matchesFor(song).firstOrNull?.level;

  _SimilarCache _compute(SongRaw song){
    SongIndex<SongRaw>? app = _app;
    if(app == null) return const _SimilarCache.empty();

    // Sygnatura tylko pytanej piosenki — ona bywa spoza warsztatu (piosenka
    // z maila), więc jej wersji warsztat nie zna. Jedna piosenka to tanio.
    int workspaceRevision = workspace.revision;
    String sig = songContentSignature(song);
    _SimilarCache? cached = _cache[song];
    if(cached != null && cached.signature == sig && cached.workspaceRevision == workspaceRevision)
      return cached;
    // Właśnie piszesz: poprzedni wynik, przeliczenie po chwili ciszy.
    if(cached != null && _stillChanging(song, '$sig\x03$workspaceRevision'))
      return cached;

    SongIndex<SongRaw> workspaceIndex = _currentWorkspaceIndex();

    _AppPart appPart = _appPartOf(song, sig, app);
    SongProfile profile = appPart.profile;

    // Pierwowzór, który [song] **deklaruje**, że poprawia — najpierw w apce,
    // potem w warsztacie (po „zachowaj obie” oryginał leży obok poprawki).
    OriginalMatch? originalMatch = appPart.original;
    if(originalMatch == null)
      if(correctionTargetLookupOf(song, workspaceIndex) case final found?)
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
      ...workspaceIndex.matches(profile, source: MatchSource.workspace, exclude: skip),
    ]..sort(compareSongMatches);

    _SimilarCache result = _SimilarCache(sig, workspaceRevision, originalMatch, matches);
    _cache[song] = result;
    return result;
  }

}

/// Pierwowzór poprawki. [guessed]: to domysł — piosenkomat sam zgadł, którą
/// piosenkę autor poprawiał, albo id pasuje dopiero bez członu `@wykonawca`.
class OriginalMatch{

  final SongMatch<SongRaw> match;
  final bool guessed;

  const OriginalMatch(this.match, {required this.guessed});

  /// Dopisek do podpisu, gdy [guessed]. Bez powodu — bywają dwa, a „inny
  /// wykonawca” przy celu zgadniętym przez piosenkomat kłamał.
  static const String guessedText = 'zgadnięta';

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
  final int? workspaceRevision;
  final OriginalMatch? original;
  final List<SongMatch<SongRaw>> matches;

  const _SimilarCache(this.signature, this.workspaceRevision, this.original, this.matches);
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