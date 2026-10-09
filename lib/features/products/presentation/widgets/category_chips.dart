import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class CategoryChips extends StatelessWidget {
  final String selectedCategory;
  final Function(String) onSelected;

  const CategoryChips({
    super.key,
    required this.selectedCategory,
    required this.onSelected,
  });

  static const List<Map<String, String>> categories = [
    {'id': 'all', 'label': 'All Products'},
    {'id': 'beauty', 'label': 'Beauty'},
    {'id': 'fragrances', 'label': 'Fragrances'},
    {'id': 'furniture', 'label': 'Furniture'},
    {'id': 'groceries', 'label': 'Groceries'},
    {'id': 'home-decoration', 'label': 'Home Decor'},
    {'id': 'kitchen-accessories', 'label': 'Kitchen'},
    {'id': 'laptops', 'label': 'Laptops'},
    {'id': 'mens-shirts', 'label': 'Men Shirts'},
    {'id': 'mens-shoes', 'label': 'Men Shoes'},
    {'id': 'mens-watches', 'label': 'Men Watches'},
    {'id': 'mobile-accessories', 'label': 'Accessories'},
    {'id': 'skin-care', 'label': 'Skin Care'},
    {'id': 'smartphones', 'label': 'Smartphones'},
    {'id': 'sports-accessories', 'label': 'Sports'},
    {'id': 'sunglasses', 'label': 'Sunglasses'},
    {'id': 'tablets', 'label': 'Tablets'},
    {'id': 'tops', 'label': 'Tops'},
    {'id': 'vehicle', 'label': 'Vehicles'},
    {'id': 'womens-bags', 'label': 'Bags'},
    {'id': 'womens-dresses', 'label': 'Dresses'},
    {'id': 'womens-jewellery', 'label': 'Jewellery'},
    {'id': 'womens-shoes', 'label': 'Women Shoes'},
    {'id': 'womens-watches', 'label': 'Women Watches'},
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = selectedCategory == cat['id'];

          return ChoiceChip(
            label: Text(cat['label']!),
            selected: isSelected,
            onSelected: (_) => onSelected(cat['id']!),
            selectedColor: AppTheme.primaryColor,
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : null,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
            backgroundColor: Theme.of(context).cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
              ),
            ),
          );
        },
      ),
    );
  }
}
