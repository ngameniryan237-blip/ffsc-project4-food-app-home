import '../../../../core/utils/result.dart';
import '../entities/user.dart';

abstract class AuthRepository {
  Future<Result<User>> login({required String username, required String password});
  Future<Result<User>> register({
    required String username,
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  });
  Future<Result<User>> getCurrentUser();
  Future<Result<void>> logout();
  User? getCachedUser();
  bool get isAuthenticated;
}
