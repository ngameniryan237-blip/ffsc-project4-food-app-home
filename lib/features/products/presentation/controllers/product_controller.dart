import 'package:flutter/foundation.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';

enum ProductState { initial, loading, loaded, error }

class ProductController extends ChangeNotifier {
  final ProductRepository _repository;

  ProductState _state = ProductState.initial;
  List<Product> _products = [];
  String? _errorMessage;
  String _selectedCategory = 'all';
  String _searchQuery = '';
  DateTime? _lastSyncTime;

  ProductController({required ProductRepository repository})
      : _repository = repository;

  ProductState get state => _state;
  List<Product> get products => _products;
  String? get errorMessage => _errorMessage;
  String get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;
  DateTime? get lastSyncTime => _lastSyncTime ?? _repository.getLastCachedTimestamp();
  bool get isLoading => _state == ProductState.loading;

  Future<void> fetchProducts({bool forceRefresh = false}) async {
    _state = ProductState.loading;
    _errorMessage = null;
    notifyListeners();

    final result = await _repository.getProducts(forceRefresh: forceRefresh);
    result.when(
      success: (data) {
        _products = data;
        _lastSyncTime = DateTime.now();
        _state = ProductState.loaded;
        notifyListeners();
      },
      error: (failure) {
        _errorMessage = failure.message;
        _state = _products.isNotEmpty ? ProductState.loaded : ProductState.error;
        notifyListeners();
      },
    );
  }

  Future<void> search(String query) async {
    _searchQuery = query;
    _selectedCategory = 'all';
    _state = ProductState.loading;
    notifyListeners();

    final result = await _repository.searchProducts(query);
    result.when(
      success: (data) {
        _products = data;
        _state = ProductState.loaded;
        notifyListeners();
      },
      error: (failure) {
        _errorMessage = failure.message;
        _state = _products.isNotEmpty ? ProductState.loaded : ProductState.error;
        notifyListeners();
      },
    );
  }

  Future<void> filterByCategory(String category) async {
    _selectedCategory = category;
    _searchQuery = '';
    _state = ProductState.loading;
    notifyListeners();

    if (category == 'all') {
      await fetchProducts(forceRefresh: false);
      return;
    }

    final result = await _repository.getProductsByCategory(category);
    result.when(
      success: (data) {
        _products = data;
        _state = ProductState.loaded;
        notifyListeners();
      },
      error: (failure) {
        _errorMessage = failure.message;
        _state = _products.isNotEmpty ? ProductState.loaded : ProductState.error;
        notifyListeners();
      },
    );
  }
}
