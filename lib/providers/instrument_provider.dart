import 'package:flutter/foundation.dart';

import '../core/network/api_exception.dart';
import '../data/models/instrument.dart';
import '../data/repositories/instrument_repository.dart';

class InstrumentProvider extends ChangeNotifier {
  final InstrumentRepository _repository;

  InstrumentProvider(this._repository);

  List<Instrument> _items = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _isUnauthorized = false; // true = server said 401 (session expired)

  List<Instrument> get items => _items;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isUnauthorized => _isUnauthorized;

  /// Search by name or short name (same rule as the web page).
  List<Instrument> filter(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return _items;

    return _items
        .where((i) =>
            i.name.toLowerCase().contains(q) ||
            i.shortName.toLowerCase().contains(q))
        .toList();
  }

  /// Loads the list from the server.
  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    _isUnauthorized = false;
    notifyListeners();

    try {
      _items = await _repository.getAll();
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isUnauthorized = e.statusCode == 401;
    } catch (_) {
      _errorMessage = 'Failed to fetch instruments';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // The three actions below return:
  //   null        -> success
  //   String text -> the error message to show to the user

  Future<String?> add(String name, String shortName) {
    return _save(() => _repository.add(name: name, shortName: shortName));
  }

  Future<String?> update(int id, String name, String shortName) {
    return _save(
      () => _repository.update(id: id, name: name, shortName: shortName),
    );
  }

  Future<String?> delete(int id) {
    return _save(() => _repository.delete(id));
  }

  /// Runs one action, and on success reloads the list from the server.
  Future<String?> _save(Future<void> Function() action) async {
    _isUnauthorized = false;

    try {
      await action();
    } on ApiException catch (e) {
      _isUnauthorized = e.statusCode == 401;
      return e.message;
    } catch (_) {
      return 'Something went wrong. Please try again.';
    }

    await load(); // fresh list, same as the web page does
    return null;
  }
}