import 'dart:convert';

enum AddressType {
  shipping,
  billing,
  home,
  work,
  other,
}

class ShippingAddress {
  final String id;
  final String userId;
  final String firstName;
  final String lastName;
  final String company;
  final String addressLine1;
  final String addressLine2;
  final String city;
  final String state;
  final String postalCode;
  final String country;
  final String countryCode;
  final String phoneNumber;
  final AddressType type;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic>? coordinates;

  ShippingAddress({
    required this.id,
    required this.userId,
    required this.firstName,
    required this.lastName,
    this.company = '',
    required this.addressLine1,
    this.addressLine2 = '',
    required this.city,
    required this.state,
    required this.postalCode,
    required this.country,
    required this.countryCode,
    this.phoneNumber = '',
    this.type = AddressType.home,
    this.isDefault = false,
    required this.createdAt,
    this.updatedAt,
    this.coordinates,
  });

  factory ShippingAddress.fromMap(Map<String, dynamic> map) {
    return ShippingAddress(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      firstName: map['firstName'] ?? '',
      lastName: map['lastName'] ?? '',
      company: map['company'] ?? '',
      addressLine1: map['addressLine1'] ?? '',
      addressLine2: map['addressLine2'] ?? '',
      city: map['city'] ?? '',
      state: map['state'] ?? '',
      postalCode: map['postalCode'] ?? '',
      country: map['country'] ?? '',
      countryCode: map['countryCode'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      type: AddressType.values.firstWhere(
        (type) => type.toString().split('.').last == map['type'],
        orElse: () => AddressType.home,
      ),
      isDefault: map['isDefault'] ?? false,
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
      coordinates: map['coordinates'] != null ? Map<String, dynamic>.from(map['coordinates']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'firstName': firstName,
      'lastName': lastName,
      'company': company,
      'addressLine1': addressLine1,
      'addressLine2': addressLine2,
      'city': city,
      'state': state,
      'postalCode': postalCode,
      'country': country,
      'countryCode': countryCode,
      'phoneNumber': phoneNumber,
      'type': type.toString().split('.').last,
      'isDefault': isDefault,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'coordinates': coordinates,
    };
  }

  factory ShippingAddress.fromJson(String source) =>
      ShippingAddress.fromMap(json.decode(source));

  String toJson() => json.encode(toMap());

  ShippingAddress copyWith({
    String? id,
    String? userId,
    String? firstName,
    String? lastName,
    String? company,
    String? addressLine1,
    String? addressLine2,
    String? city,
    String? state,
    String? postalCode,
    String? country,
    String? countryCode,
    String? phoneNumber,
    AddressType? type,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? coordinates,
  }) {
    return ShippingAddress(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      company: company ?? this.company,
      addressLine1: addressLine1 ?? this.addressLine1,
      addressLine2: addressLine2 ?? this.addressLine2,
      city: city ?? this.city,
      state: state ?? this.state,
      postalCode: postalCode ?? this.postalCode,
      country: country ?? this.country,
      countryCode: countryCode ?? this.countryCode,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      type: type ?? this.type,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      coordinates: coordinates ?? this.coordinates,
    );
  }

  String get fullName {
    return '$firstName $lastName'.trim();
  }

  String get displayName {
    if (company.isNotEmpty) {
      return '$fullName - $company';
    }
    return fullName;
  }

  String get fullAddress {
    final buffer = StringBuffer();

    buffer.writeln(addressLine1);

    if (addressLine2.isNotEmpty) {
      buffer.writeln(addressLine2);
    }

    buffer.writeln('$city, $state $postalCode');
    buffer.write(country);

    return buffer.toString();
  }

  String get shortAddress {
    final buffer = StringBuffer();

    buffer.write(addressLine1);

    if (addressLine2.isNotEmpty) {
      buffer.write(', ${addressLine2}');
    }

    buffer.write(', $city');

    return buffer.toString();
  }

  String get typeDisplayName {
    switch (type) {
      case AddressType.shipping:
        return 'Shipping';
      case AddressType.billing:
        return 'Billing';
      case AddressType.home:
        return 'Home';
      case AddressType.work:
        return 'Work';
      case AddressType.other:
        return 'Other';
    }
  }

  Map<String, dynamic> toWooCommerceFormat({bool isBilling = false}) {
    final prefix = isBilling ? 'billing' : 'shipping';

    return {
      '${prefix}_first_name': firstName,
      '${prefix}_last_name': lastName,
      '${prefix}_company': company,
      '${prefix}_address_1': addressLine1,
      '${prefix}_address_2': addressLine2,
      '${prefix}_city': city,
      '${prefix}_state': state,
      '${prefix}_postcode': postalCode,
      '${prefix}_country': countryCode,
      if (isBilling) '${prefix}_phone': phoneNumber,
      if (isBilling) '${prefix}_email': '',
    };
  }

  static bool isValidPostalCode(String postalCode, String countryCode) {
    switch (countryCode.toUpperCase()) {
      case 'CY':
        return RegExp(r'^\d{4}$').hasMatch(postalCode);
      case 'US':
        return RegExp(r'^\d{5}(-\d{4})?$').hasMatch(postalCode);
      case 'CA':
        return RegExp(r'^[A-Za-z]\d[A-Za-z] \d[A-Za-z]\d$').hasMatch(postalCode);
      case 'GB':
        return RegExp(r'^[A-Z]{1,2}\d[A-Z\d]? \d[A-Z]{2}$').hasMatch(postalCode);
      case 'DE':
        return RegExp(r'^\d{5}$').hasMatch(postalCode);
      case 'FR':
        return RegExp(r'^\d{5}$').hasMatch(postalCode);
      case 'IT':
        return RegExp(r'^\d{5}$').hasMatch(postalCode);
      case 'ES':
        return RegExp(r'^\d{5}$').hasMatch(postalCode);
      case 'AU':
        return RegExp(r'^\d{4}$').hasMatch(postalCode);
      case 'JP':
        return RegExp(r'^\d{3}-\d{4}$').hasMatch(postalCode);
      case 'BR':
        return RegExp(r'^\d{5}-\d{3}$').hasMatch(postalCode);
      case 'IN':
        return RegExp(r'^\d{6}$').hasMatch(postalCode);
      case 'NL':
        return RegExp(r'^\d{4} [A-Z]{2}$').hasMatch(postalCode);
      case 'IE':
        return RegExp(r'^[A-Z]\d{2} [A-Z\d]{4}$').hasMatch(postalCode);
      default:
        return postalCode.isNotEmpty;
    }
  }

  static bool isValidPhoneNumber(String phoneNumber) {
    if (phoneNumber.isEmpty) return true;

    final cleaned = phoneNumber.replaceAll(RegExp(r'[\s\-\(\)\+]'), '');
    return RegExp(r'^\d{10,15}$').hasMatch(cleaned);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ShippingAddress &&
      other.id == id &&
      other.firstName == firstName &&
      other.lastName == lastName &&
      other.company == company &&
      other.addressLine1 == addressLine1 &&
      other.addressLine2 == addressLine2 &&
      other.city == city &&
      other.state == state &&
      other.postalCode == postalCode &&
      other.country == country &&
      other.countryCode == countryCode &&
      other.phoneNumber == phoneNumber &&
      other.type == type &&
      other.isDefault == isDefault;
  }

  @override
  int get hashCode {
    return id.hashCode ^
      firstName.hashCode ^
      lastName.hashCode ^
      company.hashCode ^
      addressLine1.hashCode ^
      addressLine2.hashCode ^
      city.hashCode ^
      state.hashCode ^
      postalCode.hashCode ^
      country.hashCode ^
      countryCode.hashCode ^
      phoneNumber.hashCode ^
      type.hashCode ^
      isDefault.hashCode;
  }
}

class AddressValidation {
  static String? validateFirstName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'First name is required';
    }
    if (value.trim().length < 2) {
      return 'First name must be at least 2 characters';
    }
    if (value.trim().length > 50) {
      return 'First name must be less than 50 characters';
    }
    return null;
  }

