import 'package:flutter/foundation.dart';
import '../models/service_profile.dart';
import '../models/user_model.dart';
import 'service_profile_service.dart';
import 'config_service.dart';

enum ReminderType {
  filterDue,
  filterOverdue,
  serviceScheduled,
  serviceCompleted,
}

class Reminder {
  final String id;
  final String userId;
  final String serviceProfileId;
  final ReminderType type;
  final String title;
  final String message;
  final DateTime dueDate;
  final DateTime createdAt;
  final bool isRead;
  final bool isActive;
  final Map<String, dynamic>? metadata;

  Reminder({
    required this.id,
    required this.userId,
    required this.serviceProfileId,
    required this.type,
    required this.title,
    required this.message,
    required this.dueDate,
    required this.createdAt,
    this.isRead = false,
    this.isActive = true,
    this.metadata,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'serviceProfileId': serviceProfileId,
      'type': type.toString().split('.').last,
      'title': title,
      'message': message,
      'dueDate': dueDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
      'isActive': isActive,
      'metadata': metadata,
    };
  }

  factory Reminder.fromMap(Map<String, dynamic> map) {
    return Reminder(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      serviceProfileId: map['serviceProfileId'] ?? '',
      type: ReminderType.values.firstWhere(
        (type) => type.toString().split('.').last == map['type'],
        orElse: () => ReminderType.filterDue,
      ),
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      dueDate: DateTime.parse(map['dueDate']),
      createdAt: DateTime.parse(map['createdAt']),
      isRead: map['isRead'] ?? false,
      isActive: map['isActive'] ?? true,
      metadata: map['metadata'],
    );
  }

  Reminder copyWith({
    String? id,
    String? userId,
    String? serviceProfileId,
    ReminderType? type,
    String? title,
    String? message,
    DateTime? dueDate,
    DateTime? createdAt,
    bool? isRead,
    bool? isActive,
    Map<String, dynamic>? metadata,
  }) {
    return Reminder(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      serviceProfileId: serviceProfileId ?? this.serviceProfileId,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      dueDate: dueDate ?? this.dueDate,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      isActive: isActive ?? this.isActive,
      metadata: metadata ?? this.metadata,
    );
  }
}

class ReminderService {
  static final ReminderService _instance = ReminderService._internal();
  factory ReminderService() => _instance;
  ReminderService._internal();

  final ServiceProfileService _serviceProfileService = ServiceProfileService();
  final ConfigService _config = ConfigService();

  // Demo storage for when Firestore is unavailable
  static final List<Reminder> _demoReminders = [];
  static final Map<String, List<Reminder>> _demoUserReminders = {};

  /// Check all service profiles and generate reminders for due/overdue filters
  Future<List<Reminder>> checkAndGenerateReminders(String userId, UserModel user) async {
    try {
      print('ReminderService: Checking reminders for user $userId');

      final serviceProfiles = await _serviceProfileService.getUserServiceProfiles(userId: userId);
      final newReminders = <Reminder>[];
      final now = DateTime.now();

      for (final profile in serviceProfiles) {
        if (!profile.isActive) continue;

        // Check each component for due/overdue status
        for (final component in profile.system.components) {
          final daysUntilDue = component.nextDueDate.difference(now).inDays;

          // Generate reminder based on user preferences
          if (_shouldGenerateReminder(daysUntilDue, user.servicePreferences)) {
            final reminder = _createComponentReminder(
              profile: profile,
              component: component,
              daysUntilDue: daysUntilDue,
              user: user,
            );

            if (reminder != null) {
              newReminders.add(reminder);
            }
          }
        }
      }

      // Store reminders
      if (_config.isDemoMode) {
        _demoUserReminders[userId] = (_demoUserReminders[userId] ?? [])..addAll(newReminders);
        _demoReminders.addAll(newReminders);
      } else {
        // In production, these would be stored in Firestore
        // For now, we'll keep them in memory
      }

      print('ReminderService: Generated ${newReminders.length} new reminders');
      return newReminders;
    } catch (e) {
      print('ReminderService: Error generating reminders: $e');
      return [];
    }
  }

  /// Get all active reminders for a user
  Future<List<Reminder>> getUserReminders(String userId) async {
    try {
      if (_config.isDemoMode) {
        return (_demoUserReminders[userId] ?? [])
            .where((reminder) => reminder.isActive)
            .toList()
          ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
      }

      // In production, fetch from Firestore
      return [];
    } catch (e) {
      print('ReminderService: Error getting user reminders: $e');
      return [];
    }
  }

