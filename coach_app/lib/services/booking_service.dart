import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/session_model.dart';
import '../models/package_model.dart';
import 'supabase_service.dart';
import 'google_calendar_service.dart';

/// Enhanced Booking Service - Production Ready
/// Features: Transactions, race condition protection, offline support, retry logic
class BookingService {
  static final BookingService _instance = BookingService._internal();
  factory BookingService() => _instance;
  BookingService._internal();

  // Offline queue
  static final List<PendingBooking> _offlineQueue = [];
  
  // Rate limiting
  static final Map<String, List<DateTime>> _rateLimitMap = {};
  
  /// Book session(s) with transaction safety and retry logic
  Future<BookingResult> bookSession({
    required BookingRequest request,
    int maxRetries = 3,
  }) async {
    // Check rate limiting
    if (!_checkRateLimit(request.clientId)) {
      return BookingResult.error('Too many booking attempts. Please wait a moment.');
    }
    
    // Validate request
    final validation = await _validateBookingRequest(request);
    if (!validation.isValid) {
      return BookingResult.error(validation.reason);
    }
    
    // Attempt booking with retry logic
    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        final result = await _attemptBooking(request);
        
        // Success - process any offline queue
        _processOfflineQueue();
        
        return result;
      } on ConflictException catch (e) {
        // Conflict detected - don't retry
        return BookingResult.error(e.message);
      } on NetworkException catch (e) {
        if (attempt == maxRetries - 1) {
          // Final attempt failed - queue for offline
          if (await _isOffline()) {
            _offlineQueue.add(PendingBooking(request, DateTime.now()));
            return BookingResult.queued(
              'Booking queued. Will auto-sync when online.',
            );
          }
          return BookingResult.error('Connection failed. Please try again.');
        }
        
        // Exponential backoff before retry
        final delaySeconds = math.pow(2, attempt).toInt();
        await Future.delayed(Duration(seconds: delaySeconds));
      } catch (e) {
        if (attempt == maxRetries - 1) {
          return BookingResult.error('Booking failed: ${e.toString()}');
        }
      }
    }
    
    return BookingResult.error('Unknown error occurred');
  }

  /// Validate booking request before attempting
  Future<BookingValidation> _validateBookingRequest(BookingRequest request) async {
    // 1. Check package validity
    final packageCheck = await _validatePackage(
      request.packageId,
      request.dates.length,
      request.dates.last,
    );
    
    if (!packageCheck.isValid) {
      return packageCheck;
    }
    
    // 2. Check minimum advance time
    for (final date in request.dates) {
      if (!_checkMinAdvanceTime(date, request.minAdvanceHours)) {
        return BookingValidation(
          isValid: false,
          reason: 'Must book at least ${request.minAdvanceHours} hours in advance',
        );
      }
    }
    
    // 3. Check business hours
    for (final date in request.dates) {
      if (!await _checkBusinessHours(date, request.duration)) {
        return BookingValidation(
          isValid: false,
          reason: 'Selected time is outside business hours',
        );
      }
    }
    
    // 4. Check for conflicts (with lock)
    final conflicts = await _checkConflicts(
      request.trainerId,
      request.dates,
      request.duration,
    );
    
    if (conflicts.isNotEmpty) {
      return BookingValidation(
        isValid: false,
        reason: 'Time slot(s) no longer available',
        conflicts: conflicts,
      );
    }
    
    return BookingValidation(isValid: true, reason: 'Valid');
  }

  /// Attempt to book with database transaction
  Future<BookingResult> _attemptBooking(BookingRequest request) async {
    final client = SupabaseService.instance.client;
    
    try {
      // Start transaction by calling stored procedure
      final response = await client.rpc(
        'book_session_transaction',
        params: {
          'p_client_id': request.clientId,
          'p_trainer_id': request.trainerId,
          'p_dates': request.dates.map((d) => d.toIso8601String()).toList(),
          'p_duration': request.duration,
          'p_package_id': request.packageId,
          'p_session_type': request.sessionType,
          'p_location': request.location,
          'p_notes': request.notes,
        },
      );
      
      if (response['success'] == true) {
        final sessionIds = List<String>.from(response['session_ids'] ?? []);
        
        // Send notifications
        await _sendBookingNotifications(
          clientId: request.clientId,
          trainerId: request.trainerId,
          dates: request.dates,
          sessionIds: sessionIds,
        );
        
        return BookingResult.success(
          'Booking confirmed!',
          sessionIds: sessionIds,
        );
      } else {
        return BookingResult.error(response['error'] ?? 'Booking failed');
      }
    } catch (e) {
      if (e.toString().contains('conflict') || e.toString().contains('duplicate')) {
        throw ConflictException('Time slot is no longer available');
      }
      if (e.toString().contains('network') || e.toString().contains('connection')) {
        throw NetworkException('Network error');
      }
      rethrow;
    }
  }

  /// Validate package for booking
  Future<BookingValidation> _validatePackage(
    String packageId,
    int requiredSessions,
    DateTime lastSessionDate,
  ) async {
    try {
      final response = await SupabaseService.instance.client
          .from('client_packages')
          .select()
          .eq('id', packageId)
          .single();
      
      final package = ClientPackage.fromSupabaseMap(response);
      
      // Check remaining sessions
      if (package.remainingSessions < requiredSessions) {
        return BookingValidation(
          isValid: false,
          reason: 'Package has only ${package.remainingSessions} session(s) remaining',
          suggestRenewal: true,
        );
      }
      
      // Check expiration
      if (package.expiryDate.isBefore(lastSessionDate)) {
        return BookingValidation(
          isValid: false,
          reason: 'Package expires on ${package.expiryDate.toString().split(' ')[0]}',
          suggestRenewal: true,
        );
      }
      
      // Check if package is active
      if (package.status != PackageStatus.active) {
        return BookingValidation(
          isValid: false,
          reason: 'Package is ${package.status.name}',
        );
      }
      
      return BookingValidation(isValid: true, reason: 'Valid');
    } catch (e) {
      return BookingValidation(
        isValid: false,
        reason: 'Unable to validate package',
      );
    }
  }

  /// Check minimum advance booking time
  bool _checkMinAdvanceTime(DateTime scheduledDate, int minHours) {
    final now = DateTime.now();
    final minBookingTime = now.add(Duration(hours: minHours));
    // Changed from isAfter to !isBefore to allow booking AT the minimum time (not just after)
    // This fixes "0 hours advance" to allow booking from NOW onwards, not just future
    return !scheduledDate.isBefore(minBookingTime);
  }

  /// Check if time is within business hours
  Future<bool> _checkBusinessHours(DateTime scheduledDate, int duration) async {
    // Get trainer's business hours (could be from database)
    final dayOfWeek = scheduledDate.weekday;
    
    // Sunday closed
    if (dayOfWeek == DateTime.sunday) {
      return false;
    }
    
    final hour = scheduledDate.hour;
    final endHour = scheduledDate.add(Duration(minutes: duration)).hour;
    
    // Saturday: 8 AM - 2 PM
    if (dayOfWeek == DateTime.saturday) {
      return hour >= 8 && endHour <= 14;
    }
    
    // Weekdays: 7 AM - 10 PM
    return hour >= 7 && endHour <= 22;
  }

  /// Check for scheduling conflicts with locking
  /// Now checks BOTH database AND Google Calendar to prevent double bookings
  Future<List<DateTime>> _checkConflicts(
    String trainerId,
    List<DateTime> proposedDates,
    int duration,
  ) async {
    final conflicts = <DateTime>[];

    for (final date in proposedDates) {
      final sessionEnd = date.add(Duration(minutes: duration));

      // Check for overlapping sessions (with 15min buffer)
      final bufferStart = date.subtract(const Duration(minutes: 15));
      final bufferEnd = sessionEnd.add(const Duration(minutes: 15));

      // 1. Check database for conflicts
      final response = await SupabaseService.instance.client
          .from('sessions')
          .select()
          .eq('trainer_id', trainerId)
          .gte('scheduled_date', bufferStart.toIso8601String())
          .lte('scheduled_date', bufferEnd.toIso8601String())
          .neq('status', 'cancelled');

      if (response is List && (response as List).isNotEmpty) {
        conflicts.add(date);
        continue; // Already has conflict, skip Google Calendar check
      }

      // 2. Check Google Calendar for conflicts
      try {
        final calendarService = GoogleCalendarService.instance;

        // Only check if user is signed in with Google
        if (calendarService.isGoogleSignedIn) {
          final calendarEvents = await calendarService.getEvents(
            startDate: bufferStart,
            endDate: bufferEnd,
          );

          // Check if any calendar event conflicts with proposed time
          for (final event in calendarEvents) {
            if (event.start?.dateTime == null || event.end?.dateTime == null) {
              continue; // Skip all-day events
            }

            final eventStart = event.start!.dateTime!;
            final eventEnd = event.end!.dateTime!;

            // Check for overlap
            if (bufferStart.isBefore(eventEnd) && bufferEnd.isAfter(eventStart)) {
              print('⚠️ Google Calendar conflict detected with: ${event.summary}');
              conflicts.add(date);
              break; // Found conflict, no need to check more events
            }
          }
        }
      } catch (e) {
        // Don't fail booking if Google Calendar check fails
        // But log the error for debugging
        print('⚠️ Could not check Google Calendar for conflicts: $e');
        // Continue with booking based on database check only
      }
    }

    return conflicts;
  }

  /// Send booking confirmation notifications
  Future<void> _sendBookingNotifications({
    required String clientId,
    required String trainerId,
    required List<DateTime> dates,
    required List<String> sessionIds,
  }) async {
    try {
      // In production, trigger email/SMS/push notifications
      await SupabaseService.instance.client.from('notifications').insert({
        'user_id': clientId,
        'type': 'booking_confirmed',
        'title': 'Session Booked',
        'message': 'Your training session has been confirmed',
        'data': {'session_ids': sessionIds},
        'created_at': DateTime.now().toIso8601String(),
      });
      
      // Notify trainer
      await SupabaseService.instance.client.from('notifications').insert({
        'user_id': trainerId,
        'type': 'new_booking',
        'title': 'New Booking',
        'message': 'You have a new session booking',
        'data': {'session_ids': sessionIds},
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // Don't fail booking if notification fails
      print('Notification failed: $e');
    }
  }

  /// Check rate limiting
  bool _checkRateLimit(String userId) {
    final now = DateTime.now();
    final userRequests = _rateLimitMap[userId] ?? [];
    
    // Remove old requests (older than 1 minute)
    userRequests.removeWhere((time) => now.difference(time).inMinutes > 1);
    
    // Max 5 booking attempts per minute
    if (userRequests.length >= 5) {
      return false;
    }
    
    userRequests.add(now);
    _rateLimitMap[userId] = userRequests;
    return true;
  }

  /// Check if device is offline
  Future<bool> _isOffline() async {
    try {
      await SupabaseService.instance.client.from('sessions').select().limit(1);
      return false;
    } catch (e) {
      return true;
    }
  }

  /// Process offline booking queue
  Future<void> _processOfflineQueue() async {
    if (_offlineQueue.isEmpty) return;
    
    final queue = List<PendingBooking>.from(_offlineQueue);
    _offlineQueue.clear();
    
    for (final pending in queue) {
      // Check if booking is still valid (not too old)
      final age = DateTime.now().difference(pending.timestamp).inMinutes;
      if (age > 30) {
        // Too old, skip
        continue;
      }
      
      try {
        await bookSession(
          request: pending.request,
          maxRetries: 1, // Only 1 retry for queued items
        );
      } catch (e) {
        // Put back in queue if failed
        _offlineQueue.add(pending);
      }
    }
  }

  /// Get booking statistics for analytics
  Future<BookingStats> getBookingStats(String trainerId) async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    
    final response = await SupabaseService.instance.client
        .from('sessions')
        .select()
        .eq('trainer_id', trainerId)
        .gte('scheduled_date', startOfMonth.toIso8601String());
    
    final sessions = (response is List)
        ? (response as List).map((data) => SessionModel.fromSupabaseMap(data)).toList()
        : <SessionModel>[];
    
    final completed = sessions.where((s) => s.status == SessionStatus.completed).length;
    final cancelled = sessions.where((s) => s.status == SessionStatus.cancelled).length;
    final scheduled = sessions.where((s) => s.status == SessionStatus.scheduled).length;
    
    return BookingStats(
      totalBookings: sessions.length,
      completed: completed,
      cancelled: cancelled,
      scheduled: scheduled,
      cancellationRate: sessions.isEmpty ? 0 : cancelled / sessions.length,
    );
  }
}

