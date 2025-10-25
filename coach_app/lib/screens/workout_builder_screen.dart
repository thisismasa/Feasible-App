import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import '../models/user_model.dart';

/// Workout Program Builder Screen - Interactive Program Creation
/// Features: Drag-and-drop exercise builder, program templates, exercise library, video previews
class WorkoutBuilderScreen extends StatefulWidget {
  final UserModel client;
  final dynamic existingProgram;

  const WorkoutBuilderScreen({
    Key? key,
    required this.client,
    this.existingProgram,
  }) : super(key: key);

  @override
  State<WorkoutBuilderScreen> createState() => _WorkoutBuilderScreenState();
}

class _WorkoutBuilderScreenState extends State<WorkoutBuilderScreen>
    with TickerProviderStateMixin {
  late AnimationController _fabController;
  late AnimationController _listController;
  
  final List<WorkoutDay> _workoutDays = [];
  WorkoutDay? _selectedDay;
  String _programName = '';
  String _programDescription = '';
  int _programWeeks = 4;
  String _selectedTemplate = '';
  
  final List<ExerciseTemplate> _exerciseLibrary = [];
  List<ExerciseTemplate> _filteredExercises = [];
  String _exerciseSearchQuery = '';
  String _selectedMuscleGroup = 'All';
  
  final TextEditingController _searchController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _listController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..forward();
    
    _initializeWorkout();
    _loadExerciseLibrary();
  }

  @override
  void dispose() {
    _fabController.dispose();
    _listController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _initializeWorkout() {
    // Create empty days
    setState(() {
      _workoutDays.addAll([
        WorkoutDay(id: '1', name: 'Day 1 - Upper Body', exercises: []),
        WorkoutDay(id: '2', name: 'Day 2 - Lower Body', exercises: []),
        WorkoutDay(id: '3', name: 'Day 3 - Full Body', exercises: []),
      ]);
    });
  }

  void _loadExerciseLibrary() {
    // Demo exercise library - replace with real data
    _exerciseLibrary.addAll([
      // Chest
      ExerciseTemplate('Bench Press', 'Chest', 'Compound', 'https://via.placeholder.com/200', 'Barbell'),
      ExerciseTemplate('Incline Dumbbell Press', 'Chest', 'Compound', 'https://via.placeholder.com/200', 'Dumbbell'),
      ExerciseTemplate('Cable Flyes', 'Chest', 'Isolation', 'https://via.placeholder.com/200', 'Cable'),
      ExerciseTemplate('Push-ups', 'Chest', 'Bodyweight', 'https://via.placeholder.com/200', 'Bodyweight'),
      
      // Back
      ExerciseTemplate('Deadlift', 'Back', 'Compound', 'https://via.placeholder.com/200', 'Barbell'),
      ExerciseTemplate('Pull-ups', 'Back', 'Compound', 'https://via.placeholder.com/200', 'Bodyweight'),
      ExerciseTemplate('Barbell Rows', 'Back', 'Compound', 'https://via.placeholder.com/200', 'Barbell'),
      ExerciseTemplate('Lat Pulldown', 'Back', 'Compound', 'https://via.placeholder.com/200', 'Cable'),
      
      // Legs
      ExerciseTemplate('Squats', 'Legs', 'Compound', 'https://via.placeholder.com/200', 'Barbell'),
      ExerciseTemplate('Leg Press', 'Legs', 'Compound', 'https://via.placeholder.com/200', 'Machine'),
      ExerciseTemplate('Lunges', 'Legs', 'Compound', 'https://via.placeholder.com/200', 'Dumbbell'),
      ExerciseTemplate('Leg Curl', 'Legs', 'Isolation', 'https://via.placeholder.com/200', 'Machine'),
      
      // Shoulders
      ExerciseTemplate('Overhead Press', 'Shoulders', 'Compound', 'https://via.placeholder.com/200', 'Barbell'),
      ExerciseTemplate('Lateral Raises', 'Shoulders', 'Isolation', 'https://via.placeholder.com/200', 'Dumbbell'),
      ExerciseTemplate('Face Pulls', 'Shoulders', 'Isolation', 'https://via.placeholder.com/200', 'Cable'),
      
      // Arms
      ExerciseTemplate('Barbell Curl', 'Arms', 'Isolation', 'https://via.placeholder.com/200', 'Barbell'),
      ExerciseTemplate('Tricep Dips', 'Arms', 'Compound', 'https://via.placeholder.com/200', 'Bodyweight'),
      ExerciseTemplate('Hammer Curls', 'Arms', 'Isolation', 'https://via.placeholder.com/200', 'Dumbbell'),
      ExerciseTemplate('Tricep Pushdown', 'Arms', 'Isolation', 'https://via.placeholder.com/200', 'Cable'),
      
      // Core
      ExerciseTemplate('Plank', 'Core', 'Bodyweight', 'https://via.placeholder.com/200', 'Bodyweight'),
      ExerciseTemplate('Russian Twists', 'Core', 'Isolation', 'https://via.placeholder.com/200', 'Dumbbell'),
      ExerciseTemplate('Hanging Leg Raises', 'Core', 'Bodyweight', 'https://via.placeholder.com/200', 'Bodyweight'),
    ]);
    
    _filteredExercises = List.from(_exerciseLibrary);
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
                _buildProgramHeader(),
                const SizedBox(height: 20),
                _buildTemplateSelector(),
                const SizedBox(height: 20),
                _buildWorkoutDaysSection(),
                const SizedBox(height: 20),
                if (_selectedDay != null) _buildExerciseLibrary(),
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
      expandedHeight: 160,
      pinned: true,
      backgroundColor: Colors.deepPurple,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text('Workout Builder', style: TextStyle(fontWeight: FontWeight.bold)),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.deepPurple.shade400, Colors.deepPurple.shade800],
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                Hero(
                  tag: 'client-workout-${widget.client.id}',
                  child: CircleAvatar(
                    radius: 35,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.fitness_center,
                      size: 35,
                      color: Colors.deepPurple.shade600,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Building for ${widget.client.name}',
                  style: const TextStyle(
                    fontSize: 16,
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

  Widget _buildProgramHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
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
            children: [
              Icon(Icons.article, color: Colors.deepPurple, size: 24),
              const SizedBox(width: 8),
              const Text(
                'Program Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            decoration: InputDecoration(
              labelText: 'Program Name',
              hintText: 'e.g., 8-Week Strength Builder',
              prefixIcon: const Icon(Icons.title),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (value) => _programName = value,
          ),
          const SizedBox(height: 12),
          TextField(
            decoration: InputDecoration(
              labelText: 'Description',
              hintText: 'Brief description of the program...',
              prefixIcon: const Icon(Icons.description),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            maxLines: 3,
            onChanged: (value) => _programDescription = value,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Program Duration',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove),
                            onPressed: () {
                              if (_programWeeks > 1) {
                                setState(() => _programWeeks--);
                              }
                            },
                          ),
                          Text(
                            '$_programWeeks Weeks',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple.shade700,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () {
                              setState(() => _programWeeks++);
                            },
                          ),
                        ],
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
                      'Total Days',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          '${_workoutDays.length} Days',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateSelector() {
    final templates = [
      {'name': 'Custom', 'icon': Icons.edit, 'color': Colors.blue},
      {'name': 'Push/Pull/Legs', 'icon': Icons.fitness_center, 'color': Colors.green},
      {'name': 'Upper/Lower', 'icon': Icons.accessibility, 'color': Colors.orange},
      {'name': 'Full Body', 'icon': Icons.person, 'color': Colors.purple},
      {'name': 'Powerlifting', 'icon': Icons.sports_gymnastics, 'color': Colors.red},
    ];
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Templates',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: templates.length,
              itemBuilder: (context, index) {
                final template = templates[index];
                final isSelected = _selectedTemplate == template['name'];
                
                return GestureDetector(
                  onTap: () => _applyTemplate(template['name'] as String),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 100,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? LinearGradient(
                              colors: [
                                (template['color'] as Color),
                                (template['color'] as Color).withOpacity(0.7),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: isSelected ? null : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? (template['color'] as Color)
                            : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: (template['color'] as Color).withOpacity(0.3),
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
                          template['icon'] as IconData,
                          size: 32,
                          color: isSelected
                              ? Colors.white
                              : (template['color'] as Color),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          template['name'] as String,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutDaysSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Workout Days',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton.icon(
                onPressed: _addWorkoutDay,
                icon: const Icon(Icons.add),
                label: const Text('Add Day'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._workoutDays.asMap().entries.map((entry) {
            final index = entry.key;
            final day = entry.value;
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(-1, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: _listController,
                curve: Interval(
                  (index * 0.1).clamp(0.0, 1.0),
                  ((index + 1) * 0.1).clamp(0.0, 1.0),
                  curve: Curves.easeOutCubic,
                ),
              )),
              child: _buildWorkoutDayCard(day),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildWorkoutDayCard(WorkoutDay day) {
    final isSelected = _selectedDay?.id == day.id;
    final totalExercises = day.exercises.length;
    final totalSets = day.exercises.fold<int>(
      0,
      (sum, exercise) => sum + exercise.sets.length,
    );
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? Colors.deepPurple : Colors.grey.shade200,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: Colors.deepPurple.withOpacity(0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ]
            : [],
      ),
      child: ExpansionTile(
        leading: GestureDetector(
          onTap: () {
            setState(() {
              _selectedDay = isSelected ? null : day;
            });
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.deepPurple.shade50
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.calendar_today,
              color: isSelected ? Colors.deepPurple : Colors.grey.shade600,
            ),
          ),
        ),
        title: Text(
          day.name,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.deepPurple : Colors.black87,
          ),
        ),
        subtitle: Text(
          '$totalExercises exercises • $totalSets sets',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'EDITING',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
              ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red.shade400),
              onPressed: () => _deleteWorkoutDay(day),
            ),
          ],
        ),
        children: [
          if (day.exercises.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(Icons.fitness_center, size: 48, color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  Text(
                    'No exercises added yet',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() => _selectedDay = day);
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add Exercises'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                    ),
                  ),
                ],
              ),
            )
          else
            ReorderableListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) newIndex--;
                  final exercise = day.exercises.removeAt(oldIndex);
                  day.exercises.insert(newIndex, exercise);
                });
              },
              children: day.exercises.asMap().entries.map((entry) {
                final index = entry.key;
                final exercise = entry.value;
                return _buildExerciseCard(day, exercise, index);
              }).toList(),
            ),
        ],
        onExpansionChanged: (expanded) {
          if (expanded) {
            setState(() => _selectedDay = day);
          }
        },
      ),
    );
  }

  Widget _buildExerciseCard(WorkoutDay day, WorkoutExercise exercise, int index) {
    return Container(
      key: ValueKey(exercise.id),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          // Drag Handle
          Icon(Icons.drag_handle, color: Colors.grey.shade400),
          const SizedBox(width: 12),
          
          // Exercise Number
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.deepPurple,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          
          // Exercise Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: exercise.sets.map((set) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        '${set.reps} reps @ ${set.weight} lbs',
                        style: const TextStyle(fontSize: 11),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          
          // Actions
          IconButton(
            icon: const Icon(Icons.edit, size: 20),
            color: Colors.blue,
            onPressed: () => _editExercise(day, exercise),
          ),
          IconButton(
            icon: const Icon(Icons.delete, size: 20),
            color: Colors.red,
            onPressed: () => _deleteExercise(day, exercise),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseLibrary() {
    final muscleGroups = ['All', 'Chest', 'Back', 'Legs', 'Shoulders', 'Arms', 'Core'];
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepPurple.shade50, Colors.blue.shade50],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.deepPurple.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.library_books, color: Colors.deepPurple, size: 24),
              const SizedBox(width: 8),
              const Text(
                'Exercise Library',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Search Bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search exercises...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _exerciseSearchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _exerciseSearchQuery = '';
                          _filterExercises();
                        });
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (value) {
              setState(() {
                _exerciseSearchQuery = value;
                _filterExercises();
              });
            },
          ),
          
          const SizedBox(height: 12),
          
          // Muscle Group Filter
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: muscleGroups.length,
              itemBuilder: (context, index) {
                final group = muscleGroups[index];
                final isSelected = _selectedMuscleGroup == group;
                
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(group),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedMuscleGroup = group;
                        _filterExercises();
                      });
                    },
                    selectedColor: Colors.deepPurple,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                );
              },
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Exercise List
          SizedBox(
            height: 400,
            child: _filteredExercises.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(
                          'No exercises found',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredExercises.length,
                    itemBuilder: (context, index) {
                      final exercise = _filteredExercises[index];
                      return _buildExerciseLibraryCard(exercise);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseLibraryCard(ExerciseTemplate exercise) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            exercise.thumbnailUrl,
            width: 50,
            height: 50,
            fit: BoxFit.cover,
          ),
        ),
        title: Text(
          exercise.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Row(
          children: [
            _buildBadge(exercise.muscleGroup, Colors.blue),
            const SizedBox(width: 8),
            _buildBadge(exercise.type, Colors.orange),
          ],
        ),
        trailing: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.add, color: Colors.green.shade600),
          ),
          onPressed: () => _addExerciseToDay(exercise),
        ),
        onTap: () => _showExerciseDetails(exercise),
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildFAB() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_selectedDay != null)
          FloatingActionButton.small(
            heroTag: 'preview',
            onPressed: _previewProgram,
            backgroundColor: Colors.blue,
            child: const Icon(Icons.visibility),
          ),
        const SizedBox(height: 12),
        FloatingActionButton.extended(
          heroTag: 'save',
          onPressed: _saveProgram,
          backgroundColor: Colors.green,
          icon: const Icon(Icons.save),
          label: const Text('Save Program'),
        ),
      ],
    );
  }

  void _filterExercises() {
    setState(() {
      _filteredExercises = _exerciseLibrary.where((exercise) {
        final matchesSearch = _exerciseSearchQuery.isEmpty ||
            exercise.name.toLowerCase().contains(_exerciseSearchQuery.toLowerCase());
        final matchesGroup = _selectedMuscleGroup == 'All' ||
            exercise.muscleGroup == _selectedMuscleGroup;
        return matchesSearch && matchesGroup;
      }).toList();
    });
  }

  void _applyTemplate(String templateName) {
    // Implement template application
    setState(() => _selectedTemplate = templateName);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Applied $templateName template')),
    );
  }

  void _addWorkoutDay() {
    setState(() {
      final newDay = WorkoutDay(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: 'Day ${_workoutDays.length + 1}',
        exercises: [],
      );
      _workoutDays.add(newDay);
    });
  }

  void _deleteWorkoutDay(WorkoutDay day) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Day'),
        content: Text('Delete "${day.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _workoutDays.remove(day);
                if (_selectedDay?.id == day.id) {
                  _selectedDay = null;
                }
              });
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _addExerciseToDay(ExerciseTemplate template) {
    if (_selectedDay == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a workout day first')),
      );
      return;
    }
    
    setState(() {
      final newExercise = WorkoutExercise(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: template.name,
        muscleGroup: template.muscleGroup,
        equipment: template.equipment,
        sets: [
          ExerciseSetSimple(reps: 10, weight: 0, restSeconds: 60),
          ExerciseSetSimple(reps: 10, weight: 0, restSeconds: 60),
          ExerciseSetSimple(reps: 10, weight: 0, restSeconds: 60),
        ],
      );
      _selectedDay!.exercises.add(newExercise);
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added ${template.name} to ${_selectedDay!.name}'),
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () {
            setState(() {
              _selectedDay!.exercises.removeLast();
            });
          },
        ),
      ),
    );
  }

  void _editExercise(WorkoutDay day, WorkoutExercise exercise) {
    // Implement edit dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit exercise feature coming soon!')),
    );
  }

  void _deleteExercise(WorkoutDay day, WorkoutExercise exercise) {
    setState(() {
      day.exercises.remove(exercise);
    });
  }

  void _showExerciseDetails(ExerciseTemplate exercise) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(20),
          child: ListView(
            controller: scrollController,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  exercise.thumbnailUrl,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                exercise.name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildBadge(exercise.muscleGroup, Colors.blue),
                  const SizedBox(width: 8),
                  _buildBadge(exercise.type, Colors.orange),
                  const SizedBox(width: 8),
                  _buildBadge(exercise.equipment, Colors.green),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'Instructions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '1. Position yourself correctly\n'
                '2. Engage your core\n'
                '3. Execute the movement with control\n'
                '4. Return to starting position\n'
                '5. Repeat for prescribed reps',
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _addExerciseToDay(exercise);
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add to Workout'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _previewProgram() {
    // Implement program preview
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Preview feature coming soon!')),
    );
  }

  void _saveProgram() {
    if (_programName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a program name')),
      );
      return;
    }
    
    // Implement save to database
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Program "$_programName" saved successfully!'),
        backgroundColor: Colors.green,
      ),
    );
    
    Navigator.pop(context, true);
  }
}

// Models
// Simple models for the builder
class WorkoutDay {
  final String id;
  final String name;
  final List<WorkoutExercise> exercises;

  WorkoutDay({
    required this.id,
    required this.name,
    required this.exercises,
  });
}

class WorkoutExercise {
  final String id;
  final String name;
  final String muscleGroup;
  final String equipment;
  final List<ExerciseSetSimple> sets;

  WorkoutExercise({
    required this.id,
    required this.name,
    required this.muscleGroup,
    required this.equipment,
    required this.sets,
  });
}

class ExerciseSetSimple {
  final int reps;
  final double weight;
  final int restSeconds;

  ExerciseSetSimple({
    required this.reps,
    required this.weight,
    required this.restSeconds,
  });
}

class ExerciseTemplate {
  final String name;
  final String muscleGroup;
  final String type;
  final String thumbnailUrl;
  final String equipment;

  ExerciseTemplate(
    this.name,
    this.muscleGroup,
    this.type,
    this.thumbnailUrl,
    this.equipment,
  );
}

