import 'dart:convert';

enum ServiceComponentType {
  sediment,
  carbon,
  membrane,
  mineralizer,
  co2,
  unknown,
}

class ServiceComponent {
  final ServiceComponentType type;
  final String sku;
  final String name;
  final int intervalDays;
  final DateTime lastChangedAt;
  final String? notes;

  ServiceComponent({
    required this.type,
    required this.sku,
    required this.name,
    required this.intervalDays,
    required this.lastChangedAt,
    this.notes,
  });

  DateTime get nextDueDate {
    return lastChangedAt.add(Duration(days: intervalDays));
  }

  bool get isDue {
    return DateTime.now().isAfter(nextDueDate);
  }

  bool get isDueSoon {
    final daysUntilDue = nextDueDate.difference(DateTime.now()).inDays;
    return daysUntilDue <= 30 && daysUntilDue >= 0;
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type.toString().split('.').last,
      'sku': sku,
      'name': name,
      'intervalDays': intervalDays,
      'lastChangedAt': lastChangedAt.toIso8601String(),
      'notes': notes,
    };
  }

  factory ServiceComponent.fromMap(Map<String, dynamic> map) {
    return ServiceComponent(
      type: ServiceComponentType.values.firstWhere(
        (type) => type.toString().split('.').last == map['type'],
        orElse: () => ServiceComponentType.unknown,
      ),
      sku: map['sku'] ?? '',
      name: map['name'] ?? '',
      intervalDays: map['intervalDays'] ?? 180, // Default 6 months
      lastChangedAt: DateTime.parse(map['lastChangedAt']),
      notes: map['notes'],
    );
  }

  ServiceComponent copyWith({
    ServiceComponentType? type,
    String? sku,
    String? name,
    int? intervalDays,
    DateTime? lastChangedAt,
    String? notes,
  }) {
    return ServiceComponent(
      type: type ?? this.type,
      sku: sku ?? this.sku,
      name: name ?? this.name,
      intervalDays: intervalDays ?? this.intervalDays,
      lastChangedAt: lastChangedAt ?? this.lastChangedAt,
      notes: notes ?? this.notes,
    );
  }
}

enum SystemType {
  underSink,
  wholehouse,
  commercial,
  portable,
  unknown,
}

class WaterFilterSystem {
  final String brand;
  final String model;
  final String? serial;
  final SystemType type;
  final List<ServiceComponent> components;
  final String? notes;

  WaterFilterSystem({
    required this.brand,
    required this.model,
    this.serial,
    required this.type,
    required this.components,
    this.notes,
  });

  DateTime? get nextServiceDate {
    if (components.isEmpty) return null;

    final dueDates = components.map((c) => c.nextDueDate).toList();
    dueDates.sort();
    return dueDates.first;
  }

  bool get hasOverdueComponents {
    return components.any((c) => c.isDue);
  }

  bool get hasDueSoonComponents {
    return components.any((c) => c.isDueSoon);
  }

  List<ServiceComponent> get overdueComponents {
    return components.where((c) => c.isDue).toList();
  }

  List<ServiceComponent> get dueSoonComponents {
    return components.where((c) => c.isDueSoon).toList();
  }

  Map<String, dynamic> toMap() {
    return {
      'brand': brand,
      'model': model,
      'serial': serial,
      'type': type.toString().split('.').last,
      'components': components.map((c) => c.toMap()).toList(),
      'notes': notes,
    };
  }

  factory WaterFilterSystem.fromMap(Map<String, dynamic> map) {
    return WaterFilterSystem(
      brand: map['brand'] ?? '',
      model: map['model'] ?? '',
      serial: map['serial'],
      type: SystemType.values.firstWhere(
        (type) => type.toString().split('.').last == map['type'],
        orElse: () => SystemType.unknown,
      ),
      components: (map['components'] as List<dynamic>?)
          ?.map((c) => ServiceComponent.fromMap(c))
          .toList() ?? [],
      notes: map['notes'],
    );
  }

