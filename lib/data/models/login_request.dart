/// Data we SEND to POST /api/Login/login.
class LoginRequest {
  final String username;
  final String password;

  const LoginRequest({required this.username, required this.password});

  /// Dart object -> JSON map.
  /// Keys are capitalised ("Username", "Password") because the React app
  /// sends them like this to the .NET LoginRequest model.
  Map<String, dynamic> toJson() => {
        'Username': username,
        'Password': password,
      };
}