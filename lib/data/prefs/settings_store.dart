import 'package:shared_preferences/shared_preferences.dart';

/// Plain user preferences. Nothing sensitive lives here — see [SecurityStore].
class SettingsStore {
  SettingsStore(this._prefs);

  final SharedPreferences _prefs;

  static const _kUserName = 'user_name';
  static const _kHideAmounts = 'hide_amounts';
  static const _kBudgetAlerts = 'budget_alerts';
  static const _kOnboarded = 'onboarded';

  static Future<SettingsStore> create() async =>
      SettingsStore(await SharedPreferences.getInstance());

  String get userName => _prefs.getString(_kUserName) ?? 'Faizan';
  Future<void> setUserName(String v) => _prefs.setString(_kUserName, v);

  /// Blurs every amount on screen — handy when someone is looking over your shoulder.
  bool get hideAmounts => _prefs.getBool(_kHideAmounts) ?? false;
  Future<void> setHideAmounts(bool v) => _prefs.setBool(_kHideAmounts, v);

  bool get budgetAlerts => _prefs.getBool(_kBudgetAlerts) ?? true;
  Future<void> setBudgetAlerts(bool v) => _prefs.setBool(_kBudgetAlerts, v);

  bool get onboarded => _prefs.getBool(_kOnboarded) ?? false;
  Future<void> setOnboarded(bool v) => _prefs.setBool(_kOnboarded, v);
}
