import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';
import '../storage/session_storage.dart';
import 'api_exception.dart';

/// The ONLY class that talks to the internet. It:
///   1. Builds the URL (baseUrl + endpoint)
///   2. Sends saved session cookies with every request
///   3. Saves new cookies from the server's "Set-Cookie" header
///   4. Converts every failure into a friendly ApiException
class ApiClient {
  final http.Client _client;
  final SessionStorage _sessionStorage;

  // In-memory copy of the cookies. null = not loaded from storage yet.
  Map<String, String>? _cookies;

  ApiClient({
    required SessionStorage sessionStorage,
    http.Client? httpClient,
  })  : _sessionStorage = sessionStorage,
        _client = httpClient ?? http.Client();

  /// GET request. Returns the decoded JSON map.
  Future<Map<String, dynamic>> get(String endpoint) {
    return _send('GET', endpoint);
  }

  /// POST request. [body] is optional (logout has no body).
  Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? body,
  }) {
    return _send('POST', endpoint, body: body);
  }

  Future<Map<String, dynamic>> put(
    String endpoint, {
    Map<String, dynamic>? body,
  }) {
    return _send('PUT', endpoint, body: body);
  }

  /// DELETE request.
  Future<Map<String, dynamic>> delete(String endpoint) {
    return _send('DELETE', endpoint);
  }

  /// Forget everything: cookies + saved user (logout / expired session).
  Future<void> clearSession() async {
    _cookies = {};
    await _sessionStorage.clear();
  }

  // ---------------------------------------------------------------------
  // One method that does the real work for both GET and POST
  // ---------------------------------------------------------------------

  Future<Map<String, dynamic>> _send(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');

    try {
      final headers = <String, String>{};
      if (body != null) headers['Content-Type'] = 'application/json';

      final cookieHeader = await _buildCookieHeader();
      if (cookieHeader.isNotEmpty) headers['Cookie'] = cookieHeader;

            final encodedBody = body == null ? null : jsonEncode(body);
      final timeout = ApiConstants.requestTimeout;

      final http.Response response;
      if (method == 'GET') {
        response = await _client.get(uri, headers: headers).timeout(timeout);
      } else if (method == 'POST') {
        response = await _client
            .post(uri, headers: headers, body: encodedBody)
            .timeout(timeout);
      } else if (method == 'PUT') {
        response = await _client
            .put(uri, headers: headers, body: encodedBody)
            .timeout(timeout);
      } else {
        response = await _client.delete(uri, headers: headers).timeout(timeout);
      }
      
      // Never print the body (it can contain the password).
      if (kDebugMode) {
        debugPrint('[API] $method $endpoint -> ${response.statusCode}');
      }

      await _saveCookiesFrom(response);
      return _handleResponse(response);
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw const ApiException(
        'Server took too long to respond. Please try again.',
      );
    } on SocketException {
      throw const ApiException(
        'Cannot reach the server. Check your internet connection and server address.',
      );
    } on http.ClientException {
      throw const ApiException(
        'Cannot reach the server. Check your internet connection and server address.',
      );
    } on FormatException {
      throw const ApiException('Unexpected response from server.');
    }
  }

  // ---------------------------------------------------------------------
  // Response handling
  // ---------------------------------------------------------------------

  Map<String, dynamic> _handleResponse(http.Response response) {
    final json = _tryDecode(response.body);
    final status = response.statusCode;

    if (status >= 200 && status < 300) {
      if (json == null) {
        throw ApiException('Unexpected response from server.', statusCode: status);
      }
      return json;
    }

    throw ApiException(_errorMessage(json, status), statusCode: status);
  }

  /// Same priority as the React app: message -> error -> generic text.
  String _errorMessage(Map<String, dynamic>? json, int status) {
    final message = json?['message'];
    if (message is String && message.trim().isNotEmpty) return message;

    final error = json?['error'];
    if (error is String && error.trim().isNotEmpty) return error;

    if (status >= 500) return 'Server error. Please try again later.';
    return 'Something went wrong';
  }

  Map<String, dynamic>? _tryDecode(String body) {
    try {
      final decoded = jsonDecode(body);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null; // empty or non-JSON body
    }
  }

  // ---------------------------------------------------------------------
  // Cookie handling (a browser does this automatically, Flutter does not)
  // ---------------------------------------------------------------------

  Future<void> _loadCookiesIfNeeded() async {
    _cookies ??= await _sessionStorage.readCookies();
  }

  /// "name1=value1; name2=value2" -> goes into the Cookie request header.
  Future<String> _buildCookieHeader() async {
    await _loadCookiesIfNeeded();
    return _cookies!.entries.map((e) => '${e.key}=${e.value}').join('; ');
  }

  Future<void> _saveCookiesFrom(http.Response response) async {
    final raw = response.headers['set-cookie'];
    if (raw == null || raw.isEmpty) return;

    await _loadCookiesIfNeeded();

    for (final cookie in _splitSetCookie(raw)) {
      // "name=value; path=/; httponly" -> keep only "name=value"
      final pair = cookie.split(';').first.trim();
      final index = pair.indexOf('=');
      if (index <= 0) continue;

      final name = pair.substring(0, index).trim();
      final value = pair.substring(index + 1).trim();

      if (value.isEmpty) {
        _cookies!.remove(name); // server is deleting this cookie
      } else {
        _cookies![name] = value;
      }
    }

    await _sessionStorage.saveCookies(_cookies!);

    // Names only, never values (the value is the session key).
    if (kDebugMode) debugPrint('[API] Cookies saved: ${_cookies!.keys.toList()}');
  }

  /// The http package joins several Set-Cookie headers with commas.
  /// Split only at a comma followed by "name=", so the comma inside
  /// "expires=Wed, 21 Oct ..." is NOT split.
  List<String> _splitSetCookie(String raw) {
    return raw.split(RegExp(r',(?=\s*[^;,=\s]+=)'));
  }
}