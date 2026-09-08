import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/storage/session_storage.dart';
import '../../../core/utils/role_helper.dart';
import 'models/dashboard_model.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository(
    ref.watch(apiClientProvider),
    ref.watch(sessionStorageProvider),
  );
});

class DashboardRepository {
  DashboardRepository(this._client, this._storage);

  final ApiClient _client;
  final SessionStorage _storage;

  Future<DashboardModel> fetchDashboard() async {
    final query = <String, dynamic>{};
    final user = await _storage.getUser();
    final storeId = await _storage.getSelectedStoreId();
    if (RoleHelper.isSuperAdminRole(user?.role?.name) &&
        storeId != null &&
        storeId > 0) {
      query['businessLocationId'] = storeId;
    }
    final json = await _client.get(
      '/dashboard',
      query: query.isEmpty ? null : query,
    );
    final data = json['data'];
    if (data is Map<String, dynamic>) {
      return DashboardModel.fromJson(data);
    }
    return DashboardModel.fromJson(const {});
  }
}
