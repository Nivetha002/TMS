import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../models/machine.dart';

/// All Machine API calls. Every failure throws [ApiException].
class MachineRepository {
  final ApiClient _apiClient;

  MachineRepository(this._apiClient);

  Future<List<Machine>> getAll() async {
    final json = await _apiClient.get(ApiConstants.machineListEndpoint);

    final list = json['data'];
    if (list is! List) return [];

    return list
        .whereType<Map<String, dynamic>>()
        .map(Machine.fromJson)
        .toList();
  }

  Future<void> add({required String name, required String shortName}) async {
    final json = await _apiClient.post(
      ApiConstants.machineAddEndpoint,
      body: {'machine_name': name, 'machine_short_name': shortName},
    );
    _ensureSuccess(json, 'Add failed');
  }

  Future<void> update({
    required int id,
    required String name,
    required String shortName,
  }) async {
    final json = await _apiClient.put(
      '${ApiConstants.machineUpdateEndpoint}/$id',
      body: {'machine_name': name, 'machine_short_name': shortName},
    );
    _ensureSuccess(json, 'Update failed');
  }

  Future<void> delete(int id) async {
    final json = await _apiClient.delete(
      '${ApiConstants.machineDeleteEndpoint}/$id',
    );
    _ensureSuccess(json, 'Failed to delete machine.');
  }

  /// A 200 reply can still say success:false.
  void _ensureSuccess(Map<String, dynamic> json, String fallbackMessage) {
    if (json['success'] == false) {
      final message = (json['message'] ?? '').toString();
      throw ApiException(message.isEmpty ? fallbackMessage : message);
    }
  }
}