import 'dart:convert';

enum ServiceRequestType {
  filterChange,
  installation,
  repair,
  inspection,
  co2Exchange,
  maintenance,
  other,
}

enum ServiceRequestStatus {
  pending,
  confirmed,
  scheduled,
  inProgress,
  completed,
  cancelled,
}

enum ServiceRequestPriority {
  low,
  normal,
  high,
  urgent,
}

class ServiceRequestItem {
  final String sku;
  final String name;
  final int quantity;
  final double price;
  final String? notes;

  ServiceRequestItem({
    required this.sku,
    required this.name,
    required this.quantity,
    required this.price,
    this.notes,
  });

  double get total => price * quantity;

  Map<String, dynamic> toMap() {
    return {
      'sku': sku,
      'name': name,
      'quantity': quantity,
      'price': price,
      'notes': notes,
    };
  }

  factory ServiceRequestItem.fromMap(Map<String, dynamic> map) {
    return ServiceRequestItem(
      sku: map['sku'] ?? '',
      name: map['name'] ?? '',
      quantity: map['quantity'] ?? 1,
      price: (map['price'] ?? 0.0).toDouble(),
      notes: map['notes'],
    );
  }

  ServiceRequestItem copyWith({
    String? sku,
    String? name,
    int? quantity,
    double? price,
    String? notes,
  }) {
    return ServiceRequestItem(
      sku: sku ?? this.sku,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      notes: notes ?? this.notes,
    );
  }
}

class ServiceQuote {
  final List<ServiceRequestItem> items;
  final double laborCost;
  final double travelCost;
  final double discount;
  final String? notes;

  ServiceQuote({
    required this.items,
    this.laborCost = 0.0,
    this.travelCost = 0.0,
    this.discount = 0.0,
    this.notes,
  });

  double get subtotal => items.fold(0.0, (sum, item) => sum + item.total);
  double get total => subtotal + laborCost + travelCost - discount;

  Map<String, dynamic> toMap() {
    return {
      'items': items.map((item) => item.toMap()).toList(),
      'laborCost': laborCost,
      'travelCost': travelCost,
      'discount': discount,
      'notes': notes,
    };
  }

  factory ServiceQuote.fromMap(Map<String, dynamic> map) {
    return ServiceQuote(
      items: (map['items'] as List<dynamic>?)
          ?.map((item) => ServiceRequestItem.fromMap(item))
          .toList() ?? [],
      laborCost: (map['laborCost'] ?? 0.0).toDouble(),
      travelCost: (map['travelCost'] ?? 0.0).toDouble(),
      discount: (map['discount'] ?? 0.0).toDouble(),
      notes: map['notes'],
    );
  }

  ServiceQuote copyWith({
    List<ServiceRequestItem>? items,
    double? laborCost,
    double? travelCost,
    double? discount,
    String? notes,
  }) {
    return ServiceQuote(
      items: items ?? this.items,
      laborCost: laborCost ?? this.laborCost,
      travelCost: travelCost ?? this.travelCost,
      discount: discount ?? this.discount,
      notes: notes ?? this.notes,
    );
  }
}

class PreferredSchedule {
  final DateTime? preferredDate;
  final String? preferredTimeSlot; // e.g., "09:00-12:00", "14:00-17:00"
  final List<String>? availableDays; // e.g., ["monday", "tuesday", "friday"]
  final String? notes;

  PreferredSchedule({
    this.preferredDate,
    this.preferredTimeSlot,
    this.availableDays,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'preferredDate': preferredDate?.toIso8601String(),
      'preferredTimeSlot': preferredTimeSlot,
      'availableDays': availableDays,
      'notes': notes,
    };
  }

  factory PreferredSchedule.fromMap(Map<String, dynamic> map) {
    return PreferredSchedule(
      preferredDate: map['preferredDate'] != null
          ? DateTime.parse(map['preferredDate'])
          : null,
      preferredTimeSlot: map['preferredTimeSlot'],
      availableDays: (map['availableDays'] as List<dynamic>?)
          ?.map((day) => day.toString())
          .toList(),
      notes: map['notes'],
    );
  }

