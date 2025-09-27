import 'dart:convert';
import 'package:waterfilternet/models/product.dart';
import 'package:waterfilternet/models/shipping_address.dart';
import 'package:waterfilternet/models/payment_card.dart';

enum OrderStatus {
  pending,
  processing,
  shipped,
  outForDelivery,
  delivered,
  cancelled,
  refunded,
  onHold,
}

enum PaymentStatus {
  pending,
  authorized,
  paid,
  partiallyPaid,
  refunded,
  partiallyRefunded,
  failed,
  cancelled,
}

class OrderItem {
  final String id;
  final Product product;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final Map<String, dynamic>? metadata;

  OrderItem({
    required this.id,
    required this.product,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    this.metadata,
  });

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      id: map['id'] ?? '',
      product: Product.fromJson(map['product']),
      quantity: map['quantity'] ?? 0,
      unitPrice: (map['unitPrice'] ?? 0.0).toDouble(),
      totalPrice: (map['totalPrice'] ?? 0.0).toDouble(),
      metadata: map['metadata'] != null ? Map<String, dynamic>.from(map['metadata']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'product': product.toMap(),
      'quantity': quantity,
      'unitPrice': unitPrice,
      'totalPrice': totalPrice,
      'metadata': metadata,
    };
  }

  factory OrderItem.fromJson(String source) =>
      OrderItem.fromMap(json.decode(source));

  String toJson() => json.encode(toMap());

  OrderItem copyWith({
    String? id,
    Product? product,
    int? quantity,
    double? unitPrice,
    double? totalPrice,
    Map<String, dynamic>? metadata,
  }) {
    return OrderItem(
      id: id ?? this.id,
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      totalPrice: totalPrice ?? this.totalPrice,
      metadata: metadata ?? this.metadata,
    );
  }
}

class ShippingMethod {
  final String id;
  final String name;
  final String description;
  final double cost;
  final String estimatedDays;
  final bool trackingAvailable;

  ShippingMethod({
    required this.id,
    required this.name,
    required this.description,
    required this.cost,
    required this.estimatedDays,
    this.trackingAvailable = true,
  });

  factory ShippingMethod.fromMap(Map<String, dynamic> map) {
    return ShippingMethod(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      cost: (map['cost'] ?? 0.0).toDouble(),
      estimatedDays: map['estimatedDays'] ?? '',
      trackingAvailable: map['trackingAvailable'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'cost': cost,
      'estimatedDays': estimatedDays,
      'trackingAvailable': trackingAvailable,
    };
  }

  factory ShippingMethod.fromJson(String source) =>
      ShippingMethod.fromMap(json.decode(source));

  String toJson() => json.encode(toMap());
}

class TrackingInfo {
  final String trackingNumber;
  final String carrier;
  final String carrierUrl;
  final List<TrackingEvent> events;
  final DateTime? estimatedDelivery;

  TrackingInfo({
    required this.trackingNumber,
    required this.carrier,
    required this.carrierUrl,
    required this.events,
    this.estimatedDelivery,
  });

