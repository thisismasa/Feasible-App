import 'package:flutter/foundation.dart';
import 'dart:async';
import '../models/session_model.dart';
import '../services/supabase_service.dart';

class SessionReminderService {
  static final SessionReminderService _instance = SessionReminderService._internal();
  factory SessionReminderService() => _instance;
  SessionReminderService._internal();

  Timer? _reminderCheckTimer;
  final List<String> _sentReminders = [];

  /// Start the reminder service
  void start() {
    // Check for reminders every minute
    _reminderCheckTimer = Timer.periodic(
      const Duration(minutes: 1),
      (timer) => _checkUpcomingSessions(),
    );

    // Run initial check
    _checkUpcomingSessions();
  }

  /// Stop the reminder service
  void stop() {
    _reminderCheckTimer?.cancel();
    _reminderCheckTimer = null;
  }

  /// Check for upcoming sessions and send reminders
  Future<void> _checkUpcomingSessions() async {
    try {
      final now = DateTime.now();
      final next24Hours = now.add(const Duration(hours: 24));
      final next2Hours = now.add(const Duration(hours: 2));

      // Query upcoming sessions
      final response = await SupabaseService.instance.client
          .from('sessions')
          .select('*, clients(*)')
          .eq('status', 'scheduled')
          .gte('scheduled_date', now.toIso8601String())
          .lte('scheduled_date', next24Hours.toIso8601String());

      final sessions = (response is List)
          ? (response as List).map((data) => SessionModel.fromSupabaseMap(data)).toList()
          : <SessionModel>[];

      for (final session in sessions) {
        final reminderKey = '${session.id}_${session.scheduledDate.millisecondsSinceEpoch}';

        // Skip if reminder already sent
        if (_sentReminders.contains(reminderKey)) {
          continue;
        }

        final timeUntilSession = session.scheduledDate.difference(now);

        // 24-hour reminder
        if (timeUntilSession.inHours <= 24 && timeUntilSession.inHours >= 23) {
          await _sendReminder(
            session,
            ReminderType.twentyFourHour,
            'Session Tomorrow',
            'You have a session with ${session.clientName} tomorrow at ${_formatTime(session.scheduledDate)}',
          );
          _sentReminders.add('${reminderKey}_24h');
        }

        // 2-hour reminder
        if (timeUntilSession.inMinutes <= 120 && timeUntilSession.inMinutes >= 115) {
          await _sendReminder(
            session,
            ReminderType.twoHour,
            'Upcoming Session',
            'Session with ${session.clientName} in 2 hours at ${_formatTime(session.scheduledDate)}',
          );
          _sentReminders.add('${reminderKey}_2h');
        }

        // 30-minute reminder
        if (timeUntilSession.inMinutes <= 30 && timeUntilSession.inMinutes >= 25) {
          await _sendReminder(
            session,
            ReminderType.thirtyMinute,
            'Session Starting Soon',
            'Session with ${session.clientName} starts in 30 minutes',
          );
          _sentReminders.add('${reminderKey}_30m');
        }
      }

      // Clean up old reminders (older than 48 hours)
      _sentReminders.removeWhere((key) {
        final parts = key.split('_');
        if (parts.length >= 2) {
          final timestamp = int.tryParse(parts[1]);
          if (timestamp != null) {
            final reminderTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
            return DateTime.now().difference(reminderTime).inHours > 48;
          }
        }
        return false;
      });
    } catch (e) {
      debugPrint('Error checking reminders: $e');
    }
  }

  /// Send a reminder notification
  Future<void> _sendReminder(
    SessionModel session,
    ReminderType type,
    String title,
    String body,
  ) async {
    try {
      // Log reminder in database
      await SupabaseService.instance.client.from('session_reminders').insert({
        'session_id': session.id,
        'trainer_id': session.trainerId,
        'client_id': session.clientId,
        'reminder_type': type.name,
        'title': title,
        'body': body,
        'sent_at': DateTime.now().toIso8601String(),
      });

      // TODO: Integrate with actual notification service
      // For now, just log it
      debugPrint('Reminder sent: $title - $body');

      // You would integrate with:
      // - Firebase Cloud Messaging for push notifications
      // - Local notifications for in-app notifications
      // - Email service for email reminders
      // - SMS service for text reminders

    } catch (e) {
      debugPrint('Error sending reminder: $e');
    }
  }

