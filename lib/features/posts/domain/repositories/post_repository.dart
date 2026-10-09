import '../../../../core/utils/result.dart';
import '../entities/post.dart';

abstract class PostRepository {
  Future<Result<List<Post>>> getPosts({bool forceRefresh = false, int limit = 30, int skip = 0});
  Future<Result<List<Post>>> searchPosts(String query);
  Future<Result<List<Post>>> getPostsByTag(String tag);
  Future<Result<List<PostComment>>> getCommentsForPost(int postId);
  DateTime? getLastCachedTimestamp();
}
