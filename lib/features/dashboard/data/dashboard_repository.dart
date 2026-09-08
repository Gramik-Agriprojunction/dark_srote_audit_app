import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import 'models/dashboard_model.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository(ref.watch(apiClientProvider));
});

class DashboardRepository {
  DashboardRepository(this._client);

  final ApiClient _client;

  Future<DashboardModel> fetchDashboard() async {
    final json = await _client.get('/dashboard');
    final data = json['data'];
    if (data is Map<String, dynamic>) {
      return DashboardModel.fromJson(data);
    }
    return DashboardModel.fromJson(const {});
  }
}
