import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../models/instrument.dart';

/// All Instrument API calls. Every failure throws [ApiException].
class InstrumentRepository {
  final ApiClient _apiClient;

  InstrumentRepository(this._apiClient);

  Future<List<Instrument>> getAll() async {
    final json = await _apiClient.get(ApiConstants.instrumentListEndpoint);

    final list = json['data'];
    if (list is! List) return [];

    return list
        .whereType<Map<String, dynamic>>()
        .map(Instrument.fromJson)
        .toList();
  }

  Future<void> add({required String name, required String shortName}) async {
    final json = await _apiClient.post(
      ApiConstants.instrumentAddEndpoint,
      body: {'instrument_name': name, 'instrument_short_name': shortName},
    );
    _ensureSuccess(json, 'Add failed');
  }

  Future<void> update({
    required int id,
    required String name,
    required String shortName,
  }) async {
    final json = await _apiClient.put(
      '${ApiConstants.instrumentUpdateEndpoint}/$id',
      body: {'instrument_name': name, 'instrument_short_name': shortName},
    );
    _ensureSuccess(json, 'Update failed');
  }

  Future<void> delete(int id) async {
    final json = await _apiClient.delete(
      '${ApiConstants.instrumentDeleteEndpoint}/$id',
    );
    _ensureSuccess(json, 'Failed to delete instrument.');
  }

  /// A 200 reply can still say success:false.
  void _ensureSuccess(Map<String, dynamic> json, String fallbackMessage) {
    if (json['success'] == false) {
      final message = (json['message'] ?? '').toString();
      throw ApiException(message.isEmpty ? fallbackMessage : message);
    }
  }
}