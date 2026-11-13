import 'package:flutter/cupertino.dart';
import 'package:harcapp_core/harcthought/konspekts/konspekt.dart';
import 'package:harcapp_core/values/people/contributor_ref.dart';

class KonspektAuthorData{

  ContributorRef ref;
  final TextEditingController noteController;

  KonspektAuthorData({required this.ref, required this.noteController});

  static KonspektAuthorData from(ContributorRef ref) =>
      KonspektAuthorData(ref: ref, noteController: TextEditingController());

  static KonspektAuthorData fromKonspektAuthor(KonspektAuthor author) =>
      KonspektAuthorData(ref: author.ref, noteController: TextEditingController(text: author.note));

  KonspektAuthor toKonspektAuthor(){
    final note = noteController.text.trim();
    return KonspektAuthor(ref, note: note.isEmpty ? null : note);
  }

}
