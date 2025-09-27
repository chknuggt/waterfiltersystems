import 'package:flutter/material.dart';
import '../../pagestyle/product_category_page.dart';

class ProductCategory {
  final String title;
  final String categoryId;

  const ProductCategory({required this.title, required this.categoryId});
}

class ProductCategories {
  static const Map<String, ProductCategory> categories = {
    'waterFilter': ProductCategory(title: 'Water Filter', categoryId: '67'),
    'waterCoolers': ProductCategory(title: 'Water Coolers', categoryId: '64'),
    'sodaStream': ProductCategory(title: 'Soda Streams', categoryId: '2073'),
    'reverseOsmosis': ProductCategory(title: 'Reverse Osmosis', categoryId: '58'),
    'waterSofteners': ProductCategory(title: 'Water Softeners', categoryId: '61'),
    'waterMakers': ProductCategory(title: 'Water Makers', categoryId: '1444'),
    'waterMeasuring': ProductCategory(title: 'Water Measuring', categoryId: '749'),
    'waterSterilization': ProductCategory(title: 'Water Sterilization', categoryId: '747'),
    'faucets': ProductCategory(title: 'Faucets', categoryId: '1399'),
  };

  static Widget getCategoryPage(String categoryKey) {
    final category = categories[categoryKey];
    if (category == null) {
      return Scaffold(
        body: Center(
          child: Text('Category not found'),
        ),
      );
    }
    return ProductCategoryPage(
      title: category.title,
      categoryId: category.categoryId,
    );
  }

  static Widget buildCategoryPage(String title, String categoryId) {
    return ProductCategoryPage(title: title, categoryId: categoryId);
  }
}