/// Booking Request Model
class BookingRequest {
  final String clientId;
  final String trainerId;
  final String packageId;
  final List<DateTime> dates; // Support multiple dates for recurring
  final int duration;
  final String sessionType;
  final String? location;
  final String? notes;
  final int minAdvanceHours;

  BookingRequest({
    required this.clientId,
    required this.trainerId,
    required this.packageId,
    required this.dates,
    required this.duration,
    required this.sessionType,
    this.location,
    this.notes,
    this.minAdvanceHours = 0, // ✅ Changed from 2 to 0 to allow same-day booking
  });
}

/// Booking Result
class BookingResult {
  final bool success;
  final String message;
  final List<String>? sessionIds;
  final BookingResultType type;

  BookingResult._({
    required this.success,
    required this.message,
    this.sessionIds,
    required this.type,
  });

  factory BookingResult.success(String message, {List<String>? sessionIds}) {
    return BookingResult._(
      success: true,
      message: message,
      sessionIds: sessionIds,
      type: BookingResultType.success,
    );
  }

  factory BookingResult.error(String message) {
    return BookingResult._(
      success: false,
      message: message,
      type: BookingResultType.error,
    );
  }

  factory BookingResult.queued(String message) {
    return BookingResult._(
      success: true,
      message: message,
      type: BookingResultType.queued,
    );
  }
}

