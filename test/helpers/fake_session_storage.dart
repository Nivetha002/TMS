import 'package:tms/core/storage/session_storage.dart';

/// Fake storage that keeps everything in memory (no phone needed in tests).
class FakeSessionStorage extends SessionStorage {
  Map<String, String> saved = {}; // cookies
  Map<String, String>? savedUser;

  @override
  Future<Map<String, String>> readCookies() async => Map.of(saved);

  @override
  Future<void> saveCookies(Map<String, String> cookies) async {
    saved = Map.of(cookies);
  }

  @override
  Future<void> saveUser({required String username, required String role}) async {
    savedUser = {'username': username, 'role': role};
  }

  @override
  Future<Map<String, String>?> readUser() async => savedUser;

  @override
  Future<void> clear() async {
    saved = {};
    savedUser = null;
  }
}