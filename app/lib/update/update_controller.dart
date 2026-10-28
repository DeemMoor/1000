import 'package:flutter/widgets.dart';

import '../settings.dart';
import 'update.dart';

/// Tracks whether a newer release exists and drives its installation.
class UpdateController extends ChangeNotifier {
  UpdateController(this.settings);

  final Settings settings;

  static const checkInterval = Duration(days: 1);

  /// A newer release, once found.
  Release? available;

  bool checking = false;

  /// Download progress 0..1 while installing, else null.
  double? progress;

  String? error;

  bool get supported => updatesSupported;

  /// Checks at most once per [checkInterval], if the player allows it.
  Future<void> checkIfDue() async {
    if (!supported || !settings.checkUpdates) return;
    final last = settings.lastUpdateCheck;
    if (last != null && DateTime.now().difference(last) < checkInterval) {
      return;
    }
    await checkNow(quiet: true);
  }

  /// [quiet] keeps network errors out of the UI (startup checks).
  Future<void> checkNow({bool quiet = false}) async {
    if (!supported || checking) return;
    checking = true;
    error = null;
    notifyListeners();
    try {
      available = await checkForUpdate();
      settings.lastUpdateCheck = DateTime.now();
    } catch (e) {
      if (!quiet) error = 'Не удалось проверить обновления: $e';
    } finally {
      checking = false;
      notifyListeners();
    }
  }

  Future<void> installAvailable() async {
    final release = available;
    if (release == null || progress != null) return;
    progress = 0;
    error = null;
    notifyListeners();
    try {
      await install(
        release,
        onProgress: (p) {
          progress = p;
          notifyListeners();
        },
      );
    } catch (e) {
      error = 'Не удалось установить обновление: $e';
    } finally {
      progress = null;
      notifyListeners();
    }
  }

  static UpdateController of(BuildContext context) => maybeOf(context)!;

  /// Null when the app runs without update support (tests, previews).
  static UpdateController? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<UpdateScope>()?.notifier;
}

class UpdateScope extends InheritedNotifier<UpdateController> {
  const UpdateScope({
    super.key,
    required UpdateController controller,
    required super.child,
  }) : super(notifier: controller);
}
