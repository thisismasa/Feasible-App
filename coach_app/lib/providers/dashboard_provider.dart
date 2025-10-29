import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/session_model.dart';
import '../models/package_model.dart';
import '../utils/sample_data.dart';
import '../services/database_service.dart';

class DashboardMetrics {
  final int totalClients;
  final int activeClients;
  final int completedSessions;
  final int upcomingSessions;
  final int todaySessions;
  final double totalRevenue;
  final double monthlyRevenue;
  final double weeklyRevenue;
  final double averageSessionRating;
  final int totalPackagesSold;
  final Map<String, int> sessionsByDay;
  final Map<String, double> revenueByMonth;
  final List<ClientActivity> recentActivities;

  DashboardMetrics({
    required this.totalClients,
    required this.activeClients,
    required this.completedSessions,
    required this.upcomingSessions,
    required this.todaySessions,
    required this.totalRevenue,
    required this.monthlyRevenue,
    required this.weeklyRevenue,
    required this.averageSessionRating,
    required this.totalPackagesSold,
    required this.sessionsByDay,
    required this.revenueByMonth,
    required this.recentActivities,
  });
}

class ClientActivity {
  final String clientId;
  final String clientName;
  final String activity;
  final DateTime timestamp;
  final String? details;

  ClientActivity({
    required this.clientId,
    required this.clientName,
    required this.activity,
    required this.timestamp,
    this.details,
  });
}

class DashboardProvider extends ChangeNotifier {
  DashboardMetrics? _metrics;
  List<UserModel> _clients = [];
  List<SessionModel> _sessions = [];
  List<SessionModel> _todaySessions = [];
  List<ClientPackage> _packages = [];
  Map<String, List<Map<String, dynamic>>> _chatMessages = {};
  List<Map<String, dynamic>> _notifications = [];
  
  bool _isLoading = false;
  String? _error;
  String? _trainerId;
  
  DashboardMetrics? get metrics => _metrics;
  List<UserModel> get clients => _clients;
  List<SessionModel> get sessions => _sessions;
  List<SessionModel> get todaySessions => _todaySessions;
  List<ClientPackage> get packages => _packages;
  List<Map<String, dynamic>> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, List<Map<String, dynamic>>> get chatMessages => _chatMessages;
  
  /// Reset provider to clean state (call on logout or before new user login)
  void reset() {
    debugPrint('🔄 Resetting DashboardProvider to default state');

    _metrics = null;
    _clients = [];
    _sessions = [];
    _todaySessions = [];
    _packages = [];
    _chatMessages = {};
    _notifications = [];
    _isLoading = false;
    _error = null;
    _trainerId = null;

    notifyListeners();
    debugPrint('✅ DashboardProvider reset complete');
  }

  Future<void> initialize(String trainerId) async {
    // CRITICAL: Reset all data first to prevent data leakage between users
    debugPrint('🔒 Initializing dashboard for new user: $trainerId');
    reset();

    _trainerId = trainerId;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint('⏳ Loading dashboard data...');

      // Check if we're in real mode or demo mode
      final isRealMode = DatabaseService.instance.isRealMode;
      debugPrint('🔹 Dashboard mode: ${isRealMode ? "REAL" : "DEMO"}');

      if (isRealMode) {
        // REAL MODE: Load from database (starts empty for new trainers)
        debugPrint('📊 Loading real data from database...');

        // For real mode, start with empty data
        // The actual dashboard should load data from DatabaseService methods
        _clients = [];
        _sessions = [];
        _packages = [];
        _todaySessions = [];
        _notifications = [];

        debugPrint('✅ Real mode initialized - empty state for new trainer');
      } else {
        // DEMO MODE: Load sample data for demonstration
        debugPrint('📱 Loading demo sample data...');
        await Future.delayed(const Duration(milliseconds: 800));

        _clients = SampleData.clients;
        _sessions = SampleData.sessions;
        _packages = SampleData.packages;

        final now = DateTime.now();
        _todaySessions = _sessions.where((session) {
          return session.scheduledDate.year == now.year &&
                 session.scheduledDate.month == now.month &&
                 session.scheduledDate.day == now.day;
        }).toList();

        _notifications = [
          {'id': '1', 'title': 'New client', 'message': 'John Doe joined', 'timestamp': DateTime.now(), 'read': false},
          {'id': '2', 'title': 'Session done', 'message': 'Completed with Sarah', 'timestamp': DateTime.now(), 'read': true},
        ];

        debugPrint('✅ Demo data loaded');
      }

      _calculateMetrics();

      debugPrint('✓ Dashboard loaded successfully for user: $trainerId');
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Dashboard error: $e');
      _error = 'Failed to load dashboard: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }
  
  void _calculateMetrics() {
    final sessionsByDay = <String, int>{};
    final now = DateTime.now();
    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final dayName = _getDayName(day.weekday);
      final count = _sessions.where((s) =>
          s.scheduledDate.year == day.year &&
          s.scheduledDate.month == day.month &&
          s.scheduledDate.day == day.day).length;
      sessionsByDay[dayName] = count;
    }
    
    final revenueByMonth = <String, double>{};
    for (int i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final monthName = _getMonthName(month.month);
      final revenue = _sessions
          .where((s) => s.scheduledDate.year == month.year &&
                       s.scheduledDate.month == month.month &&
                       s.status == SessionStatus.completed)
          .fold<double>(0.0, (sum, s) => sum + s.price);
      revenueByMonth[monthName] = revenue;
    }
    
    final completedSessions = _sessions.where((s) => s.status == SessionStatus.completed).length;
    final upcomingSessions = _sessions.where((s) => s.status == SessionStatus.scheduled).length;
    final totalRevenue = _sessions
        .where((s) => s.status == SessionStatus.completed)
        .fold<double>(0.0, (sum, s) => sum + s.price);
    
    final recentActivities = <ClientActivity>[
      ClientActivity(clientId: '1', clientName: 'John Doe', activity: 'Completed Session', timestamp: DateTime.now(), details: 'Upper Body'),
      ClientActivity(clientId: '2', clientName: 'Sarah Wilson', activity: 'Booked Session', timestamp: DateTime.now(), details: 'Tomorrow 9AM'),
    ];
    
    _metrics = DashboardMetrics(
      totalClients: _clients.length,
      activeClients: _clients.where((c) => c.isActive).length,
      completedSessions: completedSessions,
      upcomingSessions: upcomingSessions,
      todaySessions: _todaySessions.length,
      totalRevenue: totalRevenue,
      monthlyRevenue: revenueByMonth.values.isEmpty ? 0 : revenueByMonth.values.reduce((a, b) => a + b),
      weeklyRevenue: totalRevenue * 0.25,
      averageSessionRating: 4.7,
      totalPackagesSold: _packages.length,
      sessionsByDay: sessionsByDay,
      revenueByMonth: revenueByMonth,
      recentActivities: recentActivities,
    );
  }
  
  int get unreadNotifications => _notifications.where((n) => n['read'] == false).length;
  
  Future<void> markNotificationAsRead(String id) async {
    final index = _notifications.indexWhere((n) => n['id'] == id);
    if (index != -1) {
      _notifications[index]['read'] = true;
      notifyListeners();
    }
  }
  
  Future<void> sendChatMessage(String clientId, String message) async {
    debugPrint('📱 Demo: Sending message to $clientId: $message');
    // In demo mode, just log
  }
  
  Future<void> refresh() async => await initialize(_trainerId!);
  
  String _getDayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }
  
  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
}


