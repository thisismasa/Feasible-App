import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:intl/intl.dart';
import '../models/user_model.dart';

/// Badges & Rewards Screen - Gamification & Achievement System
/// Features: Badge collection, milestone rewards, leaderboards, achievement animations
class BadgesRewardsScreen extends StatefulWidget {
  final UserModel client;

  const BadgesRewardsScreen({
    Key? key,
    required this.client,
  }) : super(key: key);

  @override
  State<BadgesRewardsScreen> createState() => _BadgesRewardsScreenState();
}

class _BadgesRewardsScreenState extends State<BadgesRewardsScreen>
    with TickerProviderStateMixin {
  late AnimationController _shineController;
  late AnimationController _floatController;
  
  final List<Badge> _badges = [];
  final List<Reward> _rewards = [];
  int _totalPoints = 0;
  int _currentLevel = 0;
  String _selectedCategory = 'All';
  
  @override
  void initState() {
    super.initState();
    
    _shineController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();
    
    _floatController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat(reverse: true);
    
    _loadBadgesAndRewards();
  }

  @override
  void dispose() {
    _shineController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  void _loadBadgesAndRewards() {
    // Demo data
    setState(() {
      _badges.addAll([
        // Workout Badges
        Badge('workout_1', 'First Workout', 'Complete your first workout', 
          BadgeCategory.workout, BadgeTier.bronze, true, DateTime.now().subtract(const Duration(days: 60)), 10),
        Badge('workout_10', '10 Workouts', 'Complete 10 workouts', 
          BadgeCategory.workout, BadgeTier.silver, true, DateTime.now().subtract(const Duration(days: 45)), 25),
        Badge('workout_50', 'Fitness Warrior', 'Complete 50 workouts', 
          BadgeCategory.workout, BadgeTier.gold, true, DateTime.now().subtract(const Duration(days: 20)), 100),
        Badge('workout_100', 'Gym Legend', 'Complete 100 workouts', 
          BadgeCategory.workout, BadgeTier.platinum, false, null, 250),
        
        // Streak Badges
        Badge('streak_7', 'Week Warrior', '7-day workout streak', 
          BadgeCategory.streak, BadgeTier.bronze, true, DateTime.now().subtract(const Duration(days: 30)), 20),
        Badge('streak_30', 'Monthly Master', '30-day workout streak', 
          BadgeCategory.streak, BadgeTier.gold, true, DateTime.now().subtract(const Duration(days: 5)), 150),
        Badge('streak_100', 'Unstoppable', '100-day workout streak', 
          BadgeCategory.streak, BadgeTier.diamond, false, null, 500),
        
        // Weight Loss Badges
        Badge('weight_5', 'First 5 lbs', 'Lose 5 pounds', 
          BadgeCategory.weightLoss, BadgeTier.bronze, true, DateTime.now().subtract(const Duration(days: 50)), 15),
        Badge('weight_10', '10 lbs Down', 'Lose 10 pounds', 
          BadgeCategory.weightLoss, BadgeTier.silver, true, DateTime.now().subtract(const Duration(days: 25)), 50),
        Badge('weight_20', 'Transformation', 'Lose 20 pounds', 
          BadgeCategory.weightLoss, BadgeTier.gold, false, null, 150),
        
        // Strength Badges
        Badge('bench_135', 'Bench Presser', 'Bench press 135 lbs', 
          BadgeCategory.strength, BadgeTier.silver, true, DateTime.now().subtract(const Duration(days: 40)), 30),
        Badge('bench_225', 'Strong Lifter', 'Bench press 225 lbs', 
          BadgeCategory.strength, BadgeTier.gold, false, null, 100),
        Badge('squat_315', 'Squat King', 'Squat 315 lbs', 
          BadgeCategory.strength, BadgeTier.platinum, false, null, 200),
        
        // Consistency Badges
        Badge('checkin_4', 'Consistent', 'Complete 4 weekly check-ins', 
          BadgeCategory.consistency, BadgeTier.bronze, true, DateTime.now().subtract(const Duration(days: 28)), 25),
        Badge('checkin_12', 'Dedicated', 'Complete 12 weekly check-ins', 
          BadgeCategory.consistency, BadgeTier.silver, true, DateTime.now().subtract(const Duration(days: 10)), 75),
        Badge('checkin_52', 'Year Champion', 'Complete 52 weekly check-ins', 
          BadgeCategory.consistency, BadgeTier.diamond, false, null, 400),
        
        // Special Badges
        Badge('early_bird', 'Early Bird', '10 morning workouts', 
          BadgeCategory.special, BadgeTier.gold, true, DateTime.now().subtract(const Duration(days: 15)), 50),
        Badge('night_owl', 'Night Owl', '10 evening workouts', 
          BadgeCategory.special, BadgeTier.gold, false, null, 50),
        Badge('social', 'Social Butterfly', 'Invite 5 friends', 
          BadgeCategory.special, BadgeTier.silver, false, null, 60),
      ]);
      
      _rewards.addAll([
        Reward('reward_1', 'Free Training Session', 'Earn a free 1-on-1 session', 100, false),
        Reward('reward_2', 'Protein Shake', 'Free protein shake', 50, true),
        Reward('reward_3', 'Gym Merch', 'Free gym t-shirt', 150, true),
        Reward('reward_4', 'Meal Plan', '1-week custom meal plan', 200, false),
        Reward('reward_5', 'Premium Upgrade', '1 month premium features', 300, false),
      ]);
      
      _totalPoints = _badges.where((b) => b.isUnlocked).fold(0, (sum, b) => sum + b.points);
      _currentLevel = (_totalPoints / 100).floor() + 1;
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
                _buildPlayerCard(),
                const SizedBox(height: 20),
                _buildCategoryFilter(),
                const SizedBox(height: 20),
                _buildBadgeGrid(),
                const SizedBox(height: 20),
                _buildRewardsSection(),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showLeaderboard,
        backgroundColor: Colors.amber,
        icon: const Icon(Icons.leaderboard),
        label: const Text('Leaderboard'),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: Colors.amber,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text('Badges & Rewards', style: TextStyle(fontWeight: FontWeight.bold)),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.amber.shade400, Colors.orange.shade600],
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                Hero(
                  tag: 'client-badges-${widget.client.id}',
                  child: AnimatedBuilder(
                    animation: _floatController,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, math.sin(_floatController.value * 2 * math.pi) * 10),
                        child: child,
                      );
                    },
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
                      child: const Icon(
                        Icons.emoji_events,
                        size: 40,
                        color: Colors.amber,
                      ),
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
                  'Level $_currentLevel • $_totalPoints Points',
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

  Widget _buildPlayerCard() {
    final unlockedCount = _badges.where((b) => b.isUnlocked).length;
    final totalCount = _badges.length;
    final progress = unlockedCount / totalCount;
    final pointsToNextLevel = ((_currentLevel) * 100) - _totalPoints;
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepPurple.shade600, Colors.deepPurple.shade800],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your Progress',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Level $_currentLevel',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber.shade300,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.star, color: Colors.white, size: 32),
                    const SizedBox(height: 4),
                    Text(
                      '$_totalPoints',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Points',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Level Progress
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Next Level',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '$pointsToNextLevel points to go',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: (_totalPoints % 100) / 100,
                  minHeight: 12,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.amber.shade300),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Badge Progress
          Row(
            children: [
              Expanded(
                child: _buildStatBox('Badges', '$unlockedCount/$totalCount', Icons.emoji_events),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatBox('Completion', '${(progress * 100).toInt()}%', Icons.check_circle),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    final categories = ['All', 'Workout', 'Streak', 'Weight', 'Strength', 'Special'];
    
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = _selectedCategory == category;
          
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilterChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                setState(() => _selectedCategory = category);
              },
              selectedColor: Colors.amber,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBadgeGrid() {
    final filteredBadges = _selectedCategory == 'All'
        ? _badges
        : _badges.where((b) => b.category.name.toLowerCase().contains(_selectedCategory.toLowerCase())).toList();
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.75,
        ),
        itemCount: filteredBadges.length,
        itemBuilder: (context, index) {
          final badge = filteredBadges[index];
          return _buildBadgeCard(badge);
        },
      ),
    );
  }

  Widget _buildBadgeCard(Badge badge) {
    return GestureDetector(
      onTap: () => _showBadgeDetail(badge),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: badge.isUnlocked
                ? badge.getTierColor()
                : Colors.grey.shade300,
            width: badge.isUnlocked ? 2 : 1,
          ),
          boxShadow: badge.isUnlocked
              ? [
                  BoxShadow(
                    color: badge.getTierColor().withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                if (badge.isUnlocked)
                  AnimatedBuilder(
                    animation: _shineController,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _shineController.value * 2 * math.pi,
                        child: Icon(
                          Icons.auto_awesome,
                          size: 60,
                          color: badge.getTierColor().withOpacity(0.2),
                        ),
                      );
                    },
                  ),
                Icon(
                  badge.isUnlocked ? Icons.emoji_events : Icons.lock,
                  size: 48,
                  color: badge.isUnlocked
                      ? badge.getTierColor()
                      : Colors.grey.shade400,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                badge.name,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: badge.isUnlocked ? Colors.black87 : Colors.grey,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: badge.isUnlocked
                    ? badge.getTierColor().withOpacity(0.1)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${badge.points} pts',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: badge.isUnlocked
                      ? badge.getTierColor()
                      : Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRewardsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Available Rewards',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ..._rewards.map((reward) => _buildRewardCard(reward)).toList(),
        ],
      ),
    );
  }

  Widget _buildRewardCard(Reward reward) {
    final canAfford = _totalPoints >= reward.pointsCost;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: reward.isClaimed ? Colors.grey.shade100 : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: reward.isClaimed
              ? Colors.grey.shade300
              : (canAfford ? Colors.green.shade300 : Colors.grey.shade200),
          width: canAfford && !reward.isClaimed ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: reward.isClaimed
                  ? Colors.grey.shade300
                  : (canAfford ? Colors.green.shade50 : Colors.orange.shade50),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              reward.isClaimed ? Icons.check_circle : Icons.card_giftcard,
              color: reward.isClaimed
                  ? Colors.grey.shade600
                  : (canAfford ? Colors.green : Colors.orange),
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reward.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: reward.isClaimed ? Colors.grey.shade600 : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  reward.description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.star, size: 16, color: Colors.amber.shade600),
                    const SizedBox(width: 4),
                    Text(
                      '${reward.pointsCost} points',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.shade700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (reward.isClaimed)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'CLAIMED',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            )
          else if (canAfford)
            ElevatedButton(
              onPressed: () => _claimReward(reward),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text('Claim'),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${reward.pointsCost - _totalPoints} more',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showBadgeDetail(Badge badge) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: badge.isUnlocked
                  ? [badge.getTierColor().withOpacity(0.1), Colors.white]
                  : [Colors.grey.shade100, Colors.white],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  if (badge.isUnlocked)
                    Icon(
                      Icons.auto_awesome,
                      size: 120,
                      color: badge.getTierColor().withOpacity(0.2),
                    ),
                  Icon(
                    badge.isUnlocked ? Icons.emoji_events : Icons.lock,
                    size: 80,
                    color: badge.isUnlocked
                        ? badge.getTierColor()
                        : Colors.grey.shade400,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                badge.name,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: badge.isUnlocked ? Colors.black87 : Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: badge.getTierColor().withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  badge.tier.name.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: badge.getTierColor(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                badge.description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.star, color: Colors.amber.shade600),
                  const SizedBox(width: 8),
                  Text(
                    '${badge.points} Points',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber.shade700,
                    ),
                  ),
                ],
              ),
              if (badge.isUnlocked && badge.unlockedDate != null) ...[
                const SizedBox(height: 16),
                Text(
                  'Unlocked on ${DateFormat('MMM dd, yyyy').format(badge.unlockedDate!)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: badge.isUnlocked
                        ? badge.getTierColor()
                        : Colors.grey,
                    padding: const EdgeInsets.all(16),
                  ),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _claimReward(Reward reward) {
    if (_totalPoints >= reward.pointsCost) {
      setState(() {
        reward.isClaimed = true;
        _totalPoints -= reward.pointsCost;
      });
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.celebration, color: Colors.amber.shade600),
              const SizedBox(width: 12),
              const Text('Reward Claimed!'),
            ],
          ),
          content: Text('You have successfully claimed ${reward.name}!'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Awesome!'),
            ),
          ],
        ),
      );
    }
  }

  void _showLeaderboard() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Leaderboard feature coming soon!')),
    );
  }
}

// Models
enum BadgeCategory { workout, streak, weightLoss, strength, consistency, special }

enum BadgeTier { bronze, silver, gold, platinum, diamond }

class Badge {
  final String id;
  final String name;
  final String description;
  final BadgeCategory category;
  final BadgeTier tier;
  bool isUnlocked;
  final DateTime? unlockedDate;
  final int points;

  Badge(
    this.id,
    this.name,
    this.description,
    this.category,
    this.tier,
    this.isUnlocked,
    this.unlockedDate,
    this.points,
  );

  Color getTierColor() {
    switch (tier) {
      case BadgeTier.bronze:
        return Colors.brown;
      case BadgeTier.silver:
        return Colors.grey.shade600;
      case BadgeTier.gold:
        return Colors.amber;
      case BadgeTier.platinum:
        return Colors.blue.shade700;
      case BadgeTier.diamond:
        return Colors.cyan;
    }
  }
}

class Reward {
  final String id;
  final String name;
  final String description;
  final int pointsCost;
  bool isClaimed;

  Reward(this.id, this.name, this.description, this.pointsCost, this.isClaimed);
}
