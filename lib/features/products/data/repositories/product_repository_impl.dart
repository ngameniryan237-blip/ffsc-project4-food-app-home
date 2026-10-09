import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../datasources/product_local_data_source.dart';
import '../datasources/product_remote_data_source.dart';

class ProductRepositoryImpl implements ProductRepository {
  final ProductRemoteDataSource _remoteDataSource;
  final ProductLocalDataSource _localDataSource;
  final NetworkInfo _networkInfo;

  ProductRepositoryImpl({
    required ProductRemoteDataSource remoteDataSource,
    required ProductLocalDataSource localDataSource,
    required NetworkInfo networkInfo,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource,
        _networkInfo = networkInfo;

  @override
  DateTime? getLastCachedTimestamp() => _localDataSource.getLastCachedTimestamp();

  @override
  Future<Result<List<Product>>> getProducts({
    bool forceRefresh = false,
    int limit = 30,
    int skip = 0,
  }) async {
    final isConnected = await _networkInfo.isConnected;

    if (isConnected) {
      try {
        final remoteProducts = await _remoteDataSource.getProducts(limit: limit, skip: skip);
        if (skip == 0) {
          await _localDataSource.cacheProducts(remoteProducts);
        }
        return Result.success(remoteProducts);
      } catch (e) {
        // Fallback to cache if remote call encounters an issue
        final cached = _localDataSource.getCachedProducts();
        if (cached != null && cached.isNotEmpty) {
          return Result.success(cached);
        }
        if (e is ServerException) {
          return Result.error(ServerFailure(e.message, statusCode: e.statusCode));
        }
        return Result.error(ServerFailure(e.toString()));
      }
    } else {
      // Offline mode
      final cached = _localDataSource.getCachedProducts();
      if (cached != null && cached.isNotEmpty) {
        return Result.success(cached);
      }
      return Result.error(const NetworkFailure('You are offline and no cached products are available.'));
    }
  }

  @override
  Future<Result<List<Product>>> searchProducts(String query) async {
    if (query.trim().isEmpty) {
      return getProducts();
    }

    final isConnected = await _networkInfo.isConnected;
    if (isConnected) {
      try {
        final products = await _remoteDataSource.searchProducts(query);
        return Result.success(products);
      } catch (e) {
        return _searchInCache(query);
      }
    } else {
      return _searchInCache(query);
    }
  }

  Result<List<Product>> _searchInCache(String query) {
    final cached = _localDataSource.getCachedProducts();
    if (cached != null && cached.isNotEmpty) {
      final filtered = cached
          .where((p) =>
              p.title.toLowerCase().contains(query.toLowerCase()) ||
              p.description.toLowerCase().contains(query.toLowerCase()) ||
              p.category.toLowerCase().contains(query.toLowerCase()) ||
              p.brand.toLowerCase().contains(query.toLowerCase()))
          .toList();
      return Result.success(filtered);
    }
    return Result.error(const NetworkFailure('Offline: cannot search without cache.'));
  }

  @override
  Future<Result<List<Product>>> getProductsByCategory(String category) async {
    final isConnected = await _networkInfo.isConnected;
    if (isConnected) {
      try {
        final products = await _remoteDataSource.getProductsByCategory(category);
        return Result.success(products);
      } catch (e) {
        return _filterCategoryInCache(category);
      }
    } else {
      return _filterCategoryInCache(category);
    }
  }

  Result<List<Product>> _filterCategoryInCache(String category) {
    final cached = _localDataSource.getCachedProducts();
    if (cached != null && cached.isNotEmpty) {
      final filtered = cached
          .where((p) => p.category.toLowerCase() == category.toLowerCase())
          .toList();
      return Result.success(filtered);
    }
    return Result.error(const NetworkFailure('Offline: category not cached.'));
  }

  @override
  Future<Result<Product>> getProductById(int id) async {
    final isConnected = await _networkInfo.isConnected;
    if (isConnected) {
      try {
        final product = await _remoteDataSource.getProductById(id);
        return Result.success(product);
      } catch (e) {
        return _findByIdInCache(id);
      }
    } else {
      return _findByIdInCache(id);
    }
  }

  Result<Product> _findByIdInCache(int id) {
    final cached = _localDataSource.getCachedProducts();
    if (cached != null) {
      try {
        final found = cached.firstWhere((p) => p.id == id);
        return Result.success(found);
      } catch (_) {
        return Result.error(const CacheFailure('Product not found in offline cache.'));
      }
    }
    return Result.error(const NetworkFailure('Product unavailable offline.'));
  }
}
