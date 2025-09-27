import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product.dart';
import 'environment_service.dart';

class WooCommerceAPI {
  final EnvironmentService _env = EnvironmentService();

  String get baseUrl => _env.wooCommerceUrl;
  String get productsUrl => "${_env.wooCommerceUrl}/products";
  String get ordersUrl => "${_env.wooCommerceUrl}/orders";
  String get consumerKey => _env.wooCommerceConsumerKey;
  String get consumerSecret => _env.wooCommerceConsumerSecret;

  Future<List<Product>> fetchProducts({
    String? category,
    String? search,
  }) async {
    String url =
        "$productsUrl?consumer_key=$consumerKey&consumer_secret=$consumerSecret";

    // Add category filter if provided
    if (category != null && category.isNotEmpty) {
      url += "&category=$category";
    }

    // Add search filter if provided
    if (search != null && search.isNotEmpty) {
      url += "&search=$search";
    }

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((item) => Product.fromJson(item as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Failed to load products: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> createOrder(Map<String, dynamic> orderData) async {
    final url = "$ordersUrl?consumer_key=$consumerKey&consumer_secret=$consumerSecret";

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: json.encode(orderData),
    );

    if (response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to create order: ${response.statusCode} - ${response.body}');
    }
  }

  Future<Map<String, dynamic>> getOrder(String orderId) async {
    final url = "$ordersUrl/$orderId?consumer_key=$consumerKey&consumer_secret=$consumerSecret";

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to get order: ${response.statusCode}');
    }
  }

  Future<List<Map<String, dynamic>>> getOrders({
    int page = 1,
    int perPage = 20,
    String? status,
    String? customer,
  }) async {
    String url = "$ordersUrl?consumer_key=$consumerKey&consumer_secret=$consumerSecret&page=$page&per_page=$perPage";

    if (status != null && status.isNotEmpty) {
      url += "&status=$status";
    }

    if (customer != null && customer.isNotEmpty) {
      url += "&customer=$customer";
    }

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to get orders: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> updateOrderStatus(String orderId, String status) async {
    final url = "$ordersUrl/$orderId?consumer_key=$consumerKey&consumer_secret=$consumerSecret";

    final response = await http.put(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: json.encode({
        'status': status,
      }),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to update order status: ${response.statusCode}');
    }
  }

  Future<List<Map<String, dynamic>>> getShippingMethods() async {
    final url = "$baseUrl/shipping/zones?consumer_key=$consumerKey&consumer_secret=$consumerSecret";

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to get shipping methods: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> calculateShipping({
    required String country,
    required String state,
    required String city,
    required String postcode,
    required List<Map<String, dynamic>> items,
  }) async {
    final url = "$baseUrl/shipping/calculate?consumer_key=$consumerKey&consumer_secret=$consumerSecret";

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: json.encode({
        'shipping': {
          'country': country,
          'state': state,
          'city': city,
          'postcode': postcode,
        },
        'items': items,
      }),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to calculate shipping: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> validateCoupon(String couponCode) async {
    final url = "$baseUrl/coupons?consumer_key=$consumerKey&consumer_secret=$consumerSecret&code=$couponCode";

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      if (data.isNotEmpty) {
        return data.first;
      } else {
        throw Exception('Coupon not found');
      }
    } else {
      throw Exception('Failed to validate coupon: ${response.statusCode}');
    }
  }

  Future<double> calculateTax({
    required String country,
    required String state,
    required String city,
    required String postcode,
    required double amount,
  }) async {
    final url = "$baseUrl/taxes?consumer_key=$consumerKey&consumer_secret=$consumerSecret";

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);

      // Find applicable tax rate
      for (var taxRate in data) {
        if (_isTaxRateApplicable(taxRate, country, state, city, postcode)) {
          final rate = double.tryParse(taxRate['rate'].toString()) ?? 0.0;
          return amount * (rate / 100);
        }
      }

      return 0.0;
    } else {
      throw Exception('Failed to calculate tax: ${response.statusCode}');
    }
  }

  bool _isTaxRateApplicable(Map<String, dynamic> taxRate, String country, String state, String city, String postcode) {
    // Simplified tax rate matching logic
    final taxCountry = taxRate['country'] ?? '';
    final taxState = taxRate['state'] ?? '';

    if (taxCountry.isNotEmpty && taxCountry != country) {
      return false;
    }

    if (taxState.isNotEmpty && taxState != state) {
      return false;
    }

    return true;
  }

  Future<Product?> getProduct(int productId) async {
    final url = "$productsUrl/$productId?consumer_key=$consumerKey&consumer_secret=$consumerSecret";

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      Map<String, dynamic> data = json.decode(response.body);
      return Product.fromJson(data as Map<String, dynamic>);
    } else if (response.statusCode == 404) {
      return null;
    } else {
      throw Exception('Failed to get product: ${response.statusCode}');
    }
  }

  Future<List<Map<String, dynamic>>> getCategories() async {
    final url = "$baseUrl/products/categories?consumer_key=$consumerKey&consumer_secret=$consumerSecret";

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to get categories: ${response.statusCode}');
    }
  }
}
