import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/service_profile.dart';
import '../models/shipping_address.dart';
import 'config_service.dart';

class ServiceProfileService {
  static final ServiceProfileService _instance = ServiceProfileService._internal();
  factory ServiceProfileService() => _instance;
  ServiceProfileService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ConfigService _config = ConfigService();

  static const String _serviceProfilesCollection = 'service_profiles';
  static const String _serviceCatalogCollection = 'service_catalog';

  // Demo storage for when Firestore is unavailable
  static final List<ServiceProfile> _demoProfiles = [];
  static final Map<String, List<ServiceProfile>> _demoUserProfiles = {};

  String get _currentUserId => _auth.currentUser?.uid ?? 'demo_user';

  /// Create a new service profile
  Future<String> createServiceProfile({
    required String addressId,
    required String addressLabel,
    required WaterFilterSystem system,
    DateTime? installedAt,
    String? technicianNotes,
  }) async {
    try {
      final userId = _currentUserId;
      final profileId = _generateProfileId();
      final now = DateTime.now();

      final profile = ServiceProfile(
        id: profileId,
        userId: userId,
        addressId: addressId,
        addressLabel: addressLabel,
        system: system,
        installedAt: installedAt ?? now,
        createdAt: now,
        technicianNotes: technicianNotes,
      );

      if (_config.isDemoMode) {
        print('ServiceProfileService: Creating profile in demo mode');
        _demoProfiles.add(profile);
        _demoUserProfiles[userId] = (_demoUserProfiles[userId] ?? [])..add(profile);
        return profileId;
      }

      // Save to Firestore
      await _firestore
          .collection('users')
          .doc(userId)
          .collection(_serviceProfilesCollection)
          .doc(profileId)
          .set(profile.toMap());

      print('ServiceProfileService: Profile created successfully: $profileId');
      return profileId;
    } catch (e) {
      print('ServiceProfileService: Error creating profile: $e');
      throw Exception('Failed to create service profile: $e');
    }
  }

  /// Get all service profiles for the current user
  Future<List<ServiceProfile>> getUserServiceProfiles({String? userId}) async {
    try {
      final targetUserId = userId ?? _currentUserId;

      if (_config.isDemoMode) {
        print('ServiceProfileService: Getting profiles in demo mode');
        return _demoUserProfiles[targetUserId] ?? [];
      }

      final querySnapshot = await _firestore
          .collection('users')
          .doc(targetUserId)
          .collection(_serviceProfilesCollection)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => ServiceProfile.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('ServiceProfileService: Error getting profiles: $e');
      if (_config.isDemoMode) {
        return _demoUserProfiles[userId ?? _currentUserId] ?? [];
      }
      throw Exception('Failed to get service profiles: $e');
    }
  }

  /// Get a specific service profile by ID
  Future<ServiceProfile?> getServiceProfile(String profileId, {String? userId}) async {
    try {
      final targetUserId = userId ?? _currentUserId;

      if (_config.isDemoMode) {
        return _demoUserProfiles[targetUserId]
            ?.where((p) => p.id == profileId)
            .firstOrNull;
      }

      final doc = await _firestore
          .collection('users')
          .doc(targetUserId)
          .collection(_serviceProfilesCollection)
          .doc(profileId)
          .get();

      if (!doc.exists) return null;
      return ServiceProfile.fromMap(doc.data()!);
    } catch (e) {
      print('ServiceProfileService: Error getting profile: $e');
      if (_config.isDemoMode) {
        return _demoUserProfiles[userId ?? _currentUserId]
            ?.where((p) => p.id == profileId)
            .firstOrNull;
      }
      return null;
    }
  }

  /// Update a service profile
  Future<void> updateServiceProfile(ServiceProfile profile) async {
    try {
      final updatedProfile = profile.copyWith(updatedAt: DateTime.now());

      if (_config.isDemoMode) {
        final userProfiles = _demoUserProfiles[profile.userId] ?? [];
        final index = userProfiles.indexWhere((p) => p.id == profile.id);
        if (index != -1) {
          userProfiles[index] = updatedProfile;
        }

        final globalIndex = _demoProfiles.indexWhere((p) => p.id == profile.id);
        if (globalIndex != -1) {
          _demoProfiles[globalIndex] = updatedProfile;
        }
        return;
      }

      await _firestore
          .collection('users')
          .doc(profile.userId)
          .collection(_serviceProfilesCollection)
          .doc(profile.id)
          .update(updatedProfile.toMap());

      print('ServiceProfileService: Profile updated successfully: ${profile.id}');
    } catch (e) {
      print('ServiceProfileService: Error updating profile: $e');
      throw Exception('Failed to update service profile: $e');
    }
  }

  /// Update specific components after service
  Future<void> updateServiceComponents({
    required String profileId,
    required List<ServiceComponent> updatedComponents,
    String? technicianNotes,
  }) async {
    try {
      final profile = await getServiceProfile(profileId);
      if (profile == null) {
        throw Exception('Service profile not found');
      }

      final updatedSystem = profile.system.copyWith(
        components: updatedComponents,
      );

      final updatedProfile = profile.copyWith(
        system: updatedSystem,
        updatedAt: DateTime.now(),
        technicianNotes: technicianNotes ?? profile.technicianNotes,
      );

      await updateServiceProfile(updatedProfile);
    } catch (e) {
      print('ServiceProfileService: Error updating components: $e');
      throw Exception('Failed to update service components: $e');
    }
  }

