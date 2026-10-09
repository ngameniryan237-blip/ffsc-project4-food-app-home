import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../models/recipe_model.dart';

abstract class RecipeRemoteDataSource {
  Future<List<RecipeModel>> getRecipes({int limit = 30, int skip = 0});
  Future<List<RecipeModel>> searchRecipes(String query);
  Future<List<RecipeModel>> getRecipesByMealType(String mealType);
  Future<RecipeModel> getRecipeById(int id);
}

class RecipeRemoteDataSourceImpl implements RecipeRemoteDataSource {
  final ApiClient _client;

  RecipeRemoteDataSourceImpl({required ApiClient client}) : _client = client;

  @override
  Future<List<RecipeModel>> getRecipes({int limit = 30, int skip = 0}) async {
    final response = await _client.get(
      ApiConstants.recipes,
      queryParameters: {'limit': limit, 'skip': skip},
    );

    final recipesRaw = response['recipes'] as List? ?? [];
    return recipesRaw
        .map((r) => RecipeModel.fromJson(Map<String, dynamic>.from(r as Map)))
        .toList();
  }

  @override
  Future<List<RecipeModel>> searchRecipes(String query) async {
    final response = await _client.get(
      ApiConstants.recipeSearch,
      queryParameters: {'q': query},
    );

    final recipesRaw = response['recipes'] as List? ?? [];
    return recipesRaw
        .map((r) => RecipeModel.fromJson(Map<String, dynamic>.from(r as Map)))
        .toList();
  }

  @override
  Future<List<RecipeModel>> getRecipesByMealType(String mealType) async {
    final response = await _client.get('${ApiConstants.recipeMealType}/$mealType');

    final recipesRaw = response['recipes'] as List? ?? [];
    return recipesRaw
        .map((r) => RecipeModel.fromJson(Map<String, dynamic>.from(r as Map)))
        .toList();
  }

  @override
  Future<RecipeModel> getRecipeById(int id) async {
    final response = await _client.get('${ApiConstants.recipes}/$id');
    return RecipeModel.fromJson(Map<String, dynamic>.from(response as Map));
  }
}
