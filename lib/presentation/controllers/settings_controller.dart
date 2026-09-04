import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsController extends ChangeNotifier {
  static const String _vibrationKey = 'etikket_vibration_enabled';
  bool _vibrationEnabled = true;

  SettingsController() {
    loadSettings();
  }

  bool get vibrationEnabled => _vibrationEnabled;

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _vibrationEnabled = prefs.getBool(_vibrationKey) ?? true;
    notifyListeners();
  }

  Future<void> setVibrationEnabled(bool enabled) async {
    _vibrationEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_vibrationKey, enabled);
    notifyListeners();
  }
}
