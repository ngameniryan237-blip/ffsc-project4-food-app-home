import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../widgets/error_view.dart';
import '../../../../widgets/loading_indicator.dart';
import '../../../../widgets/offline_banner.dart';
import '../../domain/entities/recipe.dart';
import '../controllers/recipe_controller.dart';
import 'recipe_detail_screen.dart';

class RecipeListScreen extends StatefulWidget {
  const RecipeListScreen({super.key});

  @override
  State<RecipeListScreen> createState() => _RecipeListScreenState();
}

class _RecipeListScreenState extends State<RecipeListScreen> {
  final _searchController = TextEditingController();

  static const List<Map<String, String>> mealTypes = [
    {'id': 'all', 'label': 'All Recipes'},
    {'id': 'Dinner', 'label': 'Dinner'},
    {'id': 'Lunch', 'label': 'Lunch'},
    {'id': 'Snack', 'label': 'Snack'},
    {'id': 'Dessert', 'label': 'Dessert'},
    {'id': 'Breakfast', 'label': 'Breakfast'},
    {'id': 'Beverage', 'label': 'Beverage'},
    {'id': 'Appetizer', 'label': 'Appetizer'},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = context.read<RecipeController>();
      if (controller.recipes.isEmpty) {
        controller.fetchRecipes();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<RecipeController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Culinary Discovery', style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(108),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search recipes by name, cuisine, ingredients...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              controller.fetchRecipes();
                            },
                          )
                        : null,
                  ),
                  onSubmitted: (q) => controller.searchRecipes(q),
                  textInputAction: TextInputAction.search,
                ),
              ),
              const SizedBox(height: 6),
              // Meal types list
              SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: mealTypes.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final meal = mealTypes[index];
                    final isSelected = controller.selectedMealType.toLowerCase() == meal['id']!.toLowerCase();

                    return ChoiceChip(
                      label: Text(meal['label']!),
                      selected: isSelected,
                      onSelected: (_) => controller.filterByMealType(meal['id']!),
                      selectedColor: AppTheme.accentColor,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : null,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                      ),
                      backgroundColor: Theme.of(context).cardColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(child: _buildBody(context, controller)),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, RecipeController controller) {
    if (controller.isLoading && controller.recipes.isEmpty) {
      return const LoadingIndicator(message: 'Discovering gourmet recipes...');
    }

    if (controller.state == RecipeState.error && controller.recipes.isEmpty) {
      return ErrorView(
        message: controller.errorMessage ?? 'Failed to load recipes',
        onRetry: () => controller.fetchRecipes(forceRefresh: true),
      );
    }

    if (controller.recipes.isEmpty) {
      return const Center(child: Text('No recipes found matching criteria.'));
    }

    return RefreshIndicator(
      onRefresh: () => controller.fetchRecipes(forceRefresh: true),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: controller.recipes.length,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (context, index) {
          final recipe = controller.recipes[index];
          return _buildRecipeCard(context, recipe);
        },
      ),
    );
  }

  Widget _buildRecipeCard(BuildContext context, Recipe recipe) {
    final theme = Theme.of(context);

    Color difficultyColor;
    switch (recipe.difficulty.toLowerCase()) {
      case 'easy':
        difficultyColor = AppTheme.successColor;
        break;
      case 'medium':
        difficultyColor = AppTheme.accentColor;
        break;
      default:
        difficultyColor = AppTheme.errorColor;
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => RecipeDetailScreen(recipe: recipe)),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Recipe Image & Overlays
            Stack(
              children: [
                Container(
                  height: 180,
                  width: double.infinity,
                  color: Colors.grey.shade200,
                  child: CachedNetworkImage(
                    imageUrl: recipe.image,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => const Center(child: CircularProgressIndicator()),
                    errorWidget: (_, __, ___) => const Center(
                      child: Icon(Icons.restaurant, size: 50, color: Colors.grey),
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(180),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      recipe.cuisine,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: difficultyColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      recipe.difficulty,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Recipe info
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      const Icon(Icons.timer_outlined, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        '${recipe.totalTimeMinutes} mins',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                      ),
                      const SizedBox(width: 16),
                      const Icon(Icons.local_fire_department_outlined, size: 16, color: AppTheme.accentColor),
                      const SizedBox(width: 4),
                      Text(
                        '${recipe.caloriesPerServing} kcal',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                      ),
                      const SizedBox(width: 16),
                      const Icon(Icons.star_rounded, size: 18, color: AppTheme.accentColor),
                      const SizedBox(width: 2),
                      Text(
                        recipe.rating.toStringAsFixed(1),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
