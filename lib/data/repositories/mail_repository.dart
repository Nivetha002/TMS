import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../models/mail_record.dart';

/// All Mail API calls. Every failure throws [ApiException].
class MailRepository {
  final ApiClient _apiClient;

  MailRepository(this._apiClient);

  Future<List<MailRecord>> getAll() async {
    final json = await _apiClient.get(ApiConstants.mailListEndpoint);

    final list = json['data'];
    if (list is! List) return [];

    return list
        .whereType<Map<String, dynamic>>()
        .map(MailRecord.fromJson)
        .toList();
  }

  Future<void> add({required String description, required String mail}) async {
    final json = await _apiClient.post(
      ApiConstants.mailAddEndpoint,
      body: {'description': description, 'mail': mail},
    );
    _ensureSuccess(json, 'Add failed');
  }

  Future<void> update({
    required int id,
    required String description,
    required String mail,
  }) async {
    final json = await _apiClient.put(
      '${ApiConstants.mailUpdateEndpoint}/$id',
      body: {'description': description, 'mail': mail},
    );
    _ensureSuccess(json, 'Update failed');
  }

  Future<void> delete(int id) async {
    final json = await _apiClient.delete('${ApiConstants.mailDeleteEndpoint}/$id');
    _ensureSuccess(json, 'Delete failed');
  }

  /// A 200 reply can still say success:false.
  void _ensureSuccess(Map<String, dynamic> json, String fallbackMessage) {
    if (json['success'] == false) {
      final message = (json['message'] ?? '').toString();
      throw ApiException(message.isEmpty ? fallbackMessage : message);
    }
  }
}