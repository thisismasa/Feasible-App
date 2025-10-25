import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/user_model.dart';
import '../models/comprehensive_training_models.dart';
import '../services/program_generator_service.dart';

/// Advanced Program Builder - Multi-Sport with Periodization
/// Supports: Powerlifting, Strongman, Running, Hyrox, Hybrid Training
class AdvancedProgramBuilderScreen extends StatefulWidget {
  final UserModel client;

  const AdvancedProgramBuilderScreen({
    Key? key,
    required this.client,
  }) : super(key: key);

  @override
  State<AdvancedProgramBuilderScreen> createState() => _AdvancedProgramBuilderScreenState();
}

class _AdvancedProgramBuilderScreenState extends State<AdvancedProgramBuilderScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animController;
  
  int _currentStep = 0;
  ProgramType _selectedProgramType = ProgramType.generalStrength;
  PeriodizationType _selectedPeriodization = PeriodizationType.linear;
  
  // Program parameters
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 84)); // 12 weeks
  DateTime? _competitionDate;
  String _experienceLevel = ExperienceLevel.intermediate;
  
  // Sport-specific data
  final Map<String, dynamic> _athleteData = {};
  ComprehensiveProgram? _generatedProgram;
  bool _isGenerating = false;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _animController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: _buildAppBar(),
      body: _buildBody(),
      floatingActionButton: _buildFAB(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Advanced Program Builder', style: TextStyle(fontWeight: FontWeight.bold)),
      backgroundColor: Colors.deepPurple,
      elevation: 0,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(50),
        child: Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: Colors.deepPurple,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.deepPurple,
            indicatorWeight: 3,
            tabs: const [
              Tab(icon: Icon(Icons.sports), text: 'Sport'),
              Tab(icon: Icon(Icons.timeline), text: 'Periodization'),
              Tab(icon: Icon(Icons.person), text: 'Athlete'),
              Tab(icon: Icon(Icons.calendar_month), text: 'Schedule'),
              Tab(icon: Icon(Icons.preview), text: 'Preview'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildSportSelection(),
        _buildPeriodizationSetup(),
        _buildAthleteProfile(),
        _buildScheduleSetup(),
        _buildProgramPreview(),
      ],
    );
  }

  Widget _buildSportSelection() {
    final sports = [
      {
        'type': ProgramType.powerlifting,
        'name': 'Powerlifting',
        'icon': Icons.fitness_center,
        'color': Colors.red,
        'desc': 'Squat, Bench, Deadlift focus',
      },
      {
        'type': ProgramType.strongman,
        'name': 'Strongman',
        'icon': Icons.sports_gymnastics,
        'color': Colors.orange,
        'desc': 'Events, carries, overhead work',
      },
      {
        'type': ProgramType.running,
        'name': 'Running',
        'icon': Icons.directions_run,
        'color': Colors.blue,
        'desc': '5K to Marathon training',
      },
      {
        'type': ProgramType.trailRunning,
        'name': 'Trail Running',
        'icon': Icons.terrain,
        'color': Colors.green,
        'desc': 'Mountain and ultra training',
      },
      {
        'type': ProgramType.hyrox,
        'name': 'Hyrox',
        'icon': Icons.track_changes,
        'color': Colors.purple,
        'desc': 'Functional fitness racing',
      },
      {
        'type': ProgramType.hybrid,
        'name': 'Hybrid Athlete',
        'icon': Icons.all_inclusive,
        'color': Colors.teal,
        'desc': 'Strength + endurance',
      },
      {
        'type': ProgramType.bodybuilding,
        'name': 'Bodybuilding',
        'icon': Icons.accessibility_new,
        'color': Colors.indigo,
        'desc': 'Hypertrophy and aesthetics',
      },
      {
        'type': ProgramType.generalStrength,
        'name': 'General Strength',
        'icon': Icons.school,
        'color': Colors.blueGrey,
        'desc': 'All-around fitness',
      },
    ];
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Training Focus',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose the primary sport or training goal',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.1,
            ),
            itemCount: sports.length,
            itemBuilder: (context, index) {
              final sport = sports[index];
              final isSelected = _selectedProgramType == sport['type'];
              
              return GestureDetector(
                onTap: () => setState(() => _selectedProgramType = sport['type'] as ProgramType),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? LinearGradient(
                            colors: [
                              (sport['color'] as Color),
                              (sport['color'] as Color).withOpacity(0.7),
                            ],
                          )
                        : null,
                    color: isSelected ? null : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? (sport['color'] as Color) : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: (sport['color'] as Color).withOpacity(0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ]
                        : [],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        sport['icon'] as IconData,
                        size: 48,
                        color: isSelected ? Colors.white : (sport['color'] as Color),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        sport['name'] as String,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        sport['desc'] as String,
                        style: TextStyle(
                          fontSize: 11,
                          color: isSelected ? Colors.white.withOpacity(0.9) : Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodizationSetup() {
    final models = [
      {
        'type': PeriodizationType.linear,
        'name': 'Linear',
        'desc': 'Progressive overload\nBeginner friendly',
        'icon': Icons.trending_up,
        'color': Colors.blue,
      },
      {
        'type': PeriodizationType.block,
        'name': 'Block',
        'desc': 'Focused adaptations\nCompetition prep',
        'icon': Icons.view_module,
        'color': Colors.orange,
      },
      {
        'type': PeriodizationType.undulating,
        'name': 'Undulating (DUP)',
        'desc': 'Daily variation\nAdvanced lifters',
        'icon': Icons.waves,
        'color': Colors.purple,
      },
      {
        'type': PeriodizationType.conjugate,
        'name': 'Conjugate',
        'desc': 'Westside method\nElite powerlifters',
        'icon': Icons.psychology,
        'color': Colors.red,
      },
      {
        'type': PeriodizationType.concurrent,
        'name': 'Concurrent',
        'desc': 'Multiple qualities\nStrongman/Hybrid',
        'icon': Icons.all_inclusive,
        'color': Colors.teal,
      },
      {
        'type': PeriodizationType.polarized,
        'name': 'Polarized',
        'desc': '80/20 rule\nEndurance sports',
        'icon': Icons.show_chart,
        'color': Colors.green,
      },
    ];
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Periodization Model',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'How should training progress over time?',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),
          ...models.map((model) {
            final isSelected = _selectedPeriodization == model['type'];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => setState(() => _selectedPeriodization = model['type'] as PeriodizationType),
                  borderRadius: BorderRadius.circular(16),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isSelected ? (model['color'] as Color).withOpacity(0.1) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? (model['color'] as Color) : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: (model['color'] as Color).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            model['icon'] as IconData,
                            color: model['color'] as Color,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                model['name'] as String,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                model['desc'] as String,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Icon(Icons.check_circle, color: model['color'] as Color, size: 32),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildAthleteProfile() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Athlete Profile',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          
          // Experience Level
          _buildCard(
            'Experience Level',
            Icons.school,
            Colors.blue,
            _buildExperienceSelector(),
          ),
          
          const SizedBox(height: 16),
          
          // Sport-specific inputs
          if (_selectedProgramType == ProgramType.powerlifting)
            _buildPowerliftingInputs(),
          
          if (_selectedProgramType == ProgramType.strongman)
            _buildStrongmanInputs(),
          
          if (_selectedProgramType == ProgramType.running || 
              _selectedProgramType == ProgramType.trailRunning)
            _buildRunningInputs(),
          
          if (_selectedProgramType == ProgramType.hyrox)
            _buildHyroxInputs(),
        ],
      ),
    );
  }

  Widget _buildScheduleSetup() {
    final totalWeeks = _endDate.difference(_startDate).inDays ~/ 7;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Program Schedule',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          
          _buildCard(
            'Program Duration',
            Icons.calendar_today,
            Colors.green,
            Column(
              children: [
                ListTile(
                  title: const Text('Start Date'),
                  subtitle: Text(DateFormat('MMM dd, yyyy').format(_startDate)),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _startDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) setState(() => _startDate = date);
                    },
                  ),
                ),
                ListTile(
                  title: const Text('End Date'),
                  subtitle: Text(DateFormat('MMM dd, yyyy').format(_endDate)),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _endDate,
                        firstDate: _startDate.add(const Duration(days: 7)),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) setState(() => _endDate = date);
                    },
                  ),
                ),
                const Divider(),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStat('Total Weeks', '$totalWeeks', Icons.calendar_month),
                      _buildStat('Training Days', '${totalWeeks * 4}', Icons.fitness_center),
                      _buildStat('Phases', '${_getPhaseCount()}', Icons.timeline),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          _buildCard(
            'Competition Date (Optional)',
            Icons.emoji_events,
            Colors.amber,
            Column(
              children: [
                if (_competitionDate == null)
                  ElevatedButton.icon(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _endDate,
                        firstDate: _startDate,
                        lastDate: _endDate.add(const Duration(days: 90)),
                      );
                      if (date != null) setState(() => _competitionDate = date);
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Set Competition Date'),
                  )
                else
                  ListTile(
                    leading: const Icon(Icons.emoji_events, color: Colors.amber),
                    title: Text(DateFormat('MMM dd, yyyy').format(_competitionDate!)),
                    subtitle: Text('${_competitionDate!.difference(DateTime.now()).inDays} days away'),
                    trailing: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _competitionDate = null),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgramPreview() {
    if (_generatedProgram == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.preview, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text(
              'Generate Program First',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Complete previous steps and click Generate',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }
    
    final program = _generatedProgram!;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.deepPurple.shade400, Colors.deepPurple.shade600],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Program Generated!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  program.name,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildProgramStat('Workouts', '${program.analytics.totalWorkouts}', Icons.fitness_center),
                    ),
                    Expanded(
                      child: _buildProgramStat('Weeks', '${program.macrocycle.totalWeeks}', Icons.calendar_today),
                    ),
                    Expanded(
                      child: _buildProgramStat('Phases', '${program.macrocycle.phases.length}', Icons.timeline),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          const Text(
            'Macrocycle Structure',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          
          ...program.macrocycle.phases.map((phase) => _buildPhaseCard(phase)).toList(),
          
          const SizedBox(height: 24),
          
          const Text(
            'Training Blocks',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          
          ...program.mesocycles.take(3).map((meso) => _buildMesocycleCard(meso)).toList(),
          
          if (program.mesocycles.length > 3)
            Center(
              child: TextButton(
                onPressed: () {
                  // Show all mesocycles
                },
                child: Text('View all ${program.mesocycles.length} blocks'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCard(String title, IconData icon, Color color, Widget child) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildExperienceSelector() {
    return Wrap(
      spacing: 12,
      children: [
        ExperienceLevel.beginner,
        ExperienceLevel.intermediate,
        ExperienceLevel.advanced,
        ExperienceLevel.elite,
      ].map((level) {
        final isSelected = _experienceLevel == level;
        return FilterChip(
          label: Text(level.toUpperCase()),
          selected: isSelected,
          onSelected: (selected) => setState(() => _experienceLevel = level),
          selectedColor: Colors.blue.shade100,
        );
      }).toList(),
    );
  }

  Widget _buildPowerliftingInputs() {
    return _buildCard(
      'Powerlifting Data',
      Icons.fitness_center,
      Colors.red,
      Column(
        children: [
          _buildMaxInput('Squat Max', 'squat_max'),
          const SizedBox(height: 12),
          _buildMaxInput('Bench Max', 'bench_max'),
          const SizedBox(height: 12),
          _buildMaxInput('Deadlift Max', 'deadlift_max'),
        ],
      ),
    );
  }

  Widget _buildStrongmanInputs() {
    return _buildCard(
      'Strongman Events',
      Icons.sports_gymnastics,
      Colors.orange,
      const Text('Select competition events and PRs'),
    );
  }

  Widget _buildRunningInputs() {
    return _buildCard(
      'Running Goals',
      Icons.directions_run,
      Colors.blue,
      Column(
        children: [
          DropdownButtonFormField<String>(
            value: _athleteData['goal_race'] ?? '10K',
            decoration: const InputDecoration(labelText: 'Goal Race'),
            items: ['5K', '10K', 'Half Marathon', 'Marathon', 'Ultra'].map((race) =>
              DropdownMenuItem(value: race, child: Text(race))).toList(),
            onChanged: (value) => setState(() => _athleteData['goal_race'] = value),
          ),
          const SizedBox(height: 12),
          _buildMaxInput('Weekly Mileage Target', 'weekly_mileage'),
        ],
      ),
    );
  }

  Widget _buildHyroxInputs() {
    return _buildCard(
      'Hyrox Profile',
      Icons.track_changes,
      Colors.purple,
      Column(
        children: [
          DropdownButtonFormField<String>(
            value: _athleteData['division'] ?? 'Men',
            decoration: const InputDecoration(labelText: 'Division'),
            items: ['Men', 'Women', 'Doubles', 'Pro'].map((div) =>
              DropdownMenuItem(value: div, child: Text(div))).toList(),
            onChanged: (value) => setState(() => _athleteData['division'] = value),
          ),
          const SizedBox(height: 12),
          _buildMaxInput('Goal Time (minutes)', 'goal_time'),
        ],
      ),
    );
  }

  Widget _buildMaxInput(String label, String key) {
    return TextField(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      keyboardType: TextInputType.number,
      onChanged: (value) => _athleteData[key] = double.tryParse(value) ?? 0,
    );
  }

  Widget _buildStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.green, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
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

  Widget _buildProgramStat(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhaseCard(TrainingPhase phase) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _getPhaseColor(phase.type).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _getPhaseColor(phase.type).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_getPhaseIcon(phase.type), color: _getPhaseColor(phase.type)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      phase.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${phase.durationWeeks} weeks',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: phase.goals.map((goal) => Chip(
              label: Text(goal, style: const TextStyle(fontSize: 11)),
              backgroundColor: _getPhaseColor(phase.type).withOpacity(0.1),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMesocycleCard(Mesocycle meso) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            meso.name,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Week ${meso.weekNumber}-${meso.weekNumber + meso.durationWeeks - 1}',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Volume', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    Text('${meso.volumeTarget.toInt()} sets', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Intensity', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    Text('${(meso.intensityTarget * 100).toInt()}% 1RM', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFAB() {
    if (_tabController.index == 4 && _generatedProgram == null) {
      return FloatingActionButton.extended(
        onPressed: _isGenerating ? null : _generateProgram,
        backgroundColor: Colors.green,
        icon: _isGenerating
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : const Icon(Icons.auto_awesome),
        label: Text(_isGenerating ? 'Generating...' : 'Generate Program'),
      );
    }
    
    if (_generatedProgram != null) {
      return FloatingActionButton.extended(
        onPressed: _saveProgram,
        backgroundColor: Colors.deepPurple,
        icon: const Icon(Icons.save),
        label: const Text('Save Program'),
      );
    }
    
    return const SizedBox.shrink();
  }

  Future<void> _generateProgram() async {
    setState(() => _isGenerating = true);
    
    try {
      await Future.delayed(const Duration(seconds: 2)); // Simulate generation
      
      final program = await ProgramGeneratorService().generateProgram(
        clientId: widget.client.id,
        coachId: 'coach-123',
        type: _selectedProgramType,
        startDate: _startDate,
        endDate: _endDate,
        competitionDate: _competitionDate,
        experienceLevel: _experienceLevel,
        athleteData: _athleteData,
      );
      
      setState(() {
        _generatedProgram = program;
        _isGenerating = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Program generated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() => _isGenerating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _saveProgram() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Program saved! (Database integration needed)')),
    );
    Navigator.pop(context, _generatedProgram);
  }

  Color _getPhaseColor(PhaseType type) {
    switch (type) {
      case PhaseType.hypertrophy: return Colors.blue;
      case PhaseType.strength: return Colors.red;
      case PhaseType.power: return Colors.orange;
      case PhaseType.peaking: return Colors.purple;
      case PhaseType.baseBuilding: return Colors.green;
      default: return Colors.grey;
    }
  }

  IconData _getPhaseIcon(PhaseType type) {
    switch (type) {
      case PhaseType.hypertrophy: return Icons.fitness_center;
      case PhaseType.strength: return Icons.flash_on;
      case PhaseType.power: return Icons.rocket_launch;
      case PhaseType.peaking: return Icons.emoji_events;
      case PhaseType.baseBuilding: return Icons.foundation;
      default: return Icons.timeline;
    }
  }

  int _getPhaseCount() {
    switch (_selectedPeriodization) {
      case PeriodizationType.linear: return 3;
      case PeriodizationType.block: return 3;
      case PeriodizationType.undulating: return 6;
      case PeriodizationType.concurrent: return 3;
      default: return 4;
    }
  }
}

