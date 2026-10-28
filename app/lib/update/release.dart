/// A published release found on GitHub.
class Release {
  const Release({
    required this.version,
    required this.notes,
    required this.page,
    this.installer,
    this.checksums,
  });

  final String version;

  /// Markdown from the release description, i.e. this version's CHANGELOG
  /// section.
  final String notes;

  /// The release page on GitHub.
  final String page;

  /// The file this platform can install itself, if any.
  final String? installer;

  /// URL of SHA256SUMS.txt from the same release.
  final String? checksums;
}

/// Whether [candidate] is a later version than [current] (major.minor.patch;
/// a leading "v" and any build suffix are ignored).
bool isNewer(String candidate, String current) {
  List<int> parts(String v) => v
      .replaceFirst(RegExp('^v'), '')
      .split(RegExp(r'[.+-]'))
      .take(3)
      .map((p) => int.tryParse(p) ?? 0)
      .toList();
  final a = parts(candidate);
  final b = parts(current);
  for (var i = 0; i < 3; i++) {
    final x = i < a.length ? a[i] : 0;
    final y = i < b.length ? b[i] : 0;
    if (x != y) return x > y;
  }
  return false;
}

/// The hash listed for [file] in a sha256sum-style listing.
String? expectedHash(String listing, String file) => listing
    .split('\n')
    .map((line) => line.trim().split(RegExp(r'\s+')))
    .where((p) => p.length == 2 && p[1].replaceFirst('*', '') == file)
    .map((p) => p[0].toLowerCase())
    .firstOrNull;
