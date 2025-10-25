import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import '../models/user_model.dart';

/// Measurement Tracking Screen - Body Measurements & Analytics
/// Features: Interactive charts, trend analysis, multi-metric comparison, goal tracking
class MeasurementTrackingScreen extends StatefulWidget {
  final UserModel client;

  const MeasurementTrackingScreen({
    Key? key,
    required this.client,
  }) : super(key: key);

  @override
  State<MeasurementTrackingScreen> createState() => _MeasurementTrackingScreenState();
}

class _MeasurementTrackingScreenState extends State<MeasurementTrackingScreen>
    with TickerProviderStateMixin {
  late AnimationController _chartController;
  late AnimationController _cardController;
  
  String _selectedMetric = 'weight';
  String _selectedPeriod = '3M'; // 1M, 3M, 6M, 1Y, ALL
  List<MeasurementEntry> _measurements = [];
  
  final Map<String, MetricInfo> _metrics = {
    'weight': MetricInfo('Weight', 'lbs', Icons.monitor_weight, Colors.blue),
    'bodyFat': MetricInfo('Body Fat', '%', Icons.show_chart, Colors.orange),
    'chest': MetricInfo('Chest', 'in', Icons.accessibility, Colors.purple),
    'waist': MetricInfo('Waist', 'in', Icons.straighten, Colors.green),
    'hips': MetricInfo('Hips', 'in', Icons.accessibility_new, Colors.pink),
    'arms': MetricInfo('Arms', 'in', Icons.fitness_center, Colors.red),
    'thighs': MetricInfo('Thighs', 'in', Icons.directions_run, Colors.teal),
  };

  @override
  void initState() {
    super.initState();
    
    _chartController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..forward();
    
    _cardController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();
    
    _loadMeasurements();
  }

  @override
  void dispose() {
    _chartController.dispose();
    _cardController.dispose();
    super.dispose();
  }

  void _loadMeasurements() {
    // Demo data - replace with real data from Supabase
    final now = DateTime.now();
    setState(() {
      _measurements = List.generate(24, (index) {
        final date = now.subtract(Duration(days: index * 7));
        return MeasurementEntry(
          id: 'measure_$index',
          clientId: widget.client.id,
          timestamp: date,
          measurements: {
            'weight': 185.0 - (index * 0.8) + (math.Random().nextDouble() * 2),
            'bodyFat': 22.0 - (index * 0.2) + (math.Random().nextDouble() * 0.5),
            'chest': 42.0 - (index * 0.1) + (math.Random().nextDouble() * 0.3),
            'waist': 36.0 - (index * 0.15) + (math.Random().nextDouble() * 0.2),
            'hips': 40.0 - (index * 0.08) + (math.Random().nextDouble() * 0.2),
            'arms': 15.5 - (index * 0.05) + (math.Random().nextDouble() * 0.1),
            'thighs': 24.0 - (index * 0.06) + (math.Random().nextDouble() * 0.15),
          },
          notes: index % 3 == 0 ? 'Regular check-in' : '',
        );
      }).reversed.toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildMetricSelector(),
                const SizedBox(height: 16),
                _buildPeriodSelector(),
                const SizedBox(height: 20),
                _buildMainChart(),
                const SizedBox(height: 20),
                _buildStatistics(),
                const SizedBox(height: 20),
                _buildAllMetricsCards(),
                const SizedBox(height: 20),
                _buildTrendAnalysis(),
                const SizedBox(height: 20),
                _buildGoalsSection(),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addMeasurement(),
        backgroundColor: Colors.green,
        icon: const Icon(Icons.add),
        label: const Text('Add Entry'),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 160,
      pinned: true,
      backgroundColor: Colors.green,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text('Measurements', style: TextStyle(fontWeight: FontWeight.bold)),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.green.shade400, Colors.green.shade700],
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                Hero(
                  tag: 'client-measurements-${widget.client.id}',
                  child: CircleAvatar(
                    radius: 35,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.straighten,
                      size: 35,
                      color: Colors.green.shade600,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.client.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricSelector() {
    return Container(
      height: 120,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _metrics.length,
        itemBuilder: (context, index) {
          final entry = _metrics.entries.elementAt(index);
          final key = entry.key;
          final metric = entry.value;
          final isSelected = _selectedMetric == key;
          
          return GestureDetector(
            onTap: () {
              setState(() => _selectedMetric = key);
              _chartController.reset();
              _chartController.forward();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 90,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        colors: [metric.color, metric.color.withOpacity(0.7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isSelected ? null : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? metric.color : Colors.grey.shade300,
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: metric.color.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    metric.icon,
                    size: 32,
                    color: isSelected ? Colors.white : metric.color,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    metric.name,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getCurrentValue(key),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : metric.color,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPeriodSelector() {
    final periods = ['1M', '3M', '6M', '1Y', 'ALL'];
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: periods.map((period) {
          final isSelected = _selectedPeriod == period;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedPeriod = period);
                _chartController.reset();
                _chartController.forward();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.green : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  period,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? Colors.white : Colors.grey.shade600,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMainChart() {
    final metric = _metrics[_selectedMetric]!;
    final data = _getFilteredData();
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(metric.icon, color: metric.color, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    '${metric.name} Trend',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              _buildTrendIndicator(),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 250,
            child: FadeTransition(
              opacity: _chartController,
              child: LineChart(
                _buildLineChartData(data, metric),
              ),
            ),
          ),
        ],
      ),
    );
  }

  LineChartData _buildLineChartData(List<MeasurementEntry> data, MetricInfo metric) {
    final spots = data
        .asMap()
        .entries
        .map((e) => FlSpot(
              e.key.toDouble(),
              e.value.measurements[_selectedMetric] ?? 0,
            ))
        .toList();

    final maxY = spots.map((s) => s.y).reduce(math.max);
    final minY = spots.map((s) => s.y).reduce(math.min);
    final padding = (maxY - minY) * 0.1;

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: (maxY - minY) / 5,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: Colors.grey.shade200,
            strokeWidth: 1,
          );
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: (data.length / 4).ceilToDouble(),
            getTitlesWidget: (value, meta) {
              if (value.toInt() >= 0 && value.toInt() < data.length) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    DateFormat('MMM dd').format(data[value.toInt()].timestamp),
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 10,
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
            reservedSize: 40,
            interval: (maxY - minY) / 5,
            getTitlesWidget: (value, meta) {
              return Text(
                value.toStringAsFixed(1),
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
      maxX: (data.length - 1).toDouble(),
      minY: minY - padding,
      maxY: maxY + padding,
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: metric.color,
          barWidth: 4,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: 5,
                color: Colors.white,
                strokeWidth: 3,
                strokeColor: metric.color,
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                metric.color.withOpacity(0.3),
                metric.color.withOpacity(0.0),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
      lineTouchData: LineTouchData(
        enabled: true,
        touchTooltipData: LineTouchTooltipData(
          tooltipBgColor: metric.color.withOpacity(0.9),
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((spot) {
              final date = data[spot.x.toInt()].timestamp;
              return LineTooltipItem(
                '${DateFormat('MMM dd').format(date)}\n${spot.y.toStringAsFixed(1)} ${metric.unit}',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              );
            }).toList();
          },
        ),
      ),
    );
  }

  Widget _buildTrendIndicator() {
    final data = _getFilteredData();
    if (data.length < 2) return const SizedBox();
    
    final first = data.first.measurements[_selectedMetric] ?? 0;
    final last = data.last.measurements[_selectedMetric] ?? 0;
    final change = last - first;
    final percentChange = (change / first * 100).abs();
    final isPositive = change < 0; // Negative is good for most metrics
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: (isPositive ? Colors.green : Colors.red).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive ? Icons.trending_down : Icons.trending_up,
            color: isPositive ? Colors.green : Colors.red,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            '${percentChange.toStringAsFixed(1)}%',
            style: TextStyle(
              color: isPositive ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatistics() {
    final data = _getFilteredData();
    if (data.isEmpty) return const SizedBox();
    
    final values = data.map((e) => e.measurements[_selectedMetric] ?? 0).toList();
    final current = values.last;
    final avg = values.reduce((a, b) => a + b) / values.length;
    final max = values.reduce(math.max);
    final min = values.reduce(math.min);
    final metric = _metrics[_selectedMetric]!;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [metric.color.withOpacity(0.1), Colors.white],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: metric.color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Statistics Overview',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard('Current', current, metric.unit, metric.color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard('Average', avg, metric.unit, Colors.blue),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard('Highest', max, metric.unit, Colors.red),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard('Lowest', min, metric.unit, Colors.green),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, double value, String unit, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
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
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  unit,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAllMetricsCards() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'All Measurements',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.5,
            ),
            itemCount: _metrics.length,
            itemBuilder: (context, index) {
              final entry = _metrics.entries.elementAt(index);
              return _buildMetricCard(entry.key, entry.value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String key, MetricInfo metric) {
    final value = _measurements.isNotEmpty
        ? _measurements.last.measurements[key] ?? 0
        : 0;
    final previousValue = _measurements.length > 1
        ? _measurements[_measurements.length - 2].measurements[key] ?? 0
        : value;
    final change = value - previousValue;
    
    return GestureDetector(
      onTap: () {
        setState(() => _selectedMetric = key);
        _chartController.reset();
        _chartController.forward();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _selectedMetric == key
                ? metric.color
                : Colors.grey.shade200,
            width: _selectedMetric == key ? 2 : 1,
          ),
          boxShadow: _selectedMetric == key
              ? [
                  BoxShadow(
                    color: metric.color.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(metric.icon, color: metric.color, size: 24),
                if (change != 0)
                  Icon(
                    change < 0 ? Icons.arrow_downward : Icons.arrow_upward,
                    color: change < 0 ? Colors.green : Colors.red,
                    size: 16,
                  ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  metric.name,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      value.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: metric.color,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      metric.unit,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendAnalysis() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics, color: Colors.blue, size: 24),
              const SizedBox(width: 8),
              const Text(
                'Trend Analysis',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTrendItem(
            'Weight Loss Progress',
            'On track - losing 0.8 lbs/week',
            Icons.check_circle,
            Colors.green,
            85,
          ),
          const Divider(height: 24),
          _buildTrendItem(
            'Body Fat Reduction',
            'Excellent progress - down 2.5%',
            Icons.trending_down,
            Colors.green,
            92,
          ),
          const Divider(height: 24),
          _buildTrendItem(
            'Muscle Gain',
            'Building lean mass steadily',
            Icons.fitness_center,
            Colors.blue,
            78,
          ),
        ],
      ),
    );
  }

  Widget _buildTrendItem(
    String title,
    String description,
    IconData icon,
    Color color,
    double progress,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              '${progress.toInt()}%',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          description,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress / 100,
          backgroundColor: Colors.grey.shade200,
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 6,
          borderRadius: BorderRadius.circular(3),
        ),
      ],
    );
  }

  Widget _buildGoalsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.amber.shade50, Colors.orange.shade50],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.flag, color: Colors.orange, size: 24),
                  const SizedBox(width: 8),
                  const Text(
                    'Goals',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: () => _setGoal(),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Set Goal'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildGoalItem('Target Weight', '175 lbs', '10 lbs to go', 65),
          const SizedBox(height: 12),
          _buildGoalItem('Target Body Fat', '18%', '4% to go', 72),
          const SizedBox(height: 12),
          _buildGoalItem('Waist Size', '32 inches', '4 inches to go', 58),
        ],
      ),
    );
  }

  Widget _buildGoalItem(String title, String target, String remaining, double progress) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                target,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress / 100,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 8),
          Text(
            remaining,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  void _addMeasurement() {
    // Implement add measurement dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add measurement feature coming soon!')),
    );
  }

  void _setGoal() {
    // Implement set goal dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Set goal feature coming soon!')),
    );
  }

  String _getCurrentValue(String metricKey) {
    if (_measurements.isEmpty) return '--';
    final metric = _metrics[metricKey]!;
    final value = _measurements.last.measurements[metricKey] ?? 0;
    return '${value.toStringAsFixed(1)} ${metric.unit}';
  }

  List<MeasurementEntry> _getFilteredData() {
    final now = DateTime.now();
    int daysToShow;
    
    switch (_selectedPeriod) {
      case '1M':
        daysToShow = 30;
        break;
      case '3M':
        daysToShow = 90;
        break;
      case '6M':
        daysToShow = 180;
        break;
      case '1Y':
        daysToShow = 365;
        break;
      default:
        return _measurements;
    }
    
    return _measurements
        .where((m) => now.difference(m.timestamp).inDays <= daysToShow)
        .toList();
  }
}

// Models
class MeasurementEntry {
  final String id;
  final String clientId;
  final DateTime timestamp;
  final Map<String, double> measurements;
  final String notes;

  MeasurementEntry({
    required this.id,
    required this.clientId,
    required this.timestamp,
    required this.measurements,
    this.notes = '',
  });
}

class MetricInfo {
  final String name;
  final String unit;
  final IconData icon;
  final Color color;

  MetricInfo(this.name, this.unit, this.icon, this.color);
}

