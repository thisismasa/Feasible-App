import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:badges/badges.dart' as badges;

import '../providers/dashboard_provider.dart';
import '../models/user_model.dart';
import '../models/session_model.dart';
import '../widgets/animated_metric_card.dart';
import '../widgets/revenue_chart_widget.dart';
import '../widgets/dashboard_action_buttons.dart';
import '../services/supabase_service.dart';
import '../services/database_service.dart';
import 'add_client_screen_enhanced.dart';
import 'client_selection_screen.dart';
import 'booking_screen_enhanced.dart';
import 'invoice_management_screen.dart';
import 'live_session_screen.dart';
import 'progress_photos_screen.dart';
import 'measurement_tracking_screen.dart';
import 'workout_builder_screen.dart';
import 'advanced_program_builder_screen.dart';
import 'habits_goals_screen.dart';
import 'weekly_checkin_screen.dart';
import 'badges_rewards_screen.dart';

/// Enhanced PT Coach Dashboard - Mobile Optimized
/// Features: Hamburger menu, no overflow, responsive, modern UI
class TrainerDashboardEnhanced extends StatefulWidget {
  final String trainerId;

  const TrainerDashboardEnhanced({
    Key? key,
    required this.trainerId,
  }) : super(key: key);

  @override
  State<TrainerDashboardEnhanced> createState() => _TrainerDashboardEnhancedState();
}

