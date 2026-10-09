import '../../../../core/storage/hive_storage.dart';
import '../models/post_model.dart';

abstract class PostLocalDataSource {
  Future<void> cachePosts(List<PostModel> posts);
  List<PostModel>? getCachedPosts();
  DateTime? getLastCachedTimestamp();
}

class PostLocalDataSourceImpl implements PostLocalDataSource {
  final HiveStorageService _storage;

  PostLocalDataSourceImpl({HiveStorageService? storage})
      : _storage = storage ?? HiveStorageService();

  @override
  Future<void> cachePosts(List<PostModel> posts) async {
    final listJson = posts.map((p) => p.toJson()).toList();
    await _storage.cachePosts(listJson);
  }

  @override
  List<PostModel>? getCachedPosts() {
    final cached = _storage.getCachedPosts();
    if (cached == null) return null;
    return cached.map((json) => PostModel.fromJson(json)).toList();
  }

  @override
  DateTime? getLastCachedTimestamp() {
    return _storage.getPostsCacheTimestamp();
  }
}
