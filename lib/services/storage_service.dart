import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const _keyApiKey = 'mimo_api_key';
  static const _keyServerEnabled = 'server_enabled';
  static const _keyServerPort = 'server_port';

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  String get apiKey => _prefs.getString(_keyApiKey) ?? '';
  set apiKey(String value) => _prefs.setString(_keyApiKey, value);

  bool get serverEnabled => _prefs.getBool(_keyServerEnabled) ?? false;
  set serverEnabled(bool value) => _prefs.setBool(_keyServerEnabled, value);

  int get serverPort => _prefs.getInt(_keyServerPort) ?? 8899;
  set serverPort(int value) => _prefs.setInt(_keyServerPort, value);
}
