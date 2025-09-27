enum UserRole {
  user,
  admin,
}

class LoyaltyInfo {
  final int points;
  final String tier;
  final DateTime? lastEarned;

  LoyaltyInfo({
    this.points = 0,
    this.tier = 'Bronze',
    this.lastEarned,
  });

  Map<String, dynamic> toMap() {
    return {
      'points': points,
      'tier': tier,
      'lastEarned': lastEarned?.toIso8601String(),
    };
  }

  factory LoyaltyInfo.fromMap(Map<String, dynamic> map) {
    return LoyaltyInfo(
      points: map['points'] ?? 0,
      tier: map['tier'] ?? 'Bronze',
      lastEarned: map['lastEarned'] != null
          ? DateTime.parse(map['lastEarned'])
          : null,
    );
  }

  LoyaltyInfo copyWith({
    int? points,
    String? tier,
    DateTime? lastEarned,
  }) {
    return LoyaltyInfo(
      points: points ?? this.points,
      tier: tier ?? this.tier,
      lastEarned: lastEarned ?? this.lastEarned,
    );
  }
}

class ServicePreferences {
  final List<String> preferredTimeSlots;
  final List<String> availableDays;
  final bool emailReminders;
  final bool smsReminders;
  final bool pushNotifications;
  final int reminderDaysBefore;
  final String? preferredContactMethod;
  final String? specialInstructions;

  ServicePreferences({
    this.preferredTimeSlots = const ['09:00-12:00'],
    this.availableDays = const ['monday', 'tuesday', 'wednesday', 'thursday', 'friday'],
    this.emailReminders = true,
    this.smsReminders = false,
    this.pushNotifications = true,
    this.reminderDaysBefore = 14,
    this.preferredContactMethod = 'email',
    this.specialInstructions,
  });

  Map<String, dynamic> toMap() {
    return {
      'preferredTimeSlots': preferredTimeSlots,
      'availableDays': availableDays,
      'emailReminders': emailReminders,
      'smsReminders': smsReminders,
      'pushNotifications': pushNotifications,
      'reminderDaysBefore': reminderDaysBefore,
      'preferredContactMethod': preferredContactMethod,
      'specialInstructions': specialInstructions,
    };
  }

  factory ServicePreferences.fromMap(Map<String, dynamic> map) {
    return ServicePreferences(
      preferredTimeSlots: (map['preferredTimeSlots'] as List<dynamic>?)
          ?.map((slot) => slot.toString())
          .toList() ?? ['09:00-12:00'],
      availableDays: (map['availableDays'] as List<dynamic>?)
          ?.map((day) => day.toString())
          .toList() ?? ['monday', 'tuesday', 'wednesday', 'thursday', 'friday'],
      emailReminders: map['emailReminders'] ?? true,
      smsReminders: map['smsReminders'] ?? false,
      pushNotifications: map['pushNotifications'] ?? true,
      reminderDaysBefore: map['reminderDaysBefore'] ?? 14,
      preferredContactMethod: map['preferredContactMethod'] ?? 'email',
      specialInstructions: map['specialInstructions'],
    );
  }

