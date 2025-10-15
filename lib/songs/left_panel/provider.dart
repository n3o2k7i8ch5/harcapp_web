import 'package:flutter/material.dart';
import 'package:harcapp_core/comm_classes/text_utils.dart';
import 'package:harcapp_core/song_book/song_editor/song_raw.dart';
import 'package:provider/provider.dart';


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
    currSongList = [];

    String simplifiedText = searchableString(text);
    for(SongRaw? song in allSongs){
      if(searchableString(song!.title).contains(simplifiedText))
        currSongList.add(song);
    }

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