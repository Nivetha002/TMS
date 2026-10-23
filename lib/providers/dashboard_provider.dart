import 'package:flutter/foundation.dart';

import '../core/network/api_exception.dart';
import '../data/models/dashboard_summary.dart';
import '../data/repositories/dashboard_repository.dart';

class DashboardProvider extends ChangeNotifier {
  final DashboardRepository _repository;

  DashboardProvider(this._repository, {int? year})
      : _year = year ?? DateTime.now().year;

  int _year;
  DashboardSummary? _summary;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isUnauthorized = false;

  int get year => _year;
  DashboardSummary? get summary => _summary;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isUnauthorized => _isUnauthorized;

  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    _isUnauthorized = false;
    notifyListeners();

    try {
      _summary = await _repository.getSummary(_year);
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isUnauthorized = e.statusCode == 401;
    } catch (_) {
      _errorMessage = 'Could not load the dashboard.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// delta = -1 (previous year) or +1 (next year)
  Future<void> changeYear(int delta) async {
    if (_isLoading) return; // ignore taps while a request is running
    _year += delta;
    _summary = null; // so the screen shows the spinner for the new year
    await load();
  }
}