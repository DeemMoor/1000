import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thousand_engine/thousand_engine.dart';

enum CardStyle {
  atlas('Атласная'),
  english('Английская'),
  simple('Простая');

  const CardStyle(this.title);

  final String title;

  /// Asset folder with SVG faces, or null for cards drawn in code.
  String? get assetDir => this == simple ? null : 'assets/cards/$name';
}

/// User preferences, persisted between launches.
class Settings extends ChangeNotifier {
  Settings._(this._prefs)
    : _cardStyle =
          CardStyle.values.asNameMap()[_prefs?.getString(_kCards)] ??
          CardStyle.atlas,
      _aceMarriage = _prefs?.getBool(_kAceMarriage) ?? false;

  /// In-memory settings with defaults (tests, previews).
  Settings.defaults() : this._(null);

  static Future<Settings> load() async =>
      Settings._(await SharedPreferences.getInstance());

  static const _kCards = 'cardStyle';
  static const _kAceMarriage = 'aceMarriage';

  final SharedPreferences? _prefs;

  CardStyle get cardStyle => _cardStyle;
  CardStyle _cardStyle;
  set cardStyle(CardStyle value) {
    _cardStyle = value;
    _prefs?.setString(_kCards, value.name);
    notifyListeners();
  }

  bool get aceMarriage => _aceMarriage;
  bool _aceMarriage;
  set aceMarriage(bool value) {
    _aceMarriage = value;
    _prefs?.setBool(_kAceMarriage, value);
    notifyListeners();
  }

  /// Rules for a new game.
  GameRules get rules => GameRules(aceMarriage: aceMarriage);

  static Settings of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SettingsScope>()!.notifier!;
}

class SettingsScope extends InheritedNotifier<Settings> {
  const SettingsScope({
    super.key,
    required Settings settings,
    required super.child,
  }) : super(notifier: settings);
}
