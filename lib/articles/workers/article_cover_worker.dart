import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:harcapp_core/comm_classes/dio.dart';
import 'package:isolate_manager/isolate_manager.dart';

/// Worker that takes a ZHR article page URL and returns the og:image URL
/// extracted from its HTML. The actual image bytes are loaded by the browser
/// via an `<img>` tag in `WebCoverImage`, which works cross-origin without
/// CORS (unlike fetch/XHR which the ZHR servers don't support).
@pragma('vm:entry-point')
@isolateManagerCustomWorker
void articleCoverWorker(dynamic params) {
  IsolateManagerFunction.customFunction<Map, String>(
    params,
    onEvent: (controller, message) async {
      try {
        final args = jsonDecode(message) as Map;
        final link = args['link'] as String;

        final htmlResp = await defDio.get(
          webCorsProxy(link),
          options: Options(responseType: ResponseType.plain),
        );
        final html = htmlResp.data as String;
        final marker = '<meta property="og:image" content="';
        final idx = html.indexOf(marker);
        if (idx < 0) {
          return {'success': false, 'debug': 'no og:image in html'};
        }
        var imageLink = html.substring(idx + marker.length);
        final endIdx = imageLink.indexOf('"');
        if (endIdx < 0) {
          return {'success': false, 'debug': 'malformed og:image meta'};
        }
        imageLink = imageLink.substring(0, endIdx);
        return {'success': true, 'imageUrl': imageLink};
      } catch (e, st) {
        return {
          'success': false,
          'debug':
              '${e.runtimeType}: $e | ${st.toString().split("\n").take(3).join(" || ")}',
        };
      }
    },
  );
}
