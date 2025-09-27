import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/product_cache.dart';
import '../models/product.dart';
import '../services/woocommerce_api.dart';
import 'config_service.dart';

class ProductCacheService {
  static final ProductCacheService _instance = ProductCacheService._internal();
  factory ProductCacheService() => _instance;
  ProductCacheService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ConfigService _config = ConfigService();
  final WooCommerceAPI _wooCommerce = WooCommerceAPI();

  static const String _productsCacheCollection = 'products_cache';

  // Demo storage for when Firestore is unavailable
  static final List<ProductCache> _demoProducts = [];

  /// Sync products from WooCommerce to Firestore cache
  Future<void> syncProductsFromWooCommerce() async {
    try {
      print('ProductCacheService: Starting WooCommerce sync...');

      // Fetch products from WooCommerce
      final wooProducts = await _wooCommerce.fetchProducts();
      print('ProductCacheService: Fetched ${wooProducts.length} products from WooCommerce');

      if (_config.isDemoMode) {
        _syncToDemo(wooProducts);
        return;
      }

      // Batch write to Firestore
      final batch = _firestore.batch();
      int batchCount = 0;

      for (final wooProduct in wooProducts) {
        try {
          final productCache = ProductCache.fromWooCommerceProduct(wooProduct.toMap());
          final docRef = _firestore
              .collection(_productsCacheCollection)
              .doc(productCache.id);

          batch.set(docRef, productCache.toMap());
          batchCount++;

          // Firestore batch limit is 500 operations
          if (batchCount >= 400) {
            await batch.commit();
            print('ProductCacheService: Committed batch of $batchCount products');
            batchCount = 0;
          }
        } catch (e) {
          print('ProductCacheService: Error processing product ${wooProduct.id}: $e');
        }
      }

      // Commit remaining products
      if (batchCount > 0) {
        await batch.commit();
        print('ProductCacheService: Committed final batch of $batchCount products');
      }

      // Update sync timestamp
      await _updateSyncTimestamp();

      print('ProductCacheService: Sync completed successfully');
    } catch (e) {
      print('ProductCacheService: Error syncing products: $e');
      throw Exception('Failed to sync products from WooCommerce: $e');
    }
  }

