import '../../domain/entities/post.dart';

class PostCommentModel extends PostComment {
  const PostCommentModel({
    required super.id,
    required super.body,
    required super.postId,
    required super.userFullName,
    required super.username,
  });

  factory PostCommentModel.fromJson(Map<String, dynamic> json) {
    String userFullName = 'Anonymous';
    String username = 'anonymous';

    if (json['user'] is Map) {
      final userMap = json['user'] as Map;
      userFullName = userMap['fullName']?.toString() ?? 'Anonymous';
      username = userMap['username']?.toString() ?? 'anonymous';
    }

    return PostCommentModel(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      body: json['body']?.toString() ?? '',
      postId: json['postId'] is int ? json['postId'] as int : int.tryParse(json['postId']?.toString() ?? '0') ?? 0,
      userFullName: userFullName,
      username: username,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'body': body,
      'postId': postId,
      'user': {
        'fullName': userFullName,
        'username': username,
      },
    };
  }
}

class PostModel extends Post {
  const PostModel({
    required super.id,
    required super.title,
    required super.body,
    required super.tags,
    required super.likes,
    required super.dislikes,
    required super.views,
    required super.userId,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    var tagsList = <String>[];
    if (json['tags'] is List) {
      tagsList = (json['tags'] as List).map((e) => e.toString()).toList();
    }

    int likesCount = 0;
    int dislikesCount = 0;

    if (json['reactions'] is Map) {
      final reactionsMap = json['reactions'] as Map;
      likesCount = reactionsMap['likes'] is int ? reactionsMap['likes'] as int : int.tryParse(reactionsMap['likes']?.toString() ?? '0') ?? 0;
      dislikesCount = reactionsMap['dislikes'] is int ? reactionsMap['dislikes'] as int : int.tryParse(reactionsMap['dislikes']?.toString() ?? '0') ?? 0;
    } else if (json['reactions'] is int) {
      likesCount = json['reactions'] as int;
    }

    return PostModel(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      tags: tagsList,
      likes: likesCount,
      dislikes: dislikesCount,
      views: json['views'] is int ? json['views'] as int : int.tryParse(json['views']?.toString() ?? '0') ?? 0,
      userId: json['userId'] is int ? json['userId'] as int : int.tryParse(json['userId']?.toString() ?? '1') ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'tags': tags,
      'reactions': {
        'likes': likes,
        'dislikes': dislikes,
      },
      'views': views,
      'userId': userId,
    };
  }
}
