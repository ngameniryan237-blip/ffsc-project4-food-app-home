import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/recipe.dart';
import '../../domain/repositories/recipe_repository.dart';
import '../datasources/recipe_local_data_source.dart';
import '../datasources/recipe_remote_data_source.dart';

class RecipeRepositoryImpl implements RecipeRepository {
  final RecipeRemoteDataSource _remoteDataSource;
  final RecipeLocalDataSource _localDataSource;
  final NetworkInfo _networkInfo;

  RecipeRepositoryImpl({
    required RecipeRemoteDataSource remoteDataSource,
    required RecipeLocalDataSource localDataSource,
    required NetworkInfo networkInfo,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource,
        _networkInfo = networkInfo;

  @override
  DateTime? getLastCachedTimestamp() => _localDataSource.getLastCachedTimestamp();

  @override
  Future<Result<List<Recipe>>> getRecipes({
    bool forceRefresh = false,
    int limit = 30,
    int skip = 0,
  }) async {
    final isConnected = await _networkInfo.isConnected;

    if (isConnected) {
      try {
        final remoteRecipes = await _remoteDataSource.getRecipes(limit: limit, skip: skip);
        if (skip == 0) {
          await _localDataSource.cacheRecipes(remoteRecipes);
        }
        return Result.success(remoteRecipes);
      } catch (e) {
        final cached = _localDataSource.getCachedRecipes();
        if (cached != null && cached.isNotEmpty) {
          return Result.success(cached);
        }
        if (e is ServerException) {
          return Result.error(ServerFailure(e.message, statusCode: e.statusCode));
        }
        return Result.error(ServerFailure(e.toString()));
      }
    } else {
      final cached = _localDataSource.getCachedRecipes();
      if (cached != null && cached.isNotEmpty) {
        return Result.success(cached);
      }
      return Result.error(const NetworkFailure('You are offline and no cached recipes are available.'));
    }
  }

  @override
  Future<Result<List<Recipe>>> searchRecipes(String query) async {
    if (query.trim().isEmpty) {
      return getRecipes();
    }

    final isConnected = await _networkInfo.isConnected;
    if (isConnected) {
      try {
        final recipes = await _remoteDataSource.searchRecipes(query);
        return Result.success(recipes);
      } catch (e) {
        return _searchInCache(query);
      }
    } else {
      return _searchInCache(query);
    }
  }

  Result<List<Recipe>> _searchInCache(String query) {
    final cached = _localDataSource.getCachedRecipes();
    if (cached != null && cached.isNotEmpty) {
      final filtered = cached
          .where((r) =>
              r.name.toLowerCase().contains(query.toLowerCase()) ||
              r.cuisine.toLowerCase().contains(query.toLowerCase()) ||
              r.tags.any((t) => t.toLowerCase().contains(query.toLowerCase())))
          .toList();
      return Result.success(filtered);
    }
    return Result.error(const NetworkFailure('Offline: cannot search recipes without cache.'));
  }

  @override
  Future<Result<List<Recipe>>> getRecipesByMealType(String mealType) async {
    final isConnected = await _networkInfo.isConnected;
    if (isConnected) {
      try {
        final recipes = await _remoteDataSource.getRecipesByMealType(mealType);
        return Result.success(recipes);
      } catch (e) {
        return _filterMealTypeInCache(mealType);
      }
    } else {
      return _filterMealTypeInCache(mealType);
    }
  }

  Result<List<Recipe>> _filterMealTypeInCache(String mealType) {
    final cached = _localDataSource.getCachedRecipes();
    if (cached != null && cached.isNotEmpty) {
      final filtered = cached
          .where((r) => r.mealType.any((m) => m.toLowerCase() == mealType.toLowerCase()))
          .toList();
      return Result.success(filtered);
    }
    return Result.error(const NetworkFailure('Offline: meal type not cached.'));
  }

  @override
  Future<Result<Recipe>> getRecipeById(int id) async {
    final isConnected = await _networkInfo.isConnected;
    if (isConnected) {
      try {
        final recipe = await _remoteDataSource.getRecipeById(id);
        return Result.success(recipe);
      } catch (e) {
        final cached = _localDataSource.getCachedRecipes();
        if (cached != null) {
          try {
            final found = cached.firstWhere((r) => r.id == id);
            return Result.success(found);
          } catch (_) {}
        }
        return Result.error(ServerFailure(e.toString()));
      }
    } else {
      final cached = _localDataSource.getCachedRecipes();
      if (cached != null) {
        try {
          final found = cached.firstWhere((r) => r.id == id);
          return Result.success(found);
        } catch (_) {}
      }
      return Result.error(const NetworkFailure('Recipe unavailable offline.'));
    }
  }
}
