import '../../../../core/utils/result.dart';
import '../entities/recipe.dart';

abstract class RecipeRepository {
  Future<Result<List<Recipe>>> getRecipes({bool forceRefresh = false, int limit = 30, int skip = 0});
  Future<Result<List<Recipe>>> searchRecipes(String query);
  Future<Result<List<Recipe>>> getRecipesByMealType(String mealType);
  Future<Result<Recipe>> getRecipeById(int id);
  DateTime? getLastCachedTimestamp();
}
