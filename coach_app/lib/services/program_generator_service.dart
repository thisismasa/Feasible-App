import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/comprehensive_training_models.dart';

/// Comprehensive Program Generator - Multi-Sport Support
/// Generates periodized programs for Powerlifting, Strongman, Running, Hyrox, HIIT
class ProgramGeneratorService {
  static final ProgramGeneratorService _instance = ProgramGeneratorService._internal();
  factory ProgramGeneratorService() => _instance;
  ProgramGeneratorService._internal();

  final _random = Random();
  
  /// Generate Complete Program
  Future<ComprehensiveProgram> generateProgram({
    required String clientId,
    required String coachId,
    required ProgramType type,
    required DateTime startDate,
    required DateTime endDate,
    DateTime? competitionDate,
    required String experienceLevel,
    required Map<String, dynamic> athleteData,
  }) async {
    debugPrint('🏋️ Generating ${type.name} program...');
    
    // Select periodization model
    final periodization = _selectPeriodization(
      type,
      experienceLevel,
      competitionDate,
    );
    
    // Generate macrocycle
    final macrocycle = _generateMacrocycle(
      startDate,
      endDate,
      periodization,
      competitionDate,
    );
    
    // Generate mesocycles
    final mesocycles = _generateMesocycles(macrocycle, type);
    
    // Generate microcycles (weekly plans)
    final microcycles = _generateMicrocycles(mesocycles, type, athleteData);
    
    // Sport-specific configuration
    final sportConfig = _createSportConfig(type, athleteData);
    
    // Create program
    final program = ComprehensiveProgram(
      id: _generateId(),
      name: '${type.name.toUpperCase()} Program - ${_getDateRange(startDate, endDate)}',
      description: _generateProgramDescription(type, periodization),
      clientId: clientId,
      coachId: coachId,
      type: type,
      periodizationType: periodization,
      macrocycle: macrocycle,
      mesocycles: mesocycles,
      microcycles: microcycles,
      sportConfig: sportConfig,
      startDate: startDate,
      endDate: endDate,
      competitionDate: competitionDate,
      analytics: ProgramAnalytics(
        totalWorkouts: microcycles.fold(0, (sum, m) => sum + m.trainingDays.length),
        completedWorkouts: 0,
        adherenceRate: 0,
        averageRPE: 0,
        totalVolumeLoad: 0,
      ),
    );
    
    debugPrint('✅ Program generated: ${program.name}');
    return program;
  }

  /// Select Periodization Type
  PeriodizationType _selectPeriodization(
    ProgramType type,
    String experience,
    DateTime? competitionDate,
  ) {
    // Competition approaching - use block
    if (competitionDate != null) {
      final weeksUntilComp = competitionDate.difference(DateTime.now()).inDays ~/ 7;
      if (weeksUntilComp <= 12) {
        return PeriodizationType.block;
      }
    }
    
    switch (type) {
      case ProgramType.powerlifting:
        if (experience == ExperienceLevel.advanced) {
          return PeriodizationType.conjugate;
        }
        return PeriodizationType.block;
        
      case ProgramType.strongman:
        return PeriodizationType.concurrent;
        
      case ProgramType.running:
      case ProgramType.trailRunning:
        return PeriodizationType.polarized;
        
      case ProgramType.hyrox:
        return PeriodizationType.concurrent;
        
      case ProgramType.hybrid:
        return PeriodizationType.concurrent;
        
      default:
        return PeriodizationType.linear;
    }
  }

  /// Generate Macrocycle
  Macrocycle _generateMacrocycle(
    DateTime startDate,
    DateTime endDate,
    PeriodizationType periodization,
    DateTime? competitionDate,
  ) {
    final totalWeeks = endDate.difference(startDate).inDays ~/ 7;
    final phases = _generatePhases(periodization, totalWeeks, competitionDate);
    final testingDays = _scheduleTestingDays(startDate, totalWeeks);
    final deloadWeeks = _scheduleDeloads(startDate, totalWeeks);
    
    return Macrocycle(
      id: _generateId(),
      name: '${totalWeeks}-Week ${periodization.name} Macrocycle',
      totalWeeks: totalWeeks,
      phases: phases,
      testingDays: testingDays,
      deloadWeeks: deloadWeeks,
      peakWeek: competitionDate,
    );
  }

