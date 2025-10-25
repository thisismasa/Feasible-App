import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../screens/client_selection_screen.dart';
import '../screens/booking_screen_enhanced.dart';
import '../screens/session_mode_selector_screen.dart';
import '../screens/add_client_screen_enhanced.dart';
import '../screens/invoice_management_screen.dart';
import '../screens/booking_management_screen.dart';
import '../services/package_validation_service.dart';
import '../services/supabase_service.dart';
import '../models/user_model.dart';
import '../models/package_model.dart';

/// Book Session Button - Opens client selection then booking flow
class BookSessionButton extends StatelessWidget {
  final VoidCallback? onSuccess;

  const BookSessionButton({
    Key? key,
    this.onSuccess,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => _handleBookSession(context),
      icon: const Icon(Icons.calendar_today),
      label: const Text('Book Session'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Future<void> _handleBookSession(BuildContext context) async {
    HapticFeedback.mediumImpact();

    // Step 1: Select client (use UniqueKey to ensure fresh data load)
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClientSelectionScreen(
          key: UniqueKey(), // Force new instance to reload data
          mode: SelectionMode.booking,
          onlyActiveClients: false, // Show all clients, even without packages
        ),
      ),
    );

    if (result != null && result is Map && context.mounted) {
      final client = result['client'] as UserModel;
      var package = result['package'] as ClientPackage?;

      // Step 2: Validate package exists
      if (package == null) {
        debugPrint('❌ No package returned for client ${client.name}');
        final shouldPurchase = await _showPackageRequiredDialog(context, client);
        if (shouldPurchase != true) return;

        // TODO: Navigate to package purchase
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Package purchase flow - coming soon'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Step 3: Validate package is valid for booking
      debugPrint('✅ Package loaded: ${package.packageName}, ${package.remainingSessions} sessions remaining');

      if (package.remainingSessions < 1) {
        if (context.mounted) {
          _showValidationError(
            context,
            'No sessions remaining in ${package.packageName}. Please purchase a new package.',
          );
        }
        return;
      }

      if (package.expiryDate.isBefore(DateTime.now())) {
        if (context.mounted) {
          _showValidationError(
            context,
            'Package "${package.packageName}" expired on ${package.expiryDate.toString().split(' ')[0]}',
          );
        }
        return;
      }

      // Step 4: Navigate to booking screen (package is now guaranteed non-null)
      if (context.mounted) {
        debugPrint('🚀 Navigating to BookingScreenEnhanced with valid package');
        final booked = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BookingScreenEnhanced(
              client: client,
              package: package, // Non-null guaranteed by checks above
              trainerId: SupabaseService.instance.currentUser?.id,
            ),
          ),
        );

        if (booked == true && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Session booked successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          onSuccess?.call();
        }
      }
    }
  }

  Future<bool?> _showPackageRequiredDialog(
    BuildContext context,
    UserModel client,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('No Active Package'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${client.name} doesn\'t have an active package.'),
            const SizedBox(height: 16),
            const Text(
              'Would you like to purchase a package for this client?',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('Purchase Package'),
          ),
        ],
      ),
    );
  }

  void _showValidationError(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 8),
            Text('Package Issue'),
          ],
        ),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

/// Start Session Button - Opens workout mode selector
class StartSessionButton extends StatelessWidget {
  final VoidCallback? onSessionComplete;

  const StartSessionButton({
    Key? key,
    this.onSessionComplete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => _handleStartSession(context),
      icon: const Icon(Icons.play_arrow, size: 28),
      label: const Text(
        'Start Session',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Future<void> _handleStartSession(BuildContext context) async {
    HapticFeedback.mediumImpact();

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SessionModeSelectorScreen(),
      ),
    );

    if (result != null && context.mounted) {
      onSessionComplete?.call();
    }
  }
}

/// Add Client Button - Opens enhanced add client screen
class AddClientButton extends StatelessWidget {
  final String trainerId;
  final VoidCallback? onClientAdded;

