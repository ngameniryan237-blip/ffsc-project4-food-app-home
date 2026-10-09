import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_connected_app/core/error/exceptions.dart';
import 'package:flutter_connected_app/core/error/failures.dart';
import 'package:flutter_connected_app/core/network/network_info.dart';
import 'package:flutter_connected_app/features/products/data/datasources/product_local_data_source.dart';
import 'package:flutter_connected_app/features/products/data/datasources/product_remote_data_source.dart';
import 'package:flutter_connected_app/features/products/data/models/product_model.dart';
import 'package:flutter_connected_app/features/products/data/repositories/product_repository_impl.dart';

class MockProductRemoteDataSource extends Mock implements ProductRemoteDataSource {}
class MockProductLocalDataSource extends Mock implements ProductLocalDataSource {}
class MockNetworkInfo extends Mock implements NetworkInfo {}

void main() {
  late ProductRepositoryImpl repository;
  late MockProductRemoteDataSource mockRemoteDataSource;
  late MockProductLocalDataSource mockLocalDataSource;
  late MockNetworkInfo mockNetworkInfo;

  const tProductModel = ProductModel(
    id: 1,
    title: 'Essence Mascara Lash Princess',
    description: 'The Essence Mascara Lash Princess is a popular mascara.',
    category: 'beauty',
    price: 9.99,
    discountPercentage: 7.17,
    rating: 4.94,
    stock: 5,
    brand: 'Essence',
    thumbnail: 'https://cdn.dummyjson.com/products/images/beauty/1/thumbnail.png',
    images: ['https://cdn.dummyjson.com/products/images/beauty/1/1.png'],
  );

  final tProductsList = [tProductModel];

  setUpAll(() {
    registerFallbackValue(tProductsList);
  });

  setUp(() {
    mockRemoteDataSource = MockProductRemoteDataSource();
    mockLocalDataSource = MockProductLocalDataSource();
    mockNetworkInfo = MockNetworkInfo();

    when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);

    repository = ProductRepositoryImpl(
      remoteDataSource: mockRemoteDataSource,
      localDataSource: mockLocalDataSource,
      networkInfo: mockNetworkInfo,
    );
  });

  group('ProductRepositoryImpl - getProducts', () {
    test('should return remote data and cache it when connection is available', () async {
      // Arrange
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(() => mockRemoteDataSource.getProducts(limit: any(named: 'limit'), skip: any(named: 'skip')))
          .thenAnswer((_) async => tProductsList);
      when(() => mockLocalDataSource.cacheProducts(any())).thenAnswer((_) async => {});

      // Act
      final result = await repository.getProducts(limit: 30, skip: 0);

      // Assert
      expect(result.isSuccess, isTrue);
      expect(result.data, equals(tProductsList));
      verify(() => mockRemoteDataSource.getProducts(limit: 30, skip: 0)).called(1);
      verify(() => mockLocalDataSource.cacheProducts(tProductsList)).called(1);
    });

    test('should return cached data when remote call fails with ServerException', () async {
      // Arrange
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(() => mockRemoteDataSource.getProducts(limit: any(named: 'limit'), skip: any(named: 'skip')))
          .thenThrow(const ServerException(message: 'Internal server error', statusCode: 500));
      when(() => mockLocalDataSource.getCachedProducts()).thenReturn(tProductsList);

      // Act
      final result = await repository.getProducts();

      // Assert
      expect(result.isSuccess, isTrue);
      expect(result.data, equals(tProductsList));
      verify(() => mockLocalDataSource.getCachedProducts()).called(1);
    });

    test('should return cached data when offline', () async {
      // Arrange
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);
      when(() => mockLocalDataSource.getCachedProducts()).thenReturn(tProductsList);

      // Act
      final result = await repository.getProducts();

      // Assert
      expect(result.isSuccess, isTrue);
      expect(result.data?.length, equals(1));
      verifyNever(() => mockRemoteDataSource.getProducts());
      verify(() => mockLocalDataSource.getCachedProducts()).called(1);
    });

    test('should return NetworkFailure when offline and cache is empty', () async {
      // Arrange
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);
      when(() => mockLocalDataSource.getCachedProducts()).thenReturn(null);

      // Act
      final result = await repository.getProducts();

      // Assert
      expect(result.isError, isTrue);
      expect(result.failure, isA<NetworkFailure>());
    });
  });

  group('ProductRepositoryImpl - searchProducts', () {
    test('should search within offline cache when device is offline', () async {
      // Arrange
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);
      when(() => mockLocalDataSource.getCachedProducts()).thenReturn(tProductsList);

      // Act
      final result = await repository.searchProducts('mascara');

      // Assert
      expect(result.isSuccess, isTrue);
      expect(result.data?.first.title, contains('Mascara'));
    });
  });
}
