import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/user_model.dart';
import '../models/session_model.dart';
import '../models/package_model.dart';
import '../providers/dashboard_provider.dart';
import '../services/supabase_service.dart';
import '../widgets/chat_widget.dart';
import 'booking_screen_enhanced.dart';
import 'package_selection_screen.dart';

class ClientDetailScreen extends StatefulWidget {
  final UserModel client;

  const ClientDetailScreen({
    Key? key,
    required this.client,
  }) : super(key: key);

  @override
  State<ClientDetailScreen> createState() => _ClientDetailScreenState();
}

class _ClientDetailScreenState extends State<ClientDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<SessionModel> _clientSessions = [];
  List<ClientPackage> _clientPackages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadClientData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadClientData() async {
    try {
      // Load sessions
      final sessionsResponse = await SupabaseService.instance.client
          .from('sessions')
          .select()
          .eq('client_id', widget.client.id)
          .order('scheduled_date', ascending: false);
      
      if (sessionsResponse is List) {
        _clientSessions = (sessionsResponse as List)
            .map((data) => SessionModel.fromSupabaseMap(data))
            .toList();
      }
      
      // Load packages
      final packagesResponse = await SupabaseService.instance.client
          .from('client_packages')
          .select()
          .eq('client_id', widget.client.id)
          .order('purchase_date', ascending: false);
      
      if (packagesResponse is List) {
        _clientPackages = (packagesResponse as List)
            .map((data) => ClientPackage.fromSupabaseMap(data))
            .toList();
      }
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading client data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 280,
              pinned: true,
              backgroundColor: Colors.blue,
              flexibleSpace: FlexibleSpaceBar(
                background: _buildHeader(),
              ),
              bottom: TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                tabs: const [
                  Tab(icon: Icon(Icons.info), text: 'Overview'),
                  Tab(icon: Icon(Icons.card_giftcard), text: 'Packages'),
                  Tab(icon: Icon(Icons.calendar_today), text: 'Sessions'),
                  Tab(icon: Icon(Icons.bar_chart), text: 'Progress'),
                ],
              ),
            ),
          ];
        },
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildOverviewTab(),
                  _buildPackagesTab(),
                  _buildSessionsTab(),
                  _buildProgressTab(),
                ],
              ),
      ),
      floatingActionButton: _buildSpeedDial(),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue.shade600, Colors.blue.shade800],
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Profile Picture
            Hero(
              tag: 'client-avatar-${widget.client.id}',
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  image: widget.client.photoUrl != null
                      ? DecorationImage(
                          image: CachedNetworkImageProvider(widget.client.photoUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: widget.client.photoUrl == null
                    ? CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white24,
                        child: Text(
                          widget.client.name[0].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 40,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            
            // Client Name
            Text(
              widget.client.name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            
            // Status
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: widget.client.isOnline
                    ? Colors.green.withOpacity(0.2)
                    : Colors.grey.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: widget.client.isOnline ? Colors.green : Colors.grey,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: widget.client.isOnline ? Colors.green : Colors.grey,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    widget.client.isOnline ? 'Online' : 'Offline',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    final activePackage = _clientPackages.firstWhere(
      (p) => p.status == PackageStatus.active && !p.isExpired,
      orElse: () => _clientPackages.first,
    );
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Contact Information
          _buildSectionCard(
            title: 'Contact Information',
            icon: Icons.contact_phone,
            child: Column(
              children: [
                _buildInfoRow(Icons.email, 'Email', widget.client.email),
                const Divider(),
                _buildInfoRow(Icons.phone, 'Phone', widget.client.phone),
                if (widget.client.metadata?['address'] != null) ...[
                  const Divider(),
                  _buildInfoRow(
                    Icons.location_on,
                    'Address',
                    widget.client.metadata!['address'],
                  ),
                ],
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Current Package Summary
          if (_clientPackages.isNotEmpty)
            _buildSectionCard(
              title: 'Active Package',
              icon: Icons.card_giftcard,
              action: TextButton(
                onPressed: () => _showPackageOptions(),
                child: const Text('Manage'),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activePackage.packageName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Valid until ${DateFormat('MMM dd, yyyy').format(activePackage.expiryDate)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: activePackage.isExpired
                              ? Colors.red.shade100
                              : Colors.green.shade100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          activePackage.isExpired ? 'Expired' : 'Active',
                          style: TextStyle(
                            color: activePackage.isExpired
                                ? Colors.red.shade700
                                : Colors.green.shade700,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Sessions Progress
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Sessions Used'),
                          Text(
                            '${activePackage.sessionsUsed} / ${activePackage.totalSessions}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: activePackage.sessionsUsed / activePackage.totalSessions,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          activePackage.remainingSessions > 0
                              ? Colors.blue
                              : Colors.red,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${activePackage.remainingSessions} sessions remaining',
                        style: TextStyle(
                          fontSize: 12,
                          color: activePackage.remainingSessions > 0
                              ? Colors.green.shade700
                              : Colors.red.shade700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          
          const SizedBox(height: 16),
          
          // Quick Stats
          _buildSectionCard(
            title: 'Statistics',
            icon: Icons.analytics,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  icon: Icons.fitness_center,
                  value: _clientSessions
                      .where((s) => s.status == SessionStatus.completed)
                      .length
                      .toString(),
                  label: 'Completed',
                  color: Colors.green,
                ),
                _buildStatItem(
                  icon: Icons.schedule,
                  value: _clientSessions
                      .where((s) => s.status == SessionStatus.scheduled)
                      .length
                      .toString(),
                  label: 'Scheduled',
                  color: Colors.blue,
                ),
                _buildStatItem(
                  icon: Icons.cancel,
                  value: _clientSessions
                      .where((s) => s.status == SessionStatus.cancelled)
                      .length
                      .toString(),
                  label: 'Cancelled',
                  color: Colors.orange,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Health Information
          if (widget.client.metadata?['health_conditions'] != null ||
              widget.client.metadata?['goals'] != null)
            _buildSectionCard(
              title: 'Health & Goals',
              icon: Icons.favorite,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.client.metadata?['fitness_level'] != null) ...[
                    Row(
                      children: [
                        const Icon(Icons.speed, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        const Text('Fitness Level: '),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            widget.client.metadata!['fitness_level']
                                .toString()
                                .toUpperCase(),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                  
                  if (widget.client.metadata?['health_conditions'] != null) ...[
                    const Text(
                      'Health Conditions:',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: (widget.client.metadata!['health_conditions'] as List)
                          .map((condition) => Chip(
                                label: Text(
                                  condition,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                backgroundColor: Colors.red.shade50,
                                labelStyle: TextStyle(
                                  color: Colors.red.shade700,
                                ),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  if (widget.client.metadata?['goals'] != null) ...[
                    const Text(
                      'Fitness Goals:',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: (widget.client.metadata!['goals'] as List)
                          .map((goal) => Chip(
                                label: Text(
                                  goal,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                backgroundColor: Colors.green.shade50,
                                labelStyle: TextStyle(
                                  color: Colors.green.shade700,
                                ),
                              ))
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPackagesTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Add Package Button
        ElevatedButton.icon(
          onPressed: () => _addNewPackage(),
          icon: const Icon(Icons.add),
          label: const Text('Add New Package'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Package History
        if (_clientPackages.isEmpty)
          Center(
            child: Column(
              children: [
                Icon(
                  Icons.card_giftcard,
                  size: 80,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 16),
                Text(
                  'No packages yet',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          )
        else
          ..._clientPackages.map((package) => _buildPackageCard(package)).toList(),
      ],
    );
  }

  Widget _buildSessionsTab() {
    final upcomingSessions = _clientSessions
        .where((s) => s.scheduledDate.isAfter(DateTime.now()))
        .toList();
    final pastSessions = _clientSessions
        .where((s) => s.scheduledDate.isBefore(DateTime.now()))
        .toList();
    
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(text: 'Upcoming'),
              Tab(text: 'Past'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                // Upcoming Sessions
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (upcomingSessions.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Text('No upcoming sessions'),
                        ),
                      )
                    else
                      ...upcomingSessions.map((session) => _buildSessionCard(session)),
                  ],
                ),
                
                // Past Sessions
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (pastSessions.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Text('No past sessions'),
                        ),
                      )
                    else
                      ...pastSessions.map((session) => _buildSessionCard(session)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressTab() {
    // Calculate monthly session data
    final monthlyData = <String, int>{};
    final now = DateTime.now();
    
    for (int i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final monthName = DateFormat('MMM').format(month);
      final count = _clientSessions
          .where((s) =>
              s.scheduledDate.year == month.year &&
              s.scheduledDate.month == month.month &&
              s.status == SessionStatus.completed)
          .length;
      monthlyData[monthName] = count;
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Session Trend Chart
          _buildSectionCard(
            title: 'Session Trend',
            icon: Icons.trending_up,
            child: SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 2,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.shade200,
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          final months = monthlyData.keys.toList();
                          if (value.toInt() >= 0 && value.toInt() < months.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                months[value.toInt()],
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                            );
                          }
                          return const SizedBox();
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 2,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 11,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: monthlyData.length.toDouble() - 1,
                  minY: 0,
                  maxY: (monthlyData.values.reduce((a, b) => a > b ? a : b) + 2).toDouble(),
                  lineBarsData: [
                    LineChartBarData(
                      spots: monthlyData.entries.map((entry) {
                        final index = monthlyData.keys.toList().indexOf(entry.key);
                        return FlSpot(index.toDouble(), entry.value.toDouble());
                      }).toList(),
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: Colors.white,
                            strokeWidth: 2,
                            strokeColor: Colors.blue,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.blue.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Attendance Rate
          _buildSectionCard(
            title: 'Attendance Statistics',
            icon: Icons.check_circle,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Attendance Rate'),
                    Text(
                      '${_calculateAttendanceRate()}%',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: _calculateAttendanceRate() / 100,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Activity Summary
          _buildSectionCard(
            title: 'Activity Summary',
            icon: Icons.summarize,
            child: Column(
              children: [
                _buildSummaryRow(
                  'Total Sessions',
                  _clientSessions.length.toString(),
                  Icons.fitness_center,
                ),
                const Divider(),
                _buildSummaryRow(
                  'Total Packages',
                  _clientPackages.length.toString(),
                  Icons.card_giftcard,
                ),
                const Divider(),
                _buildSummaryRow(
                  'Member Since',
                  DateFormat('MMM yyyy').format(widget.client.createdAt),
                  Icons.calendar_today,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
    Widget? action,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: Colors.blue, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (action != null) action,
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
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

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildPackageCard(ClientPackage package) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: package.status == PackageStatus.active
              ? Colors.green.shade200
              : Colors.grey.shade200,
        ),
      ),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: package.status == PackageStatus.active
                ? Colors.green.shade50
                : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.card_giftcard,
            color: package.status == PackageStatus.active
                ? Colors.green
                : Colors.grey,
          ),
        ),
        title: Text(package.packageName),
        subtitle: Text(
          'Purchased: ${DateFormat('MMM dd, yyyy').format(package.purchaseDate)}',
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: _getPackageStatusColor(package).withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            package.status.name.toUpperCase(),
            style: TextStyle(
              color: _getPackageStatusColor(package),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Sessions:'),
                    Text(
                      '${package.sessionsUsed} / ${package.totalSessions}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Valid Until:'),
                    Text(
                      DateFormat('MMM dd, yyyy').format(package.expiryDate),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Amount Paid:'),
                    Text(
                      '\$${package.amountPaid.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                if (package.status == PackageStatus.active &&
                    package.remainingSessions > 0) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _bookSessionWithPackage(package),
                      icon: const Icon(Icons.calendar_today),
                      label: const Text('Book Session'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionCard(SessionModel session) {
    final isPast = session.scheduledDate.isBefore(DateTime.now());
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPast ? Colors.grey.shade200 : Colors.blue.shade200,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: _getStatusColor(session.status).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  DateFormat('dd').format(session.scheduledDate),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _getStatusColor(session.status),
                  ),
                ),
                Text(
                  DateFormat('MMM').format(session.scheduledDate),
                  style: TextStyle(
                    fontSize: 12,
                    color: _getStatusColor(session.status),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('EEEE, hh:mm a').format(session.scheduledDate),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.timer,
                      size: 14,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${session.durationMinutes} minutes',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getStatusColor(session.status).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              session.status.name.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: _getStatusColor(session.status),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(child: Text(label)),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeedDial() {
    return SpeedDial(
      icon: Icons.add,
      activeIcon: Icons.close,
      backgroundColor: Colors.blue,
      foregroundColor: Colors.white,
      children: [
        SpeedDialChild(
          child: const Icon(Icons.calendar_today),
          backgroundColor: Colors.green,
          label: 'Book Session',
          onTap: () => _bookSession(),
        ),
        SpeedDialChild(
          child: const Icon(Icons.card_giftcard),
          backgroundColor: Colors.purple,
          label: 'Add Package',
          onTap: () => _addNewPackage(),
        ),
        SpeedDialChild(
          child: const Icon(Icons.message),
          backgroundColor: Colors.orange,
          label: 'Send Message',
          onTap: () => _openChat(),
        ),
      ],
    );
  }

  void _showPackageOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Package Options',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.autorenew),
              title: const Text('Renew Package'),
              onTap: () {
                Navigator.pop(context);
                _renewPackage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Add New Package'),
              onTap: () {
                Navigator.pop(context);
                _addNewPackage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('View History'),
              onTap: () {
                Navigator.pop(context);
                _tabController.animateTo(1);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _bookSession() async {
    final activePackage = _clientPackages.firstWhere(
      (p) => p.status == PackageStatus.active && p.remainingSessions > 0,
      orElse: () => _clientPackages.first,
    );
    
    if (activePackage.remainingSessions == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No sessions remaining in active package'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    // Use enhanced booking screen directly
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookingScreenEnhanced(
          client: widget.client,
          package: activePackage,
          trainerId: SupabaseService.instance.currentUser?.id,
        ),
      ),
    );
    
    if (result == true) {
      _loadClientData();
    }
  }

  void _bookSessionWithPackage(ClientPackage package) async {
    // Use enhanced booking by default for direct package booking
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookingScreenEnhanced(
          client: widget.client,
          package: package,
          trainerId: SupabaseService.instance.currentUser?.id,
        ),
      ),
    );
    
    if (result == true) {
      _loadClientData();
    }
  }

  void _addNewPackage() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PackageSelectionScreen(
          client: widget.client,
        ),
      ),
    );
    
    if (result == true) {
      _loadClientData();
    }
  }

  void _renewPackage() {
    // Implement package renewal
  }

  void _openChat() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatWidget(
          trainerId: SupabaseService.instance.currentUser!.id,
          clientId: widget.client.id,
          clientName: widget.client.name,
          messages: const [],
          onSendMessage: (clientId, message) {
            // Send message implementation
          },
        ),
      ),
    );
  }

  double _calculateAttendanceRate() {
    final totalScheduled = _clientSessions
        .where((s) => s.scheduledDate.isBefore(DateTime.now()))
        .length;
    
    if (totalScheduled == 0) return 100;
    
    final attended = _clientSessions
        .where((s) =>
            s.scheduledDate.isBefore(DateTime.now()) &&
            s.status == SessionStatus.completed)
        .length;
    
    return (attended / totalScheduled * 100);
  }

  Color _getStatusColor(SessionStatus status) {
    switch (status) {
      case SessionStatus.scheduled:
        return Colors.blue;
      case SessionStatus.completed:
        return Colors.green;
      case SessionStatus.cancelled:
        return Colors.red;
      case SessionStatus.noShow:
        return Colors.orange;
    }
  }

  Color _getPackageStatusColor(ClientPackage package) {
    if (package.status == PackageStatus.expired || package.isExpired) {
      return Colors.red;
    } else if (package.status == PackageStatus.completed) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }
}

// Speed Dial Widget
class SpeedDial extends StatefulWidget {
  final IconData icon;
  final IconData activeIcon;
  final Color backgroundColor;
  final Color foregroundColor;
  final List<SpeedDialChild> children;

  const SpeedDial({
    Key? key,
    required this.icon,
    required this.activeIcon,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.children,
  }) : super(key: key);

  @override
  State<SpeedDial> createState() => _SpeedDialState();
}

class _SpeedDialState extends State<SpeedDial>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ..._isOpen
            ? widget.children.reversed.map((child) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (child.label != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade800,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            child.label!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      const SizedBox(width: 12),
                      FloatingActionButton.small(
                        onPressed: () {
                          _toggle();
                          child.onTap?.call();
                        },
                        backgroundColor: child.backgroundColor,
                        child: child.child,
                      ),
                    ],
                  ),
                ))
            : [],
        FloatingActionButton(
          onPressed: _toggle,
          backgroundColor: widget.backgroundColor,
          child: AnimatedIcon(
            icon: AnimatedIcons.menu_close,
            progress: _controller,
            color: widget.foregroundColor,
          ),
        ),
      ],
    );
  }
}

class SpeedDialChild {
  final Widget child;
  final Color? backgroundColor;
  final String? label;
  final VoidCallback? onTap;

  SpeedDialChild({
    required this.child,
    this.backgroundColor,
    this.label,
    this.onTap,
  });
}

