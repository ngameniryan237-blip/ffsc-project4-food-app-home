import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/network/api_client.dart';
import 'core/network/network_info.dart';
import 'core/storage/hive_storage.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/data/datasources/auth_local_data_source.dart';
import 'features/auth/data/datasources/auth_remote_data_source.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/presentation/controllers/auth_controller.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/home/presentation/screens/main_shell.dart';
import 'features/posts/data/datasources/post_local_data_source.dart';
import 'features/posts/data/datasources/post_remote_data_source.dart';
import 'features/posts/data/repositories/post_repository_impl.dart';
import 'features/posts/presentation/controllers/post_controller.dart';
import 'features/products/data/datasources/product_local_data_source.dart';
import 'features/products/data/datasources/product_remote_data_source.dart';
import 'features/products/data/repositories/product_repository_impl.dart';
import 'features/products/presentation/controllers/product_controller.dart';
import 'features/recipes/data/datasources/recipe_local_data_source.dart';
import 'features/recipes/data/datasources/recipe_remote_data_source.dart';
import 'features/recipes/data/repositories/recipe_repository_impl.dart';
import 'features/recipes/presentation/controllers/recipe_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Local Hive Storage
  final storageService = HiveStorageService();
  await storageService.init();

  // Core Services
  final networkInfo = NetworkInfoImpl(storage: storageService);

  late final AuthController authController;
  final apiClient = ApiClient(
    storage: storageService,
    networkInfo: networkInfo,
    onSessionExpired: () {
      authController.handleSessionExpired();
    },
  );

  // Auth dependencies
  final authRemoteDataSource = AuthRemoteDataSourceImpl(client: apiClient);
  final authLocalDataSource = AuthLocalDataSourceImpl(storage: storageService);
  final authRepository = AuthRepositoryImpl(
    remoteDataSource: authRemoteDataSource,
    localDataSource: authLocalDataSource,
    networkInfo: networkInfo,
  );
  authController = AuthController(
    authRepository: authRepository,
    storage: storageService,
  );

  // Products dependencies
  final productRemoteDataSource = ProductRemoteDataSourceImpl(client: apiClient);
  final productLocalDataSource = ProductLocalDataSourceImpl(storage: storageService);
  final productRepository = ProductRepositoryImpl(
    remoteDataSource: productRemoteDataSource,
    localDataSource: productLocalDataSource,
    networkInfo: networkInfo,
  );
  final productController = ProductController(repository: productRepository);

  // Posts dependencies
  final postRemoteDataSource = PostRemoteDataSourceImpl(client: apiClient);
  final postLocalDataSource = PostLocalDataSourceImpl(storage: storageService);
  final postRepository = PostRepositoryImpl(
    remoteDataSource: postRemoteDataSource,
    localDataSource: postLocalDataSource,
    networkInfo: networkInfo,
  );
  final postController = PostController(repository: postRepository);

  // Recipes dependencies
  final recipeRemoteDataSource = RecipeRemoteDataSourceImpl(client: apiClient);
  final recipeLocalDataSource = RecipeLocalDataSourceImpl(storage: storageService);
  final recipeRepository = RecipeRepositoryImpl(
    remoteDataSource: recipeRemoteDataSource,
    localDataSource: recipeLocalDataSource,
    networkInfo: networkInfo,
  );
  final recipeController = RecipeController(repository: recipeRepository);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<NetworkInfoImpl>.value(value: networkInfo),
        ChangeNotifierProvider<AuthController>.value(value: authController),
        ChangeNotifierProvider<ProductController>.value(value: productController),
        ChangeNotifierProvider<PostController>.value(value: postController),
        ChangeNotifierProvider<RecipeController>.value(value: recipeController),
      ],
      child: const ConnectedApp(),
    ),
  );
}

class ConnectedApp extends StatelessWidget {
  const ConnectedApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Connected Flutter App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();

    if (authController.status == AuthStatus.initial ||
        (authController.isLoading && authController.currentUser == null)) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Checking session...', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    if (authController.isAuthenticated) {
      return const MainShell();
    }

    return const LoginScreen();
  }
}
