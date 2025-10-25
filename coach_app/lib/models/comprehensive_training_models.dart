/// ================================================
/// COMPREHENSIVE TRAINING PLATFORM MODELS
/// Supporting: Strength, Powerlifting, Running, Strongman, Hyrox, HIIT, Trail Running
/// With Periodization, Complex Programming, and Enterprise Features
/// ================================================

import 'package:flutter/material.dart';

// ==================== CORE ENUMS ====================

enum ExerciseCategory {
  // Powerlifting
  squatVariation,
  benchVariation,
  deadliftVariation,
  
  // Olympic Lifting
  snatchVariation,
  cleanJerkVariation,
  
  // Strongman
  carry,
  load,
  pressOverhead,
  pullDrag,
  throwEvent,
  
  // Running
  sprint,
  tempo,
  intervals,
  longDistance,
  hillWork,
  trailTechnique,
  
  // HIIT/Hyrox
  metabolic,
  functional,
  ergometer,
  bodyweight,
  
  // Accessory
  isolation,
  prehab,
  mobility,
  core,
  plyometric
}

enum MuscleGroup {
  // Upper body
  chest, frontDelts, sideDelts, rearDelts,
  biceps, triceps, forearms,
  upperBack, lats, traps,
  
  // Core
  abs, obliques, lowerBack, spinalErectors,
  
  // Lower body
  quads, hamstrings, glutes, adductors, abductors,
  calves, hipFlexors,
  
  // Full body
  fullBody
}

enum Equipment {
  barbell, dumbbell, kettlebell, cable,
  machine, bodyweight, resistanceBand,
  
  // Strongman
  log, axle, yoke, stones, sandbag,
  sled, prowler, farmersHandles,
  
  // Cardio
  treadmill, bike, rower, skiErg,
  assaultBike, echoBike,
  
  // Other
  medicineBall, battlingRopes, plyo
}

enum DifficultyLevel {
  beginner,      // 1-3
  intermediate,  // 4-6
  advanced,      // 7-8
  elite          // 9-10
}

enum ProgramType {
  powerlifting,
  strongman,
  running,
  trailRunning,
  hyrox,
  crosstraining,
  hybrid,
  generalStrength,
  bodybuilding,
  sportSpecific
}

enum PeriodizationType {
  linear,
  block,
  undulating,
  conjugate,
  concurrent,
  polarized,
  reverseLinear,
  agile // Adaptive based on response
}

enum PhaseType {
  // Strength phases
  anatomicalAdaptation,
  hypertrophy,
  strength,
  power,
  peaking,
  
  // Endurance phases
  baseBuilding,
  threshold,
  vo2max,
  speed,
  racePrep,
  
  // Recovery phases
  deload,
  transition,
  activeRecovery
}

enum SessionType {
  strengthMain,
  strengthAccessory,
  powerDay,
  speedDay,
  technicalDay,
  
  // Endurance
  longRun,
  tempoRun,
  intervalsRun,
  easyRun,
  recoveryRun,
  
  // Strongman
  eventDay,
  maxEffort,
  volumeDay,
  
  // HIIT
  metabolicConditioning,
  hyroxSimulation,
  
  // Other
  testing,
  assessment,
  recovery
}

enum SetType {
  straight,
  warmup,
  working,
  backoff,
  dropset,
  cluster,
  restPause,
  amrap,
  emom,
  tabata,
  pyramid,
  wave,
  ladder
}

enum PowerliftingMethod {
  linear,
  conjugate,
  block,
  dup, // Daily Undulating
  bulgarian,
  sheiko,
  cube,
  fiveThreeOne,
  rpeBased,
  velocityBased
}

enum HyroxStationType {
  skiErg,
  sledPush,
  sledPull,
  burpeeBroadJump,
  rowing,
  farmersCarry,
  sandbagLunges,
  wallBalls,
  running
}

enum StrongmanEventType {
  // Overhead
  logPress,
  axlePress,
  dumbbellPress,
  vikingPress,
  
  // Deadlift
  deadliftMax,
  deadliftReps,
  carDeadlift,
  silverDollarDeadlift,
  
