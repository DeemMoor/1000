import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'release.dart';

const _latest = 'https://api.github.com/repos/DeemMoor/1000/releases/latest';
const _timeout = Duration(seconds: 20);

/// Whether this platform can check for updates at all.
const updatesSupported = true;

Future<Map<String, String>> _headers() async => {
  'Accept': 'application/vnd.github+json',
  // GitHub's API rejects requests without a User-Agent.
  'User-Agent': 'Thousand/${(await PackageInfo.fromPlatform()).version}',
};

/// The latest release if it is newer than this build, otherwise null.
Future<Release?> checkForUpdate() async {
  final res = await http
      .get(Uri.parse(_latest), headers: await _headers())
      .timeout(_timeout);
  // No release published yet.
  if (res.statusCode == 404) return null;
  if (res.statusCode != 200) {
    throw HttpException('GitHub answered ${res.statusCode}');
  }
  final json = jsonDecode(res.body) as Map<String, dynamic>;
  final version = (json['tag_name'] as String).replaceFirst(RegExp('^v'), '');
  final current = (await PackageInfo.fromPlatform()).version;
  if (!isNewer(version, current)) return null;

  final assets = (json['assets'] as List).cast<Map<String, dynamic>>();
  String? asset(bool Function(String name) match) => assets
      .where((a) => match(a['name'] as String))
      .map((a) => a['browser_download_url'] as String)
      .firstOrNull;
  return Release(
    version: version,
    notes: json['body'] as String? ?? '',
    page: json['html_url'] as String,
    installer: Platform.isWindows
        ? asset((n) => n.endsWith('-windows-setup.exe'))
        : Platform.isAndroid
        ? asset((n) => n.endsWith('.apk'))
        : null,
    checksums: asset((n) => n == 'SHA256SUMS.txt'),
  );
}

/// Windows: download, verify against SHA256SUMS.txt, run the installer
/// silently and quit; the installer starts the new version. Android: hand
/// the APK to the system. Elsewhere: open the release page.
Future<void> install(
  Release release, {
  void Function(double)? onProgress,
}) async {
  final url = release.installer;
  if (url == null || Platform.isAndroid) {
    await launchUrl(
      Uri.parse(url ?? release.page),
      mode: LaunchMode.externalApplication,
    );
    return;
  }

  final name = url.split('/').last;
  final listing = release.checksums;
  if (listing == null) throw StateError('the release has no SHA256SUMS.txt');
  final expected = expectedHash(await http.read(Uri.parse(listing)), name);
  if (expected == null) {
    throw StateError('$name is not listed in SHA256SUMS.txt');
  }

  final file = File(
    '${Directory.systemTemp.path}${Platform.pathSeparator}$name',
  );
  final client = http.Client();
  try {
    final response = await client.send(http.Request('GET', Uri.parse(url)));
    if (response.statusCode != 200) {
      throw HttpException('download failed: ${response.statusCode}');
    }
    final total = response.contentLength ?? 0;
    var received = 0;
    final sink = file.openWrite();
    await for (final chunk in response.stream) {
      sink.add(chunk);
      received += chunk.length;
      if (total > 0) onProgress?.call(received / total);
    }
    await sink.close();
  } finally {
    client.close();
  }

  final actual = (await sha256.bind(file.openRead()).first).toString();
  if (actual != expected) {
    await file.delete();
    throw StateError('checksum mismatch, the file is damaged or replaced');
  }
  await Process.start(file.path, [
    '/VERYSILENT',
    '/SUPPRESSMSGBOXES',
    '/NORESTART',
  ], mode: ProcessStartMode.detached);
  exit(0);
}
