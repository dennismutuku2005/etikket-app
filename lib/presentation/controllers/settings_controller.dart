import 'package:flutter/foundation.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';

class SettingsController extends ChangeNotifier {
  final ApiClient apiClient;

  String _currentBaseUrl = ApiEndpoints.defaultBaseUrl;
  bool _isTestingConnection = false;
  bool? _connectionSuccess;
  String? _connectionMessage;
  bool _vibrationEnabled = true;

  SettingsController({required this.apiClient}) {
    loadSettings();
  }

  String get currentBaseUrl => _currentBaseUrl;
  bool get isTestingConnection => _isTestingConnection;
  bool? get connectionSuccess => _connectionSuccess;
  String? get connectionMessage => _connectionMessage;
  bool get vibrationEnabled => _vibrationEnabled;

  Future<void> loadSettings() async {
    _currentBaseUrl = await apiClient.getBaseUrl();
    notifyListeners();
  }

  Future<void> updateBaseUrl(String newUrl) async {
    await apiClient.setBaseUrl(newUrl);
    _currentBaseUrl = await apiClient.getBaseUrl();
    _connectionSuccess = null;
    _connectionMessage = null;
    notifyListeners();
  }

  Future<void> setVibrationEnabled(bool enabled) async {
    _vibrationEnabled = enabled;
    notifyListeners();
  }

  Future<bool> testConnection() async {
    _isTestingConnection = true;
    _connectionSuccess = null;
    _connectionMessage = null;
    notifyListeners();

    try {
      final res = await apiClient.get(ApiEndpoints.health);
      _connectionSuccess = true;
      _connectionMessage = res is Map && res.containsKey('status')
          ? 'Connected: ${res['status']}'
          : 'Server connection verified successfully.';
      _isTestingConnection = false;
      notifyListeners();
      return true;
    } catch (e) {
      _connectionSuccess = false;
      _connectionMessage = 'Connection failed: $e';
      _isTestingConnection = false;
      notifyListeners();
      return false;
    }
  }
}