  // Carry
  farmersWalk,
  yokeWalk,
  sandbagCarry,
  hussafellCarry,
  
  // Loading
  atlasStones,
  sandbagLoad,
  kegLoad,
  
  // Moving
  truckPull,
  sledDrag,
  prowlerPush,
  
  // Grip
  herculesHold,
  frameHold
}

enum TimeProtocolType {
  emom,
  amrap,
  tabata,
  intervals,
  fartlek,
  tempo,
  timeTrial,
  chipper,
  ladder,
  deathBy,
  fightGoneBad
}

// ==================== CORE DATA MODELS ====================

/// Comprehensive Exercise Model
class Exercise {
  final String id;
  final String name;
  final ExerciseCategory category;
  final List<MuscleGroup> primaryMuscles;
  final List<MuscleGroup> secondaryMuscles;
  final List<Equipment> equipment;
  final DifficultyLevel difficulty;
  
  // Biomechanics
  final String forceVector; // Vertical, Horizontal, Rotational
  final String strengthCurve; // Ascending, Descending, Bell
  final String rangeOfMotion; // Full, Partial, Variable
  
  // Instructions
  final List<String> setupSteps;
  final List<String> executionSteps;
  final List<String> commonMistakes;
  final List<String> coachingCues;
  
  // Safety
  final List<String> prerequisites;
  final List<String> contraindications;
  final int injuryRiskScore; // 1-10
  
  // Media
  final String? videoUrl;
  final String? imageUrl;
  final String? thumbnailUrl;
  
  // Sport-specific tags
  final Map<String, dynamic> sportSpecificData;

  Exercise({
    required this.id,
    required this.name,
    required this.category,
    required this.primaryMuscles,
    required this.secondaryMuscles,
    required this.equipment,
    required this.difficulty,
    this.forceVector = 'vertical',
    this.strengthCurve = 'ascending',
    this.rangeOfMotion = 'full',
    this.setupSteps = const [],
    this.executionSteps = const [],
    this.commonMistakes = const [],
    this.coachingCues = const [],
    this.prerequisites = const [],
    this.contraindications = const [],
    this.injuryRiskScore = 5,
    this.videoUrl,
    this.imageUrl,
    this.thumbnailUrl,
    this.sportSpecificData = const {},
  });

  factory Exercise.fromMap(Map<String, dynamic> map) {
    return Exercise(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      category: ExerciseCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => ExerciseCategory.functional,
      ),
      primaryMuscles: (map['primary_muscles'] as List?)
          ?.map((m) => MuscleGroup.values.firstWhere((e) => e.name == m))
          .toList() ?? [],
      secondaryMuscles: (map['secondary_muscles'] as List?)
          ?.map((m) => MuscleGroup.values.firstWhere((e) => e.name == m))
          .toList() ?? [],
      equipment: (map['equipment'] as List?)
          ?.map((e) => Equipment.values.firstWhere((eq) => eq.name == e))
          .toList() ?? [],
      difficulty: DifficultyLevel.values.firstWhere(
        (d) => d.name == map['difficulty'],
        orElse: () => DifficultyLevel.intermediate,
      ),
      setupSteps: List<String>.from(map['setup_steps'] ?? []),
      executionSteps: List<String>.from(map['execution_steps'] ?? []),
      coachingCues: List<String>.from(map['coaching_cues'] ?? []),
      videoUrl: map['video_url'],
      imageUrl: map['image_url'],
    );
  }
}

/// Advanced Workout Program with Periodization
class ComprehensiveProgram {
  final String id;
  final String name;
  final String description;
  final String clientId;
  final String coachId;
  final ProgramType type;
  
  // Periodization
  final PeriodizationType periodizationType;
  final Macrocycle macrocycle;
  final List<Mesocycle> mesocycles;
  final List<Microcycle> microcycles;
  
  // Sport-specific configuration
  final SportSpecificConfig sportConfig;
  
  // Dates
  final DateTime startDate;
  final DateTime endDate;
  final DateTime? competitionDate;
  
