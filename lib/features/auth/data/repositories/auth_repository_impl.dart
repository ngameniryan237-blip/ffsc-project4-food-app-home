import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_data_source.dart';
import '../datasources/auth_remote_data_source.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final AuthLocalDataSource _localDataSource;
  final NetworkInfo _networkInfo;

  AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required AuthLocalDataSource localDataSource,
    required NetworkInfo networkInfo,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource,
        _networkInfo = networkInfo;

  @override
  bool get isAuthenticated => _localDataSource.getAccessToken() != null;

  @override
  User? getCachedUser() => _localDataSource.getLastUserSession();

  @override
  Future<Result<User>> login({required String username, required String password}) async {
    final connected = await _networkInfo.isConnected;
    if (!connected) {
      return Result.error(const NetworkFailure('No internet connection. Unable to log in.'));
    }

    try {
      final userModel = await _remoteDataSource.login(
        username: username,
        password: password,
      );
      await _localDataSource.saveUserSession(userModel);
      return Result.success(userModel);
    } on AuthException catch (e) {
      return Result.error(AuthFailure(e.message, statusCode: e.statusCode));
    } on ServerException catch (e) {
      return Result.error(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Result.error(NetworkFailure(e.message));
    } catch (e) {
      return Result.error(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Result<User>> register({
    required String username,
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    final connected = await _networkInfo.isConnected;
    if (!connected) {
      return Result.error(const NetworkFailure('No internet connection. Unable to register.'));
    }

    try {
      final userModel = await _remoteDataSource.register(
        username: username,
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
      );
      await _localDataSource.saveUserSession(userModel);
      return Result.success(userModel);
    } on AuthException catch (e) {
      return Result.error(AuthFailure(e.message, statusCode: e.statusCode));
    } on ServerException catch (e) {
      return Result.error(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Result.error(NetworkFailure(e.message));
    } catch (e) {
      return Result.error(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Result<User>> getCurrentUser() async {
    final connected = await _networkInfo.isConnected;
    if (!connected) {
      final cachedUser = _localDataSource.getLastUserSession();
      if (cachedUser != null) {
        return Result.success(cachedUser);
      }
      return Result.error(const NetworkFailure('Offline and no cached session found'));
    }

    try {
      final userModel = await _remoteDataSource.getCurrentUser();
      // Keep existing tokens if /auth/me doesn't return them
      final currentToken = _localDataSource.getAccessToken();
      final currentRefreshToken = _localDataSource.getRefreshToken();
      final updatedUserModel = UserModel.fromEntity(
        userModel.copyWith(
          accessToken: currentToken,
          refreshToken: currentRefreshToken,
        ),
      );
      await _localDataSource.saveUserSession(updatedUserModel);
      return Result.success(updatedUserModel);
    } catch (e) {
      // Fallback to cache
      final cached = _localDataSource.getLastUserSession();
      if (cached != null) {
        return Result.success(cached);
      }
      return Result.error(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> logout() async {
    try {
      await _localDataSource.clearSession();
      return Result.success(null);
    } catch (e) {
      return Result.error(CacheFailure(e.toString()));
    }
  }
}
