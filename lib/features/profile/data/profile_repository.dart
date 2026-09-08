import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dark_store_api_client.dart';
import '../../../core/storage/session_storage.dart';
import '../../../core/utils/role_helper.dart';
import 'models/profile_model.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(
    ref.watch(darkStoreApiClientProvider),
    ref.watch(sessionStorageProvider),
  );
});

class ProfileRepository {
  ProfileRepository(this._client, this._storage);

  final DarkStoreApiClient _client;
  final SessionStorage _storage;

  Future<ProfileModel> fetchProfile() async {
    final query = <String, dynamic>{};
    final user = await _storage.getUser();
    final storeId = await _storage.getSelectedStoreId();
    if (RoleHelper.isSuperAdminRole(user?.role?.name) &&
        storeId != null &&
        storeId > 0) {
      query['businessLocationId'] = storeId;
    }

    try {
      final json = await _client.get(
        '/user/profile',
        query: query.isEmpty ? null : query,
      );
      final data = json['data'];
      if (data is Map<String, dynamic>) {
        return ProfileModel.fromJson(data);
      }
    } catch (_) {
      // SuperAdmin / soft failures: show session user so Profile stays usable.
      if (user != null) {
        return ProfileModel(
          name: user.name ?? user.fullName,
          phone: null,
          retailerId: user.id > 0 ? 'RET-${user.id}' : null,
        );
      }
      rethrow;
    }
    return const ProfileModel();
  }

  Future<void> logout() async {
    try {
      await _client.post('/auth/dark-store/logout');
    } catch (_) {
      // Local logout must proceed even if API fails.
    }
  }
}