  /// Get all cached products
  Future<List<ProductCache>> getAllProducts() async {
    try {
      if (_config.isDemoMode) {
        print('ProductCacheService: Getting products in demo mode');
        return _demoProducts;
      }

      final querySnapshot = await _firestore
          .collection(_productsCacheCollection)
          .where('status', isEqualTo: 'active')
          .orderBy('name')
          .get();

      return querySnapshot.docs
          .map((doc) => ProductCache.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('ProductCacheService: Error getting products: $e');
      if (_config.isDemoMode) {
        return _demoProducts;
      }
      return [];
    }
  }

  /// Get products by category
  Future<List<ProductCache>> getProductsByCategory(String categorySlug) async {
    try {
      if (_config.isDemoMode) {
        return _demoProducts
            .where((product) => product.categorySlugs.contains(categorySlug))
            .toList();
      }

      final querySnapshot = await _firestore
          .collection(_productsCacheCollection)
          .where('status', isEqualTo: 'active')
          .where('categories', arrayContains: {'slug': categorySlug})
          .orderBy('name')
          .get();

      return querySnapshot.docs
          .map((doc) => ProductCache.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('ProductCacheService: Error getting products by category: $e');
      return [];
    }
  }

  /// Search products by name or description
  Future<List<ProductCache>> searchProducts(String query) async {
    try {
      final allProducts = await getAllProducts();
      final searchQuery = query.toLowerCase();

      return allProducts.where((product) =>
          product.name.toLowerCase().contains(searchQuery) ||
          product.shortDescription.toLowerCase().contains(searchQuery) ||
          (product.sku?.toLowerCase().contains(searchQuery) ?? false)
      ).toList();
    } catch (e) {
      print('ProductCacheService: Error searching products: $e');
      return [];
    }
  }

  /// Get featured products
  Future<List<ProductCache>> getFeaturedProducts() async {
    try {
      if (_config.isDemoMode) {
        return _demoProducts.where((product) => product.featured).toList();
      }

      final querySnapshot = await _firestore
          .collection(_productsCacheCollection)
          .where('status', isEqualTo: 'active')
          .where('featured', isEqualTo: true)
          .orderBy('name')
          .get();

      return querySnapshot.docs
          .map((doc) => ProductCache.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('ProductCacheService: Error getting featured products: $e');
      return [];
    }
  }

  /// Get products on sale
  Future<List<ProductCache>> getSaleProducts() async {
    try {
      final allProducts = await getAllProducts();
      return allProducts.where((product) => product.onSale).toList();
    } catch (e) {
      print('ProductCacheService: Error getting sale products: $e');
      return [];
    }
  }

  /// Get a specific product by ID
  Future<ProductCache?> getProduct(String productId) async {
    try {
      if (_config.isDemoMode) {
        return _demoProducts
            .where((product) => product.id == productId)
            .firstOrNull;
      }

      final doc = await _firestore
          .collection(_productsCacheCollection)
          .doc(productId)
          .get();

      if (!doc.exists) return null;
      return ProductCache.fromMap(doc.data()!);
    } catch (e) {
      print('ProductCacheService: Error getting product: $e');
      return null;
    }
  }

  /// Get product by WooCommerce ID
  Future<ProductCache?> getProductByWooId(int wooProductId) async {
    try {
      return await getProduct('woo_$wooProductId');
    } catch (e) {
      print('ProductCacheService: Error getting product by WooCommerce ID: $e');
      return null;
    }
  }

  /// Stream products for real-time updates
  Stream<List<ProductCache>> streamProducts() {
    if (_config.isDemoMode) {
      return Stream.value(_demoProducts);
    }

    return _firestore
        .collection(_productsCacheCollection)
        .where('status', isEqualTo: 'active')
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProductCache.fromMap(doc.data()))
            .toList());
  }

  /// Update product stock status
  Future<void> updateProductStock(String productId, {
    required bool inStock,
    int? stockQuantity,
  }) async {
    try {
      if (_config.isDemoMode) {
        final index = _demoProducts.indexWhere((p) => p.id == productId);
        if (index != -1) {
          _demoProducts[index] = _demoProducts[index].copyWith(
            inStock: inStock,
            stockQuantity: stockQuantity,
            updatedAt: DateTime.now(),
          );
        }
        return;
      }

      await _firestore
          .collection(_productsCacheCollection)
          .doc(productId)
          .update({
        'inStock': inStock,
        'stockQuantity': stockQuantity,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      print('ProductCacheService: Updated stock for product $productId');
    } catch (e) {
      print('ProductCacheService: Error updating product stock: $e');
      throw Exception('Failed to update product stock: $e');
    }
  }

  /// Update product prices
  Future<void> updateProductPrices(String productId, {
    required double price,
    double? salePrice,
  }) async {
    try {
      if (_config.isDemoMode) {
        final index = _demoProducts.indexWhere((p) => p.id == productId);
        if (index != -1) {
          _demoProducts[index] = _demoProducts[index].copyWith(
            price: price,
            salePrice: salePrice,
            updatedAt: DateTime.now(),
          );
        }
        return;
      }

      await _firestore
          .collection(_productsCacheCollection)
          .doc(productId)
          .update({
        'price': price,
        'salePrice': salePrice,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      print('ProductCacheService: Updated prices for product $productId');
    } catch (e) {
      print('ProductCacheService: Error updating product prices: $e');
      throw Exception('Failed to update product prices: $e');
    }
  }

  /// Get sync status and last update time
  Future<Map<String, dynamic>> getSyncStatus() async {
    try {
      if (_config.isDemoMode) {
        return {
          'lastSync': DateTime.now().subtract(const Duration(hours: 1)),
          'productCount': _demoProducts.length,
          'status': 'demo',
        };
      }

      final doc = await _firestore
          .collection('app_config')
          .doc('product_sync')
          .get();

      if (!doc.exists) {
        return {
          'lastSync': null,
          'productCount': 0,
          'status': 'never_synced',
        };
      }

      final data = doc.data()!;
      return {
        'lastSync': data['lastSync'] != null
            ? DateTime.parse(data['lastSync'])
            : null,
        'productCount': data['productCount'] ?? 0,
        'status': data['status'] ?? 'unknown',
      };
    } catch (e) {
      print('ProductCacheService: Error getting sync status: $e');
      return {
        'lastSync': null,
        'productCount': 0,
        'status': 'error',
      };
    }
  }

  /// Clear all cached products
  Future<void> clearCache() async {
    try {
      if (_config.isDemoMode) {
        _demoProducts.clear();
        return;
      }

      final batch = _firestore.batch();
      final querySnapshot = await _firestore
          .collection(_productsCacheCollection)
          .get();

      for (final doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      print('ProductCacheService: Cache cleared successfully');
    } catch (e) {
      print('ProductCacheService: Error clearing cache: $e');
      throw Exception('Failed to clear product cache: $e');
    }
  }

  /// Sync demo products for testing
  void _syncToDemo(List<Product> wooProducts) {
    _demoProducts.clear();

    for (final wooProduct in wooProducts) {
      try {
        final productCache = ProductCache.fromWooCommerceProduct(wooProduct.toMap());
        _demoProducts.add(productCache);
      } catch (e) {
        print('ProductCacheService: Error adding demo product: $e');
      }
    }

    print('ProductCacheService: Synced ${_demoProducts.length} products to demo cache');
  }

  /// Update sync timestamp
  Future<void> _updateSyncTimestamp() async {
    try {
      final productCount = await _getProductCount();

      await _firestore
          .collection('app_config')
          .doc('product_sync')
          .set({
        'lastSync': DateTime.now().toIso8601String(),
        'productCount': productCount,
        'status': 'completed',
      });
    } catch (e) {
      print('ProductCacheService: Error updating sync timestamp: $e');
    }
  }

  /// Get total product count
  Future<int> _getProductCount() async {
    try {
      if (_config.isDemoMode) {
        return _demoProducts.length;
      }

      final querySnapshot = await _firestore
          .collection(_productsCacheCollection)
          .where('status', isEqualTo: 'active')
          .get();

      return querySnapshot.size;
    } catch (e) {
      print('ProductCacheService: Error getting product count: $e');
      return 0;
    }
  }

  /// Create demo products for testing
  void createDemoProducts() {
    _demoProducts.clear();

    final demoProducts = [
      ProductCache(
        wooProductId: 1001,
        name: 'Pentair Everpure 2CB5 Filter',
        slug: 'pentair-everpure-2cb5',
        shortDescription: 'Premium carbon block filter for under-sink systems',
        sku: 'PEN-2CB5',
        price: 29.90,
        salePrice: 24.90,
        inStock: true,
        stockQuantity: 15,
        images: [
          ProductCacheImage(
            src: 'https://example.com/images/pentair-2cb5.jpg',
            alt: 'Pentair Everpure 2CB5 Filter',
            position: 0,
          ),
        ],
        categories: [
          ProductCacheCategory(id: 1, name: 'Filters', slug: 'filters'),
          ProductCacheCategory(id: 2, name: 'Under-Sink', slug: 'under-sink'),
        ],
        attributes: {'Size': '10 inches', 'Type': 'Carbon Block'},
        updatedAt: DateTime.now(),
        featured: true,
      ),
      ProductCache(
        wooProductId: 1002,
        name: 'Sediment Filter 10" - 5 Micron',
        slug: 'sediment-filter-10-5-micron',
        shortDescription: 'Standard sediment filter for pre-filtration',
        sku: 'SED-10-5',
        price: 12.50,
        inStock: true,
        stockQuantity: 25,
        images: [
          ProductCacheImage(
            src: 'https://example.com/images/sediment-filter.jpg',
            alt: 'Sediment Filter',
            position: 0,
          ),
        ],
        categories: [
          ProductCacheCategory(id: 1, name: 'Filters', slug: 'filters'),
          ProductCacheCategory(id: 3, name: 'Sediment', slug: 'sediment'),
        ],
        attributes: {'Size': '10 inches', 'Micron': '5'},
        updatedAt: DateTime.now(),
      ),
      ProductCache(
        wooProductId: 1003,
        name: 'RO Membrane 75GPD',
        slug: 'ro-membrane-75gpd',
        shortDescription: 'High-performance reverse osmosis membrane',
        sku: 'RO-75',
        price: 45.00,
        salePrice: 39.99,
        inStock: true,
        stockQuantity: 8,
        images: [
          ProductCacheImage(
            src: 'https://example.com/images/ro-membrane.jpg',
            alt: 'RO Membrane',
            position: 0,
          ),
        ],
        categories: [
          ProductCacheCategory(id: 1, name: 'Filters', slug: 'filters'),
          ProductCacheCategory(id: 4, name: 'RO Membranes', slug: 'ro-membranes'),
        ],
        attributes: {'Capacity': '75 GPD', 'Type': 'TFC'},
        updatedAt: DateTime.now(),
        featured: true,
      ),
    ];

    _demoProducts.addAll(demoProducts);
    print('ProductCacheService: Created ${_demoProducts.length} demo products');
  }

  /// Clear demo data (for testing)
  void clearDemoData() {
    _demoProducts.clear();
  }
}