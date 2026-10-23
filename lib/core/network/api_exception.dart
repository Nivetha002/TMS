/// One error type for everything that can go wrong with an API call.
/// The repository/ApiClient throws it, AuthProvider catches it and
/// shows [message] in the ErrorBanner.
class ApiException implements Exception {
  final String message; // user-friendly text
  final int? statusCode; // null for network/timeout errors

  const ApiException(this.message, {this.statusCode});

  @override
  String toString() => 'ApiException($statusCode): $message';
}