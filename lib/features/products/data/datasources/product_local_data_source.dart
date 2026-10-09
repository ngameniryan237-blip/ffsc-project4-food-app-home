import '../../../../core/storage/hive_storage.dart';
import '../models/product_model.dart';

abstract class ProductLocalDataSource {
  Future<void> cacheProducts(List<ProductModel> products);
  List<ProductModel>? getCachedProducts();
  DateTime? getLastCachedTimestamp();
}

class ProductLocalDataSourceImpl implements ProductLocalDataSource {
  final HiveStorageService _storage;

  ProductLocalDataSourceImpl({HiveStorageService? storage})
      : _storage = storage ?? HiveStorageService();

  @override
  Future<void> cacheProducts(List<ProductModel> products) async {
    final listJson = products.map((p) => p.toJson()).toList();
    await _storage.cacheProducts(listJson);
  }

  @override
  List<ProductModel>? getCachedProducts() {
    final cached = _storage.getCachedProducts();
    if (cached == null) return null;
    return cached.map((json) => ProductModel.fromJson(json)).toList();
  }

  @override
  DateTime? getLastCachedTimestamp() {
    return _storage.getProductsCacheTimestamp();
  }
}