  /// Generate Training Phases
  List<TrainingPhase> _generatePhases(
    PeriodizationType periodization,
    int totalWeeks,
    DateTime? competitionDate,
  ) {
    final phases = <TrainingPhase>[];
    
    switch (periodization) {
      case PeriodizationType.linear:
        // Classic: Hypertrophy → Strength → Power
        phases.add(_createPhase(PhaseType.hypertrophy, (totalWeeks * 0.4).round()));
        phases.add(_createPhase(PhaseType.strength, (totalWeeks * 0.4).round()));
        phases.add(_createPhase(PhaseType.power, (totalWeeks * 0.2).round()));
        break;
        
      case PeriodizationType.block:
        // Block: Accumulation → Transmutation → Realization
        phases.add(_createPhase(PhaseType.hypertrophy, (totalWeeks * 0.33).round()));
        phases.add(_createPhase(PhaseType.strength, (totalWeeks * 0.33).round()));
        phases.add(_createPhase(PhaseType.peaking, (totalWeeks * 0.34).round()));
        break;
        
      case PeriodizationType.conjugate:
        // Westside: Concurrent max effort + dynamic effort
        // Single long phase with rotating emphasis
        phases.add(_createPhase(PhaseType.strength, totalWeeks));
        break;
        
      case PeriodizationType.undulating:
        // DUP: Short blocks alternating
        var remainingWeeks = totalWeeks;
        while (remainingWeeks > 0) {
          final blockLength = min(3, remainingWeeks);
          phases.add(_createPhase(PhaseType.hypertrophy, blockLength));
          remainingWeeks -= blockLength;
          
          if (remainingWeeks > 0) {
            final strengthBlock = min(3, remainingWeeks);
            phases.add(_createPhase(PhaseType.strength, strengthBlock));
            remainingWeeks -= strengthBlock;
          }
        }
        break;
        
      case PeriodizationType.concurrent:
        // Train everything simultaneously (Strongman/Hybrid)
        phases.add(_createPhase(PhaseType.baseBuilding, (totalWeeks * 0.4).round()));
        phases.add(_createPhase(PhaseType.strength, (totalWeeks * 0.4).round()));
        phases.add(_createPhase(PhaseType.peaking, (totalWeeks * 0.2).round()));
        break;
        
      case PeriodizationType.polarized:
        // Endurance: 80% easy, 20% hard
        phases.add(_createPhase(PhaseType.baseBuilding, (totalWeeks * 0.5).round()));
        phases.add(_createPhase(PhaseType.threshold, (totalWeeks * 0.3).round()));
        phases.add(_createPhase(PhaseType.racePrep, (totalWeeks * 0.2).round()));
        break;
        
      default:
        phases.add(_createPhase(PhaseType.strength, totalWeeks));
    }
    
    return phases;
  }

  TrainingPhase _createPhase(PhaseType type, int weeks) {
    final volumeProg = _createVolumeProgression(type, weeks);
    final intensityProg = _createIntensityProgression(type, weeks);
    
    return TrainingPhase(
      id: _generateId(),
      name: type.name.toUpperCase(),
      type: type,
      durationWeeks: weeks,
      goals: _getPhaseGoals(type),
      volumeProgression: volumeProg,
      intensityProgression: intensityProg,
      technicalFocus: _getTechnicalFocus(type),
      adaptationTargets: _getAdaptationTargets(type),
    );
  }

