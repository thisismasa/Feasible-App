import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:googleapis_auth/auth_io.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

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
      // Check if web is supported for Google Sign In
      if (kIsWeb) {
        debugPrint('⚠️ Google Calendar: Web platform requires OAuth client ID in index.html');
        debugPrint('   Skipping Google Calendar initialization on web');
        return false;
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
    // Skip on web platform
    if (kIsWeb) {
      return null;
    }

    if (!_isInitialized || _calendarApi == null) {
      debugPrint('⚠️ Google Calendar not initialized, attempting init...');
      final initialized = await initialize();
      if (!initialized) {
        return null;
      }
    }

    try {
      final event = calendar.Event()
        ..summary = summary
        ..description = description ?? 'Training session with $clientName'
        ..location = location
        ..start = calendar.EventDateTime(
          dateTime: startTime.toUtc(),
          timeZone: 'Asia/Bangkok',
        )
        ..end = calendar.EventDateTime(
          dateTime: endTime.toUtc(),
          timeZone: 'Asia/Bangkok',
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
      debugPrint('❌ Failed to create Google Calendar event: $e');
      return null;
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

      // Update fields if provided
      if (newStartTime != null) {
        event.start = calendar.EventDateTime(
          dateTime: newStartTime.toUtc(),
          timeZone: 'Asia/Bangkok',
        );
      }

      if (newEndTime != null) {
        event.end = calendar.EventDateTime(
          dateTime: newEndTime.toUtc(),
          timeZone: 'Asia/Bangkok',
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

  /// Get current Google account email
  String? get userEmail => _googleSignIn.currentUser?.email;
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