  static String? validateLastName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Last name is required';
    }
    if (value.trim().length < 2) {
      return 'Last name must be at least 2 characters';
    }
    if (value.trim().length > 50) {
      return 'Last name must be less than 50 characters';
    }
    return null;
  }

  static String? validateAddressLine1(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Address is required';
    }
    if (value.trim().length < 5) {
      return 'Please enter a valid address';
    }
    if (value.trim().length > 100) {
      return 'Address must be less than 100 characters';
    }
    return null;
  }

  static String? validateCity(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'City is required';
    }
    if (value.trim().length < 2) {
      return 'Please enter a valid city';
    }
    if (value.trim().length > 50) {
      return 'City must be less than 50 characters';
    }
    return null;
  }

  static String? validateState(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'State/Province is required';
    }
    if (value.trim().length > 50) {
      return 'State/Province must be less than 50 characters';
    }
    return null;
  }

  static String? validatePostalCode(String? value, String countryCode) {
    if (value == null || value.trim().isEmpty) {
      return 'Postal code is required';
    }
    if (!ShippingAddress.isValidPostalCode(value.trim(), countryCode)) {
      return 'Please enter a valid postal code';
    }
    return null;
  }

  static String? validatePhoneNumber(String? value) {
    if (value != null && value.trim().isNotEmpty) {
      if (!ShippingAddress.isValidPhoneNumber(value)) {
        return 'Please enter a valid phone number';
      }
    }
    return null;
  }
}

// Common countries with their codes and names
class CountryData {
  final String code;
  final String name;
  final String flag;

  const CountryData({
    required this.code,
    required this.name,
    required this.flag,
  });

  static const List<CountryData> countries = [
    CountryData(code: 'CY', name: 'Cyprus', flag: '🇨🇾'),
  ];

  static CountryData? findByCode(String code) {
    try {
      return countries.firstWhere((country) => country.code == code.toUpperCase());
    } catch (e) {
      return null;
    }
  }

  static CountryData? findByName(String name) {
    try {
      return countries.firstWhere((country) =>
        country.name.toLowerCase() == name.toLowerCase());
    } catch (e) {
      return null;
    }
  }
}