  const AddClientButton({
    Key? key,
    required this.trainerId,
    this.onClientAdded,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => _handleAddClient(context),
      icon: const Icon(Icons.person_add),
      label: const Text('Add Client'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.purple,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Future<void> _handleAddClient(BuildContext context) async {
    HapticFeedback.mediumImpact();

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddClientScreenEnhanced(trainerId: trainerId),
      ),
    );

    if (result == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Client added successfully!'),
          backgroundColor: Colors.green,
          action: SnackBarAction(
            label: 'Book Session',
            textColor: Colors.white,
            onPressed: () {
              // Navigate to booking using the static helper
              QuickActionButtons._handleBookSessionClick(context, onClientAdded);
            },
          ),
        ),
      );
      onClientAdded?.call();
    }
  }
}

/// Invoice Button - Opens invoice management
class InvoiceButton extends StatelessWidget {
  const InvoiceButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => _handleInvoices(context),
      icon: const Icon(Icons.receipt_long),
      label: const Text('Invoices'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.orange,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Future<void> _handleInvoices(BuildContext context) async {
    HapticFeedback.mediumImpact();

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const InvoiceManagementScreen(),
      ),
    );
  }
}

/// Quick Action Buttons Grid - Groups all action buttons
class QuickActionButtons extends StatelessWidget {
  final String trainerId;
  final VoidCallback? onRefresh;

