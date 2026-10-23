/// Form validation rules. Each function returns:
///   null        -> value is valid
///   String text -> error message to show under the field
///
/// The backend only checks "username and password required",
/// so we do the same. No extra rules like minimum length.
class Validators {
  Validators._();

  static String? username(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Username is required';
    }
    return null;
  }

  static String? password(String? value) {
    // Password is NOT trimmed: spaces can be part of a real password.
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    return null;
  }

  static String? required(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }
}