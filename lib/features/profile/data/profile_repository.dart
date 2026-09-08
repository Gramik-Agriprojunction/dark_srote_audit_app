import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dark_store_api_client.dart';
import 'models/profile_model.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.watch(darkStoreApiClientProvider));
});

class ProfileRepository {
  ProfileRepository(this._client);

  final DarkStoreApiClient _client;

  Future<ProfileModel> fetchProfile() async {
    final json = await _client.get('/user/profile');
    final data = json['data'];
    if (data is Map<String, dynamic>) {
      return ProfileModel.fromJson(data);
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
