import 'package:flutter/foundation.dart';
import '../../domain/entities/recipe.dart';
import '../../domain/repositories/recipe_repository.dart';

enum RecipeState { initial, loading, loaded, error }

class RecipeController extends ChangeNotifier {
  final RecipeRepository _repository;

  RecipeState _state = RecipeState.initial;
  List<Recipe> _recipes = [];
  String? _errorMessage;
  String _selectedMealType = 'all';
  String _searchQuery = '';

  RecipeController({required RecipeRepository repository}) : _repository = repository;

  RecipeState get state => _state;
  List<Recipe> get recipes => _recipes;
  String? get errorMessage => _errorMessage;
  String get selectedMealType => _selectedMealType;
  String get searchQuery => _searchQuery;
  bool get isLoading => _state == RecipeState.loading;

  Future<void> fetchRecipes({bool forceRefresh = false}) async {
    _state = RecipeState.loading;
    _errorMessage = null;
    notifyListeners();

    final result = await _repository.getRecipes(forceRefresh: forceRefresh);
    result.when(
      success: (data) {
        _recipes = data;
        _state = RecipeState.loaded;
        notifyListeners();
      },
      error: (failure) {
        _errorMessage = failure.message;
        _state = _recipes.isNotEmpty ? RecipeState.loaded : RecipeState.error;
        notifyListeners();
      },
    );
  }

  Future<void> searchRecipes(String query) async {
    _searchQuery = query;
    _selectedMealType = 'all';
    _state = RecipeState.loading;
    notifyListeners();

    final result = await _repository.searchRecipes(query);
    result.when(
      success: (data) {
        _recipes = data;
        _state = RecipeState.loaded;
        notifyListeners();
      },
      error: (failure) {
        _errorMessage = failure.message;
        _state = _recipes.isNotEmpty ? RecipeState.loaded : RecipeState.error;
        notifyListeners();
      },
    );
  }

  Future<void> filterByMealType(String mealType) async {
    _selectedMealType = mealType;
    _searchQuery = '';
    _state = RecipeState.loading;
    notifyListeners();

    if (mealType == 'all') {
      await fetchRecipes(forceRefresh: false);
      return;
    }

    final result = await _repository.getRecipesByMealType(mealType);
    result.when(
      success: (data) {
        _recipes = data;
        _state = RecipeState.loaded;
        notifyListeners();
      },
      error: (failure) {
        _errorMessage = failure.message;
        _state = _recipes.isNotEmpty ? RecipeState.loaded : RecipeState.error;
        notifyListeners();
      },
    );
  }
}