  // Current state
  int currentMesocycle;
  int currentMicrocycle;
  
  // Analytics
  final ProgramAnalytics analytics;

  ComprehensiveProgram({
    required this.id,
    required this.name,
    required this.description,
    required this.clientId,
    required this.coachId,
    required this.type,
    required this.periodizationType,
    required this.macrocycle,
    required this.mesocycles,
    required this.microcycles,
    required this.sportConfig,
    required this.startDate,
    required this.endDate,
    this.competitionDate,
    this.currentMesocycle = 0,
    this.currentMicrocycle = 0,
    required this.analytics,
  });
}

/// Macrocycle - Long-term planning (months to year)
class Macrocycle {
  final String id;
  final String name;
  final int totalWeeks;
  final List<TrainingPhase> phases;
  final List<DateTime> testingDays;
  final List<DateTime> deloadWeeks;
  final DateTime? peakWeek;

  Macrocycle({
    required this.id,
    required this.name,
    required this.totalWeeks,
    required this.phases,
    required this.testingDays,
    required this.deloadWeeks,
    this.peakWeek,
  });
}

/// Training Phase (part of macrocycle)
class TrainingPhase {
  final String id;
  final String name;
  final PhaseType type;
  final int durationWeeks;
  final List<String> goals;
  
  // Volume and intensity targets
  final VolumeProgression volumeProgression;
  final IntensityProgression intensityProgression;
  
  // Focus areas
  final List<String> technicalFocus;
  final List<String> adaptationTargets;

  TrainingPhase({
    required this.id,
    required this.name,
    required this.type,
    required this.durationWeeks,
    required this.goals,
    required this.volumeProgression,
    required this.intensityProgression,
    this.technicalFocus = const [],
    this.adaptationTargets = const [],
  });
}

/// Mesocycle - Medium-term block (3-6 weeks)
class Mesocycle {
  final String id;
  final String name;
  final int weekNumber;
  final PhaseType phase;
  final int durationWeeks;
  final double volumeTarget;
  final double intensityTarget;
  final List<String> primaryExercises;
  final bool includesDeload;

  Mesocycle({
    required this.id,
    required this.name,
    required this.weekNumber,
    required this.phase,
    required this.durationWeeks,
    required this.volumeTarget,
    required this.intensityTarget,
    required this.primaryExercises,
    this.includesDeload = true,
  });
}

/// Microcycle - Weekly training plan
class Microcycle {
  final String id;
  final String mesocycleId;
  final int weekNumber;
  final DateTime startDate;
  final DateTime endDate;
  final PhaseType phase;
  
  // Volume and intensity for this week
  final double weeklyVolume;
  final double weeklyIntensity;
  
  // Workouts
  final List<String> trainingDays;
  final String weeklyFocus;
  final bool isDeload;
  
  // Strongman specific
  final List<StrongmanEventType>? events;

  Microcycle({
    required this.id,
    required this.mesocycleId,
    required this.weekNumber,
    required this.startDate,
    required this.endDate,
    required this.phase,
    required this.weeklyVolume,
    required this.weeklyIntensity,
    required this.trainingDays,
    required this.weeklyFocus,
    this.isDeload = false,
    this.events,
  });
}

/// Volume Progression Model
class VolumeProgression {
  final String pattern; // linear, wave, step
  final double startingVolume;
  final double peakVolume;
  final double volumeIncrement;
  final List<double> weeklyVolumes;

  VolumeProgression({
    required this.pattern,
    required this.startingVolume,
    required this.peakVolume,
    required this.volumeIncrement,
    required this.weeklyVolumes,
  });

  double getWeeklyVolume(int weekNumber) {
    if (weekNumber < weeklyVolumes.length) {
      return weeklyVolumes[weekNumber];
    }
    return peakVolume;
  }
}

/// Intensity Progression Model
class IntensityProgression {
  final String pattern; // linear, wave, step
  final double startingIntensity;
  final double peakIntensity;
  final double intensityIncrement;
  final List<double> weeklyIntensities;

