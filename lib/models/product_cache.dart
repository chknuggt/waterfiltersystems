import 'dart:convert';

enum ProductCacheStatus {
  active,
  inactive,
  discontinued,
  outOfStock,
}

class ProductCacheImage {
  final String src;
  final String? alt;
  final int? position;

  ProductCacheImage({
    required this.src,
    this.alt,
    this.position,
  });

  Map<String, dynamic> toMap() {
    return {
      'src': src,
      'alt': alt,
      'position': position,
    };
  }

  factory ProductCacheImage.fromMap(Map<String, dynamic> map) {
    return ProductCacheImage(
      src: map['src'] ?? '',
      alt: map['alt'],
      position: map['position'],
    );
  }
}

class ProductCacheCategory {
  final int id;
  final String name;
  final String slug;

  ProductCacheCategory({
    required this.id,
    required this.name,
    required this.slug,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
    };
  }

  factory ProductCacheCategory.fromMap(Map<String, dynamic> map) {
    return ProductCacheCategory(
      id: map['id'] ?? 0,
      name: map['name'] ?? '',
      slug: map['slug'] ?? '',
    );
  }
}

class ProductCacheVariation {
  final int id;
  final String sku;
  final double price;
  final double? salePrice;
  final bool inStock;
  final Map<String, String> attributes;

  ProductCacheVariation({
    required this.id,
    required this.sku,
    required this.price,
    this.salePrice,
    required this.inStock,
    this.attributes = const {},
  });

  double get displayPrice => salePrice ?? price;
  bool get onSale => salePrice != null && salePrice! < price;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sku': sku,
      'price': price,
      'salePrice': salePrice,
      'inStock': inStock,
      'attributes': attributes,
    };
  }

  factory ProductCacheVariation.fromMap(Map<String, dynamic> map) {
    return ProductCacheVariation(
      id: map['id'] ?? 0,
      sku: map['sku'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      salePrice: map['salePrice']?.toDouble(),
      inStock: map['inStock'] ?? false,
      attributes: Map<String, String>.from(map['attributes'] ?? {}),
    );
  }
}

class ProductCache {
  final int wooProductId;
  final String name;
  final String slug;
  final String shortDescription;
  final String? sku;
  final double price;
  final double? salePrice;
  final bool inStock;
  final int? stockQuantity;
  final bool manageStock;
  final ProductCacheStatus status;
  final List<ProductCacheImage> images;
  final List<ProductCacheCategory> categories;
  final List<ProductCacheVariation> variations;
  final Map<String, String> attributes;
  final double? weight;
  final Map<String, dynamic>? dimensions;
  final DateTime updatedAt;
  final bool featured;
  final double? averageRating;
  final int? ratingCount;

  ProductCache({
    required this.wooProductId,
    required this.name,
    required this.slug,
    this.shortDescription = '',
    this.sku,
    required this.price,
    this.salePrice,
    required this.inStock,
    this.stockQuantity,
    this.manageStock = false,
    this.status = ProductCacheStatus.active,
    this.images = const [],
    this.categories = const [],
    this.variations = const [],
    this.attributes = const {},
    this.weight,
    this.dimensions,
    required this.updatedAt,
    this.featured = false,
    this.averageRating,
    this.ratingCount,
  });

  String get id => 'woo_$wooProductId';
  double get displayPrice => salePrice ?? price;
  bool get onSale => salePrice != null && salePrice! < price;
  String get primaryImageUrl => images.isNotEmpty ? images.first.src : '';
  bool get hasVariations => variations.isNotEmpty;
  bool get isAvailable => inStock && status == ProductCacheStatus.active;

  List<String> get categoryNames => categories.map((c) => c.name).toList();
  List<String> get categorySlugs => categories.map((c) => c.slug).toList();

  Map<String, dynamic> toMap() {
    return {
      'wooProductId': wooProductId,
      'name': name,
      'slug': slug,
      'shortDescription': shortDescription,
      'sku': sku,
      'price': price,
      'salePrice': salePrice,
      'inStock': inStock,
      'stockQuantity': stockQuantity,
      'manageStock': manageStock,
      'status': status.toString().split('.').last,
      'images': images.map((img) => img.toMap()).toList(),
      'categories': categories.map((cat) => cat.toMap()).toList(),
      'variations': variations.map((variation) => variation.toMap()).toList(),
      'attributes': attributes,
      'weight': weight,
      'dimensions': dimensions,
      'updatedAt': updatedAt.toIso8601String(),
      'featured': featured,
      'averageRating': averageRating,
      'ratingCount': ratingCount,
    };
  }

  factory ProductCache.fromMap(Map<String, dynamic> map) {
    return ProductCache(
      wooProductId: map['wooProductId'] ?? 0,
      name: map['name'] ?? '',
      slug: map['slug'] ?? '',
      shortDescription: map['shortDescription'] ?? '',
      sku: map['sku'],
      price: (map['price'] ?? 0.0).toDouble(),
      salePrice: map['salePrice']?.toDouble(),
      inStock: map['inStock'] ?? false,
      stockQuantity: map['stockQuantity'],
      manageStock: map['manageStock'] ?? false,
      status: ProductCacheStatus.values.firstWhere(
        (status) => status.toString().split('.').last == map['status'],
        orElse: () => ProductCacheStatus.active,
      ),
      images: (map['images'] as List<dynamic>?)
          ?.map((img) => ProductCacheImage.fromMap(img))
          .toList() ?? [],
      categories: (map['categories'] as List<dynamic>?)
          ?.map((cat) => ProductCacheCategory.fromMap(cat))
          .toList() ?? [],
      variations: (map['variations'] as List<dynamic>?)
          ?.map((variation) => ProductCacheVariation.fromMap(variation))
          .toList() ?? [],
      attributes: Map<String, String>.from(map['attributes'] ?? {}),
      weight: map['weight']?.toDouble(),
      dimensions: map['dimensions'] != null
          ? Map<String, dynamic>.from(map['dimensions'])
          : null,
      updatedAt: DateTime.parse(map['updatedAt']),
      featured: map['featured'] ?? false,
      averageRating: map['averageRating']?.toDouble(),
      ratingCount: map['ratingCount'],
    );
  }