  /// Get unread reminders for a user
  Future<List<Reminder>> getUnreadReminders(String userId) async {
    try {
      final reminders = await getUserReminders(userId);
      return reminders.where((reminder) => !reminder.isRead).toList();
    } catch (e) {
      print('ReminderService: Error getting unread reminders: $e');
      return [];
    }
  }

  /// Get overdue reminders
  Future<List<Reminder>> getOverdueReminders(String userId) async {
    try {
      final reminders = await getUserReminders(userId);
      final now = DateTime.now();
      return reminders
          .where((reminder) =>
              reminder.type == ReminderType.filterOverdue &&
              reminder.dueDate.isBefore(now))
          .toList();
    } catch (e) {
      print('ReminderService: Error getting overdue reminders: $e');
      return [];
    }
  }

  /// Mark reminder as read
  Future<void> markReminderAsRead(String reminderId, String userId) async {
    try {
      if (_config.isDemoMode) {
        final userReminders = _demoUserReminders[userId] ?? [];
        final index = userReminders.indexWhere((r) => r.id == reminderId);
        if (index != -1) {
          userReminders[index] = userReminders[index].copyWith(isRead: true);
        }

        final globalIndex = _demoReminders.indexWhere((r) => r.id == reminderId);
        if (globalIndex != -1) {
          _demoReminders[globalIndex] = _demoReminders[globalIndex].copyWith(isRead: true);
        }
        return;
      }

      // In production, update in Firestore
    } catch (e) {
      print('ReminderService: Error marking reminder as read: $e');
    }
  }

  /// Mark reminder as inactive (dismiss)
  Future<void> dismissReminder(String reminderId, String userId) async {
    try {
      if (_config.isDemoMode) {
        final userReminders = _demoUserReminders[userId] ?? [];
        final index = userReminders.indexWhere((r) => r.id == reminderId);
        if (index != -1) {
          userReminders[index] = userReminders[index].copyWith(isActive: false);
        }

        final globalIndex = _demoReminders.indexWhere((r) => r.id == reminderId);
        if (globalIndex != -1) {
          _demoReminders[globalIndex] = _demoReminders[globalIndex].copyWith(isActive: false);
        }
        return;
      }

      // In production, update in Firestore
    } catch (e) {
      print('ReminderService: Error dismissing reminder: $e');
    }
  }

  /// Get reminder statistics for user
  Future<Map<String, int>> getReminderStats(String userId) async {
    try {
      final reminders = await getUserReminders(userId);
      final now = DateTime.now();

      return {
        'total': reminders.length,
        'unread': reminders.where((r) => !r.isRead).length,
        'overdue': reminders.where((r) =>
            r.type == ReminderType.filterOverdue &&
            r.dueDate.isBefore(now)).length,
        'dueSoon': reminders.where((r) =>
            r.type == ReminderType.filterDue &&
            r.dueDate.difference(now).inDays <= 7).length,
      };
    } catch (e) {
      print('ReminderService: Error getting reminder stats: $e');
      return {'total': 0, 'unread': 0, 'overdue': 0, 'dueSoon': 0};
    }
  }

  /// Check if reminder should be generated based on user preferences
  bool _shouldGenerateReminder(int daysUntilDue, ServicePreferences preferences) {
    if (daysUntilDue < 0) {
      // Overdue - always generate reminder
      return true;
    }

    if (daysUntilDue <= preferences.reminderDaysBefore) {
      // Due soon - generate if within reminder window
      return true;
    }

    return false;
  }

  /// Create a component reminder
  Reminder? _createComponentReminder({
    required ServiceProfile profile,
    required ServiceComponent component,
    required int daysUntilDue,
    required UserModel user,
  }) {
    try {
      final isOverdue = daysUntilDue < 0;
      final type = isOverdue ? ReminderType.filterOverdue : ReminderType.filterDue;

      String title;
      String message;

      if (isOverdue) {
        final daysPastDue = -daysUntilDue;
        title = '${component.name} Overdue';
        message = 'Your ${component.name} at ${profile.addressLabel} is $daysPastDue days overdue for replacement. '
                 'Please schedule a service appointment to maintain water quality.';
      } else {
        title = '${component.name} Due Soon';
        message = 'Your ${component.name} at ${profile.addressLabel} is due for replacement in $daysUntilDue days. '
                 'Schedule a service appointment to ensure continued water quality.';
      }

      final reminderId = _generateReminderId(profile.id, component.type);

      return Reminder(
        id: reminderId,
        userId: user.uid,
        serviceProfileId: profile.id,
        type: type,
        title: title,
        message: message,
        dueDate: component.nextDueDate,
        createdAt: DateTime.now(),
        metadata: {
          'componentType': component.type.toString().split('.').last,
          'componentSku': component.sku,
          'profileAddress': profile.addressLabel,
          'daysUntilDue': daysUntilDue,
        },
      );
    } catch (e) {
      print('ReminderService: Error creating component reminder: $e');
      return null;
    }
  }

