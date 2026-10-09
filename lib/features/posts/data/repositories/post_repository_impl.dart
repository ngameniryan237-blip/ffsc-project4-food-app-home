import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/post.dart';
import '../../domain/repositories/post_repository.dart';
import '../datasources/post_local_data_source.dart';
import '../datasources/post_remote_data_source.dart';

class PostRepositoryImpl implements PostRepository {
  final PostRemoteDataSource _remoteDataSource;
  final PostLocalDataSource _localDataSource;
  final NetworkInfo _networkInfo;

  PostRepositoryImpl({
    required PostRemoteDataSource remoteDataSource,
    required PostLocalDataSource localDataSource,
    required NetworkInfo networkInfo,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource,
        _networkInfo = networkInfo;

  @override
  DateTime? getLastCachedTimestamp() => _localDataSource.getLastCachedTimestamp();

  @override
  Future<Result<List<Post>>> getPosts({
    bool forceRefresh = false,
    int limit = 30,
    int skip = 0,
  }) async {
    final isConnected = await _networkInfo.isConnected;

    if (isConnected) {
      try {
        final remotePosts = await _remoteDataSource.getPosts(limit: limit, skip: skip);
        if (skip == 0) {
          await _localDataSource.cachePosts(remotePosts);
        }
        return Result.success(remotePosts);
      } catch (e) {
        final cached = _localDataSource.getCachedPosts();
        if (cached != null && cached.isNotEmpty) {
          return Result.success(cached);
        }
        if (e is ServerException) {
          return Result.error(ServerFailure(e.message, statusCode: e.statusCode));
        }
        return Result.error(ServerFailure(e.toString()));
      }
    } else {
      final cached = _localDataSource.getCachedPosts();
      if (cached != null && cached.isNotEmpty) {
        return Result.success(cached);
      }
      return Result.error(const NetworkFailure('You are offline and no cached community posts are available.'));
    }
  }

  @override
  Future<Result<List<Post>>> searchPosts(String query) async {
    if (query.trim().isEmpty) {
      return getPosts();
    }

    final isConnected = await _networkInfo.isConnected;
    if (isConnected) {
      try {
        final posts = await _remoteDataSource.searchPosts(query);
        return Result.success(posts);
      } catch (e) {
        return _searchInCache(query);
      }
    } else {
      return _searchInCache(query);
    }
  }

  Result<List<Post>> _searchInCache(String query) {
    final cached = _localDataSource.getCachedPosts();
    if (cached != null && cached.isNotEmpty) {
      final filtered = cached
          .where((p) =>
              p.title.toLowerCase().contains(query.toLowerCase()) ||
              p.body.toLowerCase().contains(query.toLowerCase()) ||
              p.tags.any((t) => t.toLowerCase().contains(query.toLowerCase())))
          .toList();
      return Result.success(filtered);
    }
    return Result.error(const NetworkFailure('Offline: cannot search posts without cache.'));
  }

  @override
  Future<Result<List<Post>>> getPostsByTag(String tag) async {
    final isConnected = await _networkInfo.isConnected;
    if (isConnected) {
      try {
        final posts = await _remoteDataSource.getPostsByTag(tag);
        return Result.success(posts);
      } catch (e) {
        return _filterTagInCache(tag);
      }
    } else {
      return _filterTagInCache(tag);
    }
  }

  Result<List<Post>> _filterTagInCache(String tag) {
    final cached = _localDataSource.getCachedPosts();
    if (cached != null && cached.isNotEmpty) {
      final filtered = cached
          .where((p) => p.tags.any((t) => t.toLowerCase() == tag.toLowerCase()))
          .toList();
      return Result.success(filtered);
    }
    return Result.error(const NetworkFailure('Offline: tag not cached.'));
  }

  @override
  Future<Result<List<PostComment>>> getCommentsForPost(int postId) async {
    final isConnected = await _networkInfo.isConnected;
    if (isConnected) {
      try {
        final comments = await _remoteDataSource.getCommentsForPost(postId);
        return Result.success(comments);
      } catch (e) {
        return Result.error(ServerFailure(e.toString()));
      }
    } else {
      return Result.error(const NetworkFailure('Comments require an active internet connection.'));
    }
  }
}
