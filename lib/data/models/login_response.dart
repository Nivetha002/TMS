/// Data we RECEIVE from the login API.
///   success: { success: true,  message, username, role }
///   failure: { success: false, message }
class LoginResponse {
  final bool success;
  final String message;
  final String? username; // null on failure
  final String? role; // null on failure

  const LoginResponse({
    required this.success,
    required this.message,
    this.username,
    this.role,
  });

  /// JSON map -> Dart object.
  /// Written defensively: a missing field will not crash the app.
  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      success: json['success'] == true,
      message: (json['message'] ?? '').toString(),
      username: json['username']?.toString(),
      role: json['role']?.toString(),
    );
  }
}