  /// Generate unique reminder ID
  String _generateReminderId(String profileId, ServiceComponentType componentType) {
    final typeStr = componentType.toString().split('.').last;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'reminder_${profileId}_${typeStr}_$timestamp';
  }

  /// Create demo reminders for testing
  Future<void> createDemoReminders(String userId) async {
    try {
      final now = DateTime.now();

      final demoReminders = [
        Reminder(
          id: 'demo_reminder_1',
          userId: userId,
          serviceProfileId: 'demo_profile_1',
          type: ReminderType.filterDue,
          title: 'Sediment Filter Due Soon',
          message: 'Your sediment filter at Home - Kitchen is due for replacement in 5 days. Schedule a service appointment to ensure continued water quality.',
          dueDate: now.add(const Duration(days: 5)),
          createdAt: now.subtract(const Duration(hours: 2)),
        ),
        Reminder(
          id: 'demo_reminder_2',
          userId: userId,
          serviceProfileId: 'demo_profile_1',
          type: ReminderType.filterOverdue,
          title: 'Carbon Filter Overdue',
          message: 'Your carbon filter at Home - Kitchen is 3 days overdue for replacement. Please schedule a service appointment immediately to maintain water quality.',
          dueDate: now.subtract(const Duration(days: 3)),
          createdAt: now.subtract(const Duration(days: 3)),
        ),
        Reminder(
          id: 'demo_reminder_3',
          userId: userId,
          serviceProfileId: 'demo_profile_2',
          type: ReminderType.filterDue,
          title: 'RO Membrane Due Soon',
          message: 'Your RO membrane at Office - Break Room is due for replacement in 14 days. Schedule a service appointment to ensure continued water quality.',
          dueDate: now.add(const Duration(days: 14)),
          createdAt: now.subtract(const Duration(hours: 6)),
        ),
      ];

      if (_config.isDemoMode) {
        _demoUserReminders[userId] = demoReminders;
        _demoReminders.addAll(demoReminders);
      }

      print('ReminderService: Created ${demoReminders.length} demo reminders');
    } catch (e) {
      print('ReminderService: Error creating demo reminders: $e');
    }
  }

  /// Clear demo data (for testing)
  void clearDemoData() {
    _demoReminders.clear();
    _demoUserReminders.clear();
  }

  /// Daily check for all users (would be called by Cloud Function)
  Future<void> performDailyReminderCheck() async {
    try {
      print('ReminderService: Starting daily reminder check...');

      if (_config.isDemoMode) {
        // In demo mode, just log the operation
        print('ReminderService: Daily check completed (demo mode)');
        return;
      }

      // In production, this would:
      // 1. Get all active users
      // 2. For each user, check their service profiles
      // 3. Generate reminders as needed
      // 4. Send notifications (email, SMS, push) based on preferences

      print('ReminderService: Daily reminder check completed');
    } catch (e) {
      print('ReminderService: Error in daily reminder check: $e');
    }
  }

  /// Send notification for reminder (placeholder for future implementation)
  Future<void> sendReminderNotification(Reminder reminder, UserModel user) async {
    try {
      // This would integrate with:
      // - Firebase Cloud Messaging for push notifications
      // - Email service (SendGrid, etc.) for email notifications
      // - SMS service for text notifications

      print('ReminderService: Would send ${reminder.type} notification to ${user.email}');
      print('  Title: ${reminder.title}');
      print('  Message: ${reminder.message}');
    } catch (e) {
      print('ReminderService: Error sending reminder notification: $e');
    }
  }
}

extension ReminderTypeExtension on ReminderType {
  String get displayName {
    switch (this) {
      case ReminderType.filterDue:
        return 'Filter Due';
      case ReminderType.filterOverdue:
        return 'Filter Overdue';
      case ReminderType.serviceScheduled:
        return 'Service Scheduled';
      case ReminderType.serviceCompleted:
        return 'Service Completed';
    }
  }

  String get colorCode {
    switch (this) {
      case ReminderType.filterDue:
        return '#FF9800'; // Orange
      case ReminderType.filterOverdue:
        return '#F44336'; // Red
      case ReminderType.serviceScheduled:
        return '#2196F3'; // Blue
      case ReminderType.serviceCompleted:
        return '#4CAF50'; // Green
    }
  }
}