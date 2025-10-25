import 'package:flutter/foundation.dart';
import '../models/session_model.dart';
import '../services/supabase_service.dart';

class ConflictDetectionResult {
  final bool hasConflict;
  final List<SessionModel> conflictingSessions;
  final String? message;

  ConflictDetectionResult({
    required this.hasConflict,
    this.conflictingSessions = const [],
    this.message,
  });

  factory ConflictDetectionResult.noConflict() {
    return ConflictDetectionResult(hasConflict: false);
  }

  factory ConflictDetectionResult.conflict(
    List<SessionModel> sessions,
    String message,
  ) {
    return ConflictDetectionResult(
      hasConflict: true,
      conflictingSessions: sessions,
      message: message,
    );
  }
}

class ConflictDetectionService {
  static const int bufferMinutes = 15; // Buffer time between sessions

  /// Check if a proposed session conflicts with existing sessions
  static Future<ConflictDetectionResult> checkForConflicts({
    required String trainerId,
    required DateTime scheduledDate,
    required int durationMinutes,
    String? excludeSessionId, // For rescheduling
  }) async {
    try {
      // Calculate time range with buffer
      final sessionStart = scheduledDate;
      final sessionEnd = sessionStart.add(Duration(minutes: durationMinutes));
      final bufferStart =
          sessionStart.subtract(Duration(minutes: bufferMinutes));
      final bufferEnd = sessionEnd.add(Duration(minutes: bufferMinutes));

      // Query for overlapping sessions
      final response = await SupabaseService.instance.client
          .from('sessions')
          .select()
          .eq('trainer_id', trainerId)
          .neq('status', 'cancelled')
          .gte(
            'scheduled_date',
            bufferStart.toIso8601String(),
          )
          .lte(
            'scheduled_date',
            bufferEnd.toIso8601String(),
          );

      final sessions = (response is List)
          ? (response as List).map((data) => SessionModel.fromSupabaseMap(data)).where((session) {
            // Exclude the session being rescheduled
            if (excludeSessionId != null && session.id == excludeSessionId) {
              return false;
            }
            return true;
          }).toList()
          : <SessionModel>[];

      if (sessions.isEmpty) {
        return ConflictDetectionResult.noConflict();
      }

      // Check for actual time conflicts
      final conflictingSessions = <SessionModel>[];

      for (final session in sessions) {
        final existingStart = session.scheduledDate;
        final existingEnd = existingStart.add(
          Duration(minutes: session.durationMinutes),
        );

        // Check for overlap including buffer
        if (_hasOverlap(
          bufferStart,
          bufferEnd,
          existingStart.subtract(Duration(minutes: bufferMinutes)),
          existingEnd.add(Duration(minutes: bufferMinutes)),
        )) {
          conflictingSessions.add(session);
        }
      }

      if (conflictingSessions.isEmpty) {
        return ConflictDetectionResult.noConflict();
      }

      final message = conflictingSessions.length == 1
          ? 'This time conflicts with an existing session'
          : 'This time conflicts with ${conflictingSessions.length} sessions';

      return ConflictDetectionResult.conflict(conflictingSessions, message);
    } catch (e) {
      debugPrint('Error checking conflicts: $e');
      return ConflictDetectionResult.noConflict(); // Fail open
    }
  }

  /// Check if a time slot is available
  static Future<bool> isTimeSlotAvailable({
    required String trainerId,
    required DateTime startTime,
    required int durationMinutes,
    String? excludeSessionId,
  }) async {
    final result = await checkForConflicts(
      trainerId: trainerId,
      scheduledDate: startTime,
      durationMinutes: durationMinutes,
      excludeSessionId: excludeSessionId,
    );

    return !result.hasConflict;
  }

