import 'package:flutter/material.dart';
import '../services/google_calendar_service.dart';

/// Banner widget to show Google Calendar sync status
///
/// Displays at the top of booking screen to inform users about calendar sync
class CalendarSyncBanner extends StatefulWidget {
  const CalendarSyncBanner({Key? key}) : super(key: key);

  @override
  State<CalendarSyncBanner> createState() => _CalendarSyncBannerState();
}

class _CalendarSyncBannerState extends State<CalendarSyncBanner> {
  bool _isSignedIn = false;
  String? _userEmail;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkSignInStatus();
  }

  void _checkSignInStatus() {
    setState(() {
      _isSignedIn = GoogleCalendarService.instance.isGoogleSignedIn;
      _userEmail = GoogleCalendarService.instance.userEmail;
    });
  }

  Future<void> _handleSignIn() async {
    setState(() => _isLoading = true);

    final success = await GoogleCalendarService.instance.promptGoogleSignIn();

    if (mounted) {
      setState(() {
        _isLoading = false;
        _checkSignInStatus();
      });

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Signed in with Google! Calendar sync enabled'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isSignedIn) {
      // Show success banner
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          border: Border.all(color: Colors.green.shade200),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Google Calendar Sync Enabled',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade900,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Bookings will appear in Google Calendar',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontSize: 12,
                    ),
                  ),
                  if (_userEmail != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      _userEmail!,
                      style: TextStyle(
                        color: Colors.green.shade600,
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      // Show sign-in prompt
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          border: Border.all(color: Colors.orange.shade200),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: Colors.orange.shade700, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Enable Google Calendar Sync',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade900,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Sign in to auto-sync bookings to your calendar',
                    style: TextStyle(
                      color: Colors.orange.shade700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.orange.shade700),
                    ),
                  )
                : TextButton(
                    onPressed: _handleSignIn,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.orange.shade700,
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                    child: const Text('Sign In', style: TextStyle(fontSize: 12)),
                  ),
          ],
        ),
      );
    }
  }
}

/// Compact indicator for calendar sync status (for booking confirmation)
class CalendarSyncIndicator extends StatelessWidget {
  final String? calendarEventId;

  const CalendarSyncIndicator({
    Key? key,
    this.calendarEventId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (calendarEventId != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: Colors.green.shade700, size: 16),
            const SizedBox(width: 6),
            Text(
              'Synced to Google Calendar',
              style: TextStyle(
                color: Colors.green.shade900,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.info_outline, color: Colors.grey.shade600, size: 16),
            const SizedBox(width: 6),
            Text(
              'Not synced to calendar',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }
  }
}