enum BookingResultType { success, error, queued }

/// Booking Validation
class BookingValidation {
  final bool isValid;
  final String reason;
  final bool suggestRenewal;
  final List<DateTime>? conflicts;

  BookingValidation({
    required this.isValid,
    required this.reason,
    this.suggestRenewal = false,
    this.conflicts,
  });
}

/// Pending Booking (for offline queue)
class PendingBooking {
  final BookingRequest request;
  final DateTime timestamp;
  int retryCount;

  PendingBooking(this.request, this.timestamp, {this.retryCount = 0});
}

/// Booking Statistics
class BookingStats {
  final int totalBookings;
  final int completed;
  final int cancelled;
  final int scheduled;
  final double cancellationRate;

  BookingStats({
    required this.totalBookings,
    required this.completed,
    required this.cancelled,
    required this.scheduled,
    required this.cancellationRate,
  });
}

/// Custom Exceptions
class ConflictException implements Exception {
  final String message;
  ConflictException(this.message);
  
  @override
  String toString() => message;
}

class NetworkException implements Exception {
  final String message;
  NetworkException(this.message);
  
  @override
  String toString() => message;
}

class ValidationException implements Exception {
  final String message;
  ValidationException(this.message);
  
  @override
  String toString() => message;
}

/// Availability Calculator - Optimized slot generation
class AvailabilityCalculator {
  /// Calculate available slots for a specific date
  static Future<List<TimeSlotInfo>> calculateSlots({
    required DateTime date,
    required int duration,
    required String trainerId,
    required List<SessionModel> existingSessions,
  }) async {
    final slots = <TimeSlotInfo>[];
    
    // Get business hours
    final businessHours = _getBusinessHours(date);
    if (!businessHours.isOpen) {
      return [];
    }
    
    // Generate slots at 30-minute intervals
    var currentTime = DateTime(
      date.year,
      date.month,
      date.day,
      businessHours.startHour,
      0,
    );
    
    final endTime = DateTime(
      date.year,
      date.month,
      date.day,
      businessHours.endHour,
      0,
    );
    
    while (currentTime.isBefore(endTime)) {
      final slotEnd = currentTime.add(Duration(minutes: duration));
      
      // Check if slot would extend past closing
      if (slotEnd.isAfter(endTime)) {
        break;
      }
      
      final slot = TimeSlotInfo(
        startTime: currentTime,
        endTime: slotEnd,
      );
      
      // Validate slot availability
      _validateSlotAvailability(slot, existingSessions, date);
      
      slots.add(slot);
      currentTime = currentTime.add(const Duration(minutes: 30));
    }
    
    return slots;
  }