  /// Get all unavailable time slots for a specific date
  static Future<List<TimeRange>> getUnavailableSlots({
    required String trainerId,
    required DateTime date,
  }) async {
    try {
      // Get all sessions for the day
      final dayStart = DateTime(date.year, date.month, date.day);
      final dayEnd = dayStart.add(const Duration(days: 1));

      final response = await SupabaseService.instance.client
          .from('sessions')
          .select()
          .eq('trainer_id', trainerId)
          .neq('status', 'cancelled')
          .gte('scheduled_date', dayStart.toIso8601String())
          .lt('scheduled_date', dayEnd.toIso8601String())
          .order('scheduled_date');

      final sessions = (response is List)
          ? (response as List).map((data) => SessionModel.fromSupabaseMap(data)).toList()
          : <SessionModel>[];

      // Convert to time ranges with buffer
      final unavailableSlots = sessions.map((session) {
        final start = session.scheduledDate.subtract(
          Duration(minutes: bufferMinutes),
        );
        final end = session.scheduledDate.add(
          Duration(minutes: session.durationMinutes + bufferMinutes),
        );

        return TimeRange(start: start, end: end);
      }).toList();

      return unavailableSlots;
    } catch (e) {
      debugPrint('Error getting unavailable slots: $e');
      return [];
    }
  }

  /// Stream of real-time availability updates
  static Stream<bool> watchAvailability({
    required String trainerId,
    required DateTime scheduledDate,
    required int durationMinutes,
  }) async* {
    // Initial check
    final initial = await isTimeSlotAvailable(
      trainerId: trainerId,
      startTime: scheduledDate,
      durationMinutes: durationMinutes,
    );
    yield initial;

    // Watch for changes
    final sessionStart = scheduledDate;
    final sessionEnd = sessionStart.add(Duration(minutes: durationMinutes));
    final bufferStart =
        sessionStart.subtract(Duration(minutes: bufferMinutes));
    final bufferEnd = sessionEnd.add(Duration(minutes: bufferMinutes));

    final stream = SupabaseService.instance.client
        .from('sessions')
        .stream(primaryKey: ['id'])
        .eq('trainer_id', trainerId)
        .neq('status', 'cancelled')
        .gte('scheduled_date', bufferStart.toIso8601String())
        .lte('scheduled_date', bufferEnd.toIso8601String());

    await for (final sessions in stream) {
      final hasConflict = sessions.isNotEmpty;
      yield !hasConflict;
    }
  }

  /// Validate multiple recurring sessions
  static Future<Map<DateTime, ConflictDetectionResult>>
      checkRecurringConflicts({
    required String trainerId,
    required List<DateTime> dates,
    required int durationMinutes,
  }) async {
    final results = <DateTime, ConflictDetectionResult>{};

    for (final date in dates) {
      final result = await checkForConflicts(
        trainerId: trainerId,
        scheduledDate: date,
        durationMinutes: durationMinutes,
      );
      results[date] = result;
    }

    return results;
  }

  /// Find next available slot after a given time
  static Future<DateTime?> findNextAvailableSlot({
    required String trainerId,
    required DateTime startTime,
    required int durationMinutes,
    int intervalMinutes = 30,
    int maxAttempts = 20,
  }) async {
    DateTime currentTime = startTime;

    for (int i = 0; i < maxAttempts; i++) {
      final isAvailable = await isTimeSlotAvailable(
        trainerId: trainerId,
        startTime: currentTime,
        durationMinutes: durationMinutes,
      );

      if (isAvailable) {
        // Check if within business hours (6 AM - 9 PM)
        if (currentTime.hour >= 6 && currentTime.hour < 21) {
          return currentTime;
        }
      }

      currentTime = currentTime.add(Duration(minutes: intervalMinutes));
    }

    return null; // No available slot found
  }

  /// Check if two time ranges overlap
  static bool _hasOverlap(
    DateTime start1,
    DateTime end1,
    DateTime start2,
    DateTime end2,
  ) {
    return start1.isBefore(end2) && end1.isAfter(start2);
  }
}

class TimeRange {
  final DateTime start;
  final DateTime end;

  TimeRange({required this.start, required this.end});

  bool overlaps(TimeRange other) {
    return start.isBefore(other.end) && end.isAfter(other.start);
  }

  bool contains(DateTime time) {
    return time.isAfter(start) && time.isBefore(end);
  }

  Duration get duration => end.difference(start);
}
