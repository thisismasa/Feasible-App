import '../models/user_model.dart';
import '../models/session_model.dart';
import '../models/package_model.dart';

/// Static sample data for demo mode
class SampleData {
  // Sample clients
  static final List<UserModel> clients = [
    UserModel(
      id: 'client-1',
      email: 'john.doe@example.com',
      name: 'John Doe',
      phone: '+1234567890',
      role: UserRole.client,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      isActive: true,
    ),
    UserModel(
      id: 'client-2',
      email: 'sarah.wilson@example.com',
      name: 'Sarah Wilson',
      phone: '+1234567891',
      role: UserRole.client,
      createdAt: DateTime.now().subtract(const Duration(days: 20)),
      isActive: true,
    ),
    UserModel(
      id: 'client-3',
      email: 'mike.johnson@example.com',
      name: 'Mike Johnson',
      phone: '+1234567892',
      role: UserRole.client,
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
      isActive: true,
    ),
  ];
  
  // Sample sessions
  static final List<SessionModel> sessions = [
    SessionModel(
      id: 'session-1',
      clientId: 'client-1',
      trainerId: 'trainer-1',
      clientName: 'John Doe',
      scheduledDate: DateTime.now().add(const Duration(hours: 2)),
      durationMinutes: 60,
      status: SessionStatus.scheduled,
      notes: 'Upper body workout',
      createdAt: DateTime.now(),
      price: 50.0,
    ),
    SessionModel(
      id: 'session-2',
      clientId: 'client-2',
      trainerId: 'trainer-1',
      clientName: 'Sarah Wilson',
      scheduledDate: DateTime.now().subtract(const Duration(days: 1)),
      durationMinutes: 45,
      status: SessionStatus.completed,
      notes: 'Cardio session',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      price: 45.0,
    ),
    SessionModel(
      id: 'session-3',
      clientId: 'client-3',
      trainerId: 'trainer-1',
      clientName: 'Mike Johnson',
      scheduledDate: DateTime.now().add(const Duration(days: 1)),
      durationMinutes: 60,
      status: SessionStatus.scheduled,
      notes: 'Full body workout',
      createdAt: DateTime.now(),
      price: 60.0,
    ),
  ];
  
  // Sample packages
  static final List<ClientPackage> packages = [
    ClientPackage(
      id: 'package-1',
      clientId: 'client-1',
      packageId: 'pkg-starter',
      packageName: 'Starter Package',
      totalSessions: 5,
      sessionsUsed: 2,
      purchaseDate: DateTime.now().subtract(const Duration(days: 10)),
      expiryDate: DateTime.now().add(const Duration(days: 20)),
      amountPaid: 199.99,
      status: PackageStatus.active,
    ),
    ClientPackage(
      id: 'package-2',
      clientId: 'client-2',
      packageId: 'pkg-premium',
      packageName: 'Premium Package',
      totalSessions: 10,
      sessionsUsed: 5,
      purchaseDate: DateTime.now().subtract(const Duration(days: 20)),
      expiryDate: DateTime.now().add(const Duration(days: 40)),
      amountPaid: 349.99,
      status: PackageStatus.active,
    ),
  ];
}
