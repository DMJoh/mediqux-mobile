import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mediqux_mobile/config/api_config.dart';
import 'package:mediqux_mobile/models/user.dart';

class StorageService {
  StorageService()
    : _storage = const FlutterSecureStorage(
        aOptions: AndroidOptions(encryptedSharedPreferences: true),
      );

  final FlutterSecureStorage _storage;

  Future<void> saveToken(String token) =>
      _storage.write(key: ApiConfig.tokenKey, value: token);

  Future<String?> readToken() => _storage.read(key: ApiConfig.tokenKey);

  Future<void> saveUser(User user) =>
      _storage.write(key: ApiConfig.userKey, value: jsonEncode(user.toJson()));

  Future<User?> readUser() async {
    final raw = await _storage.read(key: ApiConfig.userKey);
    if (raw == null) return null;
    return User.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> saveServerUrl(String url) =>
      _storage.write(key: ApiConfig.serverUrlKey, value: url);

  Future<String?> readServerUrl() => _storage.read(key: ApiConfig.serverUrlKey);

  /// Clears auth credentials only — server URL is preserved.
  Future<void> clearAuth() async {
    await _storage.delete(key: ApiConfig.tokenKey);
    await _storage.delete(key: ApiConfig.userKey);
  }

  /// Full reset — clears everything including the server URL.
  Future<void> clearAll() => _storage.deleteAll();
}
