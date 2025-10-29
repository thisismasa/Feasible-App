import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../models/user_model.dart';

/// Booking Management Screen
/// Shows all upcoming sessions, today's schedule, and allows management
class BookingManagementScreen extends StatefulWidget {
  final String trainerId;
  final int initialTab; // 0=Today, 1=Upcoming, 2=Weekly, 3=History

  const BookingManagementScreen({
    Key? key,
    required this.trainerId,
    this.initialTab = 0, // Default to Today tab
  }) : super(key: key);

  @override
  State<BookingManagementScreen> createState() => _BookingManagementScreenState();
}

class _BookingManagementScreenState extends State<BookingManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _todaySessions = [];
  List<Map<String, dynamic>> _upcomingSessions = [];
  List<Map<String, dynamic>> _weeklySessions = [];
  List<Map<String, dynamic>> _historySessions = []; // ✅ Added for history
  bool _isLoading = true;
  String? _errorMessage;

  // ✅ Added for history filtering
  String _historyFilter = '1_day'; // '1_day', '1_week', '1_month', 'custom'
  DateTime? _customStartDate;
  DateTime? _customEndDate;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.initialTab, // Use the initialTab parameter
    );
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Load today's sessions
      final today = await DatabaseService.instance.getTodaySchedule(widget.trainerId);

      // Load upcoming sessions (next 30 days)
      final upcoming = await DatabaseService.instance.getUpcomingSessions(
        widget.trainerId,
        limit: 50,
      );

      // Load weekly calendar
      final weekly = await DatabaseService.instance.getWeeklyCalendar(widget.trainerId);

      // ✅ Load history sessions (completed sessions)
      final history = await _loadHistorySessions();

      setState(() {
        _todaySessions = today;
        _upcomingSessions = upcoming;
        _weeklySessions = weekly;
        _historySessions = history;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  /// Load history sessions based on current filter
  Future<List<Map<String, dynamic>>> _loadHistorySessions() async {
    final now = DateTime.now();
    DateTime startDate;
    // ✅ FIX: Set endDate to end of today (23:59:59) to include all sessions today
    DateTime endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);

    // Calculate date range based on filter
    switch (_historyFilter) {
      case '1_day':
        // ✅ FIX: Last 24 hours from start of yesterday to end of today
        startDate = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 1));
        break;
      case '1_week':
        startDate = now.subtract(const Duration(days: 7));
        break;
      case '1_month':
        startDate = DateTime(now.year, now.month - 1, now.day);
        break;
      case 'custom':
        if (_customStartDate == null || _customEndDate == null) {
          return [];
        }
        startDate = _customStartDate!;
        endDate = _customEndDate!;
        break;
      default:
        startDate = now.subtract(const Duration(days: 1));
    }

    try {
      return await DatabaseService.instance.getCompletedSessions(
        widget.trainerId,
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      debugPrint('Error loading history sessions: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Management'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: const Icon(Icons.today),
              text: 'Today (${_todaySessions.length})',
            ),
            Tab(
              icon: const Icon(Icons.calendar_month),
              text: 'Upcoming (${_upcomingSessions.length})',
            ),
            Tab(
              icon: const Icon(Icons.view_week),
              text: 'Weekly',
            ),
            Tab(
              icon: const Icon(Icons.history),
              text: 'History (${_historySessions.length})', // ✅ Added history tab
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading sessions',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(_errorMessage!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTodayView(),
                    _buildUpcomingView(),
                    _buildWeeklyView(),
                    _buildHistoryView(), // ✅ Added history view
                  ],
                ),
    );
  }

  Widget _buildTodayView() {
    if (_todaySessions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_available, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No sessions scheduled for today',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Enjoy your free day!',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _todaySessions.length,
        itemBuilder: (context, index) {
          final session = _todaySessions[index];
          return _buildSessionCard(session, showDate: false);
        },
      ),
    );
  }

  Widget _buildUpcomingView() {
    if (_upcomingSessions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No upcoming sessions',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Book sessions to see them here',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    // Group sessions by date
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final session in _upcomingSessions) {
      final date = DateFormat('yyyy-MM-dd').format(
        DateTime.parse(session['scheduled_start']),
      );
      grouped.putIfAbsent(date, () => []).add(session);
    }

    final sortedDates = grouped.keys.toList()..sort();

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: sortedDates.length,
        itemBuilder: (context, index) {
          final date = sortedDates[index];
          final sessions = grouped[date]!;
          final dateObj = DateTime.parse(date);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 8, top: 16, bottom: 8),
                child: Text(
                  DateFormat('EEEE, MMMM d').format(dateObj),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              ...sessions.map((session) => _buildSessionCard(session, showDate: false)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildWeeklyView() {
    if (_weeklySessions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.view_week, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No sessions this week',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      );
    }

    // Group by date
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final session in _weeklySessions) {
      final date = DateFormat('yyyy-MM-dd').format(
        DateTime.parse(session['scheduled_start']),
      );
      grouped.putIfAbsent(date, () => []).add(session);
    }

    final sortedDates = grouped.keys.toList()..sort();

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: sortedDates.length,
        itemBuilder: (context, index) {
          final date = sortedDates[index];
          final sessions = grouped[date]!;
          final dateObj = DateTime.parse(date);
          final isToday = DateFormat('yyyy-MM-dd').format(DateTime.now()) == date;

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            color: isToday ? Colors.blue[50] : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isToday ? Colors.blue : Colors.grey[200],
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    children: [
                      if (isToday)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'TODAY',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                      if (isToday) const SizedBox(width: 12),
                      Text(
                        DateFormat('EEEE, MMMM d').format(dateObj),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isToday ? Colors.white : Colors.black87,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isToday ? Colors.white24 : Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${sessions.length} session${sessions.length != 1 ? 's' : ''}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isToday ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                ...sessions.map((session) => _buildCompactSessionTile(session)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHistoryView() {
    return Column(
      children: [
        // Filter selector
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey[100],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.filter_list, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Filter by:',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildFilterChip('Last 24 Hours', '1_day'),
                  _buildFilterChip('Last 7 Days', '1_week'),
                  _buildFilterChip('Last 30 Days', '1_month'),
                  _buildFilterChip('Custom Range', 'custom'),
                ],
              ),
              if (_historyFilter == 'custom') ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _customStartDate ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (date != null) {
                            setState(() => _customStartDate = date);
                            _loadData();
                          }
                        },
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text(
                          _customStartDate != null
                              ? DateFormat('MMM d, yyyy').format(_customStartDate!)
                              : 'Start Date',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('to'),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _customEndDate ?? DateTime.now(),
                            firstDate: _customStartDate ?? DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (date != null) {
                            setState(() => _customEndDate = date);
                            _loadData();
                          }
                        },
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text(
                          _customEndDate != null
                              ? DateFormat('MMM d, yyyy').format(_customEndDate!)
                              : 'End Date',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),

        // Sessions list
        Expanded(
          child: _historySessions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No completed sessions',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sessions you complete will appear here',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _historySessions.length,
                    itemBuilder: (context, index) {
                      final session = _historySessions[index];
                      return _buildHistorySessionCard(session);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _historyFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _historyFilter = value;
          });
          _loadData();
        }
      },
      selectedColor: Colors.blue[100],
      checkmarkColor: Colors.blue[700],
    );
  }

  Widget _buildHistorySessionCard(Map<String, dynamic> session) {
    // ✅ FIXED: Add null safety for date parsing
    final scheduledStart = DateTime.parse(session['scheduled_start'] ?? DateTime.now().toIso8601String());
    final scheduledEnd = DateTime.parse(session['scheduled_end'] ?? DateTime.now().add(Duration(hours: 1)).toIso8601String());
    final clientName = session['client_name'] ?? 'Unknown Client';
    final packageName = session['package_name'] ?? 'Package';
    final location = session['location'] ?? 'TBD';
    final sessionType = session['session_type'] ?? 'in_person';
    final completedAt = session['completed_at'] != null
        ? DateTime.parse(session['completed_at'])
        : scheduledEnd;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showSessionDetails(session),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  // Date & Time
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          DateFormat('MMM d').format(scheduledStart),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.green[700],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          DateFormat('HH:mm').format(scheduledStart),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Client info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.person, size: 16),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                clientName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              sessionType == 'online'
                                  ? Icons.videocam
                                  : Icons.location_on,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                location,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Completed badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, size: 12, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'Completed',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Package and duration
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      packageName,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.timer, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${session['duration_minutes']} min',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSessionCard(Map<String, dynamic> session, {bool showDate = true}) {
    // ✅ FIXED: Add null safety for date parsing
    final scheduledStart = DateTime.parse(session['scheduled_start'] ?? DateTime.now().toIso8601String());
    final scheduledEnd = DateTime.parse(session['scheduled_end'] ?? DateTime.now().add(Duration(hours: 1)).toIso8601String());
    final clientName = session['client_name'] ?? 'Unknown Client';
    final packageName = session['package_name'] ?? 'Package';
    final location = session['location'] ?? 'TBD';
    final sessionType = session['session_type'] ?? 'in_person';
    final status = session['status'] ?? 'scheduled';
    final notes = session['client_notes'] ?? '';

    // Calculate time until session
    final now = DateTime.now();
    final minutesUntil = scheduledStart.difference(now).inMinutes;
    final isUpcoming = minutesUntil > 0 && minutesUntil <= 60;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isUpcoming ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isUpcoming
            ? const BorderSide(color: Colors.orange, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () => _showSessionDetails(session),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  // Time
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isUpcoming ? Colors.orange[50] : Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Text(
                          DateFormat('HH:mm').format(scheduledStart),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isUpcoming ? Colors.orange : Colors.blue,
                          ),
                        ),
                        Text(
                          '${session['duration_minutes']}min',
                          style: TextStyle(
                            fontSize: 12,
                            color: isUpcoming ? Colors.orange[700] : Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Client info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.person, size: 16),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                clientName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              sessionType == 'online'
                                  ? Icons.videocam
                                  : Icons.location_on,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                location,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Status badge
                  if (isUpcoming)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.access_time, size: 12, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(
                            'Soon',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              // Package badge
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  packageName,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                ),
              ),

              // Notes (if any)
              if (notes.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.note, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        notes,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],

              // Action buttons
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _confirmSession(session),
                      icon: const Icon(Icons.check_circle, size: 16),
                      label: const Text('Confirm'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _cancelSession(session),
                      icon: const Icon(Icons.cancel, size: 16),
                      label: const Text('Cancel'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactSessionTile(Map<String, dynamic> session) {
    // ✅ FIXED: Add null safety for date parsing
    final scheduledStart = DateTime.parse(session['scheduled_start'] ?? DateTime.now().toIso8601String());
    final clientName = session['client_name'] ?? 'Unknown';
    final sessionType = session['session_type'] ?? 'in_person';

    return ListTile(
      dense: true,
      leading: CircleAvatar(
        backgroundColor: Colors.blue[100],
        child: Text(
          DateFormat('HH:mm').format(scheduledStart).substring(0, 2),
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ),
      title: Text(
        clientName,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        '${DateFormat('HH:mm').format(scheduledStart)} • ${session['duration_minutes']}min',
        style: const TextStyle(fontSize: 12),
      ),
      trailing: Icon(
        sessionType == 'online' ? Icons.videocam : Icons.location_on,
        size: 16,
      ),
      onTap: () => _showSessionDetails(session),
    );
  }

  void _showSessionDetails(Map<String, dynamic> session) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          // ✅ FIXED: Add null safety for date parsing
          final scheduledStart = DateTime.parse(session['scheduled_start'] ?? DateTime.now().toIso8601String());
          final scheduledEnd = DateTime.parse(session['scheduled_end'] ?? DateTime.now().add(Duration(hours: 1)).toIso8601String());

          return SingleChildScrollView(
            controller: scrollController,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.calendar_today, color: Colors.blue[700]),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              session['client_name'] ?? 'Unknown Client',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            Text(
                              DateFormat('EEEE, MMMM d, yyyy').format(scheduledStart),
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Details
                  _buildDetailRow(
                    Icons.access_time,
                    'Time',
                    '${DateFormat('HH:mm').format(scheduledStart)} - ${DateFormat('HH:mm').format(scheduledEnd)}',
                  ),
                  _buildDetailRow(
                    Icons.timer,
                    'Duration',
                    '${session['duration_minutes']} minutes',
                  ),
                  _buildDetailRow(
                    Icons.location_on,
                    'Location',
                    session['location'] ?? 'TBD',
                  ),
                  _buildDetailRow(
                    Icons.category,
                    'Type',
                    session['session_type'] == 'online' ? 'Online' : 'In Person',
                  ),
                  _buildDetailRow(
                    Icons.card_membership,
                    'Package',
                    session['package_name'] ?? 'Package',
                  ),
                  if (session['client_notes'] != null &&
                      session['client_notes'].toString().isNotEmpty)
                    _buildDetailRow(
                      Icons.note,
                      'Notes',
                      session['client_notes']?.toString() ?? '',  // ✅ FIXED: Ensure non-null String
                    ),

                  const SizedBox(height: 24),

                  // Actions (only show for non-completed sessions)
                  if (session['status'] != 'completed') ...[
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _confirmSession(session);
                            },
                            icon: const Icon(Icons.check_circle),
                            label: const Text('Confirm'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _cancelSession(session);
                            },
                            icon: const Icon(Icons.cancel),
                            label: const Text('Cancel'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    // For completed sessions, show status badge
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green[200]!),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle, color: Colors.green[700], size: 24),
                          const SizedBox(width: 12),
                          Text(
                            'Session Completed',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmSession(Map<String, dynamic> session) async {
    // ✅ FIX: Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Confirming session...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      // ✅ FIX: Use 'id' field (not 'session_id') and change status to 'completed'
      final sessionId = session['id'] ?? session['session_id'];

      await DatabaseService.instance.updateSessionStatus(
        sessionId: sessionId,
        status: 'completed', // ✅ Changed from 'confirmed' to 'completed'
        actualEndTime: DateTime.now(), // Mark when completed
      );

      if (mounted) {
        // ✅ FIX: Close loading dialog
        Navigator.pop(context);

        // Show success
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Session completed successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Reload data to remove completed session from list
        await _loadData();
      }
    } catch (e) {
      if (mounted) {
        // ✅ FIX: Close loading dialog on error too
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error confirming session: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _cancelSession(Map<String, dynamic> session) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Session'),
        content: const Text('Are you sure you want to cancel this session?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () async {
              // ✅ FIX: Capture ScaffoldMessenger BEFORE popping dialog
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(context);

              try {
                // ✅ FIXED: Use 'id' field with fallback (same as confirm method)
                final sessionId = session['id'] ?? session['session_id'];

                await DatabaseService.instance.cancelSessionSimple(
                  sessionId,
                  'Cancelled by trainer',
                );
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('✓ Session cancelled successfully'),
                    backgroundColor: Colors.orange,
                  ),
                );
                _loadData();
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Error cancelling session: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Yes, Cancel', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
