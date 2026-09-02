import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../data/models/user_model.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(apiClientProvider));
});

class AuthRepository {
  AuthRepository(this._client);

  final ApiClient _client;

  Future<String> sendOtp(String mobile) async {
    final json = await _client.post('/login', body: {'mobile': mobile});
    return (json['message'] ?? 'OTP sent').toString();
  }

  Future<({String token, UserModel user})> verifyOtp({
    required String mobile,
    required String otp,
  }) async {
    final json = await _client.post(
      '/verify-otp',
      body: {
        'mobile': mobile,
        'otp': otp.trim(),
        'pnsToken': 'flutter',
        'deviceType': 'MOBILE',
      },
    );

    final data = json['data'] as Map<String, dynamic>?;
    final tokens = data?['tokens'] as Map<String, dynamic>?;
    final token = tokens?['accessToken']?.toString();
    final userJson = data?['user'];

    if (token == null || token.isEmpty) {
      throw Exception('Login successful par token nahi mila.');
    }

    final user = userJson is Map<String, dynamic>
        ? UserModel.fromJson(userJson)
        : const UserModel(id: 0);

    return (token: token, user: user);
  }
}