  const QuickActionButtons({
    Key? key,
    required this.trainerId,
    this.onRefresh,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _QuickActionCard(
                title: 'Book Session',
                icon: Icons.calendar_today,
                color: Colors.blue,
                onTap: () {
                  _handleBookSessionClick(context, onRefresh);
                },
              ),
              _QuickActionCard(
                title: 'Start Session',
                icon: Icons.play_arrow,
                color: Colors.green,
                onTap: () {
                  _handleStartSessionClick(context, onRefresh);
                },
              ),
              _QuickActionCard(
                title: 'View Bookings',
                icon: Icons.event_note,
                color: Colors.teal,
                onTap: () {
                  _handleViewBookingsClick(context, trainerId);
                },
              ),
              _QuickActionCard(
                title: 'Add Client',
                icon: Icons.person_add,
                color: Colors.purple,
                onTap: () {
                  _handleAddClientClick(context, trainerId, onRefresh);
                },
              ),
              _QuickActionCard(
                title: 'Invoices',
                icon: Icons.receipt_long,
                color: Colors.orange,
                onTap: () {
                  _handleInvoicesClick(context);
                },
              ),
              // Additional actions can go here
            ],
          ),
        ],
      ),
    );
  }

  // Helper methods to properly trigger navigation
  static Future<void> _handleBookSessionClick(BuildContext context, VoidCallback? onRefresh) async {
    HapticFeedback.mediumImpact();

    // Step 1: Select client (use UniqueKey to ensure fresh data load)
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClientSelectionScreen(
          key: UniqueKey(), // Force new instance to reload data
          mode: SelectionMode.booking,
          onlyActiveClients: false, // Show all clients, even without packages
        ),
      ),
    );

    if (result != null && result is Map && context.mounted) {
      final client = result['client'] as UserModel;
      var package = result['package'] as ClientPackage?;

      // Step 2: Validate package
      if (package == null) {
        final shouldPurchase = await _showPackageRequiredDialog(context, client);
        if (shouldPurchase != true) return;

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Package purchase flow - coming soon'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Step 3: Quick validation - package already validated by client selection
      // Just check basic validity
      if (package.remainingSessions < 1) {
        if (context.mounted) {
          _showValidationError(context, 'No sessions remaining in package');
        }
        return;
      }

      if (package.expiryDate.isBefore(DateTime.now())) {
        if (context.mounted) {
          _showValidationError(context, 'Package has expired');
        }
        return;
      }

      // Step 4: Navigate to booking screen
      if (context.mounted) {
        final booked = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BookingScreenEnhanced(
              client: client,
              package: package,
              trainerId: SupabaseService.instance.currentUser?.id,
            ),
          ),
        );

        if (booked == true && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Session booked successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          onRefresh?.call();
        }
      }
    }
  }

  static Future<bool?> _showPackageRequiredDialog(
    BuildContext context,
    UserModel client,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('No Active Package'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${client.name} doesn\'t have an active package.'),
            const SizedBox(height: 16),
            const Text(
              'Would you like to purchase a package for this client?',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('Purchase Package'),
          ),
        ],
      ),
    );
  }

  static void _showValidationError(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 8),
            Text('Package Issue'),
          ],
        ),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  static Future<void> _handleStartSessionClick(BuildContext context, VoidCallback? onRefresh) async {
    HapticFeedback.mediumImpact();

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SessionModeSelectorScreen(),
      ),
    );

    if (result != null && context.mounted) {
      onRefresh?.call();
    }
  }

  static Future<void> _handleAddClientClick(BuildContext context, String trainerId, VoidCallback? onRefresh) async {
    HapticFeedback.mediumImpact();

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddClientScreenEnhanced(trainerId: trainerId),
      ),
    );

    if (result != null && context.mounted) {
      // Check if user clicked "Book Session" button in success dialog
      if (result is Map && result['action'] == 'book_session') {
        final clientId = result['clientId'] as String;
        final clientName = result['clientName'] as String;
        final packageId = result['packageId'] as String;

        debugPrint('📅 Navigating to booking for client: $clientName (ID: $clientId)');

        // Navigate directly to booking screen with the newly created client
        if (context.mounted) {
          // For now, we'll use the regular booking flow which requires client selection
          // In the future, you could create a direct booking with pre-selected client
          _handleBookSessionClick(context, onRefresh);
        }
      } else if (result == true) {
        // User clicked "Done" button
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Client added successfully!'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'Book Session',
              textColor: Colors.white,
              onPressed: () {
                _handleBookSessionClick(context, onRefresh);
              },
            ),
          ),
        );
      }
      onRefresh?.call();
    }
  }

  static Future<void> _handleInvoicesClick(BuildContext context) async {
    HapticFeedback.mediumImpact();

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const InvoiceManagementScreen(),
      ),
    );
  }

  static Future<void> _handleViewBookingsClick(BuildContext context, String trainerId) async {
    HapticFeedback.mediumImpact();

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookingManagementScreen(trainerId: trainerId),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withOpacity(0.7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: Colors.white,
                size: 36,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Floating Action Button with Menu
class DashboardFAB extends StatelessWidget {
  final String trainerId;
  final VoidCallback? onRefresh;

  const DashboardFAB({
    Key? key,
    required this.trainerId,
    this.onRefresh,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => _showQuickActions(context),
      backgroundColor: Colors.blue,
      icon: const Icon(Icons.add),
      label: const Text('Quick Actions'),
    );
  }

  void _showQuickActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: Icon(Icons.calendar_today, color: Colors.white),
                ),
                title: const Text('Book Session'),
                subtitle: const Text('Schedule a new training session'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.pop(context);
                  QuickActionButtons._handleBookSessionClick(context, onRefresh);
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.green,
                  child: Icon(Icons.play_arrow, color: Colors.white),
                ),
                title: const Text('Start Session'),
                subtitle: const Text('Begin a workout session'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.pop(context);
                  QuickActionButtons._handleStartSessionClick(context, onRefresh);
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.purple,
                  child: Icon(Icons.person_add, color: Colors.white),
                ),
                title: const Text('Add Client'),
                subtitle: const Text('Add a new client to your roster'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.pop(context);
                  QuickActionButtons._handleAddClientClick(context, trainerId, onRefresh);
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.orange,
                  child: Icon(Icons.receipt_long, color: Colors.white),
                ),
                title: const Text('Invoices'),
                subtitle: const Text('Manage client invoices'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.pop(context);
                  QuickActionButtons._handleInvoicesClick(context);
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

/// View Bookings Button - Opens booking management screen
class ViewBookingsButton extends StatelessWidget {
  const ViewBookingsButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => _handleViewBookings(context),
      icon: const Icon(Icons.event_note),
      label: const Text('View Bookings'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Future<void> _handleViewBookings(BuildContext context) async {
    HapticFeedback.mediumImpact();

    final trainerId = SupabaseService.instance.currentUser?.id;
    if (trainerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not logged in')),
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookingManagementScreen(trainerId: trainerId),
      ),
    );
  }
}
