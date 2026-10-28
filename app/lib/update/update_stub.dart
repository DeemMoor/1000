import 'release.dart';

/// Whether this platform can check for updates at all.
const updatesSupported = false;

Future<Release?> checkForUpdate() async => null;

Future<void> install(
  Release release, {
  void Function(double)? onProgress,
}) async {}
