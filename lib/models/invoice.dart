import 'dart:convert';
import 'package:waterfilternet/models/order.dart';
import 'package:waterfilternet/models/shipping_address.dart';

enum InvoiceStatus {
  draft,
  sent,
  paid,
  overdue,
  cancelled,
}

class InvoiceItem {
  final String description;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final double? taxRate;
  final double? taxAmount;

  InvoiceItem({
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    this.taxRate,
    this.taxAmount,
  });

  factory InvoiceItem.fromMap(Map<String, dynamic> map) {
    return InvoiceItem(
      description: map['description'] ?? '',
      quantity: map['quantity'] ?? 0,
      unitPrice: (map['unitPrice'] ?? 0.0).toDouble(),
      totalPrice: (map['totalPrice'] ?? 0.0).toDouble(),
      taxRate: map['taxRate']?.toDouble(),
      taxAmount: map['taxAmount']?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'description': description,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'totalPrice': totalPrice,
      'taxRate': taxRate,
      'taxAmount': taxAmount,
    };
  }

  factory InvoiceItem.fromOrderItem(OrderItem orderItem, {double? taxRate}) {
    final taxAmount = taxRate != null ? orderItem.totalPrice * (taxRate / 100) : null;

    return InvoiceItem(
      description: orderItem.product.name,
      quantity: orderItem.quantity,
      unitPrice: orderItem.unitPrice,
      totalPrice: orderItem.totalPrice,
      taxRate: taxRate,
      taxAmount: taxAmount,
    );
  }

  factory InvoiceItem.fromJson(String source) =>
      InvoiceItem.fromMap(json.decode(source));

  String toJson() => json.encode(toMap());
}

class CompanyInfo {
  final String name;
  final String address;
  final String city;
  final String state;
  final String postalCode;
  final String country;
  final String phone;
  final String email;
  final String website;
  final String? taxId;
  final String? registrationNumber;
  final String? logoUrl;

  CompanyInfo({
    required this.name,
    required this.address,
    required this.city,
    required this.state,
    required this.postalCode,
    required this.country,
    required this.phone,
    required this.email,
    required this.website,
    this.taxId,
    this.registrationNumber,
    this.logoUrl,
  });

