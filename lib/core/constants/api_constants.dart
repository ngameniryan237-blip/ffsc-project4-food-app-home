class ApiConstants {
  static const String baseUrl = 'https://dummyjson.com';

  // Auth endpoints
  static const String login = '/auth/login';
  static const String refresh = '/auth/refresh';
  static const String currentUser = '/auth/me';

  // Products endpoints
  static const String products = '/products';
  static const String productCategories = '/products/categories';
  static const String productSearch = '/products/search';
  static const String productsByCategory = '/products/category';

  // Posts endpoints
  static const String posts = '/posts';
  static const String postSearch = '/posts/search';
  static const String postTag = '/posts/tag';
  static const String postComments = '/comments/post';

  // Recipes endpoints
  static const String recipes = '/recipes';
  static const String recipeSearch = '/recipes/search';
  static const String recipeMealType = '/recipes/meal-type';

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);

  // Hive Box Names
  static const String authBox = 'auth_box';
  static const String productsBox = 'products_box';
  static const String postsBox = 'posts_box';
  static const String recipesBox = 'recipes_box';
  static const String appSettingsBox = 'app_settings_box';

  // Storage Keys
  static const String tokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userKey = 'user_data';
  static const String cachedProductsKey = 'cached_products';
  static const String cachedCategoriesKey = 'cached_categories';
  static const String cachedPostsKey = 'cached_posts';
  static const String cachedRecipesKey = 'cached_recipes';
  static const String simulateOfflineKey = 'simulate_offline_mode';
}