  /// Schedule reminder for a specific session
  static Future<void> scheduleReminders(SessionModel session) async {
    try {
      final now = DateTime.now();
      final sessionTime = session.scheduledDate;

      // Calculate reminder times
      final reminder24h = sessionTime.subtract(const Duration(hours: 24));
      final reminder2h = sessionTime.subtract(const Duration(hours: 2));
      final reminder30m = sessionTime.subtract(const Duration(minutes: 30));

      // Store scheduled reminders in database
      final reminders = <Map<String, dynamic>>[];

      if (reminder24h.isAfter(now)) {
        reminders.add({
          'session_id': session.id,
          'trainer_id': session.trainerId,
          'client_id': session.clientId,
          'reminder_type': ReminderType.twentyFourHour.name,
          'scheduled_time': reminder24h.toIso8601String(),
          'status': 'scheduled',
        });
      }

      if (reminder2h.isAfter(now)) {
        reminders.add({
          'session_id': session.id,
          'trainer_id': session.trainerId,
          'client_id': session.clientId,
          'reminder_type': ReminderType.twoHour.name,
          'scheduled_time': reminder2h.toIso8601String(),
          'status': 'scheduled',
        });
      }

      if (reminder30m.isAfter(now)) {
        reminders.add({
          'session_id': session.id,
          'trainer_id': session.trainerId,
          'client_id': session.clientId,
          'reminder_type': ReminderType.thirtyMinute.name,
          'scheduled_time': reminder30m.toIso8601String(),
          'status': 'scheduled',
        });
      }

      if (reminders.isNotEmpty) {
        await SupabaseService.instance.client
            .from('scheduled_reminders')
            .insert(reminders);
      }
    } catch (e) {
      debugPrint('Error scheduling reminders: $e');
    }
  }

  /// Cancel reminders for a session
  static Future<void> cancelReminders(String sessionId) async {
    try {
      await SupabaseService.instance.client
          .from('scheduled_reminders')
          .update({'status': 'cancelled'})
          .eq('session_id', sessionId)
          .eq('status', 'scheduled');
    } catch (e) {
      debugPrint('Error cancelling reminders: $e');
    }
  }

  /// Get upcoming reminders for a trainer
  static Future<List<SessionReminder>> getUpcomingReminders(
    String trainerId,
  ) async {
    try {
      final response = await SupabaseService.instance.client
          .from('scheduled_reminders')
          .select('*, sessions(*)')
          .eq('trainer_id', trainerId)
          .eq('status', 'scheduled')
          .gte('scheduled_time', DateTime.now().toIso8601String())
          .order('scheduled_time')
          .limit(20);

      if (response is List) {
        return (response as List)
            .map((data) => SessionReminder.fromJson(data))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error getting reminders: $e');
      return [];
    }
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}

enum ReminderType {
  twentyFourHour,
  twoHour,
  thirtyMinute,
  custom,
}

class SessionReminder {
  final String id;
  final String sessionId;
  final String trainerId;
  final String clientId;
  final ReminderType reminderType;
  final DateTime scheduledTime;
  final String status;

  SessionReminder({
    required this.id,
    required this.sessionId,
    required this.trainerId,
    required this.clientId,
    required this.reminderType,
    required this.scheduledTime,
    required this.status,
  });

  factory SessionReminder.fromJson(Map<String, dynamic> json) {
    return SessionReminder(
      id: json['id'] as String,
      sessionId: json['session_id'] as String,
      trainerId: json['trainer_id'] as String,
      clientId: json['client_id'] as String,
      reminderType: ReminderType.values.firstWhere(
        (e) => e.name == json['reminder_type'],
        orElse: () => ReminderType.custom,
      ),
      scheduledTime: DateTime.parse(json['scheduled_time'] as String),
      status: json['status'] as String,
    );
  }
}