  VolumeProgression _createVolumeProgression(PhaseType type, int weeks) {
    double start, peak;
    
    switch (type) {
      case PhaseType.hypertrophy:
        start = 120; // Total sets per week
        peak = 180;
        break;
      case PhaseType.strength:
        start = 80;
        peak = 120;
        break;
      case PhaseType.power:
        start = 60;
        peak = 90;
        break;
      case PhaseType.peaking:
        start = 60;
        peak = 40; // Decrease for taper
        break;
      default:
        start = 100;
        peak = 150;
    }
    
    final weeklyVolumes = <double>[];
    for (int i = 0; i < weeks; i++) {
      final progress = i / max(weeks - 1, 1);
      weeklyVolumes.add(start + (peak - start) * progress);
    }
    
    return VolumeProgression(
      pattern: 'linear',
      startingVolume: start,
      peakVolume: peak,
      volumeIncrement: (peak - start) / weeks,
      weeklyVolumes: weeklyVolumes,
    );
  }

  IntensityProgression _createIntensityProgression(PhaseType type, int weeks) {
    double start, peak;
    
    switch (type) {
      case PhaseType.hypertrophy:
        start = 0.65; // 65% of 1RM
        peak = 0.75;
        break;
      case PhaseType.strength:
        start = 0.75;
        peak = 0.90;
        break;
      case PhaseType.power:
        start = 0.50;
        peak = 0.70;
        break;
      case PhaseType.peaking:
        start = 0.85;
        peak = 0.95;
        break;
      default:
        start = 0.70;
        peak = 0.85;
    }
    
    final weeklyIntensities = <double>[];
    for (int i = 0; i < weeks; i++) {
      final progress = i / max(weeks - 1, 1);
      weeklyIntensities.add(start + (peak - start) * progress);
    }
    
    return IntensityProgression(
      pattern: 'linear',
      startingIntensity: start,
      peakIntensity: peak,
      intensityIncrement: (peak - start) / weeks,
      weeklyIntensities: weeklyIntensities,
    );
  }

  /// Generate Mesocycles
  List<Mesocycle> _generateMesocycles(Macrocycle macro, ProgramType type) {
    final mesocycles = <Mesocycle>[];
    int weekCounter = 0;
    
    for (final phase in macro.phases) {
      // Each mesocycle is 4 weeks (3 loading + 1 deload)
      final mesoCount = (phase.durationWeeks / 4).ceil();
      
      for (int i = 0; i < mesoCount; i++) {
        final mesoDuration = min(4, phase.durationWeeks - (i * 4));
        
        mesocycles.add(Mesocycle(
          id: _generateId(),
          name: '${phase.name} Block ${i + 1}',
          weekNumber: weekCounter + 1,
          phase: phase.type,
          durationWeeks: mesoDuration,
          volumeTarget: phase.volumeProgression.getWeeklyVolume(i),
          intensityTarget: phase.intensityProgression.getWeeklyIntensity(i),
          primaryExercises: _selectPrimaryExercises(type, phase.type),
          includesDeload: true,
        ));
        
        weekCounter += mesoDuration;
      }
    }
    
    return mesocycles;
  }

  /// Generate Microcycles (Weekly Plans)
  List<Microcycle> _generateMicrocycles(
    List<Mesocycle> mesocycles,
    ProgramType type,
    Map<String, dynamic> athleteData,
  ) {
    final microcycles = <Microcycle>[];
    
    for (final meso in mesocycles) {
      for (int week = 0; week < meso.durationWeeks; week++) {
        final isDeload = week == meso.durationWeeks - 1;
        
        microcycles.add(_generateMicrocycle(
          meso,
          week,
          isDeload,
          type,
          athleteData,
        ));
      }
    }
    
    return microcycles;
  }

  Microcycle _generateMicrocycle(
    Mesocycle meso,
    int weekInMeso,
    bool isDeload,
    ProgramType type,
    Map<String, dynamic> athleteData,
  ) {
    final trainingDays = _determineTrainingDays(type, isDeload);
    final volume = isDeload ? meso.volumeTarget * 0.6 : meso.volumeTarget;
    final intensity = isDeload ? meso.intensityTarget * 0.9 : meso.intensityTarget;
    
    return Microcycle(
      id: _generateId(),
      mesocycleId: meso.id,
      weekNumber: meso.weekNumber + weekInMeso,
      startDate: DateTime.now().add(Duration(days: (meso.weekNumber + weekInMeso - 1) * 7)),
      endDate: DateTime.now().add(Duration(days: (meso.weekNumber + weekInMeso) * 7)),
      phase: meso.phase,
      weeklyVolume: volume,
      weeklyIntensity: intensity,
      trainingDays: trainingDays,
      weeklyFocus: isDeload ? 'Recovery' : _getWeeklyFocus(type, meso.phase),
      isDeload: isDeload,
      events: type == ProgramType.strongman ? _selectStrongmanEvents() : null,
    );
  }

