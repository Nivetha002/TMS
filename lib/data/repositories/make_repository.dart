import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../models/make.dart';

/// All Make API calls. Every failure throws [ApiException].
class MakeRepository {
  final ApiClient _apiClient;

  MakeRepository(this._apiClient);

  Future<List<Make>> getAll() async {
    final json = await _apiClient.get(ApiConstants.makeListEndpoint);

    final list = json['data'];
    if (list is! List) return [];

    return list
        .whereType<Map<String, dynamic>>()
        .map(Make.fromJson)
        .toList();
  }

  /// The backend needs BOTH instrument_id and instrument_name in the body.
  Map<String, dynamic> _body(
    int instrumentId,
    String instrumentName,
    String makeName,
  ) {
    return {
      'instrument_id': instrumentId,
      'instrument_name': instrumentName,
      'makename': makeName,
    };
  }

  Future<void> add({
    required int instrumentId,
    required String instrumentName,
    required String makeName,
  }) async {
    final json = await _apiClient.post(
      ApiConstants.makeAddEndpoint,
      body: _body(instrumentId, instrumentName, makeName),
    );
    _ensureSuccess(json, 'Add failed');
  }

  Future<void> update({
    required int id,
    required int instrumentId,
    required String instrumentName,
    required String makeName,
  }) async {
    final json = await _apiClient.put(
      '${ApiConstants.makeUpdateEndpoint}/$id',
      body: _body(instrumentId, instrumentName, makeName),
    );
    _ensureSuccess(json, 'Update failed');
  }

  Future<void> delete(int id) async {
    final json = await _apiClient.delete('${ApiConstants.makeDeleteEndpoint}/$id');
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