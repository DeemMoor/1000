/// Update check and install; a no-op on the web, where a reload is enough.
library;

export 'release.dart';
export 'update_stub.dart' if (dart.library.io) 'update_io.dart';
