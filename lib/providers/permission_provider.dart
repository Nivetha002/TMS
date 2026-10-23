import 'package:flutter/foundation.dart';

import '../core/network/api_exception.dart';
import '../data/repositories/permission_repository.dart';

class PermissionProvider extends ChangeNotifier {
  final PermissionRepository _repository;

  PermissionProvider(this._repository);

  List<String> _permissions = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _isUnauthorized = false; // true = server said 401 (session expired)

  List<String> get permissions => _permissions;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isUnauthorized => _isUnauthorized;

  /// For later (menu gating): permissions.has('some name')
  bool has(String name) {
    return _permissions.any((p) => p.toLowerCase() == name.toLowerCase());
  }

  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    _isUnauthorized = false;
    _permissions = []; // never show the previous user's permissions
    notifyListeners();

    try {
      _permissions = await _repository.getPermissions();
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isUnauthorized = e.statusCode == 401;
    } catch (_) {
      _errorMessage = 'Could not load permissions.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}