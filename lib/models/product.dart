import 'dart:convert';

class Product {
  final int id;
  final String name;
  final String description;
  final String imageUrl;
  final double price;
  final List<String> images;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.price,
    required this.images,
  });

  // Convert JSON to Product object
  factory Product.fromJson(dynamic json) {
    // Handle both Map and String inputs
    Map<String, dynamic> data;
    if (json is String) {
      data = jsonDecode(json);
    } else if (json is Map<String, dynamic>) {
      data = json;
    } else {
      throw ArgumentError('Product.fromJson expects Map<String, dynamic> or String');
    }

    return Product(
      id: data['id'] ?? 0,
      name: data['name'] ?? '',
      description: data['description'] ?? "",
      imageUrl: (data['images'] != null && data['images'].isNotEmpty)
          ? data['images'][0]['src'] ?? ""
          : "",
      price: _parsePrice(data['price']),
      images: (data['images'] != null)
          ? (data['images'] as List<dynamic>)
              .map((img) => img['src']?.toString() ?? '')
              .where((url) => url.isNotEmpty)
              .toList()
          : [],
    );
  }

  // Convert Product to Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'price': price.toString(),
      'images': images.map((url) => {'src': url}).toList(),
    };
  }

  // Convert Product to JSON string
  String toJson() => jsonEncode(toMap());
  // Handle cases where price is invalid
  static double _parsePrice(dynamic price) {
    if (price == null || price == "" || price is! String) {
      return 0.0; // Default to 0 if price is missing or invalid
    }
    try {
      return double.parse(price);
    } catch (e) {
      return 0.0; // Return 0.0 if parsing fails
    }
  }
}
