class PostComment {
  final int id;
  final String body;
  final int postId;
  final String userFullName;
  final String username;

  const PostComment({
    required this.id,
    required this.body,
    required this.postId,
    required this.userFullName,
    required this.username,
  });
}

class Post {
  final int id;
  final String title;
  final String body;
  final List<String> tags;
  final int likes;
  final int dislikes;
  final int views;
  final int userId;

  const Post({
    required this.id,
    required this.title,
    required this.body,
    required this.tags,
    required this.likes,
    required this.dislikes,
    required this.views,
    required this.userId,
  });
}