  ServicePreferences copyWith({
    List<String>? preferredTimeSlots,
    List<String>? availableDays,
    bool? emailReminders,
    bool? smsReminders,
    bool? pushNotifications,
    int? reminderDaysBefore,
    String? preferredContactMethod,
    String? specialInstructions,
  }) {
    return ServicePreferences(
      preferredTimeSlots: preferredTimeSlots ?? this.preferredTimeSlots,
      availableDays: availableDays ?? this.availableDays,
      emailReminders: emailReminders ?? this.emailReminders,
      smsReminders: smsReminders ?? this.smsReminders,
      pushNotifications: pushNotifications ?? this.pushNotifications,
      reminderDaysBefore: reminderDaysBefore ?? this.reminderDaysBefore,
      preferredContactMethod: preferredContactMethod ?? this.preferredContactMethod,
      specialInstructions: specialInstructions ?? this.specialInstructions,
    );
  }
}

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final String? phoneNumber;
  final DateTime createdAt;
  final DateTime lastLogin;
  final bool isEmailVerified;
  final UserRole role;
  final int? wooCustomerId;
  final String? defaultAddressId;
  final bool marketingConsent;
  final LoyaltyInfo loyalty;
  final ServicePreferences servicePreferences;
  final Map<String, dynamic>? additionalInfo;

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.phoneNumber,
    required this.createdAt,
    required this.lastLogin,
    this.isEmailVerified = false,
    this.role = UserRole.user,
    this.wooCustomerId,
    this.defaultAddressId,
    this.marketingConsent = false,
    LoyaltyInfo? loyalty,
    ServicePreferences? servicePreferences,
    this.additionalInfo,
  }) : loyalty = loyalty ?? LoyaltyInfo(),
       servicePreferences = servicePreferences ?? ServicePreferences();

  bool get isAdmin => role == UserRole.admin;
  bool get hasWooCustomer => wooCustomerId != null;

  String get loyaltyTierDisplayName {
    switch (loyalty.tier.toLowerCase()) {
      case 'bronze':
        return 'Bronze Member';
      case 'silver':
        return 'Silver Member';
      case 'gold':
        return 'Gold Member';
      case 'platinum':
        return 'Platinum Member';
      default:
        return loyalty.tier;
    }
  }

  // Convert UserModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'phoneNumber': phoneNumber,
      'createdAt': createdAt.toIso8601String(),
      'lastLogin': lastLogin.toIso8601String(),
      'isEmailVerified': isEmailVerified,
      'role': role.toString().split('.').last,
      'wooCustomerId': wooCustomerId,
      'defaultAddressId': defaultAddressId,
      'marketingConsent': marketingConsent,
      'loyalty': loyalty.toMap(),
      'servicePreferences': servicePreferences.toMap(),
      'additionalInfo': additionalInfo,
    };
  }

  // Create UserModel from Firestore document
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? '',
      photoUrl: map['photoUrl'],
      phoneNumber: map['phoneNumber'],
      createdAt: DateTime.parse(map['createdAt']),
      lastLogin: DateTime.parse(map['lastLogin']),
      isEmailVerified: map['isEmailVerified'] ?? false,
      role: UserRole.values.firstWhere(
        (role) => role.toString().split('.').last == map['role'],
        orElse: () => UserRole.user,
      ),
      wooCustomerId: map['wooCustomerId'],
      defaultAddressId: map['defaultAddressId'],
      marketingConsent: map['marketingConsent'] ?? false,
      loyalty: map['loyalty'] != null
          ? LoyaltyInfo.fromMap(map['loyalty'])
          : LoyaltyInfo(),
      servicePreferences: map['servicePreferences'] != null
          ? ServicePreferences.fromMap(map['servicePreferences'])
          : ServicePreferences(),
      additionalInfo: map['additionalInfo'],
    );
  }

  // Copy with method for updates
  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoUrl,
    String? phoneNumber,
    DateTime? createdAt,
    DateTime? lastLogin,
    bool? isEmailVerified,
    UserRole? role,
    int? wooCustomerId,
    String? defaultAddressId,
    bool? marketingConsent,
    LoyaltyInfo? loyalty,
    ServicePreferences? servicePreferences,
    Map<String, dynamic>? additionalInfo,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      role: role ?? this.role,
      wooCustomerId: wooCustomerId ?? this.wooCustomerId,
      defaultAddressId: defaultAddressId ?? this.defaultAddressId,
      marketingConsent: marketingConsent ?? this.marketingConsent,
      loyalty: loyalty ?? this.loyalty,
      servicePreferences: servicePreferences ?? this.servicePreferences,
      additionalInfo: additionalInfo ?? this.additionalInfo,
    );
  }
}

extension UserRoleExtension on UserRole {
  String get displayName {
    switch (this) {
      case UserRole.user:
        return 'Customer';
      case UserRole.admin:
        return 'Administrator';
    }
  }

  String get description {
    switch (this) {
      case UserRole.user:
        return 'Regular customer with access to orders and service requests';
      case UserRole.admin:
        return 'Administrator with full access to manage users and service requests';
    }
  }
}