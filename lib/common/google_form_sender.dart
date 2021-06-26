
import 'package:dio/dio.dart';

class GoogleFormSender{

  static const String SONG_ERROR_FORM_URL = 'https://docs.google.com/forms/d/e/1FAIpQLSeYxKO5KOmU1iBjqzQO6X8yHbsXC90v3sE72K8ODs8xQylzYA/formResponse';
  static const String GEN_ERROR_FORM_URL = "https://docs.google.com/forms/d/e/1FAIpQLScodk1gKrMhhr3aGh-OYYdGS9LHtVNXH3-6SCbQ7yl0Q7yezw/formResponse";
  static const String USAGE_STATS_FORM_URL = "https://docs.google.com/forms/d/e/1FAIpQLSdV1tuPjCU5Noo9Qjt67LoVRG2KKA75hXBSapHw7UHtGUtBtQ/formResponse";


  static const String SEPARATOR = '~';

  String url;
  Function? beforeSubmit;
  Function(Response)? afterSubmit;

  Map<String, String>? body;

  GoogleFormSender(this.url, {this.beforeSubmit, this.afterSubmit, this.body}){
    if(body == null) body = {};
  }

  addTextResponse(String entryId, String text){
    body![entryId] = text;
  }

  Future<void> submit({saveLocalPath}) async {
    if(beforeSubmit!=null) beforeSubmit!();

    FormData formData = FormData.fromMap(body!);
    Response response = await Dio().post(
      url,
      data: formData,
    );

    if(afterSubmit!=null) afterSubmit!(response);
  }


}