import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tms/core/network/api_client.dart';
import 'package:tms/data/repositories/auth_repository.dart';
import 'package:tms/providers/auth_provider.dart';

import 'helpers/fake_session_storage.dart';

/// AuthProvider whose "server" always replies with [status] + [body].
AuthProvider makeProvider(
  FakeSessionStorage storage,
  int status,
  Map<String, dynamic> body,
) {
  final client = MockClient((request) async {
    return http.Response(jsonEncode(body), status);
  });
  final apiClient = ApiClient(sessionStorage: storage, httpClient: client);
  return AuthProvider(AuthRepository(apiClient, storage));
}

void main() {
  late FakeSessionStorage storage;

  setUp(() => storage = FakeSessionStorage());

  test('successful login sets user and returns true', () async {
    final provider = makeProvider(storage, 200, {
      'success': true,
      'message': 'Login successful',
      'username': 'john',
      'role': 'Admin',
    });

    final result = await provider.login(username: 'john', password: 'x');

    expect(result, true);
    expect(provider.user?.role, 'Admin');
    expect(provider.errorMessage, isNull);
    expect(provider.isLoading, false);
  });

  test('wrong username sets errorMessage and returns false', () async {
    final provider = makeProvider(storage, 401, {
      'success': false,
      'message': 'Invalid username or password.',
    });

    final result = await provider.login(username: 'bad', password: 'x');

    expect(result, false);
    expect(provider.user, isNull);
    expect(provider.errorMessage, 'Invalid username or password.');
    expect(provider.isLoading, false);
  });

  test('isLoading is true while waiting and false after', () async {
    final provider = makeProvider(storage, 200, {
      'success': true,
      'message': 'ok',
      'username': 'a',
      'role': 'b',
    });

    final loadingValues = <bool>[];
    provider.addListener(() => loadingValues.add(provider.isLoading));

    await provider.login(username: 'a', password: 'b');

    expect(loadingValues, [true, false]);
  });

  test('restoreSession with a valid saved session sets the user', () async {
    storage.savedUser = {'username': 'john', 'role': 'Admin'};
    final provider = makeProvider(storage, 200, {'permissions': []});

    expect(provider.isRestoring, true); // splash shows first

    await provider.restoreSession();

    expect(provider.isRestoring, false);
    expect(provider.user?.username, 'john');
  });

  test('restoreSession with nothing saved leaves user null', () async {
    final provider = makeProvider(storage, 200, {'permissions': []});

    await provider.restoreSession();

    expect(provider.isRestoring, false);
    expect(provider.user, isNull);
  });

  test('logout clears the user', () async {
    final provider = makeProvider(storage, 200, {
      'success': true,
      'message': 'ok',
      'username': 'john',
      'role': 'Admin',
    });
    await provider.login(username: 'john', password: 'x');
    expect(provider.user, isNotNull);

    await provider.logout();

    expect(provider.user, isNull);
    expect(storage.savedUser, isNull);
  });
}