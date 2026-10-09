import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> login({required String username, required String password});
  Future<UserModel> register({
    required String username,
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  });
  Future<UserModel> getCurrentUser();
  Future<Map<String, String>> refreshToken(String refreshToken);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient _client;

  AuthRemoteDataSourceImpl({required ApiClient client}) : _client = client;

  @override
  Future<UserModel> login({required String username, required String password}) async {
    final response = await _client.post(
      ApiConstants.login,
      data: {
        'username': username,
        'password': password,
        'expiresInMins': 60,
      },
    );

    return UserModel.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<UserModel> register({
    required String username,
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    // DummyJSON provides /users/add for registration simulation
    final response = await _client.post(
      '/users/add',
      data: {
        'username': username,
        'email': email,
        'password': password,
        'firstName': firstName,
        'lastName': lastName,
      },
    );

    final data = Map<String, dynamic>.from(response as Map);
    // Assign mock JWT tokens for registered user session
    data['accessToken'] = 'jwt_token_${data['id']}_${DateTime.now().millisecondsSinceEpoch}';
    data['refreshToken'] = 'refresh_token_${data['id']}_${DateTime.now().millisecondsSinceEpoch}';
    data['gender'] = data['gender'] ?? 'other';
    data['image'] = data['image'] ?? 'https://dummyjson.com/icon/default/128';

    return UserModel.fromJson(data);
  }

  @override
  Future<UserModel> getCurrentUser() async {
    final response = await _client.get(ApiConstants.currentUser);
    return UserModel.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<Map<String, String>> refreshToken(String refreshToken) async {
    final response = await _client.post(
      ApiConstants.refresh,
      data: {
        'refreshToken': refreshToken,
        'expiresInMins': 60,
      },
    );

    final data = response as Map<String, dynamic>;
    final accessToken = data['accessToken']?.toString() ?? data['token']?.toString() ?? '';
    final newRefreshToken = data['refreshToken']?.toString() ?? refreshToken;

    return {
      'accessToken': accessToken,
      'refreshToken': newRefreshToken,
    };
  }
}