  factory ProductCache.fromWooCommerceProduct(Map<String, dynamic> wooProduct) {
    return ProductCache(
      wooProductId: wooProduct['id'] ?? 0,
      name: wooProduct['name'] ?? '',
      slug: wooProduct['slug'] ?? '',
      shortDescription: wooProduct['short_description'] ?? '',
      sku: wooProduct['sku'],
      price: double.tryParse(wooProduct['price']?.toString() ?? '0') ?? 0.0,
      salePrice: wooProduct['sale_price'] != null && wooProduct['sale_price'] != ''
          ? double.tryParse(wooProduct['sale_price'].toString())
          : null,
      inStock: wooProduct['in_stock'] ?? false,
      stockQuantity: wooProduct['stock_quantity'],
      manageStock: wooProduct['manage_stock'] ?? false,
      status: _parseWooCommerceStatus(wooProduct['status']),
      images: (wooProduct['images'] as List<dynamic>?)
          ?.map((img) => ProductCacheImage(
                src: img['src'] ?? '',
                alt: img['alt'],
                position: img['position'],
              ))
          .toList() ?? [],
      categories: (wooProduct['categories'] as List<dynamic>?)
          ?.map((cat) => ProductCacheCategory(
                id: cat['id'] ?? 0,
                name: cat['name'] ?? '',
                slug: cat['slug'] ?? '',
              ))
          .toList() ?? [],
      variations: [], // Variations would be fetched separately
      attributes: _parseWooCommerceAttributes(wooProduct['attributes']),
      weight: wooProduct['weight'] != null && wooProduct['weight'] != ''
          ? double.tryParse(wooProduct['weight'].toString())
          : null,
      dimensions: wooProduct['dimensions'],
      updatedAt: DateTime.now(),
      featured: wooProduct['featured'] ?? false,
      averageRating: wooProduct['average_rating'] != null && wooProduct['average_rating'] != ''
          ? double.tryParse(wooProduct['average_rating'].toString())
          : null,
      ratingCount: wooProduct['rating_count'],
    );
  }

  factory ProductCache.fromJson(String source) =>
      ProductCache.fromMap(json.decode(source));

  String toJson() => json.encode(toMap());

  ProductCache copyWith({
    int? wooProductId,
    String? name,
    String? slug,
    String? shortDescription,
    String? sku,
    double? price,
    double? salePrice,
    bool? inStock,
    int? stockQuantity,
    bool? manageStock,
    ProductCacheStatus? status,
    List<ProductCacheImage>? images,
    List<ProductCacheCategory>? categories,
    List<ProductCacheVariation>? variations,
    Map<String, String>? attributes,
    double? weight,
    Map<String, dynamic>? dimensions,
    DateTime? updatedAt,
    bool? featured,
    double? averageRating,
    int? ratingCount,
  }) {
    return ProductCache(
      wooProductId: wooProductId ?? this.wooProductId,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      shortDescription: shortDescription ?? this.shortDescription,
      sku: sku ?? this.sku,
      price: price ?? this.price,
      salePrice: salePrice ?? this.salePrice,
      inStock: inStock ?? this.inStock,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      manageStock: manageStock ?? this.manageStock,
      status: status ?? this.status,
      images: images ?? this.images,
      categories: categories ?? this.categories,
      variations: variations ?? this.variations,
      attributes: attributes ?? this.attributes,
      weight: weight ?? this.weight,
      dimensions: dimensions ?? this.dimensions,
      updatedAt: updatedAt ?? this.updatedAt,
      featured: featured ?? this.featured,
      averageRating: averageRating ?? this.averageRating,
      ratingCount: ratingCount ?? this.ratingCount,
    );
  }

  static ProductCacheStatus _parseWooCommerceStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'publish':
        return ProductCacheStatus.active;
      case 'draft':
      case 'private':
        return ProductCacheStatus.inactive;
      default:
        return ProductCacheStatus.active;
    }
  }

  static Map<String, String> _parseWooCommerceAttributes(List<dynamic>? attributes) {
    if (attributes == null) return {};

    final Map<String, String> result = {};
    for (final attr in attributes) {
      if (attr is Map<String, dynamic>) {
        final name = attr['name']?.toString();
        final options = attr['options'] as List<dynamic>?;
        if (name != null && options != null && options.isNotEmpty) {
          result[name] = options.join(', ');
        }
      }
    }
    return result;
  }
}

extension ProductCacheStatusExtension on ProductCacheStatus {
  String get displayName {
    switch (this) {
      case ProductCacheStatus.active:
        return 'Active';
      case ProductCacheStatus.inactive:
        return 'Inactive';
      case ProductCacheStatus.discontinued:
        return 'Discontinued';
      case ProductCacheStatus.outOfStock:
        return 'Out of Stock';
    }
  }

  String get colorCode {
    switch (this) {
      case ProductCacheStatus.active:
        return '#4CAF50'; // Green
      case ProductCacheStatus.inactive:
        return '#9E9E9E'; // Grey
      case ProductCacheStatus.discontinued:
        return '#F44336'; // Red
      case ProductCacheStatus.outOfStock:
        return '#FF9800'; // Orange
    }
  }
}