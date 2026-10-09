import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../models/product_model.dart';

abstract class ProductRemoteDataSource {
  Future<List<ProductModel>> getProducts({int limit = 30, int skip = 0});
  Future<List<ProductModel>> searchProducts(String query);
  Future<List<ProductModel>> getProductsByCategory(String category);
  Future<ProductModel> getProductById(int id);
}

class ProductRemoteDataSourceImpl implements ProductRemoteDataSource {
  final ApiClient _client;

  ProductRemoteDataSourceImpl({required ApiClient client}) : _client = client;

  @override
  Future<List<ProductModel>> getProducts({int limit = 30, int skip = 0}) async {
    final response = await _client.get(
      ApiConstants.products,
      queryParameters: {'limit': limit, 'skip': skip},
    );

    final productsRaw = response['products'] as List? ?? [];
    return productsRaw
        .map((p) => ProductModel.fromJson(Map<String, dynamic>.from(p as Map)))
        .toList();
  }

  @override
  Future<List<ProductModel>> searchProducts(String query) async {
    final response = await _client.get(
      ApiConstants.productSearch,
      queryParameters: {'q': query},
    );

    final productsRaw = response['products'] as List? ?? [];
    return productsRaw
        .map((p) => ProductModel.fromJson(Map<String, dynamic>.from(p as Map)))
        .toList();
  }

  @override
  Future<List<ProductModel>> getProductsByCategory(String category) async {
    final response = await _client.get('${ApiConstants.productsByCategory}/$category');

    final productsRaw = response['products'] as List? ?? [];
    return productsRaw
        .map((p) => ProductModel.fromJson(Map<String, dynamic>.from(p as Map)))
        .toList();
  }

  @override
  Future<ProductModel> getProductById(int id) async {
    final response = await _client.get('${ApiConstants.products}/$id');
    return ProductModel.fromJson(Map<String, dynamic>.from(response as Map));
  }
}
