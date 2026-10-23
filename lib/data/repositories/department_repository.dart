import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../models/department.dart';

/// All Department API calls. Every failure throws [ApiException].
class DepartmentRepository {
  final ApiClient _apiClient;

  DepartmentRepository(this._apiClient);

  Future<List<Department>> getAll() async {
    final json = await _apiClient.get(ApiConstants.departmentListEndpoint);

    final list = json['data'];
    if (list is! List) return [];

    return list
        .whereType<Map<String, dynamic>>()
        .map(Department.fromJson)
        .toList();
  }

  Future<void> add({required String name, required String shortName}) async {
    final json = await _apiClient.post(
      ApiConstants.departmentAddEndpoint,
      body: {'department_name': name, 'department_short_name': shortName},
    );
    _ensureSuccess(json, 'Add failed');
  }

  Future<void> update({
    required int id,
    required String name,
    required String shortName,
  }) async {
    final json = await _apiClient.put(
      '${ApiConstants.departmentUpdateEndpoint}/$id',
      body: {'department_name': name, 'department_short_name': shortName},
    );
    _ensureSuccess(json, 'Update failed');
  }

  Future<void> delete(int id) async {
    final json = await _apiClient.delete(
      '${ApiConstants.departmentDeleteEndpoint}/$id',
    );
    _ensureSuccess(json, 'Delete failed');
  }

  /// Web checks res.success too: a 200 reply can still say success:false.
  void _ensureSuccess(Map<String, dynamic> json, String fallbackMessage) {
    if (json['success'] == false) {
      final message = (json['message'] ?? '').toString();
      throw ApiException(message.isEmpty ? fallbackMessage : message);
    }
  }
}