  /// Determine training frequency
  List<String> _determineTrainingDays(ProgramType type, bool isDeload) {
    if (isDeload) {
      return ['Monday', 'Wednesday', 'Friday']; // 3 days during deload
    }
    
    switch (type) {
      case ProgramType.powerlifting:
        return ['Monday', 'Tuesday', 'Thursday', 'Friday']; // 4 days
        
      case ProgramType.strongman:
        return ['Monday', 'Wednesday', 'Friday', 'Saturday']; // 4 days
        
      case ProgramType.running:
      case ProgramType.trailRunning:
        return ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday']; // 6 days
        
      case ProgramType.hyrox:
        return ['Monday', 'Tuesday', 'Wednesday', 'Friday', 'Saturday']; // 5 days
        
      case ProgramType.hybrid:
        return ['Monday', 'Tuesday', 'Thursday', 'Friday', 'Saturday']; // 5 days
        
      default:
        return ['Monday', 'Wednesday', 'Friday']; // 3 days
    }
  }

  /// Select primary exercises for phase
  List<String> _selectPrimaryExercises(ProgramType type, PhaseType phase) {
    switch (type) {
      case ProgramType.powerlifting:
        return ['Back Squat', 'Bench Press', 'Deadlift', 'Front Squat', 'Close Grip Bench'];
        
      case ProgramType.strongman:
        return ['Log Press', 'Yoke Walk', 'Atlas Stones', 'Farmers Walk', 'Deadlift'];
        
      case ProgramType.hyrox:
        return ['Ski Erg', 'Sled Push', 'Burpee Broad Jump', 'Rowing', 'Wall Balls'];
        
      default:
        return ['Squat', 'Bench Press', 'Deadlift', 'Overhead Press', 'Rows'];
    }
  }

  /// Select Strongman events for the week
  List<StrongmanEventType> _selectStrongmanEvents() {
    final allEvents = StrongmanEventType.values;
    allEvents.shuffle(_random);
    return allEvents.take(3).toList(); // 3 events per week
  }

  /// Create sport-specific configuration
  SportSpecificConfig _createSportConfig(
    ProgramType type,
    Map<String, dynamic> athleteData,
  ) {
    switch (type) {
      case ProgramType.powerlifting:
        return SportSpecificConfig(
          type: type,
          powerlifting: PowerliftingConfig(
            method: PowerliftingMethod.block,
            currentMaxes: {
              'squat': athleteData['squat_max'] ?? 300.0,
              'bench': athleteData['bench_max'] ?? 225.0,
              'deadlift': athleteData['deadlift_max'] ?? 405.0,
            },
            weakPoints: {
              'squat': ['bottom position'],
              'bench': ['lockout'],
              'deadlift': ['off floor'],
            },
            meetDate: athleteData['meet_date'],
            weightClass: athleteData['weight_class'],
          ),
        );
        
      case ProgramType.strongman:
        return SportSpecificConfig(
          type: type,
          strongman: StrongmanConfig(
            competitionEvents: [
              StrongmanEventType.logPress,
              StrongmanEventType.yokeWalk,
              StrongmanEventType.atlasStones,
            ],
            eventPRs: {},
            weakEvents: [StrongmanEventType.atlasStones],
            competitionDate: athleteData['competition_date'],
            competitionClass: 'Novice',
          ),
        );
        
      case ProgramType.running:
        return SportSpecificConfig(
          type: type,
          running: RunningConfig(
            goalRace: athleteData['goal_race'] ?? '10K',
            goalTime: Duration(minutes: athleteData['goal_time_minutes'] ?? 45),
            currentPR: Duration(minutes: athleteData['current_pr_minutes'] ?? 50),
            weeklyMileageTarget: athleteData['weekly_mileage'] ?? 30,
            pacesPerMile: {
              'easy': Duration(minutes: 9),
              'tempo': Duration(minutes: 7, seconds: 30),
              'threshold': Duration(minutes: 7),
              'interval': Duration(minutes: 6, seconds: 30),
            },
          ),
        );
        
      case ProgramType.hyrox:
        return SportSpecificConfig(
          type: type,
          hyrox: HyroxConfig(
            division: athleteData['division'] ?? 'Men',
            goalTime: Duration(minutes: athleteData['goal_time'] ?? 75),
            currentBestTime: Duration(minutes: athleteData['current_best'] ?? 85),
            stationBests: {},
            weakStations: [HyroxStationType.burpeeBroadJump],
            competitionFocus: true,
          ),
        );
        
      default:
        return SportSpecificConfig(type: type);
    }
  }

