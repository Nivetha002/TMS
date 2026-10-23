import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../core/storage/session_storage.dart';
import '../models/login_request.dart';
import '../models/login_response.dart';

/// Bridge between Provider and the API + storage.
class AuthRepository {
  final ApiClient _apiClient;
  final SessionStorage _sessionStorage;

  AuthRepository(this._apiClient, this._sessionStorage);

  /// Login. Returns [LoginResponse] or throws [ApiException].
  Future<LoginResponse> login(LoginRequest request) async {
    final cleanRequest = LoginRequest(
      username: request.username.trim(),
      password: request.password,
    );

    final json = await _apiClient.post(
      ApiConstants.loginEndpoint,
      body: cleanRequest.toJson(),
    );

    final response = LoginResponse.fromJson(json);

    // A 200 reply can still carry { success: false }.
    if (!response.success) {
      throw ApiException(
        response.message.isEmpty
            ? 'Login failed. Please try again.'
            : response.message,
      );
    }

    // Remember who logged in (cookie is already saved by ApiClient).
    await _sessionStorage.saveUser(
      username: response.username ?? '',
      role: response.role ?? '',
    );

    return response;
  }

  /// App start: is the saved session still valid?
  /// Returns the user if yes, null if no. Never throws.
  Future<LoginResponse?> restoreSession() async {
    // 1. Anybody saved on this phone?
    final savedUser = await _sessionStorage.readUser();
    if (savedUser == null) return null;

    // 2. Ask the server if our cookie still works
    try {
      await _apiClient.get(ApiConstants.sessionCheckEndpoint);

      return LoginResponse(
        success: true,
        message: 'Session restored',
        username: savedUser['username'],
        role: savedUser['role'],
      );
    } on ApiException catch (e) {
      // 401 = session expired: delete the saved session.
      // Other errors (server down): keep it, we just show Login this time.
      if (e.statusCode == 401) await _apiClient.clearSession();
      return null;
    }
  }

  /// Logout. Always clears the phone session, even if the server call fails.
  Future<void> logout() async {
    try {
      await _apiClient.post(ApiConstants.logoutEndpoint);
    } on ApiException {
      // Ignore: the user wants out, so we log out locally anyway.
    }
    await _apiClient.clearSession();
  }
}