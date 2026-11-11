import 'package:harcapp_core/comm_classes/sha_pref.dart';
import 'package:harcapp_core/comm_widgets/chord_shifter.dart';
import 'package:harcapp_core/song_book/song_core.dart';
import 'package:harcapp_core/song_book/song_editor/song_raw.dart';
import 'package:harcapp_core/song_book/song_origin.dart';
import 'package:harcapp_core/song_book/song_search.dart';
import 'package:harcapp_core/values/people/contributor_ref.dart';

String _shaPrefChordShift(String songId) => 'SHA_PREF_SONG_BOOK_CHORD_SHIFT_$songId';

/// Piosenka śpiewnika na stronie: tylko do czytania, za to z transpozycją
/// chwytów, zapamiętywaną w przeglądarce osobno dla każdej piosenki.
///
/// Tekst i chwyty bazowe liczone raz — [SongRaw] składa je z części przy
/// każdym odczycie, a szablon piosenki czyta je wielokrotnie.
class SongBookSong extends SongCore{

  final SongRaw raw;

  @override
  final String text;
  final String baseChords;
  @override
  final bool hasChords;

  /// Pola do szukania, liczone raz na całe życie strony.
  late final SongSearchEntry searchEntry = SongSearchEntry(this);

  SongBookSong(this.raw):
        text = raw.text,
        baseChords = raw.chords,
        hasChords = raw.hasChords;

  /// Fragment adresu: id bez przedrostka `o!_`.
  String get slug => id.startsWith('o!_') ? id.substring(3) : id;

  int get chordShift => ShaPref.getInt(_shaPrefChordShift(id), 0);
  set chordShift(int value){
    value %= 12;
    _chords = null;
    if(value == 0) ShaPref.remove(_shaPrefChordShift(id));
    else ShaPref.setInt(_shaPrefChordShift(id), value);
  }

  void shiftChordsUp() => chordShift = ChordShifter.shiftToneUp(chordShift);
  void shiftChordsDown() => chordShift = ChordShifter.shiftToneDown(chordShift);

  String? _chords;
  @override
  String get chords => _chords ??= chordShift == 0 ? baseChords : ChordShifter.run(baseChords, chordShift);

  @override
  String get id => raw.id;
  @override
  String get title => raw.title;
  @override
  List<String> get hidTitles => raw.hidTitles;
  @override
  List<SongOrigin> get origins => raw.origins;
  @override
  List<String> get authors => raw.authors;
  @override
  List<String> get composers => raw.composers;
  @override
  List<String> get performers => raw.performers;
  @override
  DateTime? get releaseDate => raw.releaseDate;
  @override
  bool get showRelDateMonth => raw.showRelDateMonth;
  @override
  bool get showRelDateDay => raw.showRelDateDay;
  @override
  List<ContributorRef> get contribRefs => raw.contribRefs;
  @override
  ContributorData? get contributorData => raw.contributorData;
  @override
  String? get youtubeVideoId => raw.youtubeVideoId;
  @override
  bool get isOwn => false;
  @override
  List<String> get tags => raw.tags;
  @override
  SongRate? get rate => null;
  @override
  String get code => raw.code;

}
