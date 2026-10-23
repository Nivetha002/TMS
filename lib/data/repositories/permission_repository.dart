import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';

class PermissionRepository {
  final ApiClient _apiClient;

  PermissionRepository(this._apiClient);

  /// Names of everything the logged-in user's role can access.
  Future<List<String>> getPermissions() async {
    final json = await _apiClient.get(ApiConstants.permissionsEndpoint);

    final list = json['permissions'];
    if (list is List) return list.map((e) => e.toString()).toList();
    return [];
  }
}