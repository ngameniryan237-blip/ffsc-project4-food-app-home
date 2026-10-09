import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../constants/api_constants.dart';

class HiveStorageService {
  static final HiveStorageService _instance = HiveStorageService._internal();
  factory HiveStorageService() => _instance;
  HiveStorageService._internal();

  late Box _authBox;
  late Box _productsBox;
  late Box _postsBox;
  late Box _recipesBox;
  late Box _appSettingsBox;

  Future<void> init() async {
    await Hive.initFlutter();
    _authBox = await Hive.openBox(ApiConstants.authBox);
    _productsBox = await Hive.openBox(ApiConstants.productsBox);
    _postsBox = await Hive.openBox(ApiConstants.postsBox);
    _recipesBox = await Hive.openBox(ApiConstants.recipesBox);
    _appSettingsBox = await Hive.openBox(ApiConstants.appSettingsBox);
  }

  // Auth & Token Storage
  Future<void> saveTokens({required String accessToken, required String refreshToken}) async {
    await _authBox.put(ApiConstants.tokenKey, accessToken);
    await _authBox.put(ApiConstants.refreshTokenKey, refreshToken);
  }

  String? getAccessToken() => _authBox.get(ApiConstants.tokenKey);
  String? getRefreshToken() => _authBox.get(ApiConstants.refreshTokenKey);

  Future<void> saveUserData(Map<String, dynamic> userData) async {
    await _authBox.put(ApiConstants.userKey, jsonEncode(userData));
  }

  Map<String, dynamic>? getUserData() {
    final raw = _authBox.get(ApiConstants.userKey);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> clearAuthData() async {
    await _authBox.delete(ApiConstants.tokenKey);
    await _authBox.delete(ApiConstants.refreshTokenKey);
    await _authBox.delete(ApiConstants.userKey);
  }

  // Products Cache
  Future<void> cacheProducts(List<Map<String, dynamic>> productsJson) async {
    await _productsBox.put(ApiConstants.cachedProductsKey, jsonEncode(productsJson));
    await _productsBox.put('${ApiConstants.cachedProductsKey}_timestamp', DateTime.now().toIso8601String());
  }

  List<Map<String, dynamic>>? getCachedProducts() {
    final raw = _productsBox.get(ApiConstants.cachedProductsKey);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw) as List;
      return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      return null;
    }
  }

  DateTime? getProductsCacheTimestamp() {
    final raw = _productsBox.get('${ApiConstants.cachedProductsKey}_timestamp');
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  // Posts Cache
  Future<void> cachePosts(List<Map<String, dynamic>> postsJson) async {
    await _postsBox.put(ApiConstants.cachedPostsKey, jsonEncode(postsJson));
    await _postsBox.put('${ApiConstants.cachedPostsKey}_timestamp', DateTime.now().toIso8601String());
  }

  List<Map<String, dynamic>>? getCachedPosts() {
    final raw = _postsBox.get(ApiConstants.cachedPostsKey);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw) as List;
      return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      return null;
    }
  }

  DateTime? getPostsCacheTimestamp() {
    final raw = _postsBox.get('${ApiConstants.cachedPostsKey}_timestamp');
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  // Recipes Cache
  Future<void> cacheRecipes(List<Map<String, dynamic>> recipesJson) async {
    await _recipesBox.put(ApiConstants.cachedRecipesKey, jsonEncode(recipesJson));
    await _recipesBox.put('${ApiConstants.cachedRecipesKey}_timestamp', DateTime.now().toIso8601String());
  }

  List<Map<String, dynamic>>? getCachedRecipes() {
    final raw = _recipesBox.get(ApiConstants.cachedRecipesKey);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw) as List;
      return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      return null;
    }
  }

  DateTime? getRecipesCacheTimestamp() {
    final raw = _recipesBox.get('${ApiConstants.cachedRecipesKey}_timestamp');
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  // Offline simulation toggle in settings
  bool getSimulateOffline() => _appSettingsBox.get(ApiConstants.simulateOfflineKey, defaultValue: false) as bool;

  Future<void> setSimulateOffline(bool value) async {
    await _appSettingsBox.put(ApiConstants.simulateOfflineKey, value);
  }

  // Cache Management Stats & Clear
  int getCachedProductsCount() => getCachedProducts()?.length ?? 0;
  int getCachedPostsCount() => getCachedPosts()?.length ?? 0;
  int getCachedRecipesCount() => getCachedRecipes()?.length ?? 0;

  Future<void> clearAllCache() async {
    await _productsBox.clear();
    await _postsBox.clear();
    await _recipesBox.clear();
  }
}
