import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/service_request.dart';
import '../models/shipping_address.dart';
import 'config_service.dart';

class ServiceRequestService {
  static final ServiceRequestService _instance = ServiceRequestService._internal();
  factory ServiceRequestService() => _instance;
  ServiceRequestService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ConfigService _config = ConfigService();

  static const String _serviceRequestsCollection = 'service_requests';

  // Demo storage for when Firestore is unavailable
  static final List<ServiceRequest> _demoRequests = [];
  static final Map<String, List<ServiceRequest>> _demoUserRequests = {};

  String get _currentUserId => _auth.currentUser?.uid ?? 'demo_user';

  /// Create a new service request
  Future<String> createServiceRequest({
    required ServiceRequestType type,
    required String title,
    required String description,
    required String addressId,
    required Map<String, dynamic> addressSnapshot,
    String? serviceProfileId,
    ServiceRequestPriority priority = ServiceRequestPriority.normal,
    PreferredSchedule? preferredSchedule,
  }) async {
    try {
      final userId = _currentUserId;
      final requestId = _generateRequestId();
      final now = DateTime.now();

      final request = ServiceRequest(
        id: requestId,
        userId: userId,
        serviceProfileId: serviceProfileId,
        type: type,
        priority: priority,
        title: title,
        description: description,
        addressId: addressId,
        addressSnapshot: addressSnapshot,
        preferredSchedule: preferredSchedule,
        createdAt: now,
      );

      if (_config.isDemoMode) {
        print('ServiceRequestService: Creating request in demo mode');
        _demoRequests.add(request);
        _demoUserRequests[userId] = (_demoUserRequests[userId] ?? [])..add(request);
        return requestId;
      }

      // Save to Firestore
      await _firestore
          .collection('users')
          .doc(userId)
          .collection(_serviceRequestsCollection)
          .doc(requestId)
          .set(request.toMap());

      print('ServiceRequestService: Request created successfully: $requestId');
      return requestId;
    } catch (e) {
      print('ServiceRequestService: Error creating request: $e');
      throw Exception('Failed to create service request: $e');
    }
  }

  /// Get all service requests for the current user
  Future<List<ServiceRequest>> getUserServiceRequests({String? userId}) async {
    try {
      final targetUserId = userId ?? _currentUserId;

      if (_config.isDemoMode) {
        print('ServiceRequestService: Getting requests in demo mode');
        return _demoUserRequests[targetUserId] ?? [];
      }

      final querySnapshot = await _firestore
          .collection('users')
          .doc(targetUserId)
          .collection(_serviceRequestsCollection)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => ServiceRequest.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('ServiceRequestService: Error getting requests: $e');
      if (_config.isDemoMode) {
        return _demoUserRequests[userId ?? _currentUserId] ?? [];
      }
      throw Exception('Failed to get service requests: $e');
    }
  }

  /// Get a specific service request by ID
  Future<ServiceRequest?> getServiceRequest(String requestId, {String? userId}) async {
    try {
      final targetUserId = userId ?? _currentUserId;

      if (_config.isDemoMode) {
        return _demoUserRequests[targetUserId]
            ?.where((r) => r.id == requestId)
            .firstOrNull;
      }

      final doc = await _firestore
          .collection('users')
          .doc(targetUserId)
          .collection(_serviceRequestsCollection)
          .doc(requestId)
          .get();

      if (!doc.exists) return null;
      return ServiceRequest.fromMap(doc.data()!);
    } catch (e) {
      print('ServiceRequestService: Error getting request: $e');
      if (_config.isDemoMode) {
        return _demoUserRequests[userId ?? _currentUserId]
            ?.where((r) => r.id == requestId)
            .firstOrNull;
      }
      return null;
    }
  }

  /// Update a service request
  Future<void> updateServiceRequest(ServiceRequest request) async {
    try {
      final updatedRequest = request.copyWith(updatedAt: DateTime.now());

      if (_config.isDemoMode) {
        final userRequests = _demoUserRequests[request.userId] ?? [];
        final index = userRequests.indexWhere((r) => r.id == request.id);
        if (index != -1) {
          userRequests[index] = updatedRequest;
        }

        final globalIndex = _demoRequests.indexWhere((r) => r.id == request.id);
        if (globalIndex != -1) {
          _demoRequests[globalIndex] = updatedRequest;
        }
        return;
      }

      await _firestore
          .collection('users')
          .doc(request.userId)
          .collection(_serviceRequestsCollection)
          .doc(request.id)
          .update(updatedRequest.toMap());

      print('ServiceRequestService: Request updated successfully: ${request.id}');
    } catch (e) {
      print('ServiceRequestService: Error updating request: $e');
      throw Exception('Failed to update service request: $e');
    }
  }

