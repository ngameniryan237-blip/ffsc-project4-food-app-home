import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/storage/hive_storage.dart';
import '../../../../core/theme/app_theme.dart';
import '../controllers/auth_controller.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _storage = HiveStorageService();

  void _clearCache() async {
    await _storage.clearAllCache();
    if (mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All cached data cleared successfully!'),
          backgroundColor: AppTheme.successColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authController = context.watch<AuthController>();
    final networkInfo = context.watch<NetworkInfoImpl>();
    final user = authController.currentUser;

    final token = authController.accessToken ?? 'No token found';
    final refreshToken = authController.refreshToken ?? 'No refresh token';
    final isOfflineSim = networkInfo.isSimulatingOffline;

    final cachedProducts = _storage.getCachedProductsCount();
    final cachedPosts = _storage.getCachedPostsCount();
    final cachedRecipes = _storage.getCachedRecipesCount();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile & Settings', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppTheme.errorColor),
            tooltip: 'Log Out',
            onPressed: () => _confirmLogout(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // User Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: AppTheme.primaryColor.withAlpha(40),
                    child: ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: user?.image ?? '',
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => const Icon(
                          Icons.person,
                          size: 38,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.fullName.isNotEmpty == true ? user!.fullName : 'Emily Johnson',
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '@${user?.username ?? 'emilys'}',
                          style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user?.email ?? 'emily.johnson@x.dummyjson.com',
                          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Offline Simulation & Caching Controls Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.wifi_off_rounded, color: isOfflineSim ? AppTheme.accentColor : AppTheme.primaryColor),
                      const SizedBox(width: 8),
                      Text(
                        'Offline Mode & Caching',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Simulate offline network disconnection to evaluate Hive cache-first loading.',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                  const Divider(height: 24),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Simulate Offline Mode', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      isOfflineSim
                          ? 'App is currently isolated from network (Serving Hive cache)'
                          : 'App connects to real REST API endpoints',
                      style: TextStyle(
                        fontSize: 12,
                        color: isOfflineSim ? AppTheme.accentColor : Colors.grey.shade600,
                      ),
                    ),
                    value: isOfflineSim,
                    onChanged: (val) async {
                      await networkInfo.setSimulateOffline(val);
                      setState(() {});
                    },
                  ),
                  const Divider(height: 20),
                  Text(
                    'Hive Cache Statistics:',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildCacheStat('Products', cachedProducts, Icons.inventory_2_outlined),
                      _buildCacheStat('Posts', cachedPosts, Icons.forum_outlined),
                      _buildCacheStat('Recipes', cachedRecipes, Icons.restaurant_menu_outlined),
                    ],
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    onPressed: _clearCache,
                    icon: const Icon(Icons.delete_sweep_outlined, size: 18),
                    label: const Text('Clear All Local Cache'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.errorColor,
                      side: const BorderSide(color: AppTheme.errorColor),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // JWT & Dio Token Inspector Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.security_rounded, color: AppTheme.successColor),
                      const SizedBox(width: 8),
                      Text(
                        'JWT & Security Details',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Bearer token injected by Dio AuthInterceptor on all protected requests.',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 12),
                  _buildTokenField('Access Token (JWT)', token),
                  const SizedBox(height: 10),
                  _buildTokenField('Refresh Token', refreshToken),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Backend API Info
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.api_rounded, color: AppTheme.secondaryColor),
                      const SizedBox(width: 8),
                      Text(
                        'API Specifications',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildApiRow('Base URL', ApiConstants.baseUrl),
                  _buildApiRow('Auth Endpoints', '/auth/login, /auth/refresh, /auth/me'),
                  _buildApiRow('Store API', '/products, /products/categories'),
                  _buildApiRow('Community API', '/posts, /comments/post/{id}'),
                  _buildApiRow('Recipes API', '/recipes, /recipes/meal-type'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Logout button
          ElevatedButton.icon(
            onPressed: () => _confirmLogout(context),
            icon: const Icon(Icons.logout),
            label: const Text('Log Out'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildCacheStat(String label, int count, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 22, color: AppTheme.primaryColor),
        const SizedBox(height: 4),
        Text(
          '$count cached',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildTokenField(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              ),
              InkWell(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: value));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$label copied to clipboard'),
                      duration: const Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                child: const Row(
                  children: [
                    Icon(Icons.copy, size: 12),
                    SizedBox(width: 4),
                    Text('Copy', style: TextStyle(fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 10),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildApiRow(String label, String endpoint) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              endpoint,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: AppTheme.primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out and clear active tokens?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<AuthController>().logout();
            },
            child: const Text('Log Out', style: TextStyle(color: AppTheme.errorColor)),
          ),
        ],
      ),
    );
  }
}