  IntensityProgression({
    required this.pattern,
    required this.startingIntensity,
    required this.peakIntensity,
    required this.intensityIncrement,
    required this.weeklyIntensities,
  });

  double getWeeklyIntensity(int weekNumber) {
    if (weekNumber < weeklyIntensities.length) {
      return weeklyIntensities[weekNumber];
    }
    return peakIntensity;
  }
}

/// Sport-Specific Configuration
class SportSpecificConfig {
  final ProgramType type;
  final Map<String, dynamic> configuration;
  
  // Powerlifting
  final PowerliftingConfig? powerlifting;
  
  // Strongman
  final StrongmanConfig? strongman;
  
  // Running
  final RunningConfig? running;
  
  // Hyrox
  final HyroxConfig? hyrox;

  SportSpecificConfig({
    required this.type,
    this.configuration = const {},
    this.powerlifting,
    this.strongman,
    this.running,
    this.hyrox,
  });
}

/// Powerlifting Configuration
class PowerliftingConfig {
  final PowerliftingMethod method;
  final Map<String, double> currentMaxes; // squat, bench, deadlift
  final Map<String, List<String>> weakPoints;
  final DateTime? meetDate;
  final String? weightClass;
  final bool equipped; // Raw vs equipped

  PowerliftingConfig({
    required this.method,
    required this.currentMaxes,
    required this.weakPoints,
    this.meetDate,
    this.weightClass,
    this.equipped = false,
  });
}

/// Strongman Configuration
class StrongmanConfig {
  final List<StrongmanEventType> competitionEvents;
  final Map<StrongmanEventType, Map<String, dynamic>> eventPRs;
  final List<StrongmanEventType> weakEvents;
  final DateTime? competitionDate;
  final String competitionClass; // Amateur, Pro, etc.

  StrongmanConfig({
    required this.competitionEvents,
    required this.eventPRs,
    required this.weakEvents,
    this.competitionDate,
    required this.competitionClass,
  });
}

/// Running Configuration
class RunningConfig {
  final String goalRace; // 5K, 10K, Half, Marathon, Ultra
  final Duration goalTime;
  final Duration currentPR;
  final int weeklyMileageTarget;
  final Map<String, Duration> pacesPerMile; // easy, tempo, threshold, etc.
  final bool trailFocus;

  RunningConfig({
    required this.goalRace,
    required this.goalTime,
    required this.currentPR,
    required this.weeklyMileageTarget,
    required this.pacesPerMile,
    this.trailFocus = false,
  });
}

/// Hyrox Configuration
class HyroxConfig {
  final String division; // Men, Women, Doubles, etc.
  final Duration goalTime;
  final Duration currentBestTime;
  final Map<HyroxStationType, Duration> stationBests;
  final List<HyroxStationType> weakStations;
  final bool competitionFocus;

  HyroxConfig({
    required this.division,
    required this.goalTime,
    required this.currentBestTime,
    required this.stationBests,
    required this.weakStations,
    this.competitionFocus = false,
  });
}

/// Advanced Workout Session
class ComprehensiveWorkout {
  final String id;
  final String programId;
  final DateTime date;
  final SessionType type;
  
  // Structure
  final WarmupProtocol warmup;
  final List<MainWork> mainWork;
  final List<AccessoryWork> accessoryWork;
  final CooldownProtocol cooldown;
  
  // Intensity management
  final RPETarget rpeTarget;
  final LoadManagement loadManagement;
  
  // Time-based protocols (for HIIT/Hyrox)
  final List<TimeBasedProtocol> timeProtocols;
  
  // Completion tracking
  bool completed;
  DateTime? completedAt;
  SessionCompletionData? completionData;
  
  // Notes
  String coachNotes;
  String athleteNotes;

  ComprehensiveWorkout({
    required this.id,
    required this.programId,
    required this.date,
    required this.type,
    required this.warmup,
    required this.mainWork,
    required this.accessoryWork,
    required this.cooldown,
    required this.rpeTarget,
    required this.loadManagement,
    this.timeProtocols = const [],
    this.completed = false,
    this.completedAt,
    this.completionData,
    this.coachNotes = '',
    this.athleteNotes = '',
  });
}

