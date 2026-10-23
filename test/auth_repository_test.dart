import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tms/core/network/api_client.dart';
import 'package:tms/core/network/api_exception.dart';
import 'package:tms/data/models/login_request.dart';
import 'package:tms/data/repositories/auth_repository.dart';

import 'helpers/fake_session_storage.dart';

void main() {
  late FakeSessionStorage storage;

  setUp(() => storage = FakeSessionStorage());

  /// Repository whose "server" is the given handler function.
  AuthRepository makeRepo(MockClientHandler handler) {
    final apiClient = ApiClient(
      sessionStorage: storage,
      httpClient: MockClient(handler),
    );
    return AuthRepository(apiClient, storage);
  }

  http.Response reply(Map<String, dynamic> body, int status) {
    return http.Response(jsonEncode(body), status);
  }

  group('login', () {
    test('returns user, trims username and saves the user', () async {
      late Map<String, dynamic> sentBody;
      final repo = makeRepo((request) async {
        sentBody = jsonDecode(request.body);
        return reply({
          'success': true,
          'message': 'Login successful',
          'username': 'john',
          'role': 'Admin',
        }, 200);
      });

      final result = await repo.login(
        const LoginRequest(username: '  john  ', password: ' pass '),
      );

      expect(result.role, 'Admin');
      expect(sentBody['Username'], 'john'); // trimmed
      expect(sentBody['Password'], ' pass '); // NOT trimmed
      expect(storage.savedUser, {'username': 'john', 'role': 'Admin'});
    });

    test('HTTP 200 with success:false is treated as a failure', () async {
      final repo = makeRepo((request) async =>
          reply({'success': false, 'message': 'Account is inactive.'}, 200));

      expect(
        () => repo.login(const LoginRequest(username: 'a', password: 'b')),
        throwsA(isA<ApiException>()
            .having((e) => e.message, 'message', 'Account is inactive.')),
      );
    });

    test('wrong username (401) shows the backend message', () async {
      final repo = makeRepo((request) async => reply(
          {'success': false, 'message': 'Invalid username or password.'}, 401));

      expect(
        () => repo.login(const LoginRequest(username: 'x', password: 'y')),
        throwsA(isA<ApiException>()
            .having((e) => e.message, 'message', 'Invalid username or password.')),
      );
    });
  });

  group('restoreSession', () {
    test('nobody saved: returns null and makes NO request', () async {
      var requestMade = false;
      final repo = makeRepo((request) async {
        requestMade = true;
        return reply({}, 200);
      });

      final result = await repo.restoreSession();

      expect(result, isNull);
      expect(requestMade, false);
    });

    test('saved user + server says OK: returns the user (GET)', () async {
      storage.savedUser = {'username': 'john', 'role': 'Admin'};
      late http.Request sent;
      final repo = makeRepo((request) async {
        sent = request;
        return reply({'permissions': []}, 200);
      });

      final result = await repo.restoreSession();

      expect(sent.method, 'GET');
      expect(sent.url.path, endsWith('/Access/my-permissions'));
      expect(result?.username, 'john');
      expect(result?.role, 'Admin');
    });

    test('server says 401: returns null and clears the saved session', () async {
      storage.savedUser = {'username': 'john', 'role': 'Admin'};
      storage.saved = {'sid': 'old'};
      final repo = makeRepo((request) async => reply(
          {'success': false, 'message': 'Session expired. Please login again.'},
          401));

      final result = await repo.restoreSession();

      expect(result, isNull);
      expect(storage.savedUser, isNull);
      expect(storage.saved, isEmpty);
    });

    test('server unreachable: returns null but KEEPS the saved session', () async {
      storage.savedUser = {'username': 'john', 'role': 'Admin'};
      final repo = makeRepo((request) async {
        throw const SocketException('no route to host');
      });

      final result = await repo.restoreSession();

      expect(result, isNull);
      expect(storage.savedUser, isNotNull);
    });
  });

  group('logout', () {
    test('calls POST /Login/logout and clears the saved session', () async {
      storage.savedUser = {'username': 'john', 'role': 'Admin'};
      storage.saved = {'sid': 'abc'};
      late http.Request sent;
      final repo = makeRepo((request) async {
        sent = request;
        return reply({'success': true, 'message': 'Logged out'}, 200);
      });

      await repo.logout();

      expect(sent.method, 'POST');
      expect(sent.url.path, endsWith('/Login/logout'));
      expect(storage.savedUser, isNull);
      expect(storage.saved, isEmpty);
    });

    test('still clears the phone session when the server is unreachable', () async {
      storage.savedUser = {'username': 'john', 'role': 'Admin'};
      final repo = makeRepo((request) async {
        throw const SocketException('no route to host');
      });

      await repo.logout(); // must not throw

      expect(storage.savedUser, isNull);
    });
  });
}