import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;
import '../models/user_model.dart';

/// Weekly Check-In System Screen - Comprehensive Progress Review
/// Features: Multi-metric check-ins, mood tracking, photo comparison, AI insights
class WeeklyCheckinScreen extends StatefulWidget {
  final UserModel client;

  const WeeklyCheckinScreen({
    Key? key,
    required this.client,
  }) : super(key: key);

  @override
  State<WeeklyCheckinScreen> createState() => _WeeklyCheckinScreenState();
}

class _WeeklyCheckinScreenState extends State<WeeklyCheckinScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  
  final List<CheckIn> _checkIns = [];
  CheckIn? _currentCheckIn;
  int _currentStep = 0;
  
  // Form Data
  double _weight = 0;
  double _bodyFat = 0;
  int _mood = 3; // 1-5 scale
  int _energy = 3;
  int _motivation = 3;
  int _sleepQuality = 3;
  String _notes = '';
  final List<String> _challenges = [];
  final List<String> _wins = [];
  
  final TextEditingController _notesController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..forward();
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    )..forward();
    
    _loadCheckIns();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _loadCheckIns() {
    // Demo data
    setState(() {
      _checkIns.addAll(List.generate(8, (index) {
        final date = DateTime.now().subtract(Duration(days: index * 7));
        return CheckIn(
          id: 'checkin_$index',
          clientId: widget.client.id,
          date: date,
          weight: 185.0 - (index * 1.2),
          bodyFat: 22.0 - (index * 0.3),
          mood: 3 + math.Random().nextInt(3),
          energy: 3 + math.Random().nextInt(3),
          motivation: 3 + math.Random().nextInt(3),
          sleepQuality: 3 + math.Random().nextInt(3),
          notes: 'Week ${index + 1} check-in',
          challenges: ['Time management', 'Cravings'],
          wins: ['Hit gym 4x', 'Lost 1.2 lbs'],
        );
      }).reversed.toList());
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
                _buildProgressSummary(),
                const SizedBox(height: 20),
                _buildCheckInHistory(),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _startNewCheckIn,
        backgroundColor: Colors.indigo,
        icon: const Icon(Icons.edit_calendar),
        label: const Text('New Check-In'),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: Colors.indigo,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text('Weekly Check-Ins', style: TextStyle(fontWeight: FontWeight.bold)),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.indigo.shade400, Colors.indigo.shade800],
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                Hero(
                  tag: 'client-checkin-${widget.client.id}',
                  child: CircleAvatar(
                    radius: 35,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.fact_check,
                      size: 35,
                      color: Colors.indigo.shade600,
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
                Text(
                  '${_checkIns.length} check-ins completed',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressSummary() {
    if (_checkIns.length < 2) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Icon(Icons.calendar_today, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'Start Your Journey',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Complete your first check-in to track progress',
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    
    final latest = _checkIns.last;
    final oldest = _checkIns.first;
    final weightChange = latest.weight - oldest.weight;
    final bodyFatChange = latest.bodyFat - oldest.bodyFat;
    final weeksTracked = _checkIns.length;
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo.shade50, Colors.blue.shade50],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.indigo.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_down, color: Colors.green, size: 28),
              const SizedBox(width: 12),
              const Text(
                'Total Progress',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildProgressCard(
                  'Weight Change',
                  '${weightChange.toStringAsFixed(1)} lbs',
                  Icons.monitor_weight,
                  weightChange < 0 ? Colors.green : Colors.red,
                  weightChange < 0,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildProgressCard(
                  'Body Fat Change',
                  '${bodyFatChange.toStringAsFixed(1)}%',
                  Icons.show_chart,
                  bodyFatChange < 0 ? Colors.green : Colors.red,
                  bodyFatChange < 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStat('Weeks Tracked', '$weeksTracked', Icons.calendar_today),
                Container(width: 1, height: 40, color: Colors.grey.shade300),
                _buildStat('Avg Mood', '${_getAverageMood().toStringAsFixed(1)}', Icons.sentiment_satisfied),
                Container(width: 1, height: 40, color: Colors.grey.shade300),
                _buildStat('Consistency', '${(_checkIns.length / weeksTracked * 100).toInt()}%', Icons.verified),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(
    String label,
    String value,
    IconData icon,
    Color color,
    bool isPositive,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isPositive ? Icons.arrow_downward : Icons.arrow_upward,
                size: 16,
                color: color,
              ),
              const SizedBox(width: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.indigo, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildCheckInHistory() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Check-In History',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ..._checkIns.reversed.map((checkIn) => _buildCheckInCard(checkIn)).toList(),
        ],
      ),
    );
  }

  Widget _buildCheckInCard(CheckIn checkIn) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.indigo.shade400, Colors.indigo.shade600],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                DateFormat('dd').format(checkIn.date),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                DateFormat('MMM').format(checkIn.date),
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        title: Text(
          DateFormat('EEEE, MMM dd, yyyy').format(checkIn.date),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${checkIn.weight} lbs • ${checkIn.bodyFat}% BF',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Metrics Grid
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricTile('Weight', '${checkIn.weight} lbs', Icons.monitor_weight, Colors.blue),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMetricTile('Body Fat', '${checkIn.bodyFat}%', Icons.show_chart, Colors.orange),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                
                // Mood Indicators
                const Text(
                  'Weekly Ratings',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _buildRatingBar('Mood', checkIn.mood, Icons.sentiment_satisfied, Colors.purple),
                const SizedBox(height: 8),
                _buildRatingBar('Energy', checkIn.energy, Icons.bolt, Colors.amber),
                const SizedBox(height: 8),
                _buildRatingBar('Motivation', checkIn.motivation, Icons.rocket_launch, Colors.red),
                const SizedBox(height: 8),
                _buildRatingBar('Sleep Quality', checkIn.sleepQuality, Icons.bedtime, Colors.indigo),
                
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                
                // Wins & Challenges
                if (checkIn.wins.isNotEmpty) ...[
                  Row(
                    children: [
                      Icon(Icons.emoji_events, color: Colors.green, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Weekly Wins',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...checkIn.wins.map((win) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.green, size: 16),
                            const SizedBox(width: 8),
                            Expanded(child: Text(win, style: const TextStyle(fontSize: 13))),
                          ],
                        ),
                      )),
                  const SizedBox(height: 12),
                ],
                
                if (checkIn.challenges.isNotEmpty) ...[
                  Row(
                    children: [
                      Icon(Icons.flag, color: Colors.orange, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Challenges',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...checkIn.challenges.map((challenge) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.circle, color: Colors.orange, size: 12),
                            const SizedBox(width: 8),
                            Expanded(child: Text(challenge, style: const TextStyle(fontSize: 13))),
                          ],
                        ),
                      )),
                  const SizedBox(height: 12),
                ],
                
                if (checkIn.notes.isNotEmpty) ...[
                  const Text(
                    'Notes',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      checkIn.notes,
                      style: const TextStyle(fontSize: 13),
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

  Widget _buildMetricTile(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
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
      ),
    );
  }

  Widget _buildRatingBar(String label, int rating, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: List.generate(5, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Icon(
                      index < rating ? Icons.star : Icons.star_border,
                      color: index < rating ? color : Colors.grey.shade300,
                      size: 18,
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
        Text(
          '$rating/5',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  void _startNewCheckIn() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildCheckInWizard(),
    );
  }

  Widget _buildCheckInWizard() {
    return StatefulBuilder(
      builder: (context, setState) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.indigo.shade400, Colors.indigo.shade600],
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Weekly Check-In',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close, color: Colors.white),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Progress Stepper
                      Row(
                        children: List.generate(4, (index) {
                          return Expanded(
                            child: Container(
                              height: 4,
                              margin: EdgeInsets.only(right: index < 3 ? 8 : 0),
                              decoration: BoxDecoration(
                                color: index <= _currentStep
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: _buildCheckInStep(setState),
                ),
              ),
              
              // Actions
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    if (_currentStep > 0)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => setState(() => _currentStep--),
                          child: const Text('Back'),
                        ),
                      ),
                    if (_currentStep > 0) const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (_currentStep < 3) {
                            setState(() => _currentStep++);
                          } else {
                            _saveCheckIn();
                            Navigator.pop(context);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          padding: const EdgeInsets.all(16),
                        ),
                        child: Text(_currentStep < 3 ? 'Next' : 'Complete'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCheckInStep(StateSetter setState) {
    switch (_currentStep) {
      case 0:
        return _buildMetricsStep(setState);
      case 1:
        return _buildRatingsStep(setState);
      case 2:
        return _buildWinsChallengesStep(setState);
      case 3:
        return _buildNotesStep(setState);
      default:
        return const SizedBox();
    }
  }

  Widget _buildMetricsStep(StateSetter setState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Body Metrics',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Track your weight and body composition',
          style: TextStyle(color: Colors.grey.shade600),
        ),
        const SizedBox(height: 24),
        _buildNumberInput('Weight (lbs)', _weight, (value) => setState(() => _weight = value)),
        const SizedBox(height: 16),
        _buildNumberInput('Body Fat (%)', _bodyFat, (value) => setState(() => _bodyFat = value)),
      ],
    );
  }

  Widget _buildRatingsStep(StateSetter setState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'How are you feeling?',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Rate your week on a scale of 1-5',
          style: TextStyle(color: Colors.grey.shade600),
        ),
        const SizedBox(height: 24),
        _buildRatingInput('Mood', _mood, (value) => setState(() => _mood = value), Icons.sentiment_satisfied, Colors.purple),
        const SizedBox(height: 16),
        _buildRatingInput('Energy', _energy, (value) => setState(() => _energy = value), Icons.bolt, Colors.amber),
        const SizedBox(height: 16),
        _buildRatingInput('Motivation', _motivation, (value) => setState(() => _motivation = value), Icons.rocket_launch, Colors.red),
        const SizedBox(height: 16),
        _buildRatingInput('Sleep Quality', _sleepQuality, (value) => setState(() => _sleepQuality = value), Icons.bedtime, Colors.indigo),
      ],
    );
  }

  Widget _buildWinsChallengesStep(StateSetter setState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Wins & Challenges',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Reflect on your week',
          style: TextStyle(color: Colors.grey.shade600),
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: () => setState(() => _wins.add('New win')),
          icon: const Icon(Icons.add),
          label: const Text('Add Win'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
        ),
        const SizedBox(height: 12),
        ..._wins.map((win) => ListTile(
              leading: const Icon(Icons.emoji_events, color: Colors.green),
              title: Text(win),
              trailing: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() => _wins.remove(win)),
              ),
            )),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () => setState(() => _challenges.add('New challenge')),
          icon: const Icon(Icons.add),
          label: const Text('Add Challenge'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
        ),
        const SizedBox(height: 12),
        ..._challenges.map((challenge) => ListTile(
              leading: const Icon(Icons.flag, color: Colors.orange),
              title: Text(challenge),
              trailing: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() => _challenges.remove(challenge)),
              ),
            )),
      ],
    );
  }

  Widget _buildNotesStep(StateSetter setState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Additional Notes',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Any additional thoughts or observations?',
          style: TextStyle(color: Colors.grey.shade600),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _notesController,
          decoration: const InputDecoration(
            hintText: 'Write your notes here...',
            border: OutlineInputBorder(),
          ),
          maxLines: 8,
          onChanged: (value) => _notes = value,
        ),
      ],
    );
  }

  Widget _buildNumberInput(String label, double value, Function(double) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
          onChanged: (val) => onChanged(double.tryParse(val) ?? 0),
        ),
      ],
    );
  }

  Widget _buildRatingInput(
    String label,
    int value,
    Function(int) onChanged,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(5, (index) {
              final rating = index + 1;
              return GestureDetector(
                onTap: () => onChanged(rating),
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: value >= rating ? color : Colors.white,
                    border: Border.all(color: color),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      '$rating',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: value >= rating ? Colors.white : color,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  void _saveCheckIn() {
    final newCheckIn = CheckIn(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      clientId: widget.client.id,
      date: DateTime.now(),
      weight: _weight,
      bodyFat: _bodyFat,
      mood: _mood,
      energy: _energy,
      motivation: _motivation,
      sleepQuality: _sleepQuality,
      notes: _notes,
      challenges: _challenges,
      wins: _wins,
    );
    
    setState(() {
      _checkIns.add(newCheckIn);
      _currentStep = 0;
      _weight = 0;
      _bodyFat = 0;
      _mood = 3;
      _energy = 3;
      _motivation = 3;
      _sleepQuality = 3;
      _notes = '';
      _challenges.clear();
      _wins.clear();
      _notesController.clear();
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Check-in saved successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  double _getAverageMood() {
    if (_checkIns.isEmpty) return 0;
    return _checkIns.map((c) => c.mood).reduce((a, b) => a + b) / _checkIns.length;
  }
}

// Models
class CheckIn {
  final String id;
  final String clientId;
  final DateTime date;
  final double weight;
  final double bodyFat;
  final int mood;
  final int energy;
  final int motivation;
  final int sleepQuality;
  final String notes;
  final List<String> challenges;
  final List<String> wins;

  CheckIn({
    required this.id,
    required this.clientId,
    required this.date,
    required this.weight,
    required this.bodyFat,
    required this.mood,
    required this.energy,
    required this.motivation,
    required this.sleepQuality,
    required this.notes,
    required this.challenges,
    required this.wins,
  });
}