/// Warmup Protocol
class WarmupProtocol {
  final List<WarmupSection> sections;
  final int totalDurationMinutes;

  WarmupProtocol({
    required this.sections,
    required this.totalDurationMinutes,
  });
}

class WarmupSection {
  final String name;
  final List<String> exercises;
  final int durationMinutes;

  WarmupSection({
    required this.name,
    required this.exercises,
    required this.durationMinutes,
  });
}

/// Main Work
class MainWork {
  final String id;
  final Exercise exercise;
  final List<WorkingSet> sets;
  
  // Advanced parameters
  final TempoScheme tempo;
  final ClusterProtocol? cluster;
  
  // Autoregulation
  final String autoregulationMethod; // RPE, RIR, Velocity
  final int rirTarget; // Reps in reserve
  
  // Performance tracking
  final Map<String, dynamic> performanceTargets;

  MainWork({
    required this.id,
    required this.exercise,
    required this.sets,
    required this.tempo,
    this.cluster,
    this.autoregulationMethod = 'RPE',
    this.rirTarget = 2,
    this.performanceTargets = const {},
  });
}

/// Working Set with Advanced Tracking
class WorkingSet {
  final String id;
  final SetType type;
  
  // Prescribed parameters
  final int targetReps;
  final double targetWeight;
  final int restSeconds;
  
  // Tempo (eccentric-pause-concentric-pause)
  final String tempo; // e.g., "3-1-1-0"
  
  // Autoregulation
  final int targetRPE; // 1-10 scale
  final int targetRIR; // Reps in reserve
  
  // Actual performance (filled during workout)
  int? actualReps;
  double? actualWeight;
  int? actualRPE;
  int? actualRIR;
  double? velocityMS; // Meters per second
  double? powerWatts;
  int? heartRate;
  
  // Form assessment
  int? formRating; // 1-10
  String? notes;
  bool completed;

  WorkingSet({
    required this.id,
    required this.type,
    required this.targetReps,
    required this.targetWeight,
    required this.restSeconds,
    this.tempo = '2-0-2-0',
    this.targetRPE = 8,
    this.targetRIR = 2,
    this.actualReps,
    this.actualWeight,
    this.actualRPE,
    this.actualRIR,
    this.velocityMS,
    this.powerWatts,
    this.heartRate,
    this.formRating,
    this.notes,
    this.completed = false,
  });
}

/// Accessory Work
class AccessoryWork {
  final String id;
  final Exercise exercise;
  final List<WorkingSet> sets;
  final String purpose; // hypertrophy, prehab, technique

  AccessoryWork({
    required this.id,
    required this.exercise,
    required this.sets,
    required this.purpose,
  });
}

/// Cooldown Protocol
class CooldownProtocol {
  final List<String> stretches;
  final int durationMinutes;
  final bool includeFoamRolling;
  final List<String> mobilityWork;

  CooldownProtocol({
    required this.stretches,
    required this.durationMinutes,
    this.includeFoamRolling = true,
    this.mobilityWork = const [],
  });
}

/// RPE Target
class RPETarget {
  final int target;
  final int minRange;
  final int maxRange;

  RPETarget({
    required this.target,
    required this.minRange,
    required this.maxRange,
  });
}

/// Load Management
class LoadManagement {
  final double weeklyTonnage;
  final double intensityDistribution; // 0-1
  final Map<String, double> liftDistribution; // % for each main lift

  LoadManagement({
    required this.weeklyTonnage,
    required this.intensityDistribution,
    required this.liftDistribution,
  });
}

/// Tempo Scheme
class TempoScheme {
  final int eccentric; // Lowering phase seconds
  final int bottomPause; // Pause at bottom seconds
  final int concentric; // Lifting phase seconds
  final int topPause; // Pause at top seconds

  TempoScheme({
    required this.eccentric,
    required this.bottomPause,
    required this.concentric,
    required this.topPause,
  });

