import '../../../../core/storage/hive_storage.dart';
import '../models/recipe_model.dart';

abstract class RecipeLocalDataSource {
  Future<void> cacheRecipes(List<RecipeModel> recipes);
  List<RecipeModel>? getCachedRecipes();
  DateTime? getLastCachedTimestamp();
}

class RecipeLocalDataSourceImpl implements RecipeLocalDataSource {
  final HiveStorageService _storage;

  RecipeLocalDataSourceImpl({HiveStorageService? storage})
      : _storage = storage ?? HiveStorageService();

  @override
  Future<void> cacheRecipes(List<RecipeModel> recipes) async {
    final listJson = recipes.map((r) => r.toJson()).toList();
    await _storage.cacheRecipes(listJson);
  }

  @override
  List<RecipeModel>? getCachedRecipes() {
    final cached = _storage.getCachedRecipes();
    if (cached == null) return null;
    return cached.map((json) => RecipeModel.fromJson(json)).toList();
  }

  @override
  DateTime? getLastCachedTimestamp() {
    return _storage.getRecipesCacheTimestamp();
  }
}