  PreferredSchedule copyWith({
    DateTime? preferredDate,
    String? preferredTimeSlot,
    List<String>? availableDays,
    String? notes,
  }) {
    return PreferredSchedule(
      preferredDate: preferredDate ?? this.preferredDate,
      preferredTimeSlot: preferredTimeSlot ?? this.preferredTimeSlot,
      availableDays: availableDays ?? this.availableDays,
      notes: notes ?? this.notes,
    );
  }
}

class ServiceRequest {
  final String id;
  final String userId;
  final String? serviceProfileId;
  final ServiceRequestType type;
  final ServiceRequestStatus status;
  final ServiceRequestPriority priority;
  final String title;
  final String description;
  final String addressId;
  final Map<String, dynamic> addressSnapshot;
  final PreferredSchedule? preferredSchedule;
  final ServiceQuote? quote;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? scheduledAt;
  final DateTime? completedAt;
  final String? wooOrderId;
  final List<String> photos;
  final String? completionNotes;
  final String? internalNotes;

  ServiceRequest({
    required this.id,
    required this.userId,
    this.serviceProfileId,
    required this.type,
    this.status = ServiceRequestStatus.pending,
    this.priority = ServiceRequestPriority.normal,
    required this.title,
    required this.description,
    required this.addressId,
    required this.addressSnapshot,
    this.preferredSchedule,
    this.quote,
    required this.createdAt,
    this.updatedAt,
    this.scheduledAt,
    this.completedAt,
    this.wooOrderId,
    this.photos = const [],
    this.completionNotes,
    this.internalNotes,
  });

  bool get isCompleted => status == ServiceRequestStatus.completed;
  bool get isCancelled => status == ServiceRequestStatus.cancelled;
  bool get isPending => status == ServiceRequestStatus.pending;
  bool get isScheduled => status == ServiceRequestStatus.scheduled;
  bool get isInProgress => status == ServiceRequestStatus.inProgress;

  String get displayAddress {
    final address = addressSnapshot;
    return '${address['addressLine1']}, ${address['city']}';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'serviceProfileId': serviceProfileId,
      'type': type.toString().split('.').last,
      'status': status.toString().split('.').last,
      'priority': priority.toString().split('.').last,
      'title': title,
      'description': description,
      'addressId': addressId,
      'addressSnapshot': addressSnapshot,
      'preferredSchedule': preferredSchedule?.toMap(),
      'quote': quote?.toMap(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'scheduledAt': scheduledAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'wooOrderId': wooOrderId,
      'photos': photos,
      'completionNotes': completionNotes,
      'internalNotes': internalNotes,
    };
  }

  factory ServiceRequest.fromMap(Map<String, dynamic> map) {
    return ServiceRequest(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      serviceProfileId: map['serviceProfileId'],
      type: ServiceRequestType.values.firstWhere(
        (type) => type.toString().split('.').last == map['type'],
        orElse: () => ServiceRequestType.other,
      ),
      status: ServiceRequestStatus.values.firstWhere(
        (status) => status.toString().split('.').last == map['status'],
        orElse: () => ServiceRequestStatus.pending,
      ),
      priority: ServiceRequestPriority.values.firstWhere(
        (priority) => priority.toString().split('.').last == map['priority'],
        orElse: () => ServiceRequestPriority.normal,
      ),
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      addressId: map['addressId'] ?? '',
      addressSnapshot: Map<String, dynamic>.from(map['addressSnapshot'] ?? {}),
      preferredSchedule: map['preferredSchedule'] != null
          ? PreferredSchedule.fromMap(map['preferredSchedule'])
          : null,
      quote: map['quote'] != null ? ServiceQuote.fromMap(map['quote']) : null,
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
      scheduledAt: map['scheduledAt'] != null ? DateTime.parse(map['scheduledAt']) : null,
      completedAt: map['completedAt'] != null ? DateTime.parse(map['completedAt']) : null,
      wooOrderId: map['wooOrderId'],
      photos: (map['photos'] as List<dynamic>?)
          ?.map((photo) => photo.toString())
          .toList() ?? [],
      completionNotes: map['completionNotes'],
      internalNotes: map['internalNotes'],
    );
  }

  factory ServiceRequest.fromJson(String source) =>
      ServiceRequest.fromMap(json.decode(source));

  String toJson() => json.encode(toMap());