  @override
  String toString() {
    return '$eccentric-$bottomPause-$concentric-$topPause';
  }

  factory TempoScheme.fromString(String tempo) {
    final parts = tempo.split('-').map(int.parse).toList();
    return TempoScheme(
      eccentric: parts[0],
      bottomPause: parts[1],
      concentric: parts[2],
      topPause: parts[3],
    );
  }
}

/// Cluster Protocol (rest within a set)
class ClusterProtocol {
  final int repsPerCluster;
  final int restBetweenClustersSeconds;
  final int totalClusters;

  ClusterProtocol({
    required this.repsPerCluster,
    required this.restBetweenClustersSeconds,
    required this.totalClusters,
  });
}

/// Time-Based Protocol (HIIT/EMOM/AMRAP)
class TimeBasedProtocol {
  final TimeProtocolType type;
  final int totalDurationMinutes;
  final List<TimeBasedExercise> exercises;
  final String scoringMethod; // rounds, reps, time, calories

  TimeBasedProtocol({
    required this.type,
    required this.totalDurationMinutes,
    required this.exercises,
    this.scoringMethod = 'rounds',
  });
}

class TimeBasedExercise {
  final Exercise exercise;
  final int reps;
  final String? distanceOrCalories;

  TimeBasedExercise({
    required this.exercise,
    required this.reps,
    this.distanceOrCalories,
  });
}

/// Hyrox Simulation Session
class HyroxSimulation {
  final String id;
  final String type; // training, competition, test
  final List<HyroxStation> stations;
  final Map<HyroxStationType, Duration> splitTargets;
  final Duration goalTime;
  
  // Real-time tracking
  int currentStation;
  Duration elapsedTime;
  final List<Duration> stationTimes;

  HyroxSimulation({
    required this.id,
    required this.type,
    required this.stations,
    required this.splitTargets,
    required this.goalTime,
    this.currentStation = 0,
    this.elapsedTime = Duration.zero,
    List<Duration>? stationTimes,
  }) : stationTimes = stationTimes ?? [];
}

class HyroxStation {
  final HyroxStationType type;
  final String distance;
  final int? reps;
  final double? weight;
  final Duration eliteTime;
  final Duration averageTime;
  final List<String> techniqueCues;

  HyroxStation({
    required this.type,
    required this.distance,
    this.reps,
    this.weight,
    required this.eliteTime,
    required this.averageTime,
    required this.techniqueCues,
  });
}

/// Running Workout
class RunningWorkout {
  final String id;
  final String workoutType; // Long, Tempo, Intervals, Easy
  final double totalDistanceKm;
  final List<RunningSegment> segments;
  final String terrainType; // Road, Trail, Track, Mixed
  final int elevationGainMeters;
  
  // Target zones
  final Map<String, Duration> paceTargets; // per km
  final Map<String, int> heartRateZones;

  RunningWorkout({
    required this.id,
    required this.workoutType,
    required this.totalDistanceKm,
    required this.segments,
    this.terrainType = 'Road',
    this.elevationGainMeters = 0,
    this.paceTargets = const {},
    this.heartRateZones = const {},
  });
}

class RunningSegment {
  final double distanceKm;
  final Duration targetPace; // per km
  final String intensity; // Easy, Tempo, Threshold, VO2Max, Sprint
  final int? targetHeartRate;
  final String? notes;

  RunningSegment({
    required this.distanceKm,
    required this.targetPace,
    required this.intensity,
    this.targetHeartRate,
    this.notes,
  });
}

/// Strongman Event
class StrongmanEvent {
  final String id;
  final StrongmanEventType type;
  final String name;
  
  // Event parameters
  final double? weight;
  final String? distance;
  final int? reps;
  final Duration? timeLimit;
  final bool isMaxWeight;
  final bool isMaxReps;
  
  // Technique breakdown
  final List<String> techniquePhases;
  final List<String> commonFaults;
  final List<String> drills;
  
  // Standards
  final Map<String, dynamic> competitionStandards;

