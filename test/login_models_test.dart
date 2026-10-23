import 'package:flutter_test/flutter_test.dart';
import 'package:tms/core/utils/validators.dart';
import 'package:tms/data/models/login_request.dart';
import 'package:tms/data/models/login_response.dart';

void main() {
  group('LoginRequest', () {
    test('toJson uses capitalised keys expected by the backend', () {
      const request = LoginRequest(username: 'john', password: 'pass');
      expect(request.toJson(), {'Username': 'john', 'Password': 'pass'});
    });
  });

  group('LoginResponse', () {
    test('parses a success response', () {
      final response = LoginResponse.fromJson({
        'success': true,
        'message': 'Login successful',
        'username': 'john',
        'role': 'Admin',
      });
      expect(response.success, true);
      expect(response.username, 'john');
      expect(response.role, 'Admin');
    });

    test('parses a failure response', () {
      final response = LoginResponse.fromJson({
        'success': false,
        'message': 'Invalid username or password.',
      });
      expect(response.success, false);
      expect(response.message, 'Invalid username or password.');
      expect(response.username, isNull);
    });

    test('does not crash on an empty body', () {
      final response = LoginResponse.fromJson({});
      expect(response.success, false);
      expect(response.message, '');
    });
  });

  group('Validators', () {
    test('username rejects null, empty and spaces only', () {
      expect(Validators.username(null), isNotNull);
      expect(Validators.username(''), isNotNull);
      expect(Validators.username('   '), isNotNull);
      expect(Validators.username('john'), isNull);
    });

    test('password rejects empty but allows spaces inside', () {
      expect(Validators.password(null), isNotNull);
      expect(Validators.password(''), isNotNull);
      expect(Validators.password('my pass'), isNull);
    });
  });
}