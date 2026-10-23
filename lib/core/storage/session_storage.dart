import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Saves the login session on the phone (encrypted storage):
///   1. cookies -> sent to the server with every request
///   2. user    -> username + role, so Home can show them after app restart
class SessionStorage {
  static const _cookieKey = 'session_cookies';
  static const _userKey = 'session_user';

  final FlutterSecureStorage _storage;

  SessionStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  // ---------------- cookies ----------------

  Future<Map<String, String>> readCookies() async {
    try {
      final raw = await _storage.read(key: _cookieKey);
      if (raw == null || raw.isEmpty) return {};

      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return decoded.map((k, v) => MapEntry(k.toString(), v.toString()));
      }
    } catch (_) {
      // Unreadable storage: behave as "not logged in".
    }
    return {};
  }

  Future<void> saveCookies(Map<String, String> cookies) async {
    await _storage.write(key: _cookieKey, value: jsonEncode(cookies));
  }

  // ---------------- user ----------------

  Future<void> saveUser({required String username, required String role}) async {
    final json = jsonEncode({'username': username, 'role': role});
    await _storage.write(key: _userKey, value: json);
  }

  /// Returns {'username': ..., 'role': ...} or null if nobody is saved.
  Future<Map<String, String>?> readUser() async {
    try {
      final raw = await _storage.read(key: _userKey);
      if (raw == null || raw.isEmpty) return null;

      final decoded = jsonDecode(raw);
      if (decoded is Map && decoded['username'] != null) {
        return {
          'username': decoded['username'].toString(),
          'role': (decoded['role'] ?? '').toString(),
        };
      }
    } catch (_) {
      // Unreadable storage: behave as "not logged in".
    }
    return null;
  }

  // ---------------- clear ----------------

  /// Logout: delete cookies AND user.
  Future<void> clear() async {
    await _storage.delete(key: _cookieKey);
    await _storage.delete(key: _userKey);
  }
}