  StrongmanEvent({
    required this.id,
    required this.type,
    required this.name,
    this.weight,
    this.distance,
    this.reps,
    this.timeLimit,
    this.isMaxWeight = false,
    this.isMaxReps = false,
    this.techniquePhases = const [],
    this.commonFaults = const [],
    this.drills = const [],
    this.competitionStandards = const {},
  });
}

/// Session Completion Data
class SessionCompletionData {
  final DateTime completedAt;
  final Duration totalDuration;
  final double averageRPE;
  final double totalVolumeLoad; // weight × reps
  final Map<String, dynamic> performanceMetrics;
  final List<int> formRatings;
  final String notes;
  final List<String> modifications;

  SessionCompletionData({
    required this.completedAt,
    required this.totalDuration,
    required this.averageRPE,
    required this.totalVolumeLoad,
    this.performanceMetrics = const {},
    this.formRatings = const [],
    this.notes = '',
    this.modifications = const [],
  });
}

/// Program Analytics
class ProgramAnalytics {
  final int totalWorkouts;
  final int completedWorkouts;
  final double adherenceRate;
  final double averageRPE;
  final double totalVolumeLoad;
  final Map<String, double> strengthGains;
  final List<String> recommendations;

  ProgramAnalytics({
    required this.totalWorkouts,
    required this.completedWorkouts,
    required this.adherenceRate,
    required this.averageRPE,
    required this.totalVolumeLoad,
    this.strengthGains = const {},
    this.recommendations = const [],
  });

  double get completionRate => totalWorkouts > 0 ? completedWorkouts / totalWorkouts : 0;
}

/// Performance Tracking
class PerformanceMetrics {
  // Strength
  final Map<String, double> oneRepMaxes;
  final Map<String, double> estimatedMaxes;
  
  // Power
  final double? peakPowerWatts;
  final double? averagePowerWatts;
  
  // Endurance
  final int? vo2MaxML;
  final int? thresholdHeartRate;
  final Map<String, Duration>? runningPaces;
  
  // Body composition
  final double? bodyweight;
  final double? bodyFatPercentage;
  final double? leanMass;
  
  // Recovery
  final int? hrvScore;
  final int? sleepQualityScore;
  final int? readinessScore;

  PerformanceMetrics({
    this.oneRepMaxes = const {},
    this.estimatedMaxes = const {},
    this.peakPowerWatts,
    this.averagePowerWatts,
    this.vo2MaxML,
    this.thresholdHeartRate,
    this.runningPaces,
    this.bodyweight,
    this.bodyFatPercentage,
    this.leanMass,
    this.hrvScore,
    this.sleepQualityScore,
    this.readinessScore,
  });
}

/// Autoregulation Settings
class AutoregulationSettings {
  final bool enabled;
  final String method; // RPE, RIR, Velocity, HRV
  final Map<String, dynamic> parameters;
  
  // RPE/RIR based
  final int? targetRPE;
  final int? targetRIR;
  
  // Velocity based
  final double? velocityThreshold;
  final double? maxVelocityLoss;
  
  // HRV based
  final bool? useHRVGuidance;
  final Map<String, String>? hrvRecommendations;

  AutoregulationSettings({
    this.enabled = true,
    this.method = 'RPE',
    this.parameters = const {},
    this.targetRPE,
    this.targetRIR,
    this.velocityThreshold,
    this.maxVelocityLoss,
    this.useHRVGuidance,
    this.hrvRecommendations,
  });
}

/// Helper Classes
class PerformanceTarget {
  final String metric;
  final double target;
  final String unit;

  PerformanceTarget({
    required this.metric,
    required this.target,
    required this.unit,
  });
}

class TrainingGoal {
  static const String strength = 'strength';
  static const String hypertrophy = 'hypertrophy';
  static const String power = 'power';
  static const String endurance = 'endurance';
  static const String weightLoss = 'weight_loss';
  static const String athleticPerformance = 'athletic_performance';
}

class ExperienceLevel {
  static const String beginner = 'beginner';
  static const String intermediate = 'intermediate';
  static const String advanced = 'advanced';
  static const String elite = 'elite';
}

