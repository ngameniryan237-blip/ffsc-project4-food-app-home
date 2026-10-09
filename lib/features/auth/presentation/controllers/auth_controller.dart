import 'package:flutter/foundation.dart';
import '../../../../core/storage/hive_storage.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthController extends ChangeNotifier {
  final AuthRepository _authRepository;
  final HiveStorageService _storage;

  AuthStatus _status = AuthStatus.initial;
  User? _currentUser;
  String? _errorMessage;

  AuthController({
    required AuthRepository authRepository,
    HiveStorageService? storage,
  })  : _authRepository = authRepository,
        _storage = storage ?? HiveStorageService() {
    _checkInitialAuth();
  }

  AuthStatus get status => _status;
  User? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isLoading => _status == AuthStatus.loading;
  String? get accessToken => _storage.getAccessToken();
  String? get refreshToken => _storage.getRefreshToken();

  void _checkInitialAuth() {
    final cachedUser = _authRepository.getCachedUser();
    if (cachedUser != null && _authRepository.isAuthenticated) {
      _currentUser = cachedUser;
      _status = AuthStatus.authenticated;
    } else {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> login(String username, String password) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    final result = await _authRepository.login(
      username: username.trim(),
      password: password,
    );

    return result.when(
      success: (user) {
        _currentUser = user;
        _status = AuthStatus.authenticated;
        notifyListeners();
        return true;
      },
      error: (failure) {
        _status = AuthStatus.error;
        _errorMessage = failure.message;
        notifyListeners();
        return false;
      },
    );
  }

  Future<bool> register({
    required String username,
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    final result = await _authRepository.register(
      username: username.trim(),
      email: email.trim(),
      password: password,
      firstName: firstName.trim(),
      lastName: lastName.trim(),
    );

    return result.when(
      success: (user) {
        _currentUser = user;
        _status = AuthStatus.authenticated;
        notifyListeners();
        return true;
      },
      error: (failure) {
        _status = AuthStatus.error;
        _errorMessage = failure.message;
        notifyListeners();
        return false;
      },
    );
  }

  Future<void> refreshProfile() async {
    final result = await _authRepository.getCurrentUser();
    result.when(
      success: (user) {
        _currentUser = user;
        notifyListeners();
      },
      error: (failure) {
        // keep current user from cache
      },
    );
  }

  Future<void> logout() async {
    _status = AuthStatus.loading;
    notifyListeners();

    await _authRepository.logout();
    _currentUser = null;
    _status = AuthStatus.unauthenticated;
    _errorMessage = null;
    notifyListeners();
  }

  void handleSessionExpired() {
    _currentUser = null;
    _status = AuthStatus.unauthenticated;
    _errorMessage = 'Session expired. Please log in again.';
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    if (_status == AuthStatus.error) {
      _status = _currentUser != null ? AuthStatus.authenticated : AuthStatus.unauthenticated;
    }
    notifyListeners();
  }
}
