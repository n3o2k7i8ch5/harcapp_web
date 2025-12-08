import 'package:flutter/cupertino.dart';
import 'package:harcapp_core/harcthought/konspekts/konspekt.dart';

class KonspektMaterialData extends BaseKonspektMaterial{
  final TextEditingController nameController;
  final TextEditingController? commentController;
  final TextEditingController? additionalPreparationController;
  final TextEditingController? attachmentNameController;
  final TextEditingController? amountController; // plain amount
  final TextEditingController? amountAttendantFactorController; // per participant factor

  const KonspektMaterialData({
    required this.nameController,
    this.commentController,
    this.additionalPreparationController,
    this.attachmentNameController,
    this.amountController,
    this.amountAttendantFactorController,
  });
  
  static KonspektMaterialData empty() => KonspektMaterialData(
      nameController: TextEditingController(),
      commentController: TextEditingController(),
      additionalPreparationController: TextEditingController(),
      attachmentNameController: TextEditingController(),
      amountController: TextEditingController(),
      amountAttendantFactorController: TextEditingController()
  );

  String get name => nameController.text;
  String? get comment => _textOrNull(commentController);
  String? get additionalPreparation => _textOrNull(additionalPreparationController);
  String? get attachmentName => _textOrNull(attachmentNameController);
  int? get amount => _intOrNull(amountController);
  int? get amountAttendantFactor => _intOrNull(amountAttendantFactorController);

  KonspektMaterial toKonspektMaterial() => KonspektMaterial(
    amount: amount,
    amountAttendantFactor: amountAttendantFactor,
    name: name,
    comment: comment,
    attachmentName: attachmentName,
    additionalPreparation: additionalPreparation,
  );

  static String? _textOrNull(TextEditingController? c){
    final t = c?.text.trim() ?? '';
    return t.isEmpty ? null : t;
    }

  static int? _intOrNull(TextEditingController? c){
    try{
      final t = c?.text.trim() ?? '';
      if(t.isEmpty) return null;
      return int.parse(t);
    }catch(_){
      return null;
    }
  }


  static KonspektMaterialData fromJsonMap(Map<String, dynamic> map) => KonspektMaterialData(
    nameController: TextEditingController(text: map['name']),
    commentController: TextEditingController(text: map['comment']),
    additionalPreparationController: TextEditingController(text: map['additionalPreparation']),
    attachmentNameController: TextEditingController(text: map['attachmentName']),

    // Jeśli w JSON-ie amount/amountAttendantFactor są null,
    // nie chcemy mieć dosłownego tekstu 'null' w polu liczbowym.
    // Zamiast tego wstawiamy pusty string, a logika UI zadba
    // o domyślną wartość (np. 1) tam, gdzie to potrzebne.
    amountController: TextEditingController(
      text: map['amount'] == null ? '' : map['amount'].toString(),
    ),
    amountAttendantFactorController: TextEditingController(
      text: map['amountAttendantFactor'] == null
          ? ''
          : map['amountAttendantFactor'].toString(),
    ),
  );

}