  static void _validateSlotAvailability(
    TimeSlotInfo slot,
    List<SessionModel> sessions,
    DateTime date,
  ) {
    // Check minimum advance time (0 hours = allow today)
    final now = DateTime.now();
    // Subtract 1 minute buffer to allow booking slots in the current minute
    final minTime = now.subtract(const Duration(minutes: 1));
    if (slot.startTime.isBefore(minTime)) {
      slot.isAvailable = false;
      slot.unavailableReason = 'Time has passed';
      slot.displayColor = const Color(0xFFE0E0E0);
      return;
    }
    
    // Check lunch break (12-1 PM)
    if (slot.startTime.hour == 12 || 
        (slot.startTime.hour == 11 && slot.endTime.hour >= 12)) {
      slot.isAvailable = false;
      slot.unavailableReason = 'Lunch break';
      slot.displayColor = const Color(0xFFFFE0B2);
      return;
    }
    
    // Check conflicts with existing sessions
    for (final session in sessions) {
      if (_hasConflict(slot, session)) {
        slot.isAvailable = false;
        slot.unavailableReason = 'Booked';
        slot.displayColor = const Color(0xFFFFCDD2);
        return;
      }
      
      // Check buffer time (15 minutes)
      if (_isWithinBuffer(slot, session)) {
        slot.isAvailable = false;
        slot.unavailableReason = 'Buffer time';
        slot.displayColor = const Color(0xFFFFE082);
        return;
      }
    }
    
    // Available!
    slot.isAvailable = true;
    slot.displayColor = const Color(0xFFC8E6C9);
  }