  /// Update service request status
  Future<void> updateRequestStatus({
    required String requestId,
    required ServiceRequestStatus status,
    String? userId,
    String? internalNotes,
  }) async {
    try {
      final request = await getServiceRequest(requestId, userId: userId);
      if (request == null) {
        throw Exception('Service request not found');
      }

      final now = DateTime.now();
      final updatedRequest = request.copyWith(
        status: status,
        updatedAt: now,
        scheduledAt: status == ServiceRequestStatus.scheduled ? now : request.scheduledAt,
        completedAt: status == ServiceRequestStatus.completed ? now : request.completedAt,
        internalNotes: internalNotes ?? request.internalNotes,
      );

      await updateServiceRequest(updatedRequest);
    } catch (e) {
      print('ServiceRequestService: Error updating status: $e');
      throw Exception('Failed to update request status: $e');
    }
  }

  /// Add quote to service request
  Future<void> addQuoteToRequest({
    required String requestId,
    required ServiceQuote quote,
    String? userId,
  }) async {
    try {
      final request = await getServiceRequest(requestId, userId: userId);
      if (request == null) {
        throw Exception('Service request not found');
      }

      final updatedRequest = request.copyWith(
        quote: quote,
        status: ServiceRequestStatus.confirmed,
        updatedAt: DateTime.now(),
      );

      await updateServiceRequest(updatedRequest);
    } catch (e) {
      print('ServiceRequestService: Error adding quote: $e');
      throw Exception('Failed to add quote to request: $e');
    }
  }

  /// Complete service request with notes and photos
  Future<void> completeServiceRequest({
    required String requestId,
    required String completionNotes,
    List<String> photos = const [],
    String? wooOrderId,
    String? userId,
  }) async {
    try {
      final request = await getServiceRequest(requestId, userId: userId);
      if (request == null) {
        throw Exception('Service request not found');
      }

      final updatedRequest = request.copyWith(
        status: ServiceRequestStatus.completed,
        completionNotes: completionNotes,
        photos: [...request.photos, ...photos],
        wooOrderId: wooOrderId ?? request.wooOrderId,
        completedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await updateServiceRequest(updatedRequest);
    } catch (e) {
      print('ServiceRequestService: Error completing request: $e');
      throw Exception('Failed to complete service request: $e');
    }
  }

  /// Cancel service request
  Future<void> cancelServiceRequest(String requestId, {String? userId}) async {
    try {
      await updateRequestStatus(
        requestId: requestId,
        status: ServiceRequestStatus.cancelled,
        userId: userId,
      );
    } catch (e) {
      print('ServiceRequestService: Error cancelling request: $e');
      throw Exception('Failed to cancel service request: $e');
    }
  }

  /// Get requests by status
  Future<List<ServiceRequest>> getRequestsByStatus({
    required ServiceRequestStatus status,
    String? userId,
  }) async {
    try {
      final requests = await getUserServiceRequests(userId: userId);
      return requests.where((request) => request.status == status).toList();
    } catch (e) {
      print('ServiceRequestService: Error getting requests by status: $e');
      return [];
    }
  }

  /// Get pending requests
  Future<List<ServiceRequest>> getPendingRequests({String? userId}) async {
    return getRequestsByStatus(status: ServiceRequestStatus.pending, userId: userId);
  }

  /// Get active requests (confirmed, scheduled, in progress)
  Future<List<ServiceRequest>> getActiveRequests({String? userId}) async {
    try {
      final requests = await getUserServiceRequests(userId: userId);
      return requests.where((request) =>
          request.status == ServiceRequestStatus.confirmed ||
          request.status == ServiceRequestStatus.scheduled ||
          request.status == ServiceRequestStatus.inProgress
      ).toList();
    } catch (e) {
      print('ServiceRequestService: Error getting active requests: $e');
      return [];
    }
  }

  /// Stream service requests for real-time updates
  Stream<List<ServiceRequest>> streamUserServiceRequests({String? userId}) {
    final targetUserId = userId ?? _currentUserId;

    if (_config.isDemoMode) {
      return Stream.value(_demoUserRequests[targetUserId] ?? []);
    }

    return _firestore
        .collection('users')
        .doc(targetUserId)
        .collection(_serviceRequestsCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ServiceRequest.fromMap(doc.data()))
            .toList());
  }

