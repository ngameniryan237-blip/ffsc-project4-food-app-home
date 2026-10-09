import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_connected_app/core/error/exceptions.dart';
import 'package:flutter_connected_app/core/network/network_info.dart';
import 'package:flutter_connected_app/features/posts/data/datasources/post_local_data_source.dart';
import 'package:flutter_connected_app/features/posts/data/datasources/post_remote_data_source.dart';
import 'package:flutter_connected_app/features/posts/data/models/post_model.dart';
import 'package:flutter_connected_app/features/posts/data/repositories/post_repository_impl.dart';

class MockPostRemoteDataSource extends Mock implements PostRemoteDataSource {}
class MockPostLocalDataSource extends Mock implements PostLocalDataSource {}
class MockNetworkInfo extends Mock implements NetworkInfo {}

void main() {
  late PostRepositoryImpl repository;
  late MockPostRemoteDataSource mockRemoteDataSource;
  late MockPostLocalDataSource mockLocalDataSource;
  late MockNetworkInfo mockNetworkInfo;

  const tPostModel = PostModel(
    id: 1,
    title: 'His mother had always taught him',
    body: 'His mother had always taught him not to ever think of himself as better than others.',
    tags: ['history', 'american', 'crime'],
    likes: 192,
    dislikes: 25,
    views: 305,
    userId: 121,
  );

  final tPostsList = [tPostModel];

  setUpAll(() {
    registerFallbackValue(tPostsList);
  });

  setUp(() {
    mockRemoteDataSource = MockPostRemoteDataSource();
    mockLocalDataSource = MockPostLocalDataSource();
    mockNetworkInfo = MockNetworkInfo();

    when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);

    repository = PostRepositoryImpl(
      remoteDataSource: mockRemoteDataSource,
      localDataSource: mockLocalDataSource,
      networkInfo: mockNetworkInfo,
    );
  });

  group('PostRepositoryImpl - getPosts', () {
    test('should fetch posts from remote data source and cache them when online', () async {
      // Arrange
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(() => mockRemoteDataSource.getPosts(limit: any(named: 'limit'), skip: any(named: 'skip')))
          .thenAnswer((_) async => tPostsList);
      when(() => mockLocalDataSource.cachePosts(any())).thenAnswer((_) async => {});

      // Act
      final result = await repository.getPosts();

      // Assert
      expect(result.isSuccess, isTrue);
      expect(result.data, equals(tPostsList));
      verify(() => mockRemoteDataSource.getPosts(limit: 30, skip: 0)).called(1);
      verify(() => mockLocalDataSource.cachePosts(tPostsList)).called(1);
    });

    test('should return cached posts when remote call fails', () async {
      // Arrange
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(() => mockRemoteDataSource.getPosts(limit: any(named: 'limit'), skip: any(named: 'skip')))
          .thenThrow(const ServerException(message: 'Server error'));
      when(() => mockLocalDataSource.getCachedPosts()).thenReturn(tPostsList);

      // Act
      final result = await repository.getPosts();

      // Assert
      expect(result.isSuccess, isTrue);
      expect(result.data, equals(tPostsList));
      verify(() => mockLocalDataSource.getCachedPosts()).called(1);
    });

    test('should return cached posts when offline', () async {
      // Arrange
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);
      when(() => mockLocalDataSource.getCachedPosts()).thenReturn(tPostsList);

      // Act
      final result = await repository.getPosts();

      // Assert
      expect(result.isSuccess, isTrue);
      expect(result.data?.first.id, equals(1));
    });
  });
}