  ServiceRequest copyWith({
    String? id,
    String? userId,
    String? serviceProfileId,
    ServiceRequestType? type,
    ServiceRequestStatus? status,
    ServiceRequestPriority? priority,
    String? title,
    String? description,
    String? addressId,
    Map<String, dynamic>? addressSnapshot,
    PreferredSchedule? preferredSchedule,
    ServiceQuote? quote,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? scheduledAt,
    DateTime? completedAt,
    String? wooOrderId,
    List<String>? photos,
    String? completionNotes,
    String? internalNotes,
  }) {
    return ServiceRequest(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      serviceProfileId: serviceProfileId ?? this.serviceProfileId,
      type: type ?? this.type,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      title: title ?? this.title,
      description: description ?? this.description,
      addressId: addressId ?? this.addressId,
      addressSnapshot: addressSnapshot ?? this.addressSnapshot,
      preferredSchedule: preferredSchedule ?? this.preferredSchedule,
      quote: quote ?? this.quote,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      completedAt: completedAt ?? this.completedAt,
      wooOrderId: wooOrderId ?? this.wooOrderId,
      photos: photos ?? this.photos,
      completionNotes: completionNotes ?? this.completionNotes,
      internalNotes: internalNotes ?? this.internalNotes,
    );
  }
}

extension ServiceRequestTypeExtension on ServiceRequestType {
  String get displayName {
    switch (this) {
      case ServiceRequestType.filterChange:
        return 'Filter Change';
      case ServiceRequestType.installation:
        return 'New Installation';
      case ServiceRequestType.repair:
        return 'System Repair';
      case ServiceRequestType.inspection:
        return 'System Inspection';
      case ServiceRequestType.co2Exchange:
        return 'CO₂ Exchange';
      case ServiceRequestType.maintenance:
        return 'Routine Maintenance';
      case ServiceRequestType.other:
        return 'Other Service';
    }
  }

  String get description {
    switch (this) {
      case ServiceRequestType.filterChange:
        return 'Replace water filter components';
      case ServiceRequestType.installation:
        return 'Install new water filtration system';
      case ServiceRequestType.repair:
        return 'Repair existing water filtration system';
      case ServiceRequestType.inspection:
        return 'Inspect and test water filtration system';
      case ServiceRequestType.co2Exchange:
        return 'Exchange CO₂ cartridge for sparkling water systems';
      case ServiceRequestType.maintenance:
        return 'Routine maintenance and system check';
      case ServiceRequestType.other:
        return 'Other water filtration service';
    }
  }
}

extension ServiceRequestStatusExtension on ServiceRequestStatus {
  String get displayName {
    switch (this) {
      case ServiceRequestStatus.pending:
        return 'Pending Review';
      case ServiceRequestStatus.confirmed:
        return 'Confirmed';
      case ServiceRequestStatus.scheduled:
        return 'Scheduled';
      case ServiceRequestStatus.inProgress:
        return 'In Progress';
      case ServiceRequestStatus.completed:
        return 'Completed';
      case ServiceRequestStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get colorCode {
    switch (this) {
      case ServiceRequestStatus.pending:
        return '#FFA500'; // Orange
      case ServiceRequestStatus.confirmed:
        return '#2196F3'; // Blue
      case ServiceRequestStatus.scheduled:
        return '#9C27B0'; // Purple
      case ServiceRequestStatus.inProgress:
        return '#FF9800'; // Amber
      case ServiceRequestStatus.completed:
        return '#4CAF50'; // Green
      case ServiceRequestStatus.cancelled:
        return '#F44336'; // Red
    }
  }
}

extension ServiceRequestPriorityExtension on ServiceRequestPriority {
  String get displayName {
    switch (this) {
      case ServiceRequestPriority.low:
        return 'Low Priority';
      case ServiceRequestPriority.normal:
        return 'Normal Priority';
      case ServiceRequestPriority.high:
        return 'High Priority';
      case ServiceRequestPriority.urgent:
        return 'Urgent';
    }
  }

  String get colorCode {
    switch (this) {
      case ServiceRequestPriority.low:
        return '#4CAF50'; // Green
      case ServiceRequestPriority.normal:
        return '#2196F3'; // Blue
      case ServiceRequestPriority.high:
        return '#FF9800'; // Orange
      case ServiceRequestPriority.urgent:
        return '#F44336'; // Red
    }
  }
}