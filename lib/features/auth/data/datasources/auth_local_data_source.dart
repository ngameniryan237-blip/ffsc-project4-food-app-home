import '../../../../core/storage/hive_storage.dart';
import '../models/user_model.dart';

abstract class AuthLocalDataSource {
  Future<void> saveUserSession(UserModel user);
  UserModel? getLastUserSession();
  String? getAccessToken();
  String? getRefreshToken();
  Future<void> clearSession();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final HiveStorageService _storage;

  AuthLocalDataSourceImpl({HiveStorageService? storage})
      : _storage = storage ?? HiveStorageService();

  @override
  Future<void> saveUserSession(UserModel user) async {
    if (user.accessToken != null && user.refreshToken != null) {
      await _storage.saveTokens(
        accessToken: user.accessToken!,
        refreshToken: user.refreshToken!,
      );
    }
    await _storage.saveUserData(user.toJson());
  }

  @override
  UserModel? getLastUserSession() {
    final data = _storage.getUserData();
    if (data == null) return null;
    return UserModel.fromJson(data);
  }

  @override
  String? getAccessToken() => _storage.getAccessToken();

  @override
  String? getRefreshToken() => _storage.getRefreshToken();

  @override
  Future<void> clearSession() async {
    await _storage.clearAuthData();
  }
}
