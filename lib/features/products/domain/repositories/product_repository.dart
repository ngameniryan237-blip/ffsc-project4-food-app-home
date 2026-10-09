import '../../../../core/utils/result.dart';
import '../entities/product.dart';

abstract class ProductRepository {
  Future<Result<List<Product>>> getProducts({bool forceRefresh = false, int limit = 30, int skip = 0});
  Future<Result<List<Product>>> searchProducts(String query);
  Future<Result<List<Product>>> getProductsByCategory(String category);
  Future<Result<Product>> getProductById(int id);
  DateTime? getLastCachedTimestamp();
}