class _TrainerDashboardEnhancedState extends State<TrainerDashboardEnhanced>
    with SingleTickerProviderStateMixin {
  late AnimationController _fabController;
  int _selectedBottomNavIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<LiquidPullToRefreshState> _refreshKey = GlobalKey<LiquidPullToRefreshState>();

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Initialize dashboard provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().initialize(widget.trainerId);
    });
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardProvider>(
      builder: (context, dashboard, child) {
        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: const Color(0xFFF5F7FA),
          appBar: _buildAppBar(dashboard),
          drawer: _buildDrawerMenu(dashboard),
          body: _buildBody(dashboard),
          bottomNavigationBar: _buildBottomNavigationBar(dashboard),
          floatingActionButton: DashboardFAB(trainerId: widget.trainerId, onRefresh: () => dashboard.refresh()),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(DashboardProvider dashboard) {
    final user = SupabaseService.instance.currentUser;

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.menu, color: Colors.black87),
        onPressed: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            user?.userMetadata?['name'] ?? 'Trainer',
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'Welcome back!',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
        ],
      ),
      actions: [
        // Notification Badge
        badges.Badge(
          badgeContent: Text(
            '${dashboard.unreadNotifications}',
            style: const TextStyle(color: Colors.white, fontSize: 10),
          ),
          showBadge: dashboard.unreadNotifications > 0,
          position: badges.BadgePosition.topEnd(top: 8, end: 8),
          child: IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.black87),
            onPressed: () => _showNotifications(dashboard),
          ),
        ),
        const SizedBox(width: 8),
        // Profile Avatar
        GestureDetector(
          onTap: () => _showProfileMenu(),
          child: Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Colors.blue,
              child: Text(
                (user?.userMetadata?['name'] ?? 'T')[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: Colors.grey.shade200,
        ),
      ),
    );
  }

  Widget _buildDrawerMenu(DashboardProvider dashboard) {
    final user = SupabaseService.instance.currentUser;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Drawer Header
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade600, Colors.blue.shade800],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.fitness_center,
                        size: 28,
                        color: Colors.blue.shade600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      user?.userMetadata?['name'] ?? 'PT Coach',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user?.email ?? '',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Menu Items
          _buildDrawerItem(
            icon: Icons.dashboard,
            title: 'Dashboard',
            onTap: () {
              Navigator.pop(context);
              setState(() => _selectedBottomNavIndex = 0);
            },
          ),
          _buildDrawerItem(
            icon: Icons.people,
            title: 'Clients',
            badge: dashboard.clients.length.toString(),
            onTap: () {
              Navigator.pop(context);
              setState(() => _selectedBottomNavIndex = 1);
            },
          ),
          _buildDrawerItem(
            icon: Icons.calendar_today,
            title: 'Sessions',
            badge: dashboard.todaySessions.length.toString(),
            onTap: () {
              Navigator.pop(context);
              setState(() => _selectedBottomNavIndex = 2);
            },
          ),
          _buildDrawerItem(
            icon: Icons.attach_money,
            title: 'Revenue',
            onTap: () {
              Navigator.pop(context);
              setState(() => _selectedBottomNavIndex = 3);
            },
          ),
          _buildDrawerItem(
            icon: Icons.analytics,
            title: 'Analytics',
            onTap: () {
              Navigator.pop(context);
            },
          ),
          const Divider(),
          _buildDrawerItem(
            icon: Icons.chat,
            title: 'Messages',
            onTap: () {
              Navigator.pop(context);
            },
          ),
          _buildDrawerItem(
            icon: Icons.settings,
            title: 'Settings',
            onTap: () {
              Navigator.pop(context);
            },
          ),
          _buildDrawerItem(
            icon: Icons.help_outline,
            title: 'Help & Support',
            onTap: () {
              Navigator.pop(context);
            },
          ),
          const Divider(),
          _buildDrawerItem(
            icon: Icons.logout,
            title: 'Sign Out',
            textColor: Colors.red,
            iconColor: Colors.red,
            onTap: () async {
              Navigator.pop(context);
              await _handleSignOut();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    String? badge,
    Color? textColor,
    Color? iconColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? Colors.grey.shade700),
      title: Text(
        title,
        style: TextStyle(
          color: textColor ?? Colors.grey.shade800,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: badge != null
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                badge,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
      onTap: onTap,
    );
  }

  Widget _buildBody(DashboardProvider dashboard) {
    if (dashboard.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (dashboard.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 80, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              'Oops! Something went wrong',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              dashboard.error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => dashboard.refresh(),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ],
        ),
      );
    }

    return LiquidPullToRefresh(
      key: _refreshKey,
      onRefresh: () async {
        await dashboard.refresh();
      },
      color: Colors.blue,
      backgroundColor: Colors.blue.shade50,
      height: 100,
      animSpeedFactor: 2,
      showChildOpacityTransition: false,
      child: _buildDashboardContent(dashboard),
    );
  }

  Widget _buildDashboardContent(DashboardProvider dashboard) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero Card - Today's Focus
          _buildHeroCard(dashboard),

          const SizedBox(height: 20),

          // Quick Actions - Enhanced with full functionality
          QuickActionButtons(trainerId: widget.trainerId, onRefresh: () => dashboard.refresh()),

          const SizedBox(height: 20),

          // Metrics Section
          const Text(
            'Overview',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 16),

          // Metrics Grid with Fixed Height
          _buildMetricsGrid(dashboard),

          const SizedBox(height: 24),

          // Live Activity Feed
          _buildLiveActivityFeed(dashboard),

                const SizedBox(height: 24),

                // Today's Schedule
                _buildTodaySchedule(dashboard),

                const SizedBox(height: 24),

                // Revenue Chart
                _buildRevenueSection(dashboard),

                const SizedBox(height: 24),

                // Feature Hub
                _buildFeatureHub(dashboard),

                const SizedBox(height: 80), // Space for FAB
        ],
      ),
    );
  }

  Widget _buildHeroCard(DashboardProvider dashboard) {
    final metrics = dashboard.metrics;
    final now = DateTime.now();
    final greeting = now.hour < 12
        ? 'Good Morning'
        : now.hour < 18
            ? 'Good Afternoon'
            : 'Good Evening';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade600, Colors.blue.shade800],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    greeting,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Today's Focus",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.wb_sunny_outlined,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildHeroStat(
                  label: 'Sessions Today',
                  value: '${metrics?.todaySessions ?? 0}',
                  icon: Icons.fitness_center,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildHeroStat(
                  label: "Today's Earnings",
                  value: '\$${((metrics?.weeklyRevenue ?? 0) / 7).toStringAsFixed(0)}',
                  icon: Icons.payments,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroStat({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildQuickAction(
          icon: Icons.person_add,
          label: 'Add Client',
          color: Colors.blue,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AddClientScreenEnhanced(trainerId: widget.trainerId)),
            );
          },
        ),
        _buildQuickAction(
          icon: Icons.calendar_today,
          label: 'Book Session',
          color: Colors.green,
          onTap: () {
            // Navigate to booking
          },
        ),
        _buildQuickAction(
          icon: Icons.receipt_long,
          label: 'Invoice',
          color: Colors.orange,
          onTap: () {
            // Create invoice
          },
        ),
        _buildQuickAction(
          icon: Icons.chat_bubble,
          label: 'Message',
          color: Colors.purple,
          onTap: () {
            // Open messages
          },
        ),
      ],
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 80,
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsGrid(DashboardProvider dashboard) {
    final metrics = dashboard.metrics;
    if (metrics == null) return const SizedBox();

    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate responsive card dimensions with more height
        final cardWidth = (constraints.maxWidth - 16) / 2;
        final cardHeight = cardWidth * 1.15; // Increased aspect ratio to prevent overflow

        return SizedBox(
          height: cardHeight * 2 + 16, // Fixed height for 2 rows
          child: GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: cardWidth / cardHeight,
            children: [
              AnimatedMetricCard(
                title: 'Total Clients',
                value: metrics.totalClients.toString(),
                icon: Icons.people,
                color: Colors.blue,
                trend: '+12%',
                trendUp: true,
              ),
              AnimatedMetricCard(
                title: 'Active Clients',
                value: metrics.activeClients.toString(),
                icon: Icons.person_pin,
                color: Colors.green,
                trend: '+5%',
                trendUp: true,
              ),
              AnimatedMetricCard(
                title: "Today's Sessions",
                value: metrics.todaySessions.toString(),
                icon: Icons.today,
                color: Colors.orange,
                trend: '${metrics.todaySessions}',
                trendUp: metrics.todaySessions > 0,
              ),
              AnimatedMetricCard(
                title: 'Monthly Revenue',
                value: '\$${metrics.monthlyRevenue.toStringAsFixed(0)}',
                icon: Icons.attach_money,
                color: Colors.purple,
                trend: '+18%',
                trendUp: true,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLiveActivityFeed(DashboardProvider dashboard) {
    final activities = dashboard.metrics?.recentActivities ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Live Activity',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'LIVE',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (activities.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.timeline, size: 48, color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  Text(
                    'No recent activity',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: activities.take(3).length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final activity = activities[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.shade50,
                    child: Text(
                      activity.clientName[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(activity.clientName),
                  subtitle: Text(activity.activity),
                  trailing: Text(
                    _formatTimeAgo(activity.timestamp),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildTodaySchedule(DashboardProvider dashboard) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Today's Schedule",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() => _selectedBottomNavIndex = 2);
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (dashboard.todaySessions.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.event_available, size: 48, color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  Text(
                    'No sessions scheduled for today',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          )
        else
          ...dashboard.todaySessions.take(3).map((session) {
            return _buildSessionCard(session);
          }).toList(),
      ],
    );
  }

  Widget _buildSessionCard(SessionModel session) {
    final timeFormat = DateFormat('hh:mm a');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  timeFormat.format(session.scheduledDate).split(' ')[0],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                Text(
                  timeFormat.format(session.scheduledDate).split(' ')[1],
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue.shade600,
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
                  session.clientName,
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
                      '${session.durationMinutes} min',
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
          Icon(Icons.chevron_right, color: Colors.grey.shade400),
        ],
      ),
    );
  }

  Widget _buildRevenueSection(DashboardProvider dashboard) {
    final metrics = dashboard.metrics;
    if (metrics == null) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Revenue Trend',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          height: 250,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: RevenueChartWidget(
            data: metrics.revenueByMonth,
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureHub(DashboardProvider dashboard) {
    // Get a sample client for demo purposes
    final sampleClient = dashboard.clients.isNotEmpty 
        ? dashboard.clients.first 
        : UserModel(
            id: 'demo',
            email: 'demo@example.com',
            name: 'Demo Client',
            role: UserRole.client,
            phone: '123-456-7890',
            createdAt: DateTime.now(),
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.apps, color: Colors.deepPurple, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Feature Hub',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.purple.shade400, Colors.blue.shade400],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'NEW',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Advanced client tracking and engagement tools',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.3,
          children: [
            _buildFeatureCard(
              'Progress Photos',
              'Visual journey tracking',
              Icons.camera_alt,
              [Colors.purple.shade400, Colors.purple.shade600],
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProgressPhotosScreen(client: sampleClient),
                  ),
                );
              },
            ),
            _buildFeatureCard(
              'Measurements',
              'Track body metrics',
              Icons.straighten,
              [Colors.green.shade400, Colors.green.shade600],
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MeasurementTrackingScreen(client: sampleClient),
                  ),
                );
              },
            ),
            _buildFeatureCard(
              'Advanced Program Builder',
              'Multi-sport periodization',
              Icons.auto_awesome,
              [Colors.deepPurple.shade400, Colors.deepPurple.shade600],
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AdvancedProgramBuilderScreen(client: sampleClient),
                  ),
                );
              },
            ),
            _buildFeatureCard(
              'Habits & Goals',
              'Track daily habits',
              Icons.emoji_events,
              [Colors.teal.shade400, Colors.teal.shade600],
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HabitsGoalsScreen(client: sampleClient),
                  ),
                );
              },
            ),
            _buildFeatureCard(
              'Weekly Check-In',
              'Progress reviews',
              Icons.fact_check,
              [Colors.indigo.shade400, Colors.indigo.shade600],
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WeeklyCheckinScreen(client: sampleClient),
                  ),
                );
              },
            ),
            _buildFeatureCard(
              'Badges & Rewards',
              'Gamify achievements',
              Icons.stars,
              [Colors.amber.shade400, Colors.orange.shade600],
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BadgesRewardsScreen(client: sampleClient),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFeatureCard(
    String title,
    String description,
    IconData icon,
    List<Color> gradient,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: gradient[0].withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background icon
            Positioned(
              right: -10,
              bottom: -10,
              child: Icon(
                icon,
                size: 70,
                color: Colors.white.withOpacity(0.12),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          icon,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          description,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withOpacity(0.9),
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Tap indicator
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar(DashboardProvider dashboard) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildBottomNavItem(
              icon: Icons.dashboard,
              label: 'Dashboard',
              index: 0,
              badge: null,
            ),
            _buildBottomNavItem(
              icon: Icons.people,
              label: 'Clients',
              index: 1,
              badge: dashboard.clients.length,
            ),
            const SizedBox(width: 40), // Space for FAB
            _buildBottomNavItem(
              icon: Icons.calendar_today,
              label: 'Sessions',
              index: 2,
              badge: dashboard.todaySessions.length,
            ),
            _buildBottomNavItem(
              icon: Icons.attach_money,
              label: 'Revenue',
              index: 3,
              badge: null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavItem({
    required IconData icon,
    required String label,
    required int index,
    int? badge,
  }) {
    final isSelected = _selectedBottomNavIndex == index;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedBottomNavIndex = index;
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          badges.Badge(
            badgeContent: Text(
              '$badge',
              style: const TextStyle(color: Colors.white, fontSize: 8),
            ),
            showBadge: badge != null && badge > 0,
            position: badges.BadgePosition.topEnd(top: -8, end: -8),
            child: Icon(
              icon,
              color: isSelected ? Colors.blue : Colors.grey,
              size: 24,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.blue : Colors.grey,
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContextAwareFAB(DashboardProvider dashboard) {
    // Context-aware FAB based on current state
    IconData icon;
    String label;
    Color color;
    VoidCallback onPressed;

    if (dashboard.todaySessions.isNotEmpty) {
      icon = Icons.play_arrow;
      label = 'Start Session';
      color = Colors.green;
      onPressed = () {
        // Quick start session
        _showSessionOptions(dashboard);
      };
    } else {
      icon = Icons.add;
      label = 'Quick Add';
      color = Colors.blue;
      onPressed = () {
        _showQuickActions();
      };
    }

    return FloatingActionButton.extended(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      backgroundColor: color,
      elevation: 4,
    );
  }

  // Helper Methods

  void _showNotifications(DashboardProvider dashboard) {
    // Show notifications
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notifications coming soon!')),
    );
  }

  void _showProfileMenu() {
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
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profile'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () => Navigator.pop(context),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Sign Out', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _handleSignOut();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSignOut() async {
    try {
      // CRITICAL: Reset dashboard provider to clear all user data
      debugPrint('🔒 Signing out - clearing user data');
      context.read<DashboardProvider>().reset();

      await SupabaseService.instance.signOut();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign out failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showSessionOptions(DashboardProvider dashboard) {
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
              'Start Session',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ...dashboard.todaySessions.map((session) {
              return ListTile(
                leading: CircleAvatar(
                  child: Text(session.clientName[0]),
                ),
                title: Text(session.clientName),
                subtitle: Text(DateFormat('hh:mm a').format(session.scheduledDate)),
                trailing: const Icon(Icons.play_arrow, color: Colors.green),
                onTap: () {
                  Navigator.pop(context);
                  // Start session
                },
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  void _showQuickActions() {
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
              'Quick Actions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildQuickActionModal(
                  icon: Icons.person_add,
                  label: 'Add Client',
                  color: Colors.blue,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AddClientScreenEnhanced(trainerId: widget.trainerId)),
                    );
                  },
                ),
                _buildQuickActionModal(
                  icon: Icons.calendar_today,
                  label: 'Book Session',
                  color: Colors.green,
                  onTap: () => Navigator.pop(context),
                ),
                _buildQuickActionModal(
                  icon: Icons.receipt_long,
                  label: 'Invoice',
                  color: Colors.orange,
                  onTap: () => Navigator.pop(context),
                ),
                _buildQuickActionModal(
                  icon: Icons.card_giftcard,
                  label: 'Package',
                  color: Colors.purple,
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionModal({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
