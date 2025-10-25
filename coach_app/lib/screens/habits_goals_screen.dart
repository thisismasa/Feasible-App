import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import '../models/user_model.dart';

/// Habits & Goals Tracker Screen - Behavior & Achievement Tracking
/// Features: Habit streaks, goal progress, daily check-ins, motivational insights
class HabitsGoalsScreen extends StatefulWidget {
  final UserModel client;

  const HabitsGoalsScreen({
    Key? key,
    required this.client,
  }) : super(key: key);

  @override
  State<HabitsGoalsScreen> createState() => _HabitsGoalsScreenState();
}

class _HabitsGoalsScreenState extends State<HabitsGoalsScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _streakController;
  
  final List<Habit> _habits = [];
  final List<Goal> _goals = [];
  DateTime _selectedDate = DateTime.now();
  
  @override
  void initState() {
    super.initState();
    
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();
    
    _streakController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    
    _loadData();
  }

  @override
  void dispose() {
    _mainController.dispose();
    _streakController.dispose();
    super.dispose();
  }

  void _loadData() {
    // Demo data
    setState(() {
      _habits.addAll([
        Habit(
          id: '1',
          name: 'Drink 8 glasses of water',
          icon: Icons.local_drink,
          color: Colors.blue,
          frequency: HabitFrequency.daily,
          currentStreak: 12,
          bestStreak: 45,
          completionDates: _generateCompletionDates(12),
        ),
        Habit(
          id: '2',
          name: '10,000 steps',
          icon: Icons.directions_walk,
          color: Colors.green,
          frequency: HabitFrequency.daily,
          currentStreak: 8,
          bestStreak: 30,
          completionDates: _generateCompletionDates(8),
        ),
        Habit(
          id: '3',
          name: 'Meal prep',
          icon: Icons.restaurant,
          color: Colors.orange,
          frequency: HabitFrequency.weekly,
          currentStreak: 4,
          bestStreak: 12,
          completionDates: _generateCompletionDates(4, weekly: true),
        ),
        Habit(
          id: '4',
          name: '7+ hours sleep',
          icon: Icons.bedtime,
          color: Colors.purple,
          frequency: HabitFrequency.daily,
          currentStreak: 15,
          bestStreak: 60,
          completionDates: _generateCompletionDates(15),
        ),
        Habit(
          id: '5',
          name: 'Meditation',
          icon: Icons.self_improvement,
          color: Colors.teal,
          frequency: HabitFrequency.daily,
          currentStreak: 5,
          bestStreak: 21,
          completionDates: _generateCompletionDates(5),
        ),
      ]);
      
      _goals.addAll([
        Goal(
          id: '1',
          title: 'Lose 20 lbs',
          description: 'Target weight: 175 lbs',
          targetValue: 20,
          currentValue: 13,
          unit: 'lbs',
          category: GoalCategory.weight,
          deadline: DateTime.now().add(const Duration(days: 60)),
          createdAt: DateTime.now().subtract(const Duration(days: 30)),
        ),
        Goal(
          id: '2',
          title: 'Bench Press 225 lbs',
          description: '3 reps with proper form',
          targetValue: 225,
          currentValue: 195,
          unit: 'lbs',
          category: GoalCategory.strength,
          deadline: DateTime.now().add(const Duration(days: 90)),
          createdAt: DateTime.now().subtract(const Duration(days: 45)),
        ),
        Goal(
          id: '3',
          title: 'Run 5K under 25 minutes',
          description: 'Build cardiovascular endurance',
          targetValue: 25,
          currentValue: 28,
          unit: 'min',
          category: GoalCategory.endurance,
          deadline: DateTime.now().add(const Duration(days: 45)),
          createdAt: DateTime.now().subtract(const Duration(days: 20)),
        ),
        Goal(
          id: '4',
          title: 'Body Fat to 15%',
          description: 'Maintain muscle mass',
          targetValue: 15,
          currentValue: 19,
          unit: '%',
          category: GoalCategory.bodyComposition,
          deadline: DateTime.now().add(const Duration(days: 120)),
          createdAt: DateTime.now().subtract(const Duration(days: 60)),
        ),
      ]);
    });
  }

  List<DateTime> _generateCompletionDates(int streak, {bool weekly = false}) {
    final dates = <DateTime>[];
    final now = DateTime.now();
    for (int i = 0; i < streak; i++) {
      dates.add(now.subtract(Duration(days: weekly ? i * 7 : i)));
    }
    return dates;
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
                _buildMotivationalCard(),
                const SizedBox(height: 20),
                _buildHabitsSection(),
                const SizedBox(height: 20),
                _buildGoalsSection(),
                const SizedBox(height: 20),
                _buildInsightsSection(),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: Colors.teal,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text('Habits & Goals', style: TextStyle(fontWeight: FontWeight.bold)),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.teal.shade400, Colors.teal.shade700],
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                Hero(
                  tag: 'client-habits-${widget.client.id}',
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.emoji_events,
                      size: 40,
                      color: Colors.amber.shade600,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.client.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '${_getTotalStreak()} day streak!',
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

  Widget _buildMotivationalCard() {
    final totalStreak = _getTotalStreak();
    final completedHabits = _habits.where((h) => 
      h.isCompletedForDate(_selectedDate)).length;
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.amber.shade400, Colors.orange.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              RotationTransition(
                turns: Tween<double>(begin: 0, end: 1).animate(
                  CurvedAnimation(
                    parent: _streakController,
                    curve: Curves.easeInOut,
                  ),
                ),
                child: const Icon(
                  Icons.local_fire_department,
                  size: 48,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "You're on fire!",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$completedHabits/${_habits.length} habits completed today',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStreakStat('Current', '$totalStreak', Icons.whatshot),
                Container(width: 1, height: 40, color: Colors.white.withOpacity(0.5)),
                _buildStreakStat('Longest', '${_getLongestStreak()}', Icons.emoji_events),
                Container(width: 1, height: 40, color: Colors.white.withOpacity(0.5)),
                _buildStreakStat('Goals', '${_goals.length}', Icons.flag),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
      ],
    );
  }

  Widget _buildHabitsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Daily Habits',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton.icon(
                onPressed: _addHabit,
                icon: const Icon(Icons.add),
                label: const Text('Add Habit'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._habits.asMap().entries.map((entry) {
            final index = entry.key;
            final habit = entry.value;
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: _mainController,
                curve: Interval(
                  (index * 0.1).clamp(0.0, 1.0),
                  ((index + 1) * 0.1).clamp(0.0, 1.0),
                  curve: Curves.easeOutCubic,
                ),
              )),
              child: _buildHabitCard(habit),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildHabitCard(Habit habit) {
    final isCompleted = habit.isCompletedForDate(_selectedDate);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCompleted ? habit.color : Colors.grey.shade200,
          width: isCompleted ? 2 : 1,
        ),
        boxShadow: isCompleted
            ? [
                BoxShadow(
                  color: habit.color.withOpacity(0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ]
            : [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _toggleHabit(habit),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Checkbox
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: isCompleted ? habit.color : habit.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    isCompleted ? Icons.check_circle : habit.icon,
                    color: isCompleted ? Colors.white : habit.color,
                    size: 32,
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Habit Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        habit.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.local_fire_department,
                            size: 16,
                            color: habit.currentStreak > 0 ? Colors.orange : Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${habit.currentStreak} day streak',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(width: 12),
                          if (habit.currentStreak >= habit.bestStreak && habit.currentStreak > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.amber.shade200),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.emoji_events, size: 12, color: Colors.amber.shade700),
                                  const SizedBox(width: 4),
                                  Text(
                                    'RECORD!',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.amber.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildHabitStreakBar(habit),
                    ],
                  ),
                ),
                
                // More Actions
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () => _showHabitOptions(habit),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHabitStreakBar(Habit habit) {
    return Row(
      children: List.generate(7, (index) {
        final date = DateTime.now().subtract(Duration(days: 6 - index));
        final isCompleted = habit.isCompletedForDate(date);
        final isToday = DateFormat('yyyy-MM-dd').format(date) == 
            DateFormat('yyyy-MM-dd').format(DateTime.now());
        
        return Expanded(
          child: Container(
            height: 4,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: isCompleted ? habit.color : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(2),
              border: isToday ? Border.all(color: habit.color, width: 2) : null,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildGoalsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Active Goals',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton.icon(
                onPressed: _addGoal,
                icon: const Icon(Icons.add),
                label: const Text('Add Goal'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._goals.asMap().entries.map((entry) {
            final index = entry.key;
            final goal = entry.value;
            return FadeTransition(
              opacity: Tween<double>(begin: 0, end: 1).animate(
                CurvedAnimation(
                  parent: _mainController,
                  curve: Interval(
                    (index * 0.1).clamp(0.0, 1.0),
                    ((index + 1) * 0.1).clamp(0.0, 1.0),
                  ),
                ),
              ),
              child: _buildGoalCard(goal),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildGoalCard(Goal goal) {
    final progress = (goal.currentValue / goal.targetValue * 100).clamp(0, 100);
    final daysLeft = goal.deadline.difference(DateTime.now()).inDays;
    final isExpiringSoon = daysLeft < 7;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: goal.getCategoryColor().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  goal.getCategoryIcon(),
                  color: goal.getCategoryColor(),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      goal.description,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () => _showGoalOptions(goal),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Progress Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progress',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                '${progress.toInt()}%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: goal.getCategoryColor(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress / 100,
              minHeight: 12,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(goal.getCategoryColor()),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Stats Row
          Row(
            children: [
              Expanded(
                child: _buildGoalStat(
                  'Current',
                  '${goal.currentValue.toStringAsFixed(1)} ${goal.unit}',
                  Icons.trending_up,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildGoalStat(
                  'Target',
                  '${goal.targetValue.toStringAsFixed(1)} ${goal.unit}',
                  Icons.flag,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildGoalStat(
                  'Days Left',
                  '$daysLeft',
                  Icons.calendar_today,
                  isExpiringSoon ? Colors.red : Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGoalStat(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo.shade50, Colors.blue.shade50],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.indigo.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb, color: Colors.amber.shade700, size: 24),
              const SizedBox(width: 8),
              const Text(
                'Insights & Tips',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInsightCard(
            'Consistency is Key!',
            "You've completed water intake for 12 days straight. Keep it up!",
            Icons.water_drop,
            Colors.blue,
          ),
          const SizedBox(height: 12),
          _buildInsightCard(
            'Close to Your Goal',
            "Only 7 lbs away from your weight goal! You're crushing it!",
            Icons.emoji_events,
            Colors.amber,
          ),
          const SizedBox(height: 12),
          _buildInsightCard(
            'New Record!',
            'Your sleep streak of 15 days is your best yet!',
            Icons.auto_awesome,
            Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard(String title, String description, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton.extended(
      onPressed: () {
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
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _buildQuickAction(
                        'Add Habit',
                        Icons.add_task,
                        Colors.teal,
                        _addHabit,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildQuickAction(
                        'Add Goal',
                        Icons.flag,
                        Colors.orange,
                        _addGoal,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
      backgroundColor: Colors.teal,
      icon: const Icon(Icons.add),
      label: const Text('Quick Add'),
    );
  }

  Widget _buildQuickAction(String label, IconData icon, Color color, VoidCallback onTap) {
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          onTap();
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleHabit(Habit habit) {
    setState(() {
      if (habit.isCompletedForDate(_selectedDate)) {
        habit.completionDates.removeWhere((date) =>
            DateFormat('yyyy-MM-dd').format(date) == 
            DateFormat('yyyy-MM-dd').format(_selectedDate));
        habit.currentStreak--;
      } else {
        habit.completionDates.add(_selectedDate);
        habit.currentStreak++;
        if (habit.currentStreak > habit.bestStreak) {
          habit.bestStreak = habit.currentStreak;
        }
      }
    });
  }

  void _showHabitOptions(Habit habit) {
    // Implement habit options
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Habit options coming soon!')),
    );
  }

  void _showGoalOptions(Goal goal) {
    // Implement goal options
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Goal options coming soon!')),
    );
  }

  void _addHabit() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add habit feature coming soon!')),
    );
  }

  void _addGoal() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add goal feature coming soon!')),
    );
  }

  int _getTotalStreak() {
    return _habits.fold(0, (sum, habit) => sum + habit.currentStreak);
  }

  int _getLongestStreak() {
    if (_habits.isEmpty) return 0;
    return _habits.map((h) => h.bestStreak).reduce(math.max);
  }
}

// Models
enum HabitFrequency { daily, weekly, custom }

class Habit {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final HabitFrequency frequency;
  int currentStreak;
  int bestStreak;
  List<DateTime> completionDates;

  Habit({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.frequency,
    this.currentStreak = 0,
    this.bestStreak = 0,
    List<DateTime>? completionDates,
  }) : completionDates = completionDates ?? [];

  bool isCompletedForDate(DateTime date) {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    return completionDates.any((d) => DateFormat('yyyy-MM-dd').format(d) == dateStr);
  }
}

enum GoalCategory { weight, strength, endurance, bodyComposition, custom }

class Goal {
  final String id;
  final String title;
  final String description;
  final double targetValue;
  double currentValue;
  final String unit;
  final GoalCategory category;
  final DateTime deadline;
  final DateTime createdAt;

  Goal({
    required this.id,
    required this.title,
    required this.description,
    required this.targetValue,
    required this.currentValue,
    required this.unit,
    required this.category,
    required this.deadline,
    required this.createdAt,
  });

  Color getCategoryColor() {
    switch (category) {
      case GoalCategory.weight:
        return Colors.blue;
      case GoalCategory.strength:
        return Colors.red;
      case GoalCategory.endurance:
        return Colors.green;
      case GoalCategory.bodyComposition:
        return Colors.orange;
      default:
        return Colors.purple;
    }
  }

  IconData getCategoryIcon() {
    switch (category) {
      case GoalCategory.weight:
        return Icons.monitor_weight;
      case GoalCategory.strength:
        return Icons.fitness_center;
      case GoalCategory.endurance:
        return Icons.directions_run;
      case GoalCategory.bodyComposition:
        return Icons.accessibility_new;
      default:
        return Icons.flag;
    }
  }
}