  /// Generate phase goals
  List<String> _getPhaseGoals(PhaseType type) {
    switch (type) {
      case PhaseType.hypertrophy:
        return ['Build muscle mass', 'Increase work capacity', 'Improve technique'];
      case PhaseType.strength:
        return ['Increase maximal strength', 'Neural adaptations', 'Heavy loading'];
      case PhaseType.power:
        return ['Develop explosive power', 'High velocity training', 'Rate of force development'];
      case PhaseType.peaking:
        return ['Maximize strength expression', 'Taper fatigue', 'Competition preparation'];
      case PhaseType.baseBuilding:
        return ['Build aerobic base', 'High volume low intensity', 'Technique refinement'];
      default:
        return ['General adaptation'];
    }
  }

  List<String> _getTechnicalFocus(PhaseType type) {
    switch (type) {
      case PhaseType.hypertrophy:
        return ['Time under tension', 'Mind-muscle connection', 'Full ROM'];
      case PhaseType.strength:
        return ['Bracing', 'Force production', 'Sticking point work'];
      case PhaseType.power:
        return ['Explosiveness', 'Bar velocity', 'Rate of force development'];
      default:
        return ['General technique'];
    }
  }

  List<String> _getAdaptationTargets(PhaseType type) {
    switch (type) {
      case PhaseType.hypertrophy:
        return ['Muscle hypertrophy', 'Metabolic stress', 'Muscle damage'];
      case PhaseType.strength:
        return ['Neural adaptation', 'Motor unit recruitment', 'Rate coding'];
      case PhaseType.power:
        return ['Power output', 'Velocity', 'Explosiveness'];
      default:
        return ['General adaptation'];
    }
  }

  String _getWeeklyFocus(ProgramType type, PhaseType phase) {
    return '${type.name} - ${phase.name} focus';
  }

  List<DateTime> _scheduleTestingDays(DateTime startDate, int totalWeeks) {
    final testingDays = <DateTime>[];
    
    // Test at start
    testingDays.add(startDate);
    
    // Test every 4-6 weeks
    for (int week = 4; week < totalWeeks; week += 6) {
      testingDays.add(startDate.add(Duration(days: week * 7)));
    }
    
    // Test at end
    testingDays.add(startDate.add(Duration(days: totalWeeks * 7)));
    
    return testingDays;
  }

  List<DateTime> _scheduleDeloads(DateTime startDate, int totalWeeks) {
    final deloads = <DateTime>[];
    
    // Deload every 4th week
    for (int week = 3; week < totalWeeks; week += 4) {
      deloads.add(startDate.add(Duration(days: week * 7)));
    }
    
    return deloads;
  }

  String _getDateRange(DateTime start, DateTime end) {
    final formatter = RegExp(r'(\d{4})-(\d{2})-(\d{2})');
    final startStr = start.toString().split(' ')[0];
    final endStr = end.toString().split(' ')[0];
    return '$startStr to $endStr';
  }

