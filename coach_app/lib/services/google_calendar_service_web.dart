import 'dart:async';
import 'dart:js' as js;
import 'package:flutter/foundation.dart';

/// Web-specific Google Calendar Service using JavaScript gapi.client
/// Calls JavaScript functions defined in web/index.html
class GoogleCalendarServiceWeb {
  static final GoogleCalendarServiceWeb _instance = GoogleCalendarServiceWeb._();
  static GoogleCalendarServiceWeb get instance => _instance;
  GoogleCalendarServiceWeb._();

  bool _isInitialized = false;

  /// Initialize Google Calendar API on web
  Future<bool> initialize({String? accessToken}) async {
    try {
      debugPrint('📅 Initializing Google Calendar for WEB platform...');

      // Wait for calendar API to be ready
      for (int i = 0; i < 10; i++) {
        if (_isCalendarApiReady()) {
          debugPrint('✅ Calendar API is ready');
          break;
        }
        debugPrint('⏳ Waiting for Calendar API... ($i/10)');
        await Future.delayed(const Duration(milliseconds: 500));
      }

      if (!_isCalendarApiReady()) {
        debugPrint('❌ Calendar API not ready after waiting');
        return false;
      }

      // Set access token if provided
      if (accessToken != null && accessToken.isNotEmpty) {
        final tokenSet = _setAccessToken(accessToken);
        if (!tokenSet) {
          debugPrint('❌ Failed to set access token');
          return false;
        }
      }

      _isInitialized = true;
      debugPrint('✅ Google Calendar API initialized for WEB');
      return true;
    } catch (e) {
      debugPrint('❌ Failed to initialize Google Calendar on web: $e');
      return false;
    }
  }

  /// Create calendar event using JavaScript gapi.client.calendar
  Future<String?> createEvent({
    required String summary,
    required DateTime startTime,
    required DateTime endTime,
    required String clientName,
    String? location,
    String? description,
    String? clientEmail,
    String? accessToken,
  }) async {
    try {
      // Set access token if provided
      if (accessToken != null && accessToken.isNotEmpty) {
        _setAccessToken(accessToken);
      }

      if (!_isInitialized && accessToken != null) {
        debugPrint('⚠️ Google Calendar not initialized, attempting init...');
        final initialized = await initialize(accessToken: accessToken);
        if (!initialized) {
          debugPrint('❌ Google Calendar initialization failed');
          return null;
        }
      }

      debugPrint('📅 Creating Google Calendar event via JavaScript...');
      debugPrint('   Summary: $summary');
      debugPrint('   Start: $startTime');
      debugPrint('   End: $endTime');
      debugPrint('   Client: $clientName');

      // Build event object
      final event = {
        'summary': summary,
        'description': description ?? 'Training session with $clientName',
        'location': location,
        'start': {
          'dateTime': startTime.toUtc().toIso8601String(),
          'timeZone': 'Asia/Bangkok',
        },
        'end': {
          'dateTime': endTime.toUtc().toIso8601String(),
          'timeZone': 'Asia/Bangkok',
        },
        'colorId': '4', // Flame red
        'reminders': {
          'useDefault': false,
          'overrides': [
            {'method': 'popup', 'minutes': 30},
            {'method': 'email', 'minutes': 120},
          ],
        },
      };

      // Add attendee if email provided
      if (clientEmail != null && clientEmail.isNotEmpty) {
        event['attendees'] = [
          {
            'displayName': clientName,
            'email': clientEmail,
          }
        ];
      }

      // Call JavaScript function to create event
      final eventId = await _callCreateCalendarEvent(event);

      if (eventId != null && eventId.isNotEmpty) {
        debugPrint('✅ Google Calendar event created via JavaScript');
        debugPrint('   Event ID: $eventId');
        return eventId;
      } else {
        debugPrint('❌ Failed to create event: No event ID returned');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Failed to create Google Calendar event: $e');
      return null;
    }
  }

  // ===== JAVASCRIPT INTEROP METHODS =====

  /// Check if calendar API is ready using JavaScript function
  bool _isCalendarApiReady() {
    try {
      final result = js.context.callMethod('isCalendarApiReady', []);
      return result == true;
    } catch (e) {
      debugPrint('⚠️ Error checking if calendar API is ready: $e');
      return false;
    }
  }

  /// Set access token using JavaScript function
  bool _setAccessToken(String token) {
    try {
      debugPrint('📅 Setting access token via JavaScript...');
      final result = js.context.callMethod('setCalendarAccessToken', [token]);
      if (result == true) {
        debugPrint('✅ Access token set successfully');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('❌ Error setting access token: $e');
      return false;
    }
  }

  /// Call JavaScript function to create calendar event
  Future<String?> _callCreateCalendarEvent(Map<String, dynamic> event) async {
    try {
      // Convert Map to JsObject
      final eventJsObj = js.JsObject.jsify(event);

      // Call the JavaScript function
      final promise = js.context.callMethod('createCalendarEvent', [eventJsObj]);

      if (promise == null) {
        debugPrint('❌ createCalendarEvent returned null');
        return null;
      }

      // Convert Promise to Future
      final completer = Completer<String?>();

      // Handle promise resolution
      final thenFunction = js.allowInterop((result) {
        if (result != null) {
          completer.complete(result.toString());
        } else {
          completer.complete(null);
        }
      });

      // Handle promise rejection
      final catchFunction = js.allowInterop((error) {
        debugPrint('❌ Promise rejected: $error');
        completer.complete(null);
      });

      // Attach then/catch handlers
      promise.callMethod('then', [thenFunction]).callMethod('catch', [catchFunction]);

      // Wait for promise to resolve (with timeout)
      return await completer.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('❌ Calendar event creation timed out');
          return null;
        },
      );
    } catch (e) {
      debugPrint('❌ Error calling createCalendarEvent: $e');
      return null;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    _isInitialized = false;
    debugPrint('👋 Signed out from Google Calendar');
  }

  /// Check if initialized
  bool get isInitialized => _isInitialized;
}