  /// Create a demo service request for testing
  Future<String> createDemoServiceRequest() async {
    final demoAddress = {
      'firstName': 'John',
      'lastName': 'Doe',
      'addressLine1': '12 Arch. Makarios Ave',
      'addressLine2': 'Flat 402',
      'city': 'Larnaca',
      'district': 'Larnaca',
      'postalCode': '6023',
      'country': 'CY',
    };

    final preferredSchedule = PreferredSchedule(
      preferredDate: DateTime.now().add(const Duration(days: 7)),
      preferredTimeSlot: '09:00-12:00',
      availableDays: ['monday', 'tuesday', 'friday'],
      notes: 'Prefer morning appointments',
    );

    return await createServiceRequest(
      type: ServiceRequestType.filterChange,
      title: 'Filter Replacement Service',
      description: 'Need to replace sediment and carbon filters in kitchen RO system. Last replacement was 6 months ago.',
      addressId: 'demo_address_home',
      addressSnapshot: demoAddress,
      serviceProfileId: 'demo_profile_001',
      priority: ServiceRequestPriority.normal,
      preferredSchedule: preferredSchedule,
    );
  }

  /// Generate a unique request ID
  String _generateRequestId() {
    return 'request_${DateTime.now().millisecondsSinceEpoch}_${_currentUserId.hashCode.abs()}';
  }

  /// Clear demo data (for testing)
  void clearDemoData() {
    _demoRequests.clear();
    _demoUserRequests.clear();
  }

  /// Get all service requests for admin view
  Future<List<ServiceRequest>> getAllServiceRequests() async {
    if (_config.isDemoMode) {
      return _demoRequests;
    }

    try {
      // This would require admin privileges
      final querySnapshot = await _firestore
          .collectionGroup(_serviceRequestsCollection)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => ServiceRequest.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('ServiceRequestService: Error getting all requests: $e');
      throw Exception('Failed to get all service requests: $e');
    }
  }

  /// Get service requests by priority for admin triage
  Future<List<ServiceRequest>> getRequestsByPriority({
    required ServiceRequestPriority priority,
  }) async {
    try {
      final requests = await getAllServiceRequests();
      return requests.where((request) => request.priority == priority).toList();
    } catch (e) {
      print('ServiceRequestService: Error getting requests by priority: $e');
      return [];
    }
  }

  /// Get urgent requests for admin attention
  Future<List<ServiceRequest>> getUrgentRequests() async {
    return getRequestsByPriority(priority: ServiceRequestPriority.urgent);
  }

  /// Create filter change request from service profile
  Future<String> createFilterChangeRequest({
    required String serviceProfileId,
    required String addressId,
    required Map<String, dynamic> addressSnapshot,
    List<String> componentsToReplace = const [],
    String? additionalNotes,
  }) async {
    final title = 'Filter Replacement Service';
    final description = componentsToReplace.isNotEmpty
        ? 'Replace the following components: ${componentsToReplace.join(', ')}'
        : 'Standard filter replacement according to service schedule';

    final fullDescription = additionalNotes != null
        ? '$description\n\nAdditional notes: $additionalNotes'
        : description;

    return await createServiceRequest(
      type: ServiceRequestType.filterChange,
      title: title,
      description: fullDescription,
      addressId: addressId,
      addressSnapshot: addressSnapshot,
      serviceProfileId: serviceProfileId,
      priority: ServiceRequestPriority.normal,
    );
  }

  /// Create CO2 exchange request
  Future<String> createCO2ExchangeRequest({
    required String serviceProfileId,
    required String addressId,
    required Map<String, dynamic> addressSnapshot,
    String? additionalNotes,
  }) async {
    return await createServiceRequest(
      type: ServiceRequestType.co2Exchange,
      title: 'CO₂ Cartridge Exchange',
      description: additionalNotes ?? 'CO₂ cartridge exchange for sparkling water system',
      addressId: addressId,
      addressSnapshot: addressSnapshot,
      serviceProfileId: serviceProfileId,
      priority: ServiceRequestPriority.normal,
    );
  }

  /// Create installation request
  Future<String> createInstallationRequest({
    required String addressId,
    required Map<String, dynamic> addressSnapshot,
    required String systemDetails,
    String? additionalNotes,
  }) async {
    final description = 'New water filtration system installation: $systemDetails';
    final fullDescription = additionalNotes != null
        ? '$description\n\nAdditional notes: $additionalNotes'
        : description;

    return await createServiceRequest(
      type: ServiceRequestType.installation,
      title: 'New System Installation',
      description: fullDescription,
      addressId: addressId,
      addressSnapshot: addressSnapshot,
      priority: ServiceRequestPriority.high,
    );
  }
}