  String _generateProgramDescription(ProgramType type, PeriodizationType periodization) {
    return 'A ${periodization.name} periodized ${type.name} program designed to optimize performance and adaptations.';
  }

  String _generateId() {
    return '${DateTime.now().millisecondsSinceEpoch}-${_random.nextInt(999999)}';
  }
}

/// Workout Generator - Creates individual workout sessions
class WorkoutGeneratorService {
  final _random = Random();
  final exerciseDb = ExerciseDatabase();
  
  /// Generate workout for specific day
  ComprehensiveWorkout generateWorkout({
    required Microcycle microcycle,
    required String dayOfWeek,
    required ProgramType programType,
    required PhaseType phase,
    Map<String, dynamic> athleteData = const {},
  }) {
    final warmup = _generateWarmup(programType);
    final mainWork = _generateMainWork(programType, phase, microcycle.weeklyIntensity);
    final accessoryWork = _generateAccessoryWork(programType, phase);
    final cooldown = _generateCooldown();
    
    return ComprehensiveWorkout(
      id: '${microcycle.id}-$dayOfWeek',
      programId: microcycle.mesocycleId,
      date: microcycle.startDate.add(Duration(days: _dayIndex(dayOfWeek))),
      type: _determineSessionType(programType, dayOfWeek),
      warmup: warmup,
      mainWork: mainWork,
      accessoryWork: accessoryWork,
      cooldown: cooldown,
      rpeTarget: RPETarget(target: 8, minRange: 7, maxRange: 9),
      loadManagement: LoadManagement(
        weeklyTonnage: microcycle.weeklyVolume * 100,
        intensityDistribution: microcycle.weeklyIntensity,
        liftDistribution: {'squat': 0.33, 'bench': 0.33, 'deadlift': 0.34},
      ),
    );
  }

  WarmupProtocol _generateWarmup(ProgramType type) {
    return WarmupProtocol(
      sections: [
        WarmupSection(
          name: 'General Warmup',
          exercises: ['Jump rope', 'Arm circles', 'Leg swings'],
          durationMinutes: 5,
        ),
        WarmupSection(
          name: 'Specific Warmup',
          exercises: ['Empty bar work', 'Movement prep', 'Activation'],
          durationMinutes: 5,
        ),
      ],
      totalDurationMinutes: 10,
    );
  }

  List<MainWork> _generateMainWork(
    ProgramType type,
    PhaseType phase,
    double intensity,
  ) {
    final mainWork = <MainWork>[];
    final exercises = exerciseDb.getMainExercises(type);
    
    for (int i = 0; i < min(3, exercises.length); i++) {
      final exercise = exercises[i];
      final sets = _generateSets(phase, intensity, i == 0);
      
      mainWork.add(MainWork(
        id: '${exercise.id}-main',
        exercise: exercise,
        sets: sets,
        tempo: TempoScheme(eccentric: 3, bottomPause: 1, concentric: 1, topPause: 0),
        rirTarget: 2,
      ));
    }
    
    return mainWork;
  }

  List<WorkingSet> _generateSets(PhaseType phase, double intensity, bool isFirstExercise) {
    final sets = <WorkingSet>[];
    int totalSets, reps;
    
    switch (phase) {
      case PhaseType.hypertrophy:
        totalSets = 4;
        reps = 10;
        break;
      case PhaseType.strength:
        totalSets = 5;
        reps = 5;
        break;
      case PhaseType.power:
        totalSets = 5;
        reps = 3;
        break;
      default:
        totalSets = 3;
        reps = 8;
    }
    
    for (int i = 0; i < totalSets; i++) {
      sets.add(WorkingSet(
        id: 'set-${i + 1}',
        type: i < 2 ? SetType.warmup : SetType.working,
        targetReps: reps,
        targetWeight: 100.0 * intensity * (i < 2 ? 0.7 : 1.0),
        restSeconds: _calculateRest(phase),
        targetRPE: i == totalSets - 1 ? 9 : 8,
      ));
    }
    
    return sets;
  }

