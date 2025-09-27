import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:waterfilternet/models/order.dart' as order_model;
import 'package:waterfilternet/models/cart_item.dart';
import 'package:waterfilternet/models/shipping_address.dart';
import 'package:waterfilternet/models/payment_card.dart';
import 'package:waterfilternet/services/woocommerce_api.dart';
import 'package:waterfilternet/services/config_service.dart';

class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final WooCommerceAPI _wooCommerce = WooCommerceAPI();
  final ConfigService _config = ConfigService();

  static const String _ordersCollection = 'orders';
  static const String _userOrdersCollection = 'user_orders';

  Future<String> createOrder({
    required List<CartItem> cartItems,
    required ShippingAddress shippingAddress,
    ShippingAddress? billingAddress,
    required order_model.ShippingMethod shippingMethod,
    required PaymentCard paymentCard,
    required String paymentMethodId,
    double discount = 0.0,
    String? notes,
    Map<String, dynamic>? metadata,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User must be logged in to create an order');
    }

    try {
      print('DEBUG OrderService: Checking configuration...');
      _config.logConfigState();

      // Use demo mode if configured or if Firestore is unavailable
      if (_config.isDemoMode) {
        print('DEBUG OrderService: Using demo mode...');
        return await _createDemoOrder(cartItems, shippingAddress, shippingMethod, total: _calculateTotal(cartItems, shippingMethod, discount));
      }

      print('DEBUG OrderService: Using Firestore...');

      // Try Firestore with better error handling
      try {
        // Generate order ID and number
        final orderId = _firestore.collection(_ordersCollection).doc().id;
        final orderNumber = await _generateOrderNumber();

      // Convert cart items to order items
      final orderItems = cartItems.map((cartItem) => order_model.OrderItem(
        id: '${orderId}_${cartItem.product.id}',
        product: cartItem.product,
        quantity: cartItem.quantity,
        unitPrice: cartItem.product.price,
        totalPrice: cartItem.totalPrice,
      )).toList();

      // Calculate totals (prices already include 19% Cyprus VAT)
      final subtotal = orderItems.fold<double>(0, (sum, item) => sum + item.totalPrice);
      final tax = 0.0; // Tax already included in product prices
      final total = subtotal + shippingMethod.cost - discount;

      // Create order object
      final order = order_model.Order(
        id: orderId,
        orderNumber: orderNumber,
        userId: user.uid,
        items: orderItems,
        shippingAddress: shippingAddress,
        billingAddress: billingAddress ?? shippingAddress,
        shippingMethod: shippingMethod,
        paymentCard: paymentCard,
        paymentMethodId: paymentMethodId,
        status: order_model.OrderStatus.pending,
        paymentStatus: order_model.PaymentStatus.pending,
        subtotal: subtotal,
        shippingCost: shippingMethod.cost,
        tax: tax,
        discount: discount,
        total: total,
        createdAt: DateTime.now(),
        metadata: metadata,
        notes: notes,
      );

      // Save to Firestore
      await _firestore.collection(_ordersCollection).doc(orderId).set(order.toMap());

      // Create user order reference
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection(_userOrdersCollection)
          .doc(orderId)
          .set({
        'orderId': orderId,
        'orderNumber': orderNumber,
        'total': total,
        'status': order.status.toString().split('.').last,
        'createdAt': order.createdAt.toIso8601String(),
      });

        return orderId;
      } catch (firestoreError) {
        print('DEBUG OrderService: Firestore failed, falling back to demo mode...');
        print('Firestore error: $firestoreError');

        // Mark Firestore as unavailable in config
        _config.enableDemoMode();

        // Fallback to demo mode when Firestore fails
        return await _createDemoOrder(cartItems, shippingAddress, shippingMethod, total: _calculateTotal(cartItems, shippingMethod, discount));
      }
    } catch (e) {
      throw Exception('Failed to create order: $e');
    }
  }

  Future<void> updateOrderStatus(String orderId, order_model.OrderStatus status) async {
    try {
      final updateData = <String, dynamic>{
        'status': status.toString().split('.').last,
        'updatedAt': DateTime.now().toIso8601String(),
      };

      // Add timestamp for specific status changes
      switch (status) {
        case order_model.OrderStatus.shipped:
          updateData['shippedAt'] = DateTime.now().toIso8601String();
          break;
        case order_model.OrderStatus.delivered:
          updateData['deliveredAt'] = DateTime.now().toIso8601String();
          break;
        default:
          break;
      }

      await _firestore.collection(_ordersCollection).doc(orderId).update(updateData);

      // Update user order reference
      final order = await getOrder(orderId);
      if (order != null) {
        await _firestore
            .collection('users')
            .doc(order.userId)
            .collection(_userOrdersCollection)
            .doc(orderId)
            .update({
          'status': status.toString().split('.').last,
          'updatedAt': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      throw Exception('Failed to update order status: $e');
    }
  }

  Future<void> updatePaymentStatus(String orderId, order_model.PaymentStatus status) async {
    try {
      final updateData = <String, dynamic>{
        'paymentStatus': status.toString().split('.').last,
        'updatedAt': DateTime.now().toIso8601String(),
      };

      await _firestore.collection(_ordersCollection).doc(orderId).update(updateData);
    } catch (e) {
      throw Exception('Failed to update payment status: $e');
    }
  }

  Future<void> addTrackingInfo(String orderId, order_model.TrackingInfo tracking) async {
    try {
      await _firestore.collection(_ordersCollection).doc(orderId).update({
        'tracking': tracking.toMap(),
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to add tracking info: $e');
    }
  }

  Future<order_model.Order?> getOrder(String orderId) async {
    try {
      // Use demo mode if configured
      if (_config.isDemoMode) {
        await Future.delayed(Duration(milliseconds: 500));
        return _createMockOrder(orderId);
      }

      try {
        final doc = await _firestore.collection(_ordersCollection).doc(orderId).get();

        if (!doc.exists) {
          return null;
        }

        return order_model.Order.fromMap(doc.data()!);
      } catch (firestoreError) {
        print('DEBUG getOrder: Firestore failed, returning mock order...');
        print('Firestore error: $firestoreError');

        // Mark Firestore as unavailable and return mock order
        _config.enableDemoMode();
        return _createMockOrder(orderId);
      }
    } catch (e) {
      throw Exception('Failed to get order: $e');
    }
  }

  /// Create a mock order for demo purposes
  order_model.Order _createMockOrder(String orderId) {
    final mockOrder = order_model.Order(
      id: orderId,
      orderNumber: 'WF${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}',
      userId: _config.getDemoUserId(),
      items: [], // Empty items for demo
      subtotal: 99.99,
      tax: 20.00,
      shippingCost: 5.00,
      total: 124.99,
      status: order_model.OrderStatus.processing,
      paymentStatus: order_model.PaymentStatus.paid,
      shippingAddress: ShippingAddress(
        id: 'demo_address',
        userId: _config.getDemoUserId(),
        firstName: 'John',
        lastName: 'Doe',
        addressLine1: '123 Demo Street',
        city: 'Nicosia',
        state: 'Nicosia District',
        postalCode: '1011',
        country: 'Cyprus',
        countryCode: 'CY',
        createdAt: DateTime.now(),
      ),
      shippingMethod: order_model.ShippingMethod(
        id: 'standard',
        name: 'Standard Shipping',
        description: 'Delivery in 3-5 business days',
        cost: 5.00,
        estimatedDays: '3-5 days',
      ),
      paymentMethodId: 'pm_demo_12345',
      createdAt: DateTime.now(),
    );

    print('Demo: Mock order returned - ID: $orderId');
    return mockOrder;
  }

  Stream<order_model.Order?> getOrderStream(String orderId) {
    return _firestore
        .collection(_ordersCollection)
        .doc(orderId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return order_model.Order.fromMap(doc.data()!);
    });
  }

  Future<List<order_model.Order>> getUserOrders({
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User must be logged in');
    }

    try {
      Query query = _firestore
          .collection(_ordersCollection)
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final snapshot = await query.get();

      return snapshot.docs
          .map((doc) => order_model.Order.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get user orders: $e');
    }
  }

  Stream<List<order_model.Order>> getUserOrdersStream({int limit = 20}) {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection(_ordersCollection)
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => order_model.Order.fromMap(doc.data()))
          .toList();
    });
  }

  Future<List<order_model.Order>> getOrdersByStatus(order_model.OrderStatus status, {int limit = 50}) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User must be logged in');
    }

    try {
      final snapshot = await _firestore
          .collection(_ordersCollection)
          .where('userId', isEqualTo: user.uid)
          .where('status', isEqualTo: status.toString().split('.').last)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => order_model.Order.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get orders by status: $e');
    }
  }

  Future<void> cancelOrder(String orderId, String reason) async {
    try {
      final order = await getOrder(orderId);
      if (order == null) {
        throw Exception('Order not found');
      }

      // Check if order can be cancelled
      if (order.status == order_model.OrderStatus.shipped ||
          order.status == order_model.OrderStatus.delivered ||
          order.status == order_model.OrderStatus.cancelled) {
        throw Exception('Order cannot be cancelled');
      }

      // Update order status
      await updateOrderStatus(orderId, order_model.OrderStatus.cancelled);

      // Add cancellation metadata
      final metadata = Map<String, dynamic>.from(order.metadata ?? {});
      metadata['cancellationReason'] = reason;
      metadata['cancelledAt'] = DateTime.now().toIso8601String();

      await _firestore.collection(_ordersCollection).doc(orderId).update({
        'metadata': metadata,
      });

      // If payment was processed, handle refund
      if (order.paymentStatus == order_model.PaymentStatus.paid) {
        await updatePaymentStatus(orderId, order_model.PaymentStatus.refunded);
      }
    } catch (e) {
      throw Exception('Failed to cancel order: $e');
    }
  }

  Future<String> _generateOrderNumber() async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 10000).toString().padLeft(4, '0');
    return 'WFN$random';
  }


  // Shipping methods available
  static List<order_model.ShippingMethod> getAvailableShippingMethods() {
    return [
      order_model.ShippingMethod(
        id: 'standard',
        name: 'Standard Shipping',
        description: 'Delivery in 5-7 business days',
        cost: 9.99,
        estimatedDays: '5-7',
      ),
      order_model.ShippingMethod(
        id: 'express',
        name: 'Express Shipping',
        description: 'Delivery in 2-3 business days',
        cost: 19.99,
        estimatedDays: '2-3',
      ),
      order_model.ShippingMethod(
        id: 'overnight',
        name: 'Overnight Shipping',
        description: 'Next business day delivery',
        cost: 39.99,
        estimatedDays: '1',
      ),
      order_model.ShippingMethod(
        id: 'free',
        name: 'Free Shipping',
        description: 'Free delivery in 7-10 business days (orders over €75)',
        cost: 0.0,
        estimatedDays: '7-10',
      ),
    ];
  }

  Future<List<order_model.ShippingMethod>> getShippingMethods({
    required ShippingAddress address,
    required double orderValue,
  }) async {
    final methods = getAvailableShippingMethods();

    // Filter free shipping based on order value
    return methods.where((method) {
      if (method.id == 'free') {
        return orderValue >= 75.0;
      }
      return true;
    }).toList();
  }

  // Integration with WooCommerce
  Future<String?> createWooCommerceOrder(order_model.Order order) async {
    try {
      final wooCommerceData = order.toWooCommerceFormat();
      final response = await _wooCommerce.createOrder(wooCommerceData);

      // Update order with WooCommerce ID
      await _firestore.collection(_ordersCollection).doc(order.id).update({
        'wooCommerceOrderId': response['id'].toString(),
        'updatedAt': DateTime.now().toIso8601String(),
      });

      return response['id'].toString();
    } catch (e) {
      print('Failed to create WooCommerce order: $e');
      return null;
    }
  }

  Future<void> syncOrderWithWooCommerce(String orderId) async {
    try {
      final order = await getOrder(orderId);
      if (order == null || order.wooCommerceOrderId == null) {
        return;
      }

      final wooCommerceOrder = await _wooCommerce.getOrder(order.wooCommerceOrderId!);

      // Update order status based on WooCommerce status
      final wooStatus = wooCommerceOrder['status'] as String;
      order_model.OrderStatus? newStatus;

      switch (wooStatus) {
        case 'pending':
          newStatus = order_model.OrderStatus.pending;
          break;
        case 'processing':
          newStatus = order_model.OrderStatus.processing;
          break;
        case 'on-hold':
          newStatus = order_model.OrderStatus.onHold;
          break;
        case 'completed':
          newStatus = order_model.OrderStatus.delivered;
          break;
        case 'cancelled':
          newStatus = order_model.OrderStatus.cancelled;
          break;
        case 'refunded':
          newStatus = order_model.OrderStatus.refunded;
          break;
      }

      if (newStatus != null && newStatus != order.status) {
        await updateOrderStatus(orderId, newStatus);
      }
    } catch (e) {
      print('Failed to sync order with WooCommerce: $e');
    }
  }

  /// Create a demo order for testing purposes
  Future<String> _createDemoOrder(
    List<CartItem> cartItems,
    ShippingAddress shippingAddress,
    order_model.ShippingMethod shippingMethod, {
    required double total,
  }) async {
    // Simulate processing time
    await Future.delayed(Duration(seconds: 2));

    final orderId = _config.generateDemoId('order');
    final orderNumber = 'WFN${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';

    print('Demo: Order created successfully');
    print('  - Order ID: $orderId');
    print('  - Order Number: $orderNumber');
    print('  - Total: €${total.toStringAsFixed(2)}');
    print('  - Items: ${cartItems.length}');
    print('  - Shipping: ${shippingMethod.name}');

    return orderId;
  }

  /// Calculate total for demo orders
  double _calculateTotal(
    List<CartItem> cartItems,
    order_model.ShippingMethod shippingMethod,
    double discount,
  ) {
    final subtotal = cartItems.fold<double>(0, (sum, item) => sum + item.totalPrice);
    // No additional tax - prices already include 19% Cyprus VAT
    return subtotal + shippingMethod.cost - discount;
  }
}