import 'package:flutter/foundation.dart';

import '../core/network/api_exception.dart';
import '../data/models/login_request.dart';
import '../data/models/login_response.dart';
import '../data/repositories/auth_repository.dart';

/// Holds the login STATE. The screens only read these values.
///   isRestoring  -> app just started, checking the saved session
///   isLoading    -> login request is running
///   errorMessage -> text for the red banner
///   user         -> who is logged in (null = nobody)
class AuthProvider extends ChangeNotifier {
  final AuthRepository _repository;

  AuthProvider(this._repository);

  bool _isRestoring = true; // true at app start, so Splash shows first
  bool _isLoading = false;
  String? _errorMessage;
  LoginResponse? _user;

  bool get isRestoring => _isRestoring;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  LoginResponse? get user => _user;

  /// Called once when the app starts.
  Future<void> restoreSession() async {
    try {
      _user = await _repository.restoreSession();
    } catch (_) {
      _user = null;
    } finally {
      _isRestoring = false;
      notifyListeners(); // AuthGate rebuilds: Splash -> Home or Login
    }
  }

  /// Returns true if login worked, false if it failed.
  Future<bool> login({
    required String username,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await _repository.login(
        LoginRequest(username: username, password: password),
      );
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _errorMessage = 'Something went wrong. Please try again.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

    /// [message] is optional: for example "Session expired" shows on Login.
  Future<void> logout({String? message}) async {
    await _repository.logout();
    _user = null;
    _errorMessage = message;
    notifyListeners(); // AuthGate rebuilds: Dashboard -> Login
  }
}