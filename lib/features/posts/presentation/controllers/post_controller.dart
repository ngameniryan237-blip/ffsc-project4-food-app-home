import 'package:flutter/foundation.dart';
import '../../domain/entities/post.dart';
import '../../domain/repositories/post_repository.dart';

enum PostState { initial, loading, loaded, error }

class PostController extends ChangeNotifier {
  final PostRepository _repository;

  PostState _state = PostState.initial;
  List<Post> _posts = [];
  String? _errorMessage;
  String _selectedTag = 'all';
  String _searchQuery = '';
  final Map<int, List<PostComment>> _commentsMap = {};
  final Map<int, bool> _loadingCommentsMap = {};
  final Set<int> _likedPostIds = {};

  PostController({required PostRepository repository}) : _repository = repository;

  PostState get state => _state;
  List<Post> get posts => _posts;
  String? get errorMessage => _errorMessage;
  String get selectedTag => _selectedTag;
  String get searchQuery => _searchQuery;
  bool get isLoading => _state == PostState.loading;

  bool isLiked(int postId) => _likedPostIds.contains(postId);
  List<PostComment>? getComments(int postId) => _commentsMap[postId];
  bool isLoadingComments(int postId) => _loadingCommentsMap[postId] ?? false;

  void toggleLike(int postId) {
    if (_likedPostIds.contains(postId)) {
      _likedPostIds.remove(postId);
    } else {
      _likedPostIds.add(postId);
    }
    notifyListeners();
  }

  Future<void> fetchPosts({bool forceRefresh = false}) async {
    _state = PostState.loading;
    _errorMessage = null;
    notifyListeners();

    final result = await _repository.getPosts(forceRefresh: forceRefresh);
    result.when(
      success: (data) {
        _posts = data;
        _state = PostState.loaded;
        notifyListeners();
      },
      error: (failure) {
        _errorMessage = failure.message;
        _state = _posts.isNotEmpty ? PostState.loaded : PostState.error;
        notifyListeners();
      },
    );
  }

  Future<void> searchPosts(String query) async {
    _searchQuery = query;
    _selectedTag = 'all';
    _state = PostState.loading;
    notifyListeners();

    final result = await _repository.searchPosts(query);
    result.when(
      success: (data) {
        _posts = data;
        _state = PostState.loaded;
        notifyListeners();
      },
      error: (failure) {
        _errorMessage = failure.message;
        _state = _posts.isNotEmpty ? PostState.loaded : PostState.error;
        notifyListeners();
      },
    );
  }

  Future<void> filterByTag(String tag) async {
    _selectedTag = tag;
    _searchQuery = '';
    _state = PostState.loading;
    notifyListeners();

    if (tag == 'all') {
      await fetchPosts(forceRefresh: false);
      return;
    }

    final result = await _repository.getPostsByTag(tag);
    result.when(
      success: (data) {
        _posts = data;
        _state = PostState.loaded;
        notifyListeners();
      },
      error: (failure) {
        _errorMessage = failure.message;
        _state = _posts.isNotEmpty ? PostState.loaded : PostState.error;
        notifyListeners();
      },
    );
  }

  Future<void> loadComments(int postId) async {
    if (_commentsMap.containsKey(postId)) return;

    _loadingCommentsMap[postId] = true;
    notifyListeners();

    final result = await _repository.getCommentsForPost(postId);
    result.when(
      success: (comments) {
        _commentsMap[postId] = comments;
        _loadingCommentsMap[postId] = false;
        notifyListeners();
      },
      error: (failure) {
        _loadingCommentsMap[postId] = false;
        notifyListeners();
      },
    );
  }
}
