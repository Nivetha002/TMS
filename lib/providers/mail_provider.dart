import 'package:flutter/foundation.dart';

import '../core/network/api_exception.dart';
import '../data/models/mail_bucket.dart';
import '../data/models/mail_record.dart';
import '../data/repositories/mail_repository.dart';

class MailProvider extends ChangeNotifier {
  final MailRepository _repository;

  MailProvider(this._repository);

  List<MailRecord> _records = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _isUnauthorized = false; // true = server said 401 (session expired)

  List<MailRecord> get records => _records;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isUnauthorized => _isUnauthorized;

  /// Search by group name or by any email inside the group.
  List<MailBucket> filter(String query) {
    final buckets = MailBucket.fromRecords(_records);

    final q = query.trim().toLowerCase();
    if (q.isEmpty) return buckets;

    return buckets
        .where((b) =>
            b.description.toLowerCase().contains(q) ||
            b.mails.any((m) => m.toLowerCase().contains(q)))
        .toList();
  }

  /// Loads all mail rows from the server.
  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    _isUnauthorized = false;
    notifyListeners();

    try {
      _records = await _repository.getAll();
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isUnauthorized = e.statusCode == 401;
    } catch (_) {
      _errorMessage = 'Failed to load mail records.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Saves one group, the same way the web page does:
  ///   1. add the new emails        (id == null)
  ///   2. update the changed emails
  ///   3. delete the removed emails
  /// Returns null on success, or an error message.
  Future<String?> saveBucket(MailBucket bucket, List<MailEntry> rows) async {
    _isUnauthorized = false;
    String? error;

    try {
      // 1. add new rows
      for (final row in rows.where((r) => r.id == null)) {
        await _repository.add(description: bucket.description, mail: row.mail);
      }

      // 2. update changed rows (compare with what the server had)
      final originalMails = {for (final r in bucket.records) r.id: r.mail};
      for (final row in rows) {
        final id = row.id;
        if (id != null && originalMails[id] != row.mail) {
          await _repository.update(
            id: id,
            description: bucket.description,
            mail: row.mail,
          );
        }
      }

      // 3. delete rows the user removed
      final keptIds = rows.map((r) => r.id).whereType<int>().toSet();
      for (final record in bucket.records) {
        if (!keptIds.contains(record.id)) {
          await _repository.delete(record.id);
        }
      }
    } on ApiException catch (e) {
      _isUnauthorized = e.statusCode == 401;
      error = e.message;
    } catch (_) {
      error = 'Something went wrong. Please try again.';
    }

    // Reload even after an error: some steps may already have worked,
    // so the list must show what the server really has now.
    if (!_isUnauthorized) await load();

    return error;
  }
}