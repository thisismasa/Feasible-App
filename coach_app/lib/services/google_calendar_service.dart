import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:googleapis_auth/auth_io.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'google_calendar_service_web.dart' if (dart.library.io) 'google_calendar_service_stub.dart';

/// Google Calendar Service for syncing training sessions
///
/// Features:
/// - Create calendar events for bookings
/// - Update existing events
/// - Delete cancelled bookings
/// - Fetch trainer's schedule
/// - Set reminders for sessions
class GoogleCalendarService {
  static final GoogleCalendarService _instance = GoogleCalendarService._();
  static GoogleCalendarService get instance => _instance;
  GoogleCalendarService._();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [calendar.CalendarApi.calendarScope],
  );

  calendar.CalendarApi? _calendarApi;
  bool _isInitialized = false;

  /// Initialize Google Calendar API with user authentication
  Future<bool> initialize() async {
    try {
      // For web platform, we need the OAuth Client ID configured in index.html
      if (kIsWeb) {
        debugPrint('📅 Initializing Google Calendar for WEB platform...');
        debugPrint('   OAuth Client ID should be configured in web/index.html');
      }

      // Check if already signed in
      GoogleSignInAccount? account = _googleSignIn.currentUser;

      // If not signed in, prompt user to sign in
      if (account == null) {
        debugPrint('📅 Requesting Google Calendar access...');
        account = await _googleSignIn.signIn();
      }

      if (account == null) {
        debugPrint('❌ User cancelled Google sign-in');
        return false;
      }

      // Get authentication headers
      final authHeaders = await account.authHeaders;
      final authenticateClient = GoogleAuthClient(authHeaders);

      _calendarApi = calendar.CalendarApi(authenticateClient);
      _isInitialized = true;

      debugPrint('✅ Google Calendar API initialized');
      debugPrint('   User: ${account.email}');
      debugPrint('   Platform: ${kIsWeb ? "WEB" : "MOBILE"}');
      return true;
    } catch (e) {
      debugPrint('⚠️ Google Calendar unavailable (non-critical): ${e.toString().split('\n').first}');
      return false;
    }
  }

  /// Create a calendar event for a training session
  ///
  /// Returns the Google Calendar event ID if successful
  Future<String?> createEvent({
    required String summary,
    required DateTime startTime,
    required DateTime endTime,
    required String clientName,
    String? location,
    String? description,
    String? clientEmail,
  }) async {
    // WEB PLATFORM: Use JavaScript-based implementation
    if (kIsWeb) {
      debugPrint('📅 Using WEB-specific calendar implementation');
      debugPrint('🔍 Checking Google Sign-In status...');

      try {
        // Get access token from current sign-in
        final account = _googleSignIn.currentUser;

        if (account == null) {
          debugPrint('❌ User NOT signed in with Google');
          debugPrint('💡 SOLUTION: User needs to click "Sign in with Google" button');
          debugPrint('📍 Calendar sync SKIPPED - booking will still succeed');
          return null;
        }

        debugPrint('✅ User signed in: ${account.email}');

        String? accessToken;
        final authHeaders = await account.authHeaders;
        // Extract access token from Authorization header
        final authHeader = authHeaders['Authorization'];
        if (authHeader != null && authHeader.startsWith('Bearer ')) {
          accessToken = authHeader.substring(7); // Remove 'Bearer ' prefix
          debugPrint('✅ Got access token for web calendar API');
        } else {
          debugPrint('❌ No access token found in auth headers');
          return null;
        }

        // Use web implementation
        debugPrint('🚀 Calling web calendar API...');
        final eventId = await GoogleCalendarServiceWeb.instance.createEvent(
          summary: summary,
          startTime: startTime,
          endTime: endTime,
          clientName: clientName,
          location: location,
          description: description,
          clientEmail: clientEmail,
          accessToken: accessToken,
        );

        if (eventId != null) {
          debugPrint('✅ SUCCESS! Calendar event created: $eventId');
          debugPrint('🎉 Check your Google Calendar: https://calendar.google.com');
        } else {
          debugPrint('❌ Calendar API returned null event ID');
        }

        return eventId;
      } catch (e) {
        debugPrint('❌ Web calendar implementation failed: $e');
        debugPrint('📍 Calendar sync FAILED - booking will still succeed');
        return null;
      }
    }

    // MOBILE PLATFORM: Use googleapis implementation
    if (!_isInitialized || _calendarApi == null) {
      debugPrint('⚠️ Google Calendar not initialized, attempting init...');
      final initialized = await initialize();
      if (!initialized) {
        debugPrint('❌ Google Calendar initialization failed');
        return null;
      }
    }

    try {
      // Use device's local timezone instead of hardcoded timezone
      final localTimeZone = DateTime.now().timeZoneName;

      final event = calendar.Event()
        ..summary = summary
        ..description = description ?? 'Training session with $clientName'
        ..location = location
        ..start = calendar.EventDateTime(
          dateTime: startTime.toUtc(),
          timeZone: localTimeZone,
        )
        ..end = calendar.EventDateTime(
          dateTime: endTime.toUtc(),
          timeZone: localTimeZone,
        )
        ..colorId = '4' // Flame red color for training sessions
        ..reminders = (calendar.EventReminders()
          ..useDefault = false
          ..overrides = [
            calendar.EventReminder()
              ..method = 'popup'
              ..minutes = 30, // 30 min before
            calendar.EventReminder()
              ..method = 'email'
              ..minutes = 120, // 2 hours before
          ]);

      // Add client as attendee if email provided
      if (clientEmail != null && clientEmail.isNotEmpty) {
        event.attendees = [
          calendar.EventAttendee()
            ..displayName = clientName
            ..email = clientEmail
        ];
      }

      debugPrint('📅 Creating Google Calendar event...');
      debugPrint('   Summary: $summary');
      debugPrint('   Start: $startTime');
      debugPrint('   End: $endTime');
      debugPrint('   Client: $clientName');

      final createdEvent = await _calendarApi!.events.insert(
        event,
        'primary', // Use trainer's primary calendar
        sendUpdates: clientEmail != null ? 'all' : 'none',
      );

      debugPrint('✅ Google Calendar event created');
      debugPrint('   Event ID: ${createdEvent.id}');
      debugPrint('   Link: ${createdEvent.htmlLink}');

      return createdEvent.id;
    } catch (e) {
      // Enhanced error handling with specific error types
      final errorMessage = e.toString();

      if (errorMessage.contains('quotaExceeded') || errorMessage.contains('429')) {
        debugPrint('❌ Google Calendar API quota exceeded');
        debugPrint('💡 SOLUTION: Wait 1 hour for quota to reset, or reduce API calls');
        throw CalendarQuotaExceededException('API quota exceeded. Try again in 1 hour.');
      } else if (errorMessage.contains('authError') ||
                 errorMessage.contains('401') ||
                 errorMessage.contains('invalid_grant')) {
        debugPrint('❌ Google Calendar authentication expired');
        debugPrint('💡 SOLUTION: User needs to re-authenticate with Google');
        throw CalendarAuthException('Google Calendar authentication expired. Please sign in again.');
      } else if (errorMessage.contains('403') || errorMessage.contains('forbidden')) {
        debugPrint('❌ No permission to access Google Calendar');
        debugPrint('💡 SOLUTION: User needs to grant calendar permissions');
        throw CalendarPermissionException('No permission to access Google Calendar. Please grant access.');
      } else {
        debugPrint('❌ Failed to create Google Calendar event: $e');
        throw CalendarException('Failed to create calendar event: ${errorMessage.split('\n').first}');
      }
    }
  }

  /// Update an existing calendar event
  Future<bool> updateEvent({
    required String eventId,
    DateTime? newStartTime,
    DateTime? newEndTime,
    String? newSummary,
    String? newDescription,
    String? newLocation,
  }) async {
    if (!_isInitialized || _calendarApi == null) {
      debugPrint('❌ Cannot update event: Google Calendar not initialized');
      return false;
    }

    try {
      debugPrint('📅 Updating Google Calendar event: $eventId');

      // Get existing event
      final event = await _calendarApi!.events.get('primary', eventId);

      // Use device's local timezone
      final localTimeZone = DateTime.now().timeZoneName;

      // Update fields if provided
      if (newStartTime != null) {
        event.start = calendar.EventDateTime(
          dateTime: newStartTime.toUtc(),
          timeZone: localTimeZone,
        );
      }

      if (newEndTime != null) {
        event.end = calendar.EventDateTime(
          dateTime: newEndTime.toUtc(),
          timeZone: localTimeZone,
        );
      }

      if (newSummary != null) {
        event.summary = newSummary;
      }

      if (newDescription != null) {
        event.description = newDescription;
      }

      if (newLocation != null) {
        event.location = newLocation;
      }

      await _calendarApi!.events.update(
        event,
        'primary',
        eventId,
        sendUpdates: 'all',
      );

      debugPrint('✅ Google Calendar event updated successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Failed to update Google Calendar event: $e');
      return false;
    }
  }

  /// Delete a calendar event (for cancelled bookings)
  Future<bool> deleteEvent(String eventId) async {
    if (!_isInitialized || _calendarApi == null) {
      debugPrint('❌ Cannot delete event: Google Calendar not initialized');
      return false;
    }

    try {
      debugPrint('🗑️ Deleting Google Calendar event: $eventId');

      await _calendarApi!.events.delete(
        'primary',
        eventId,
        sendUpdates: 'all', // Notify attendees
      );

      debugPrint('✅ Google Calendar event deleted successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Failed to delete Google Calendar event: $e');
      return false;
    }
  }

  /// Get trainer's events for a date range
  ///
  /// Useful for checking availability and avoiding conflicts
  Future<List<calendar.Event>> getEvents({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    if (!_isInitialized || _calendarApi == null) {
      debugPrint('❌ Cannot fetch events: Google Calendar not initialized');
      return [];
    }

    try {
      debugPrint('📅 Fetching Google Calendar events');
      debugPrint('   Range: $startDate to $endDate');

      final events = await _calendarApi!.events.list(
        'primary',
        timeMin: startDate.toUtc(),
        timeMax: endDate.toUtc(),
        singleEvents: true,
        orderBy: 'startTime',
      );

      final eventList = events.items ?? [];
      debugPrint('✅ Found ${eventList.length} events');

      return eventList;
    } catch (e) {
      debugPrint('❌ Failed to fetch Google Calendar events: $e');
      return [];
    }
  }

  /// Check if a time slot is available in trainer's calendar
  Future<bool> isTimeSlotAvailable({
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    final events = await getEvents(
      startDate: startTime.subtract(const Duration(hours: 1)),
      endDate: endTime.add(const Duration(hours: 1)),
    );

    // Check for conflicts
    for (var event in events) {
      if (event.start?.dateTime == null || event.end?.dateTime == null) {
        continue;
      }

      final eventStart = event.start!.dateTime!;
      final eventEnd = event.end!.dateTime!;

      // Check if there's an overlap
      if (startTime.isBefore(eventEnd) && endTime.isAfter(eventStart)) {
        debugPrint('⚠️ Time slot conflict with: ${event.summary}');
        return false;
      }
    }

    return true;
  }

  /// Sign out from Google Calendar
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _calendarApi = null;
    _isInitialized = false;
    debugPrint('👋 Signed out from Google Calendar');
  }

  /// Check if user is signed in to Google Calendar
  bool get isSignedIn => _isInitialized && _calendarApi != null;

  /// Check if user is signed in with Google (for web)
  bool get isGoogleSignedIn => _googleSignIn.currentUser != null;

  /// Get current Google account email
  String? get userEmail => _googleSignIn.currentUser?.email;

  /// Prompt user to sign in with Google for calendar sync
  Future<bool> promptGoogleSignIn() async {
    try {
      debugPrint('🔐 Prompting user to sign in with Google...');
      final account = await _googleSignIn.signIn();

      if (account != null) {
        debugPrint('✅ User signed in: ${account.email}');
        return true;
      } else {
        debugPrint('❌ User cancelled sign-in');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Sign-in failed: $e');
      return false;
    }
  }
}

/// HTTP client that adds Google authentication headers
class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _client.send(request..headers.addAll(_headers));
  }

  @override
  void close() {
    _client.close();
  }
}

/// Custom exceptions for Google Calendar errors

class CalendarException implements Exception {
  final String message;
  CalendarException(this.message);

  @override
  String toString() => message;
}

class CalendarQuotaExceededException extends CalendarException {
  CalendarQuotaExceededException(String message) : super(message);
}

class CalendarAuthException extends CalendarException {
  CalendarAuthException(String message) : super(message);
}

class CalendarPermissionException extends CalendarException {
  CalendarPermissionException(String message) : super(message);
}