  /// Deactivate a service profile (soft delete)
  Future<void> deactivateServiceProfile(String profileId, {String? userId}) async {
    try {
      final profile = await getServiceProfile(profileId, userId: userId);
      if (profile == null) {
        throw Exception('Service profile not found');
      }

      final deactivatedProfile = profile.copyWith(
        isActive: false,
        updatedAt: DateTime.now(),
      );

      await updateServiceProfile(deactivatedProfile);
    } catch (e) {
      print('ServiceProfileService: Error deactivating profile: $e');
      throw Exception('Failed to deactivate service profile: $e');
    }
  }

  /// Get profiles that need service (overdue or due soon)
  Future<List<ServiceProfile>> getProfilesNeedingService({String? userId}) async {
    try {
      final profiles = await getUserServiceProfiles(userId: userId);
      return profiles.where((profile) => profile.needsService).toList();
    } catch (e) {
      print('ServiceProfileService: Error getting profiles needing service: $e');
      return [];
    }
  }

  /// Get profiles with overdue service
  Future<List<ServiceProfile>> getOverdueProfiles({String? userId}) async {
    try {
      final profiles = await getUserServiceProfiles(userId: userId);
      return profiles.where((profile) => profile.hasOverdueService).toList();
    } catch (e) {
      print('ServiceProfileService: Error getting overdue profiles: $e');
      return [];
    }
  }

  /// Stream service profiles for real-time updates
  Stream<List<ServiceProfile>> streamUserServiceProfiles({String? userId}) {
    final targetUserId = userId ?? _currentUserId;

    if (_config.isDemoMode) {
      return Stream.value(_demoUserProfiles[targetUserId] ?? []);
    }

    return _firestore
        .collection('users')
        .doc(targetUserId)
        .collection(_serviceProfilesCollection)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ServiceProfile.fromMap(doc.data()))
            .toList());
  }

  /// Create a demo service profile for testing
  Future<String> createDemoServiceProfile() async {
    final demoComponents = [
      ServiceComponent(
        type: ServiceComponentType.sediment,
        sku: 'SED-10',
        name: 'Sediment Filter 10"',
        intervalDays: 180,
        lastChangedAt: DateTime.now().subtract(const Duration(days: 150)),
      ),
      ServiceComponent(
        type: ServiceComponentType.carbon,
        sku: 'CB-10',
        name: 'Carbon Block Filter',
        intervalDays: 180,
        lastChangedAt: DateTime.now().subtract(const Duration(days: 160)),
      ),
      ServiceComponent(
        type: ServiceComponentType.membrane,
        sku: 'RO-75',
        name: 'RO Membrane 75GPD',
        intervalDays: 730,
        lastChangedAt: DateTime.now().subtract(const Duration(days: 200)),
      ),
    ];

    final demoSystem = WaterFilterSystem(
      brand: 'Pentair',
      model: 'Everpure RO-400',
      serial: 'RO400-DEMO-123',
      type: SystemType.underSink,
      components: demoComponents,
      notes: 'Demo under-sink RO system with chiller connection',
    );

    return await createServiceProfile(
      addressId: 'demo_address_home',
      addressLabel: 'Home - Kitchen',
      system: demoSystem,
      installedAt: DateTime.now().subtract(const Duration(days: 365)),
      technicianNotes: 'Initial installation completed. Customer prefers morning appointments.',
    );
  }

  /// Get service catalog for component types
  Future<List<ServiceComponent>> getServiceCatalog() async {
    try {
      if (_config.isDemoMode) {
        return _getDemoServiceCatalog();
      }

      final querySnapshot = await _firestore
          .collection(_serviceCatalogCollection)
          .orderBy('type')
          .get();

      return querySnapshot.docs
          .map((doc) => ServiceComponent.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('ServiceProfileService: Error getting service catalog: $e');
      return _getDemoServiceCatalog();
    }
  }

  /// Generate a unique profile ID
  String _generateProfileId() {
    return 'profile_${DateTime.now().millisecondsSinceEpoch}_${_currentUserId.hashCode.abs()}';
  }

  /// Get demo service catalog
  List<ServiceComponent> _getDemoServiceCatalog() {
    return [
      ServiceComponent(
        type: ServiceComponentType.sediment,
        sku: 'SED-10',
        name: 'Sediment Filter 10"',
        intervalDays: 180,
        lastChangedAt: DateTime.now(),
      ),
      ServiceComponent(
        type: ServiceComponentType.carbon,
        sku: 'CB-10',
        name: 'Carbon Block Filter',
        intervalDays: 180,
        lastChangedAt: DateTime.now(),
      ),
      ServiceComponent(
        type: ServiceComponentType.membrane,
        sku: 'RO-75',
        name: 'RO Membrane 75GPD',
        intervalDays: 730,
        lastChangedAt: DateTime.now(),
      ),
      ServiceComponent(
        type: ServiceComponentType.mineralizer,
        sku: 'MIN-10',
        name: 'Mineralizer Filter',
        intervalDays: 365,
        lastChangedAt: DateTime.now(),
      ),
      ServiceComponent(
        type: ServiceComponentType.co2,
        sku: 'CO2-60L',
        name: 'CO₂ Cartridge 60L',
        intervalDays: 90,
        lastChangedAt: DateTime.now(),
      ),
    ];
  }

  /// Clear demo data (for testing)
  void clearDemoData() {
    _demoProfiles.clear();
    _demoUserProfiles.clear();
  }

  /// Get all profiles for admin view
  Future<List<ServiceProfile>> getAllServiceProfiles() async {
    if (_config.isDemoMode) {
      return _demoProfiles;
    }

    try {
      // This would require admin privileges
      final querySnapshot = await _firestore
          .collectionGroup(_serviceProfilesCollection)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => ServiceProfile.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('ServiceProfileService: Error getting all profiles: $e');
      throw Exception('Failed to get all service profiles: $e');
    }
  }
}