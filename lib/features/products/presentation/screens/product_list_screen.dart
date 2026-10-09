import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../widgets/error_view.dart';
import '../../../../widgets/loading_indicator.dart';
import '../../../../widgets/offline_banner.dart';
import '../controllers/product_controller.dart';
import '../widgets/category_chips.dart';
import '../widgets/product_card.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = context.read<ProductController>();
      if (controller.products.isEmpty) {
        controller.fetchProducts();
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
    final controller = context.watch<ProductController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Store Catalog', style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(108),
          child: Column(
            children: [
              // Search field
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search products by title, brand, tag...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              controller.fetchProducts();
                            },
                          )
                        : null,
                  ),
                  onSubmitted: (query) => controller.search(query),
                  textInputAction: TextInputAction.search,
                ),
              ),
              const SizedBox(height: 6),
              // Category chips
              CategoryChips(
                selectedCategory: controller.selectedCategory,
                onSelected: (cat) {
                  _searchController.clear();
                  controller.filterByCategory(cat);
                },
              ),
              const SizedBox(height: 6),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: _buildBody(context, controller),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, ProductController controller) {
    if (controller.isLoading && controller.products.isEmpty) {
      return const LoadingIndicator(message: 'Loading REST catalog...');
    }

    if (controller.state == ProductState.error && controller.products.isEmpty) {
      return ErrorView(
        message: controller.errorMessage ?? 'Failed to load products',
        onRetry: () => controller.fetchProducts(forceRefresh: true),
      );
    }

    if (controller.products.isEmpty) {
      return const Center(
        child: Text('No products found matching your search.'),
      );
    }

    return RefreshIndicator(
      onRefresh: () => controller.fetchProducts(forceRefresh: true),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final crossAxisCount = constraints.maxWidth > 900
              ? 4
              : (constraints.maxWidth > 600 ? 3 : 2);

          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: 0.65,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: controller.products.length,
            itemBuilder: (context, index) {
              final product = controller.products[index];
              return ProductCard(product: product);
            },
          );
        },
      ),
    );
  }
}