  factory TrackingInfo.fromMap(Map<String, dynamic> map) {
    return TrackingInfo(
      trackingNumber: map['trackingNumber'] ?? '',
      carrier: map['carrier'] ?? '',
      carrierUrl: map['carrierUrl'] ?? '',
      events: List<TrackingEvent>.from(
        map['events']?.map((x) => TrackingEvent.fromMap(x)) ?? [],
      ),
      estimatedDelivery: map['estimatedDelivery'] != null
          ? DateTime.parse(map['estimatedDelivery'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'trackingNumber': trackingNumber,
      'carrier': carrier,
      'carrierUrl': carrierUrl,
      'events': events.map((x) => x.toMap()).toList(),
      'estimatedDelivery': estimatedDelivery?.toIso8601String(),
    };
  }

  factory TrackingInfo.fromJson(String source) =>
      TrackingInfo.fromMap(json.decode(source));

  String toJson() => json.encode(toMap());
}

class TrackingEvent {
  final String status;
  final String description;
  final String location;
  final DateTime timestamp;

  TrackingEvent({
    required this.status,
    required this.description,
    required this.location,
    required this.timestamp,
  });

  factory TrackingEvent.fromMap(Map<String, dynamic> map) {
    return TrackingEvent(
      status: map['status'] ?? '',
      description: map['description'] ?? '',
      location: map['location'] ?? '',
      timestamp: DateTime.parse(map['timestamp']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'status': status,
      'description': description,
      'location': location,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory TrackingEvent.fromJson(String source) =>
      TrackingEvent.fromMap(json.decode(source));

  String toJson() => json.encode(toMap());
}

class Order {
  final String id;
  final String orderNumber;
  final String userId;
  final List<OrderItem> items;
  final ShippingAddress shippingAddress;
  final ShippingAddress? billingAddress;
  final ShippingMethod shippingMethod;
  final PaymentCard? paymentCard;
  final String paymentMethodId;
  final OrderStatus status;
  final PaymentStatus paymentStatus;
  final double subtotal;
  final double shippingCost;
  final double tax;
  final double discount;
  final double total;
  final String currency;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? shippedAt;
  final DateTime? deliveredAt;
  final TrackingInfo? tracking;
  final Map<String, dynamic>? metadata;
  final String? notes;
  final String? wooCommerceOrderId;

  Order({
    required this.id,
    required this.orderNumber,
    required this.userId,
    required this.items,
    required this.shippingAddress,
    this.billingAddress,
    required this.shippingMethod,
    this.paymentCard,
    required this.paymentMethodId,
    required this.status,
    required this.paymentStatus,
    required this.subtotal,
    required this.shippingCost,
    required this.tax,
    this.discount = 0.0,
    required this.total,
    this.currency = 'EUR',
    required this.createdAt,
    this.updatedAt,
    this.shippedAt,
    this.deliveredAt,
    this.tracking,
    this.metadata,
    this.notes,
    this.wooCommerceOrderId,
  });

  factory Order.fromMap(Map<String, dynamic> map) {
    return Order(
      id: map['id'] ?? '',
      orderNumber: map['orderNumber'] ?? '',
      userId: map['userId'] ?? '',
      items: List<OrderItem>.from(
        map['items']?.map((x) => OrderItem.fromMap(x)) ?? [],
      ),
      shippingAddress: ShippingAddress.fromMap(map['shippingAddress']),
      billingAddress: map['billingAddress'] != null
          ? ShippingAddress.fromMap(map['billingAddress'])
          : null,
      shippingMethod: ShippingMethod.fromMap(map['shippingMethod']),
      paymentCard: map['paymentCard'] != null
          ? PaymentCard.fromMap(map['paymentCard'])
          : null,
      paymentMethodId: map['paymentMethodId'] ?? '',
      status: OrderStatus.values.firstWhere(
        (status) => status.toString().split('.').last == map['status'],
        orElse: () => OrderStatus.pending,
      ),
      paymentStatus: PaymentStatus.values.firstWhere(
        (status) => status.toString().split('.').last == map['paymentStatus'],
        orElse: () => PaymentStatus.pending,
      ),
      subtotal: (map['subtotal'] ?? 0.0).toDouble(),
      shippingCost: (map['shippingCost'] ?? 0.0).toDouble(),
      tax: (map['tax'] ?? 0.0).toDouble(),
      discount: (map['discount'] ?? 0.0).toDouble(),
      total: (map['total'] ?? 0.0).toDouble(),
      currency: map['currency'] ?? 'EUR',
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
      shippedAt: map['shippedAt'] != null ? DateTime.parse(map['shippedAt']) : null,
      deliveredAt: map['deliveredAt'] != null ? DateTime.parse(map['deliveredAt']) : null,
      tracking: map['tracking'] != null ? TrackingInfo.fromMap(map['tracking']) : null,
      metadata: map['metadata'] != null ? Map<String, dynamic>.from(map['metadata']) : null,
      notes: map['notes'],
      wooCommerceOrderId: map['wooCommerceOrderId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'orderNumber': orderNumber,
      'userId': userId,
      'items': items.map((x) => x.toMap()).toList(),
      'shippingAddress': shippingAddress.toMap(),
      'billingAddress': billingAddress?.toMap(),
      'shippingMethod': shippingMethod.toMap(),
      'paymentCard': paymentCard?.toMap(),
      'paymentMethodId': paymentMethodId,
      'status': status.toString().split('.').last,
      'paymentStatus': paymentStatus.toString().split('.').last,
      'subtotal': subtotal,
      'shippingCost': shippingCost,
      'tax': tax,
      'discount': discount,
      'total': total,
      'currency': currency,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'shippedAt': shippedAt?.toIso8601String(),
      'deliveredAt': deliveredAt?.toIso8601String(),
      'tracking': tracking?.toMap(),
      'metadata': metadata,
      'notes': notes,
      'wooCommerceOrderId': wooCommerceOrderId,
    };
  }

  factory Order.fromJson(String source) =>
      Order.fromMap(json.decode(source));

  String toJson() => json.encode(toMap());

  Order copyWith({
    String? id,
    String? orderNumber,
    String? userId,
    List<OrderItem>? items,
    ShippingAddress? shippingAddress,
    ShippingAddress? billingAddress,
    ShippingMethod? shippingMethod,
    PaymentCard? paymentCard,
    String? paymentMethodId,
    OrderStatus? status,
    PaymentStatus? paymentStatus,
    double? subtotal,
    double? shippingCost,
    double? tax,
    double? discount,
    double? total,
    String? currency,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? shippedAt,
    DateTime? deliveredAt,
    TrackingInfo? tracking,
    Map<String, dynamic>? metadata,
    String? notes,
    String? wooCommerceOrderId,
  }) {
    return Order(
      id: id ?? this.id,
      orderNumber: orderNumber ?? this.orderNumber,
      userId: userId ?? this.userId,
      items: items ?? this.items,
      shippingAddress: shippingAddress ?? this.shippingAddress,
      billingAddress: billingAddress ?? this.billingAddress,
      shippingMethod: shippingMethod ?? this.shippingMethod,
      paymentCard: paymentCard ?? this.paymentCard,
      paymentMethodId: paymentMethodId ?? this.paymentMethodId,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      subtotal: subtotal ?? this.subtotal,
      shippingCost: shippingCost ?? this.shippingCost,
      tax: tax ?? this.tax,
      discount: discount ?? this.discount,
      total: total ?? this.total,
      currency: currency ?? this.currency,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      shippedAt: shippedAt ?? this.shippedAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      tracking: tracking ?? this.tracking,
      metadata: metadata ?? this.metadata,
      notes: notes ?? this.notes,
      wooCommerceOrderId: wooCommerceOrderId ?? this.wooCommerceOrderId,
    );
  }

  int get totalItems {
    return items.fold(0, (total, item) => total + item.quantity);
  }

  bool get isCompleted {
    return status == OrderStatus.delivered;
  }

  bool get isCancelled {
    return status == OrderStatus.cancelled;
  }

  bool get isReturnable {
    if (!isCompleted || deliveredAt == null) return false;
    final daysSinceDelivery = DateTime.now().difference(deliveredAt!).inDays;
    return daysSinceDelivery <= 30; // 30-day return policy
  }

  String get statusDisplayName {
    switch (status) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.processing:
        return 'Processing';
      case OrderStatus.shipped:
        return 'Shipped';
      case OrderStatus.outForDelivery:
        return 'Out for Delivery';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
      case OrderStatus.refunded:
        return 'Refunded';
      case OrderStatus.onHold:
        return 'On Hold';
    }
  }

  String get paymentStatusDisplayName {
    switch (paymentStatus) {
      case PaymentStatus.pending:
        return 'Payment Pending';
      case PaymentStatus.authorized:
        return 'Payment Authorized';
      case PaymentStatus.paid:
        return 'Paid';
      case PaymentStatus.partiallyPaid:
        return 'Partially Paid';
      case PaymentStatus.refunded:
        return 'Refunded';
      case PaymentStatus.partiallyRefunded:
        return 'Partially Refunded';
      case PaymentStatus.failed:
        return 'Payment Failed';
      case PaymentStatus.cancelled:
        return 'Payment Cancelled';
    }
  }

  String get estimatedDeliveryText {
    if (deliveredAt != null) {
      return 'Delivered';
    }

    if (tracking?.estimatedDelivery != null) {
      return 'Est. ${_formatDate(tracking!.estimatedDelivery!)}';
    }

    if (shippedAt != null) {
      final estimatedDelivery = shippedAt!.add(
        Duration(days: int.tryParse(shippingMethod.estimatedDays.split('-').first) ?? 3),
      );
      return 'Est. ${_formatDate(estimatedDelivery)}';
    }

    return 'Processing';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;

    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Tomorrow';
    } else if (difference > 1 && difference <= 7) {
      return 'in $difference days';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Map<String, dynamic> toWooCommerceFormat() {
    return {
      'payment_method': 'stripe',
      'payment_method_title': paymentCard?.displayName ?? 'Credit Card',
      'set_paid': paymentStatus == PaymentStatus.paid,
      'billing': billingAddress?.toWooCommerceFormat(isBilling: true) ??
                shippingAddress.toWooCommerceFormat(isBilling: true),
      'shipping': shippingAddress.toWooCommerceFormat(isBilling: false),
      'line_items': items.map((item) => {
        'product_id': item.product.id,
        'quantity': item.quantity,
        'price': item.unitPrice,
      }).toList(),
      'shipping_lines': [
        {
          'method_id': shippingMethod.id,
          'method_title': shippingMethod.name,
          'total': shippingCost.toStringAsFixed(2),
        },
      ],
      'meta_data': [
        {
          'key': '_app_order_id',
          'value': id,
        },
        if (metadata != null)
          ...metadata!.entries.map((entry) => {
            'key': '_${entry.key}',
            'value': entry.value.toString(),
          }),
      ],
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Order && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}