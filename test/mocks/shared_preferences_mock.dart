import 'package:shared_preferences/shared_preferences.dart';

class MockSharedPreferences implements SharedPreferences {
  final Map<String, dynamic> _storage = {};

  @override
  Set<String> getKeys() => _storage.keys.toSet();

  @override
  dynamic get(String key) => _storage[key];

  @override
  bool? getBool(String key) => _storage[key] as bool?;

  @override
  int? getInt(String key) => _storage[key] as int?;

  @override
  double? getDouble(String key) => _storage[key] as double?;

  @override
  String? getString(String key) => _storage[key] as String?;

  @override
  bool containsKey(String key) => _storage.containsKey(key);

  @override
  List<String>? getStringList(String key) => _storage[key] as List<String>?;

  @override
  Future<bool> setBool(String key, bool value) async {
    _storage[key] = value;
    return true;
  }

  @override
  Future<bool> setInt(String key, int value) async {
    _storage[key] = value;
    return true;
  }

  @override
  Future<bool> setDouble(String key, double value) async {
    _storage[key] = value;
    return true;
  }

  @override
  Future<bool> setString(String key, String value) async {
    _storage[key] = value;
    return true;
  }

  @override
  Future<bool> setStringList(String key, List<String> value) async {
    _storage[key] = value;
    return true;
  }

  @override
  Future<bool> remove(String key) async {
    _storage.remove(key);
    return true;
  }

  @override
  Future<bool> clear() async {
    _storage.clear();
    return true;
  }

  @override
  Future<void> reload() async {}

  @override
  Future<bool> commit() async => true;

  void clearStorage() {
    _storage.clear();
  }
}