  int _calculateRest(PhaseType phase) {
    switch (phase) {
      case PhaseType.hypertrophy:
        return 90;
      case PhaseType.strength:
        return 180;
      case PhaseType.power:
        return 240;
      default:
        return 120;
    }
  }

  List<AccessoryWork> _generateAccessoryWork(ProgramType type, PhaseType phase) {
    final accessories = <AccessoryWork>[];
    final exercises = exerciseDb.getAccessoryExercises(type);
    
    for (int i = 0; i < min(3, exercises.length); i++) {
      accessories.add(AccessoryWork(
        id: 'accessory-$i',
        exercise: exercises[i],
        sets: List.generate(3, (setIndex) => WorkingSet(
          id: 'acc-set-${setIndex + 1}',
          type: SetType.straight,
          targetReps: 12,
          targetWeight: 50.0,
          restSeconds: 60,
          targetRPE: 7,
        )),
        purpose: phase == PhaseType.hypertrophy ? 'hypertrophy' : 'strength',
      ));
    }
    
    return accessories;
  }

  CooldownProtocol _generateCooldown() {
    return CooldownProtocol(
      stretches: ['Hamstring stretch', 'Quad stretch', 'Hip flexor stretch', 'Chest stretch'],
      durationMinutes: 10,
      includeFoamRolling: true,
      mobilityWork: ['Cat-cow', 'World\'s greatest stretch', 'Shoulder dislocations'],
    );
  }

  SessionType _determineSessionType(ProgramType type, String day) {
    // Simplified - in production, this would be more complex
    if (day == 'Monday') return SessionType.strengthMain;
    if (day == 'Wednesday') return SessionType.strengthMain;
    if (day == 'Friday') return SessionType.strengthMain;
    return SessionType.strengthAccessory;
  }

  int _dayIndex(String day) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days.indexOf(day);
  }
}

/// Exercise Database - Centralized exercise library
class ExerciseDatabase {
  final List<Exercise> _exercises = [];
  
  ExerciseDatabase() {
    _initializeExercises();
  }

  void _initializeExercises() {
    // Powerlifting main lifts
    _exercises.addAll([
      Exercise(
        id: 'squat-1',
        name: 'Back Squat',
        category: ExerciseCategory.squatVariation,
        primaryMuscles: [MuscleGroup.quads, MuscleGroup.glutes],
        secondaryMuscles: [MuscleGroup.hamstrings, MuscleGroup.spinalErectors],
        equipment: [Equipment.barbell],
        difficulty: DifficultyLevel.intermediate,
        setupSteps: ['Bar on upper back', 'Feet shoulder width', 'Brace core'],
        executionSteps: ['Break at hips and knees', 'Descend to parallel', 'Drive through heels'],
        coachingCues: ['Chest up', 'Knees out', 'Drive the floor away'],
      ),
      Exercise(
        id: 'bench-1',
        name: 'Bench Press',
        category: ExerciseCategory.benchVariation,
        primaryMuscles: [MuscleGroup.chest, MuscleGroup.frontDelts],
        secondaryMuscles: [MuscleGroup.triceps],
        equipment: [Equipment.barbell],
        difficulty: DifficultyLevel.intermediate,
        coachingCues: ['Retract scapula', 'Leg drive', 'Touch chest'],
      ),
      Exercise(
        id: 'deadlift-1',
        name: 'Deadlift',
        category: ExerciseCategory.deadliftVariation,
        primaryMuscles: [MuscleGroup.hamstrings, MuscleGroup.glutes, MuscleGroup.spinalErectors],
        secondaryMuscles: [MuscleGroup.quads, MuscleGroup.lats],
        equipment: [Equipment.barbell],
        difficulty: DifficultyLevel.advanced,
        coachingCues: ['Hips back', 'Lats tight', 'Push floor away'],
      ),
    ]);
    
    // Add more exercises...
    _addStrongmanExercises();
    _addHyroxExercises();
    _addRunningDrills();
    _addAccessoryExercises();
  }

