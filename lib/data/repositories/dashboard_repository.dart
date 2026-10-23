import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../models/dashboard_summary.dart';

class DashboardRepository {
  final ApiClient _apiClient;

  DashboardRepository(this._apiClient);

  /// Summary for the whole [year] (1 Jan to 31 Dec).
  Future<DashboardSummary> getSummary(int year) async {
    final json = await _apiClient.get(
      '${ApiConstants.dashboardEndpoint}?fromDate=$year-01-01&toDate=$year-12-31',
    );
    return DashboardSummary.fromJson(json);
  }
}