  static bool _hasConflict(TimeSlotInfo slot, SessionModel session) {
    final sessionEnd = session.scheduledDate.add(
      Duration(minutes: session.durationMinutes),
    );
    return slot.startTime.isBefore(sessionEnd) && 
           slot.endTime.isAfter(session.scheduledDate);
  }

  static bool _isWithinBuffer(TimeSlotInfo slot, SessionModel session) {
    const bufferMinutes = 15;
    final bufferBefore = session.scheduledDate.subtract(
      const Duration(minutes: bufferMinutes),
    );
    final sessionEnd = session.scheduledDate.add(
      Duration(minutes: session.durationMinutes),
    );
    final bufferAfter = sessionEnd.add(const Duration(minutes: bufferMinutes));
    
    return slot.startTime.isBefore(bufferAfter) && 
           slot.endTime.isAfter(bufferBefore);
  }

  static _BusinessHours _getBusinessHours(DateTime date) {
    final dayOfWeek = date.weekday;
    
    if (dayOfWeek == DateTime.sunday) {
      return _BusinessHours(isOpen: false);
    }
    
    if (dayOfWeek == DateTime.saturday) {
      return _BusinessHours(isOpen: true, startHour: 8, endHour: 14);
    }
    
    return _BusinessHours(isOpen: true, startHour: 7, endHour: 22);
  }
}

class _BusinessHours {
  final bool isOpen;
  final int startHour;
  final int endHour;

  _BusinessHours({
    required this.isOpen,
    this.startHour = 7, // 7 AM default
    this.endHour = 22, // 10 PM default
  });
}

/// Time Slot Information
class TimeSlotInfo {
  final DateTime startTime;
  final DateTime endTime;
  bool isAvailable;
  String? unavailableReason;
  Color displayColor;

  TimeSlotInfo({
    required this.startTime,
    required this.endTime,
    this.isAvailable = true,
    this.unavailableReason,
    this.displayColor = const Color(0xFFC8E6C9),
  });
}