  void _addStrongmanExercises() {
    _exercises.addAll([
      Exercise(
        id: 'log-press-1',
        name: 'Log Press',
        category: ExerciseCategory.pressOverhead,
        primaryMuscles: [MuscleGroup.frontDelts, MuscleGroup.triceps],
        secondaryMuscles: [MuscleGroup.upperBack, MuscleGroup.abs],
        equipment: [Equipment.log],
        difficulty: DifficultyLevel.advanced,
        coachingCues: ['Clean to chest', 'Dip and drive', 'Press overhead'],
      ),
      Exercise(
        id: 'yoke-walk-1',
        name: 'Yoke Walk',
        category: ExerciseCategory.carry,
        primaryMuscles: [MuscleGroup.traps, MuscleGroup.spinalErectors, MuscleGroup.abs],
        secondaryMuscles: [MuscleGroup.quads, MuscleGroup.glutes],
        equipment: [Equipment.yoke],
        difficulty: DifficultyLevel.advanced,
        coachingCues: ['Head up', 'Small steps', 'Stable core'],
      ),
    ]);
  }

  void _addHyroxExercises() {
    _exercises.addAll([
      Exercise(
        id: 'ski-erg-1',
        name: 'Ski Erg',
        category: ExerciseCategory.ergometer,
        primaryMuscles: [MuscleGroup.lats, MuscleGroup.abs],
        secondaryMuscles: [MuscleGroup.triceps],
        equipment: [Equipment.skiErg],
        difficulty: DifficultyLevel.intermediate,
      ),
      Exercise(
        id: 'sled-push-1',
        name: 'Sled Push',
        category: ExerciseCategory.pullDrag,
        primaryMuscles: [MuscleGroup.quads, MuscleGroup.glutes],
        secondaryMuscles: [MuscleGroup.calves, MuscleGroup.abs],
        equipment: [Equipment.sled],
        difficulty: DifficultyLevel.intermediate,
      ),
    ]);
  }

  void _addRunningDrills() {
    _exercises.addAll([
      Exercise(
        id: 'intervals-1',
        name: 'Track Intervals',
        category: ExerciseCategory.intervals,
        primaryMuscles: [MuscleGroup.fullBody],
        secondaryMuscles: [],
        equipment: [Equipment.bodyweight],
        difficulty: DifficultyLevel.advanced,
      ),
    ]);
  }

  void _addAccessoryExercises() {
    _exercises.addAll([
      Exercise(
        id: 'row-1',
        name: 'Barbell Row',
        category: ExerciseCategory.pullDrag,
        primaryMuscles: [MuscleGroup.lats, MuscleGroup.upperBack],
        secondaryMuscles: [MuscleGroup.biceps],
        equipment: [Equipment.barbell],
        difficulty: DifficultyLevel.intermediate,
      ),
    ]);
  }

  List<Exercise> getMainExercises(ProgramType type) {
    switch (type) {
      case ProgramType.powerlifting:
        return _exercises.where((e) =>
          e.category == ExerciseCategory.squatVariation ||
          e.category == ExerciseCategory.benchVariation ||
          e.category == ExerciseCategory.deadliftVariation).toList();
        
      case ProgramType.strongman:
        return _exercises.where((e) =>
          e.equipment.contains(Equipment.log) ||
          e.equipment.contains(Equipment.yoke) ||
          e.equipment.contains(Equipment.stones)).toList();
        
      case ProgramType.hyrox:
        return _exercises.where((e) =>
          e.equipment.contains(Equipment.skiErg) ||
          e.equipment.contains(Equipment.sled)).toList();
        
      default:
        return _exercises.take(5).toList();
    }
  }

  List<Exercise> getAccessoryExercises(ProgramType type) {
    return _exercises.where((e) => e.category == ExerciseCategory.isolation).take(5).toList();
  }

  Exercise? getExerciseById(String id) {
    try {
      return _exercises.firstWhere((e) => e.id == id);
    } catch (e) {
      return null;
    }
  }
}