  factory CompanyInfo.fromMap(Map<String, dynamic> map) {
    return CompanyInfo(
      name: map['name'] ?? '',
      address: map['address'] ?? '',
      city: map['city'] ?? '',
      state: map['state'] ?? '',
      postalCode: map['postalCode'] ?? '',
      country: map['country'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
      website: map['website'] ?? '',
      taxId: map['taxId'],
      registrationNumber: map['registrationNumber'],
      logoUrl: map['logoUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'address': address,
      'city': city,
      'state': state,
      'postalCode': postalCode,
      'country': country,
      'phone': phone,
      'email': email,
      'website': website,
      'taxId': taxId,
      'registrationNumber': registrationNumber,
      'logoUrl': logoUrl,
    };
  }

  String get fullAddress {
    return '$address\n$city, $state $postalCode\n$country';
  }

  // Default company information for WaterFilterNet
  static CompanyInfo get defaultCompanyInfo {
    return CompanyInfo(
      name: 'WaterFilterNet',
      address: 'Business Address',
      city: 'City',
      state: 'State',
      postalCode: 'Postal Code',
      country: 'Country',
      phone: '+1 (555) 123-4567',
      email: 'info@waterfilternet.com',
      website: 'https://www.waterfilternet.com',
      taxId: 'TAX123456789',
      registrationNumber: 'REG987654321',
      logoUrl: 'https://www.waterfilternet.com/logo.png',
    );
  }
}

class Invoice {
  final String id;
  final String invoiceNumber;
  final String orderId;
  final String? orderNumber;
  final String userId;
  final CompanyInfo companyInfo;
  final ShippingAddress billingAddress;
  final List<InvoiceItem> items;
  final double subtotal;
  final double taxTotal;
  final double shippingCost;
  final double discount;
  final double total;
  final String currency;
  final InvoiceStatus status;
  final DateTime issueDate;
  final DateTime dueDate;
  final DateTime? paidDate;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? notes;
  final String? paymentTerms;
  final Map<String, dynamic>? metadata;

  Invoice({
    required this.id,
    required this.invoiceNumber,
    required this.orderId,
    this.orderNumber,
    required this.userId,
    required this.companyInfo,
    required this.billingAddress,
    required this.items,
    required this.subtotal,
    required this.taxTotal,
    this.shippingCost = 0.0,
    this.discount = 0.0,
    required this.total,
    this.currency = 'EUR',
    this.status = InvoiceStatus.draft,
    required this.issueDate,
    required this.dueDate,
    this.paidDate,
    required this.createdAt,
    this.updatedAt,
    this.notes,
    this.paymentTerms,
    this.metadata,
  });

  factory Invoice.fromMap(Map<String, dynamic> map) {
    return Invoice(
      id: map['id'] ?? '',
      invoiceNumber: map['invoiceNumber'] ?? '',
      orderId: map['orderId'] ?? '',
      orderNumber: map['orderNumber'],
      userId: map['userId'] ?? '',
      companyInfo: CompanyInfo.fromMap(map['companyInfo'] ?? {}),
      billingAddress: ShippingAddress.fromMap(map['billingAddress']),
      items: List<InvoiceItem>.from(
        map['items']?.map((x) => InvoiceItem.fromMap(x)) ?? [],
      ),
      subtotal: (map['subtotal'] ?? 0.0).toDouble(),
      taxTotal: (map['taxTotal'] ?? 0.0).toDouble(),
      shippingCost: (map['shippingCost'] ?? 0.0).toDouble(),
      discount: (map['discount'] ?? 0.0).toDouble(),
      total: (map['total'] ?? 0.0).toDouble(),
      currency: map['currency'] ?? 'EUR',
      status: InvoiceStatus.values.firstWhere(
        (status) => status.toString().split('.').last == map['status'],
        orElse: () => InvoiceStatus.draft,
      ),
      issueDate: DateTime.parse(map['issueDate']),
      dueDate: DateTime.parse(map['dueDate']),
      paidDate: map['paidDate'] != null ? DateTime.parse(map['paidDate']) : null,
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
      notes: map['notes'],
      paymentTerms: map['paymentTerms'],
      metadata: map['metadata'] != null ? Map<String, dynamic>.from(map['metadata']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoiceNumber': invoiceNumber,
      'orderId': orderId,
      'orderNumber': orderNumber,
      'userId': userId,
      'companyInfo': companyInfo.toMap(),
      'billingAddress': billingAddress.toMap(),
      'items': items.map((x) => x.toMap()).toList(),
      'subtotal': subtotal,
      'taxTotal': taxTotal,
      'shippingCost': shippingCost,
      'discount': discount,
      'total': total,
      'currency': currency,
      'status': status.toString().split('.').last,
      'issueDate': issueDate.toIso8601String(),
      'dueDate': dueDate.toIso8601String(),
      'paidDate': paidDate?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'notes': notes,
      'paymentTerms': paymentTerms,
      'metadata': metadata,
    };
  }

  factory Invoice.fromJson(String source) =>
      Invoice.fromMap(json.decode(source));

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMapForDatabase() {
    // Cyprus VAT rate is 19%
    const cyprusVatRate = 0.19;

    // If total is tax-inclusive (like €190), calculate pre-tax amounts
    // Formula: pre-tax = tax-inclusive / (1 + VAT rate)
    final totalExcludingVat = total / (1 + cyprusVatRate);
    final vatAmount = total - totalExcludingVat;
    final subtotalExcludingVat = subtotal / (1 + cyprusVatRate);
    final totalBeforeTax = totalExcludingVat + shippingCost - discount;

    return {
      'id': id,
      'number': invoiceNumber,
      'seller_id': userId,
      'buyer_id': orderId,
      'issue_date': issueDate.toIso8601String().split('T')[0],
      'due_date': dueDate.toIso8601String().split('T')[0],
      'currency': currency,
      'fx_rate_to_base': null,
      'status': status.toString().split('.').last,
      'subtotal_minor': (subtotalExcludingVat * 100).round(),
      'subtotal_major': double.parse(subtotalExcludingVat.toStringAsFixed(2)),
      'tax_total_minor': (vatAmount * 100).round(),
      'tax_total_major': double.parse(vatAmount.toStringAsFixed(2)),
      'total_before_tax_major': double.parse(totalBeforeTax.toStringAsFixed(2)),
      'rounding_minor': 0,
      'rounding_major': 0.0,
      'total_minor': (total * 100).round(),
      'total_major': double.parse(total.toStringAsFixed(2)),
      'created_at': createdAt.toIso8601String(),
      'finalized_at': updatedAt?.toIso8601String(),
    };
  }

  factory Invoice.fromOrder(Order order, {
    CompanyInfo? companyInfo,
    String? paymentTerms,
    String? notes,
    int dueDays = 30,
  }) {
    final now = DateTime.now();
    final invoiceItems = order.items
        .map((item) => InvoiceItem.fromOrderItem(item, taxRate: 20.0))
        .toList();

    return Invoice(
      id: 'inv_${order.id}',
      invoiceNumber: _generateInvoiceNumber(),
      orderId: order.id,
      orderNumber: order.orderNumber,
      userId: order.userId,
      companyInfo: companyInfo ?? CompanyInfo.defaultCompanyInfo,
      billingAddress: order.billingAddress ?? order.shippingAddress,
      items: invoiceItems,
      subtotal: order.subtotal,
      taxTotal: order.tax,
      shippingCost: order.shippingCost,
      discount: order.discount,
      total: order.total,
      currency: order.currency,
      status: order.paymentStatus == PaymentStatus.paid
          ? InvoiceStatus.paid
          : InvoiceStatus.sent,
      issueDate: now,
      dueDate: now.add(Duration(days: dueDays)),
      paidDate: order.paymentStatus == PaymentStatus.paid ? now : null,
      createdAt: now,
      paymentTerms: paymentTerms ?? 'Payment due within $dueDays days',
      notes: notes,
    );
  }

  Invoice copyWith({
    String? id,
    String? invoiceNumber,
    String? orderId,
    String? orderNumber,
    String? userId,
    CompanyInfo? companyInfo,
    ShippingAddress? billingAddress,
    List<InvoiceItem>? items,
    double? subtotal,
    double? taxTotal,
    double? shippingCost,
    double? discount,
    double? total,
    String? currency,
    InvoiceStatus? status,
    DateTime? issueDate,
    DateTime? dueDate,
    DateTime? paidDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? notes,
    String? paymentTerms,
    Map<String, dynamic>? metadata,
  }) {
    return Invoice(
      id: id ?? this.id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      orderId: orderId ?? this.orderId,
      orderNumber: orderNumber ?? this.orderNumber,
      userId: userId ?? this.userId,
      companyInfo: companyInfo ?? this.companyInfo,
      billingAddress: billingAddress ?? this.billingAddress,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      taxTotal: taxTotal ?? this.taxTotal,
      shippingCost: shippingCost ?? this.shippingCost,
      discount: discount ?? this.discount,
      total: total ?? this.total,
      currency: currency ?? this.currency,
      status: status ?? this.status,
      issueDate: issueDate ?? this.issueDate,
      dueDate: dueDate ?? this.dueDate,
      paidDate: paidDate ?? this.paidDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      notes: notes ?? this.notes,
      paymentTerms: paymentTerms ?? this.paymentTerms,
      metadata: metadata ?? this.metadata,
    );
  }

  bool get isPaid => status == InvoiceStatus.paid;

  bool get isOverdue {
    if (isPaid) return false;
    return DateTime.now().isAfter(dueDate);
  }

  int get daysPastDue {
    if (!isOverdue) return 0;
    return DateTime.now().difference(dueDate).inDays;
  }

  int get daysUntilDue {
    if (isPaid) return 0;
    final difference = dueDate.difference(DateTime.now()).inDays;
    return difference > 0 ? difference : 0;
  }

  String get statusDisplayName {
    switch (status) {
      case InvoiceStatus.draft:
        return 'Draft';
      case InvoiceStatus.sent:
        return 'Sent';
      case InvoiceStatus.paid:
        return 'Paid';
      case InvoiceStatus.overdue:
        return 'Overdue';
      case InvoiceStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get dueDateDisplay {
    if (isPaid) {
      return 'Paid on ${_formatDate(paidDate!)}';
    } else if (isOverdue) {
      return 'Overdue by $daysPastDue days';
    } else {
      return 'Due ${_formatDate(dueDate)}';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  static String _generateInvoiceNumber() {
    final now = DateTime.now();
    final year = now.year.toString().substring(2);
    final month = now.month.toString().padLeft(2, '0');
    final timestamp = now.millisecondsSinceEpoch;
    final sequence = (timestamp % 10000).toString().padLeft(4, '0');

    return 'INV-$year$month-$sequence';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Invoice && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}