import 'package:flutter/cupertino.dart';
import 'package:harcapp_core/harcthought/konspekts/konspekt.dart';

class KonspektMaterialData {
  final TextEditingController nameController;
  final TextEditingController? commentController;
  final TextEditingController? additionalPreparationController;
  final TextEditingController? attachmentNameController;
  final TextEditingController? amountController; // plain amount
  final TextEditingController? attendantFactorController; // per participant factor

  KonspektMaterialData()
      : nameController = TextEditingController(),
        commentController = TextEditingController(),
        additionalPreparationController = TextEditingController(),
        attachmentNameController = TextEditingController(),
        amountController = TextEditingController(),
        attendantFactorController = TextEditingController();

  String get name => nameController.text;
  String? get comment => _textOrNull(commentController);
  String? get additionalPreparation => _textOrNull(additionalPreparationController);
  String? get attachmentName => _textOrNull(attachmentNameController);
  int? get amount => _intOrNull(amountController);
  int? get amountAttendantFactor => _intOrNull(attendantFactorController);

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
}
