import 'package:harcapp_core/values/people/contributor_ref.dart';
import 'package:harcapp_core/song_book/song_editor/song_raw.dart';
import 'package:harcapp_core/song_book/song_element.dart';
import 'package:harcapp_core/values/people/models.dart';
import 'package:harcapp_web/songs/old/song_basic_data.dart';
import 'package:harcapp_web/songs/old/song_element_old.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

SongRaw parseOldCode(String id, String code){
  SongBasicData1 basicData = SongBasicData1.parse(id, code);

  List<String> parts = code.split('<');

  SongElement? refrenElement;
  bool hasRefren = parts[1].isNotEmpty;
  if (hasRefren) {
    SongElementOld refrenElementOld = SongElementOld.decodeOld(parts[1]);
    refrenElement = SongElement(refrenElementOld.getText(), refrenElementOld.getChords(), true);
  }

  String? firstElementChords;
  List<SongElement?> songElements = [];
  for(int i=2; i<parts.length; i++)
  {
    if (parts[i].isEmpty) {
      songElements.add(refrenElement);
      continue;
    }

    List<String> zwrotkaElements = parts[i].split('>');
    firstElementChords ??= zwrotkaElements[0];

    SongElementOld songElementOld = SongElementOld.decodeOld(parts[i], firstElementChords: firstElementChords);
    songElements.add(SongElement(songElementOld.getText(), songElementOld.getChords(), false));
  }

  return SongRaw(
    id: id,
    title: basicData.title,
    hidTitles: [],
    authors: [basicData.author],
    composers: [],
    performers: [basicData.performer],
    contribRefs: [ContributorRef(person: Person(name: basicData.moderator), emailRef: null, userKeyRef: null)],
    contributorData: null,
    youtubeVideoId: basicData.youtubeLink==null?
      null:
      YoutubePlayer.convertUrlToId(basicData.youtubeLink!),

    tags: basicData.tags,

    releaseDate: null,
    showRelDateMonth: false,
    showRelDateDay: false,

    hasRefren: hasRefren,
    refrenPart: refrenElement == null? SongPart.empty():SongPart.from(refrenElement),

    songParts: songElements.map((e) => SongPart.from(e!)).toList(),
  );
}
