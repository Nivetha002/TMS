import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tms/core/network/api_client.dart';
import 'package:tms/core/network/api_exception.dart';
import 'package:tms/core/storage/session_storage.dart';

/// Fake storage that keeps cookies in memory (no phone needed in tests).
class FakeSessionStorage extends SessionStorage {
  Map<String, String> saved = {};

  @override
  Future<Map<String, String>> readCookies() async => Map.of(saved);

  @override
  Future<void> saveCookies(Map<String, String> cookies) async {
    saved = Map.of(cookies);
  }

  @override
  Future<void> clear() async {
    saved = {};
  }
}

http.Response _json(Map<String, dynamic> body, int status,
    {Map<String, String> headers = const {}}) {
  return http.Response(jsonEncode(body), status, headers: headers);
}

void main() {
  late FakeSessionStorage storage;

  setUp(() => storage = FakeSessionStorage());

  ApiClient clientWith(MockClientHandler handler) => ApiClient(
        sessionStorage: storage,
        httpClient: MockClient(handler),
      );

  group('ApiClient request', () {
    test('sends JSON POST to the correct URL', () async {
      late http.Request sent;
      final client = clientWith((request) async {
        sent = request;
        return _json({'success': true}, 200);
      });

      await client.post('/Login/login', body: {'Username': 'a', 'Password': 'b'});

      expect(sent.method, 'POST');
      expect(sent.url.toString(), 'http://10.0.2.2:5051/api/Login/login');
      expect(sent.headers['Content-Type'], startsWith('application/json'));
      expect(jsonDecode(sent.body), {'Username': 'a', 'Password': 'b'});
    });
  });

  group('ApiClient cookies', () {
    test('saves Set-Cookie and sends it on the next request', () async {
      final sentCookies = <String?>[];
      final client = clientWith((request) async {
        sentCookies.add(request.headers['Cookie']);
        return _json({'success': true}, 200,
            headers: {'set-cookie': 'sid=abc123; path=/; httponly'});
      });

      await client.post('/Login/login');
      await client.post('/Access/something');

      expect(sentCookies[0], isNull); // first call: no cookie yet
      expect(sentCookies[1], 'sid=abc123'); // second call: cookie sent
      expect(storage.saved, {'sid': 'abc123'});
    });

    test('splits several cookies even when expires contains a comma', () async {
      String? sent;
      var call = 0;
      final client = clientWith((request) async {
        call++;
        sent = request.headers['Cookie'];
        return _json({'success': true}, 200, headers: {
          'set-cookie':
              'a=1; path=/, b=2; expires=Wed, 21 Oct 2026 07:28:00 GMT; path=/',
        });
      });

      await client.post('/one');
      await client.post('/two');

      expect(call, 2);
      expect(sent, 'a=1; b=2');
    });

    test('keeps "=" characters inside a cookie value', () async {
      String? sent;
      final client = clientWith((request) async {
        sent = request.headers['Cookie'];
        return _json({'success': true}, 200,
            headers: {'set-cookie': 'sid=abc==; path=/'});
      });

      await client.post('/one');
      await client.post('/two');

      expect(sent, 'sid=abc==');
    });

    test('a new ApiClient reuses cookies saved earlier (app restart)', () async {
      storage.saved = {'sid': 'old-session'};
      String? sent;
      final client = clientWith((request) async {
        sent = request.headers['Cookie'];
        return _json({'success': true}, 200);
      });

      await client.post('/Access/my-permissions');

      expect(sent, 'sid=old-session');
    });

    test('clearSession removes cookies', () async {
      storage.saved = {'sid': 'x'};
      final client = clientWith((request) async => _json({'success': true}, 200));

      await client.clearSession();

      expect(storage.saved, isEmpty);
    });
  });

  group('ApiClient errors', () {
    test('401 uses the message from the backend', () async {
      final client = clientWith((request) async => _json(
          {'success': false, 'message': 'Invalid username or password.'}, 401));

      expect(
        () => client.post('/Login/login'),
        throwsA(isA<ApiException>()
            .having((e) => e.message, 'message', 'Invalid username or password.')
            .having((e) => e.statusCode, 'statusCode', 401)),
      );
    });

    test('500 with an empty body gives a server-error message', () async {
      final client = clientWith((request) async => http.Response('', 500));

      expect(
        () => client.post('/Login/login'),
        throwsA(isA<ApiException>()
            .having((e) => e.message, 'message', contains('Server error'))),
      );
    });

    test('200 with a non-JSON body is reported as unexpected', () async {
      final client = clientWith((request) async => http.Response('<html>', 200));

      expect(
        () => client.post('/Login/login'),
        throwsA(isA<ApiException>()
            .having((e) => e.message, 'message', contains('Unexpected'))),
      );
    });

    test('no network gives a friendly message', () async {
      final client = clientWith((request) async {
        throw const SocketException('no route to host');
      });

      expect(
        () => client.post('/Login/login'),
        throwsA(isA<ApiException>()
            .having((e) => e.message, 'message', contains('Cannot reach the server'))
            .having((e) => e.statusCode, 'statusCode', isNull)),
      );
    });

    test('timeout gives a friendly message', () async {
      final client = clientWith((request) async {
        throw TimeoutException('too slow');
      });

      expect(
        () => client.post('/Login/login'),
        throwsA(isA<ApiException>()
            .having((e) => e.message, 'message', contains('too long'))),
      );
    });
  });

}