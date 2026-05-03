import 'dart:async';
import 'dart:convert';
import 'dart:io';

const _defaultTimeout = Duration(seconds: 30);

Future<String?> curlGet(String url, {Duration timeout = _defaultTimeout}) async {
  final result = await Process.run('curl', [
    '-sL',
    '--max-time', timeout.inSeconds.toString(),
    '--fail-with-body',
    url,
  ], stdoutEncoding: utf8, stderrEncoding: utf8);
  if (result.exitCode != 0) {
    stderr.writeln('curl failed (${result.exitCode}) for $url: ${result.stderr}');
    return null;
  }
  return result.stdout as String;
}
