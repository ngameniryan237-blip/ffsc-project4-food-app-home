import '../../domain/entities/recipe.dart';

class RecipeModel extends Recipe {
  const RecipeModel({
    required super.id,
    required super.name,
    required super.ingredients,
    required super.instructions,
    required super.prepTimeMinutes,
    required super.cookTimeMinutes,
    required super.servings,
    required super.difficulty,
    required super.cuisine,
    required super.caloriesPerServing,
    required super.tags,
    required super.image,
    required super.rating,
    required super.reviewCount,
    required super.mealType,
  });

  factory RecipeModel.fromJson(Map<String, dynamic> json) {
    var ingredientsList = <String>[];
    if (json['ingredients'] is List) {
      ingredientsList = (json['ingredients'] as List).map((e) => e.toString()).toList();
    }

    var instructionsList = <String>[];
    if (json['instructions'] is List) {
      instructionsList = (json['instructions'] as List).map((e) => e.toString()).toList();
    }

    var tagsList = <String>[];
    if (json['tags'] is List) {
      tagsList = (json['tags'] as List).map((e) => e.toString()).toList();
    }

    var mealTypeList = <String>[];
    if (json['mealType'] is List) {
      mealTypeList = (json['mealType'] as List).map((e) => e.toString()).toList();
    }

    return RecipeModel(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      ingredients: ingredientsList,
      instructions: instructionsList,
      prepTimeMinutes: json['prepTimeMinutes'] is int ? json['prepTimeMinutes'] as int : 0,
      cookTimeMinutes: json['cookTimeMinutes'] is int ? json['cookTimeMinutes'] as int : 0,
      servings: json['servings'] is int ? json['servings'] as int : 1,
      difficulty: json['difficulty']?.toString() ?? 'Easy',
      cuisine: json['cuisine']?.toString() ?? 'International',
      caloriesPerServing: json['caloriesPerServing'] is int ? json['caloriesPerServing'] as int : 0,
      tags: tagsList,
      image: json['image']?.toString() ?? '',
      rating: (json['rating'] is num) ? (json['rating'] as num).toDouble() : 4.5,
      reviewCount: json['reviewCount'] is int ? json['reviewCount'] as int : 0,
      mealType: mealTypeList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'ingredients': ingredients,
      'instructions': instructions,
      'prepTimeMinutes': prepTimeMinutes,
      'cookTimeMinutes': cookTimeMinutes,
      'servings': servings,
      'difficulty': difficulty,
      'cuisine': cuisine,
      'caloriesPerServing': caloriesPerServing,
      'tags': tags,
      'image': image,
      'rating': rating,
      'reviewCount': reviewCount,
      'mealType': mealType,
    };
  }
}
