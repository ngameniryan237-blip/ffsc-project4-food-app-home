import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../models/post_model.dart';

abstract class PostRemoteDataSource {
  Future<List<PostModel>> getPosts({int limit = 30, int skip = 0});
  Future<List<PostModel>> searchPosts(String query);
  Future<List<PostModel>> getPostsByTag(String tag);
  Future<List<PostCommentModel>> getCommentsForPost(int postId);
}

class PostRemoteDataSourceImpl implements PostRemoteDataSource {
  final ApiClient _client;

  PostRemoteDataSourceImpl({required ApiClient client}) : _client = client;

  @override
  Future<List<PostModel>> getPosts({int limit = 30, int skip = 0}) async {
    final response = await _client.get(
      ApiConstants.posts,
      queryParameters: {'limit': limit, 'skip': skip},
    );

    final postsRaw = response['posts'] as List? ?? [];
    return postsRaw
        .map((p) => PostModel.fromJson(Map<String, dynamic>.from(p as Map)))
        .toList();
  }

  @override
  Future<List<PostModel>> searchPosts(String query) async {
    final response = await _client.get(
      ApiConstants.postSearch,
      queryParameters: {'q': query},
    );

    final postsRaw = response['posts'] as List? ?? [];
    return postsRaw
        .map((p) => PostModel.fromJson(Map<String, dynamic>.from(p as Map)))
        .toList();
  }

  @override
  Future<List<PostModel>> getPostsByTag(String tag) async {
    final response = await _client.get('${ApiConstants.postTag}/$tag');

    final postsRaw = response['posts'] as List? ?? [];
    return postsRaw
        .map((p) => PostModel.fromJson(Map<String, dynamic>.from(p as Map)))
        .toList();
  }

  @override
  Future<List<PostCommentModel>> getCommentsForPost(int postId) async {
    final response = await _client.get('${ApiConstants.postComments}/$postId');

    final commentsRaw = response['comments'] as List? ?? [];
    return commentsRaw
        .map((c) => PostCommentModel.fromJson(Map<String, dynamic>.from(c as Map)))
        .toList();
  }
}
