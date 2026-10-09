import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_connected_app/core/error/exceptions.dart';
import 'package:flutter_connected_app/core/error/failures.dart';
import 'package:flutter_connected_app/core/network/network_info.dart';
import 'package:flutter_connected_app/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:flutter_connected_app/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:flutter_connected_app/features/auth/data/models/user_model.dart';
import 'package:flutter_connected_app/features/auth/data/repositories/auth_repository_impl.dart';

class MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}
class MockAuthLocalDataSource extends Mock implements AuthLocalDataSource {}
class MockNetworkInfo extends Mock implements NetworkInfo {}

void main() {
  late AuthRepositoryImpl repository;
  late MockAuthRemoteDataSource mockRemoteDataSource;
  late MockAuthLocalDataSource mockLocalDataSource;
  late MockNetworkInfo mockNetworkInfo;

  const tUserModel = UserModel(
    id: 1,
    username: 'emilys',
    email: 'emily.johnson@x.dummyjson.com',
    firstName: 'Emily',
    lastName: 'Johnson',
    gender: 'female',
    image: 'https://dummyjson.com/icon/emilys/128',
    accessToken: 'mock_jwt_token',
    refreshToken: 'mock_refresh_token',
  );

  setUpAll(() {
    registerFallbackValue(tUserModel);
  });

  setUp(() {
    mockRemoteDataSource = MockAuthRemoteDataSource();
    mockLocalDataSource = MockAuthLocalDataSource();
    mockNetworkInfo = MockNetworkInfo();

    when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);

    repository = AuthRepositoryImpl(
      remoteDataSource: mockRemoteDataSource,
      localDataSource: mockLocalDataSource,
      networkInfo: mockNetworkInfo,
    );
  });

  group('AuthRepositoryImpl - login', () {
    test('should return User entity and save user session when login is successful online', () async {
      // Arrange
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(() => mockRemoteDataSource.login(
            username: 'emilys',
            password: 'emilyspass',
          )).thenAnswer((_) async => tUserModel);
      when(() => mockLocalDataSource.saveUserSession(any()))
          .thenAnswer((_) async => {});

      // Act
      final result = await repository.login(
        username: 'emilys',
        password: 'emilyspass',
      );

      // Assert
      expect(result.isSuccess, isTrue);
      expect(result.data?.username, equals('emilys'));
      verify(() => mockRemoteDataSource.login(username: 'emilys', password: 'emilyspass')).called(1);
      verify(() => mockLocalDataSource.saveUserSession(any())).called(1);
    });

    test('should return AuthFailure when credentials are wrong (AuthException)', () async {
      // Arrange
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(() => mockRemoteDataSource.login(
            username: 'emilys',
            password: 'wrongpassword',
          )).thenThrow(const AuthException(message: 'Invalid credentials', statusCode: 400));

      // Act
      final result = await repository.login(
        username: 'emilys',
        password: 'wrongpassword',
      );

      // Assert
      expect(result.isError, isTrue);
      expect(result.failure, isA<AuthFailure>());
      expect(result.failure?.message, equals('Invalid credentials'));
      verifyNever(() => mockLocalDataSource.saveUserSession(any()));
    });

    test('should return NetworkFailure when device has no connection', () async {
      // Arrange
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);

      // Act
      final result = await repository.login(
        username: 'emilys',
        password: 'emilyspass',
      );

      // Assert
      expect(result.isError, isTrue);
      expect(result.failure, isA<NetworkFailure>());
      verifyNever(() => mockRemoteDataSource.login(username: any(named: 'username'), password: any(named: 'password')));
    });
  });

  group('AuthRepositoryImpl - logout', () {
    test('should clear local session storage on logout', () async {
      // Arrange
      when(() => mockLocalDataSource.clearSession()).thenAnswer((_) async => {});

      // Act
      final result = await repository.logout();

      // Assert
      expect(result.isSuccess, isTrue);
      verify(() => mockLocalDataSource.clearSession()).called(1);
    });
  });

  group('AuthRepositoryImpl - getCurrentUser', () {
    test('should return cached user when offline', () async {
      // Arrange
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);
      when(() => mockLocalDataSource.getLastUserSession()).thenReturn(tUserModel);

      // Act
      final result = await repository.getCurrentUser();

      // Assert
      expect(result.isSuccess, isTrue);
      expect(result.data?.id, equals(1));
      verify(() => mockLocalDataSource.getLastUserSession()).called(1);
    });
  });
}