  WaterFilterSystem copyWith({
    String? brand,
    String? model,
    String? serial,
    SystemType? type,
    List<ServiceComponent>? components,
    String? notes,
  }) {
    return WaterFilterSystem(
      brand: brand ?? this.brand,
      model: model ?? this.model,
      serial: serial ?? this.serial,
      type: type ?? this.type,
      components: components ?? this.components,
      notes: notes ?? this.notes,
    );
  }
}

class ServiceProfile {
  final String id;
  final String userId;
  final String addressId;
  final String addressLabel;
  final WaterFilterSystem system;
  final DateTime installedAt;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isActive;
  final String? technicianNotes;

  ServiceProfile({
    required this.id,
    required this.userId,
    required this.addressId,
    required this.addressLabel,
    required this.system,
    required this.installedAt,
    required this.createdAt,
    this.updatedAt,
    this.isActive = true,
    this.technicianNotes,
  });

  DateTime? get nextServiceDate => system.nextServiceDate;
  bool get needsService => system.hasOverdueComponents || system.hasDueSoonComponents;
  bool get hasOverdueService => system.hasOverdueComponents;

  String get displayName {
    return '${system.brand} ${system.model} - $addressLabel';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'addressId': addressId,
      'addressLabel': addressLabel,
      'system': system.toMap(),
      'installedAt': installedAt.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'isActive': isActive,
      'technicianNotes': technicianNotes,
    };
  }

  factory ServiceProfile.fromMap(Map<String, dynamic> map) {
    return ServiceProfile(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      addressId: map['addressId'] ?? '',
      addressLabel: map['addressLabel'] ?? '',
      system: WaterFilterSystem.fromMap(map['system'] ?? {}),
      installedAt: DateTime.parse(map['installedAt']),
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
      isActive: map['isActive'] ?? true,
      technicianNotes: map['technicianNotes'],
    );
  }

  factory ServiceProfile.fromJson(String source) =>
      ServiceProfile.fromMap(json.decode(source));

  String toJson() => json.encode(toMap());

  ServiceProfile copyWith({
    String? id,
    String? userId,
    String? addressId,
    String? addressLabel,
    WaterFilterSystem? system,
    DateTime? installedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    String? technicianNotes,
  }) {
    return ServiceProfile(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      addressId: addressId ?? this.addressId,
      addressLabel: addressLabel ?? this.addressLabel,
      system: system ?? this.system,
      installedAt: installedAt ?? this.installedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      technicianNotes: technicianNotes ?? this.technicianNotes,
    );
  }
}

extension ServiceComponentTypeExtension on ServiceComponentType {
  String get displayName {
    switch (this) {
      case ServiceComponentType.sediment:
        return 'Sediment Filter';
      case ServiceComponentType.carbon:
        return 'Carbon Filter';
      case ServiceComponentType.membrane:
        return 'RO Membrane';
      case ServiceComponentType.mineralizer:
        return 'Mineralizer';
      case ServiceComponentType.co2:
        return 'CO₂ Cartridge';
      case ServiceComponentType.unknown:
        return 'Unknown Component';
    }
  }

  int get defaultIntervalDays {
    switch (this) {
      case ServiceComponentType.sediment:
      case ServiceComponentType.carbon:
        return 180; // 6 months
      case ServiceComponentType.membrane:
        return 730; // 2 years
      case ServiceComponentType.mineralizer:
        return 365; // 1 year
      case ServiceComponentType.co2:
        return 90; // 3 months for restaurant systems
      case ServiceComponentType.unknown:
        return 180; // Default 6 months
    }
  }
}

extension SystemTypeExtension on SystemType {
  String get displayName {
    switch (this) {
      case SystemType.underSink:
        return 'Under-Sink System';
      case SystemType.wholehouse:
        return 'Whole House System';
      case SystemType.commercial:
        return 'Commercial System';
      case SystemType.portable:
        return 'Portable System';
      case SystemType.unknown:
        return 'Unknown System';
    }
  }
}