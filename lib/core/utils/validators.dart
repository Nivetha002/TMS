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

    // Same pattern the backend uses, so we never send an email it will reject.
  static final RegExp _emailPattern =
      RegExp(r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$');

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    if (!_emailPattern.hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }
  
}