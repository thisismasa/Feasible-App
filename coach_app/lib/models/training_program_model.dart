/// Core training program model that supports multiple methodologies
class TrainingProgramModel {
  final String id;
  final String name;
  final String description;
  final String createdBy; // Trainer ID
  final String? assignedTo; // Client ID (null for templates)
  final TrainingMethodology methodology;
  final ProgramStatus status;
  final DateTime startDate;
  final DateTime endDate;
  final int durationWeeks;
  final int sessionsPerWeek;
  final Map<String, dynamic> methodologySettings;
  final List<TrainingPhase> phases;
  final Map<String, dynamic> progressionRules;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isTemplate;
  final Map<String, dynamic>? analytics;

  TrainingProgramModel({
    required this.id,
    required this.name,
    required this.description,
    required this.createdBy,
    this.assignedTo,
    required this.methodology,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.durationWeeks,
    required this.sessionsPerWeek,
    required this.methodologySettings,
    required this.phases,
    required this.progressionRules,
    required this.createdAt,
    this.updatedAt,
    this.isTemplate = false,
    this.analytics,
  });

  factory TrainingProgramModel.fromMap(Map<String, dynamic> map, String id) {
    return TrainingProgramModel(
      id: id,
      name: map['name'],
      description: map['description'],
      createdBy: map['createdBy'],
      assignedTo: map['assignedTo'],
      methodology: TrainingMethodology.values.firstWhere(
        (e) => e.name == map['methodology'],
        orElse: () => TrainingMethodology.general,
      ),
      status: ProgramStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => ProgramStatus.draft,
      ),
      startDate: map['startDate'] is String
          ? DateTime.parse(map['startDate'])
          : DateTime.now(),
      endDate: map['endDate'] is String
          ? DateTime.parse(map['endDate'])
          : DateTime.now().add(Duration(days: 7)),
      durationWeeks: map['durationWeeks'],
      sessionsPerWeek: map['sessionsPerWeek'],
      methodologySettings: map['methodologySettings'] ?? {},
      phases: (map['phases'] as List<dynamic>)
          .map((p) => TrainingPhase.fromMap(p))
          .toList(),
      progressionRules: map['progressionRules'] ?? {},
      createdAt: map['createdAt'] is String
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null && map['updatedAt'] is String
          ? DateTime.parse(map['updatedAt'])
          : null,
      isTemplate: map['isTemplate'] ?? false,
      analytics: map['analytics'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'createdBy': createdBy,
      'assignedTo': assignedTo,
      'methodology': methodology.name,
      'status': status.name,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'durationWeeks': durationWeeks,
      'sessionsPerWeek': sessionsPerWeek,
      'methodologySettings': methodologySettings,
      'phases': phases.map((p) => p.toMap()).toList(),
      'progressionRules': progressionRules,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'isTemplate': isTemplate,
      'analytics': analytics,
    };
  }
}

/// Training methodologies supported
enum TrainingMethodology {
  general,
  strengthMethod, // Westside Barbell style
  rpe, // Rate of Perceived Exertion
  hyrox,
  crossfit,
  calisthenics,
  powerlifting,
  strongman,
  bodybuilding,
  hybrid, // Mix of methodologies
}

enum ProgramStatus {
  draft,
  active,
  completed,
  paused,
  archived,
}

/// Training phase (mesocycle)
class TrainingPhase {
  final String name;
  final int weekNumber;
  final int duration; // weeks
  final PhaseType type;
  final Map<String, dynamic> goals;
  final List<TrainingWeek> weeks;
  final Map<String, dynamic>? phaseSettings;

  TrainingPhase({
    required this.name,
    required this.weekNumber,
    required this.duration,
    required this.type,
    required this.goals,
    required this.weeks,
    this.phaseSettings,
  });

  factory TrainingPhase.fromMap(Map<String, dynamic> map) {
    return TrainingPhase(
      name: map['name'],
      weekNumber: map['weekNumber'],
      duration: map['duration'],
      type: PhaseType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => PhaseType.general,
      ),
      goals: map['goals'] ?? {},
      weeks: (map['weeks'] as List<dynamic>)
          .map((w) => TrainingWeek.fromMap(w))
          .toList(),
      phaseSettings: map['phaseSettings'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'weekNumber': weekNumber,
      'duration': duration,
      'type': type.name,
      'goals': goals,
      'weeks': weeks.map((w) => w.toMap()).toList(),
      'phaseSettings': phaseSettings,
    };
  }
}

enum PhaseType {
  general,
  accumulation,
  intensification,
  realization,
  deload,
  taper,
  competition,
  maxStrength,
  hypertrophy,
  power,
  endurance,
  skill,
  testing,
}

/// Training week
class TrainingWeek {
  final int weekNumber;
  final WeekType type;
  final List<TrainingDay> days;
  final Map<String, dynamic>? weekSettings;
  final String? notes;

  TrainingWeek({
    required this.weekNumber,
    required this.type,
    required this.days,
    this.weekSettings,
    this.notes,
  });

  factory TrainingWeek.fromMap(Map<String, dynamic> map) {
    return TrainingWeek(
      weekNumber: map['weekNumber'],
      type: WeekType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => WeekType.regular,
      ),
      days: (map['days'] as List<dynamic>)
          .map((d) => TrainingDay.fromMap(d))
          .toList(),
      weekSettings: map['weekSettings'],
      notes: map['notes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'weekNumber': weekNumber,
      'type': type.name,
      'days': days.map((d) => d.toMap()).toList(),
      'weekSettings': weekSettings,
      'notes': notes,
    };
  }
}

enum WeekType {
  regular,
  deload,
  taper,
  peak,
  testing,
  competition,
  recovery,
}

/// Training day
class TrainingDay {
  final int dayNumber;
  final String name;
  final DayType type;
  final List<Workout> workouts;
  final List<String>? focusAreas;
  final Map<String, dynamic>? daySettings;
  final String? notes;

  TrainingDay({
    required this.dayNumber,
    required this.name,
    required this.type,
    required this.workouts,
    this.focusAreas,
    this.daySettings,
    this.notes,
  });

  factory TrainingDay.fromMap(Map<String, dynamic> map) {
    return TrainingDay(
      dayNumber: map['dayNumber'],
      name: map['name'],
      type: DayType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => DayType.training,
      ),
      workouts: (map['workouts'] as List<dynamic>)
          .map((w) => Workout.fromMap(w))
          .toList(),
      focusAreas: map['focusAreas'] != null
          ? List<String>.from(map['focusAreas'])
          : null,
      daySettings: map['daySettings'],
      notes: map['notes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'dayNumber': dayNumber,
      'name': name,
      'type': type.name,
      'workouts': workouts.map((w) => w.toMap()).toList(),
      'focusAreas': focusAreas,
      'daySettings': daySettings,
      'notes': notes,
    };
  }
}

enum DayType {
  training,
  rest,
  activeRecovery,
  competition,
  testing,
  technique,
  conditioning,
}

/// Workout within a training day
class Workout {
  final String id;
  final String name;
  final WorkoutType type;
  final List<Exercise> exercises;
  final Map<String, dynamic>? workoutSettings;
  final String? notes;
  final int? targetDuration; // minutes
  final String? intensityGuidelines;

  Workout({
    required this.id,
    required this.name,
    required this.type,
    required this.exercises,
    this.workoutSettings,
    this.notes,
    this.targetDuration,
    this.intensityGuidelines,
  });

  factory Workout.fromMap(Map<String, dynamic> map) {
    return Workout(
      id: map['id'],
      name: map['name'],
      type: WorkoutType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => WorkoutType.standard,
      ),
      exercises: (map['exercises'] as List<dynamic>)
          .map((e) => Exercise.fromMap(e))
          .toList(),
      workoutSettings: map['workoutSettings'],
      notes: map['notes'],
      targetDuration: map['targetDuration'],
      intensityGuidelines: map['intensityGuidelines'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'exercises': exercises.map((e) => e.toMap()).toList(),
      'workoutSettings': workoutSettings,
      'notes': notes,
      'targetDuration': targetDuration,
      'intensityGuidelines': intensityGuidelines,
    };
  }
}

enum WorkoutType {
  standard,
  wod, // Workout of the Day (CrossFit)
  amrap, // As Many Rounds As Possible
  emom, // Every Minute On the Minute
  forTime,
  chipper,
  ladder,
  circuit,
  supersets,
  giantSets,
  clusters,
  waves,
  maxEffort, // Strength Method
  dynamicEffort, // Strength Method
  repetitionEffort, // Strength Method
  event, // Strongman
  skill, // Calisthenics
}

/// Individual exercise
class Exercise {
  final String id;
  final String name;
  final ExerciseCategory category;
  final List<ExerciseSet> sets;
  final RestPeriod? rest;
  final String? tempo;
  final RPE? targetRPE;
  final double? percentageOf1RM;
  final String? equipment;
  final String? notes;
  final Map<String, dynamic>? techniqueCues;
  final List<String>? alternatives;
  final ProgressionLevel? progressionLevel;

  Exercise({
    required this.id,
    required this.name,
    required this.category,
    required this.sets,
    this.rest,
    this.tempo,
    this.targetRPE,
    this.percentageOf1RM,
    this.equipment,
    this.notes,
    this.techniqueCues,
    this.alternatives,
    this.progressionLevel,
  });

  factory Exercise.fromMap(Map<String, dynamic> map) {
    return Exercise(
      id: map['id'],
      name: map['name'],
      category: ExerciseCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => ExerciseCategory.compound,
      ),
      sets: (map['sets'] as List<dynamic>)
          .map((s) => ExerciseSet.fromMap(s))
          .toList(),
      rest: map['rest'] != null ? RestPeriod.fromMap(map['rest']) : null,
      tempo: map['tempo'],
      targetRPE: map['targetRPE'] != null ? RPE.fromMap(map['targetRPE']) : null,
      percentageOf1RM: map['percentageOf1RM']?.toDouble(),
      equipment: map['equipment'],
      notes: map['notes'],
      techniqueCues: map['techniqueCues'],
      alternatives: map['alternatives'] != null
          ? List<String>.from(map['alternatives'])
          : null,
      progressionLevel: map['progressionLevel'] != null
          ? ProgressionLevel.fromMap(map['progressionLevel'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category.name,
      'sets': sets.map((s) => s.toMap()).toList(),
      'rest': rest?.toMap(),
      'tempo': tempo,
      'targetRPE': targetRPE?.toMap(),
      'percentageOf1RM': percentageOf1RM,
      'equipment': equipment,
      'notes': notes,
      'techniqueCues': techniqueCues,
      'alternatives': alternatives,
      'progressionLevel': progressionLevel?.toMap(),
    };
  }
}

enum ExerciseCategory {
  compound,
  isolation,
  olympic,
  power,
  plyometric,
  cardio,
  flexibility,
  skill,
  event, // Strongman events
  station, // Hyrox stations
  gymnastics, // Calisthenics
  accessory,
  core,
  warmup,
  cooldown,
}

/// Exercise set configuration
class ExerciseSet {
  final int setNumber;
  final SetType type;
  final int? reps;
  final int? time; // seconds
  final double? distance; // meters
  final double? weight; // kg
  final String? intensity;
  final Map<String, dynamic>? additionalParams;

  ExerciseSet({
    required this.setNumber,
    required this.type,
    this.reps,
    this.time,
    this.distance,
    this.weight,
    this.intensity,
    this.additionalParams,
  });

  factory ExerciseSet.fromMap(Map<String, dynamic> map) {
    return ExerciseSet(
      setNumber: map['setNumber'],
      type: SetType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => SetType.standard,
      ),
      reps: map['reps'],
      time: map['time'],
      distance: map['distance']?.toDouble(),
      weight: map['weight']?.toDouble(),
      intensity: map['intensity'],
      additionalParams: map['additionalParams'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'setNumber': setNumber,
      'type': type.name,
      'reps': reps,
      'time': time,
      'distance': distance,
      'weight': weight,
      'intensity': intensity,
      'additionalParams': additionalParams,
    };
  }
}

enum SetType {
  standard,
  warmup,
  working,
  dropSet,
  restPause,
  cluster,
  myo,
  isometric,
  eccentric,
  concentric,
  amrap,
  emom,
  maxEffort,
  speedWork,
}

/// Rest period configuration
class RestPeriod {
  final int minSeconds;
  final int maxSeconds;
  final RestType type;

  RestPeriod({
    required this.minSeconds,
    required this.maxSeconds,
    required this.type,
  });

  factory RestPeriod.fromMap(Map<String, dynamic> map) {
    return RestPeriod(
      minSeconds: map['minSeconds'],
      maxSeconds: map['maxSeconds'],
      type: RestType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => RestType.standard,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'minSeconds': minSeconds,
      'maxSeconds': maxSeconds,
      'type': type.name,
    };
  }
}

enum RestType {
  standard,
  active,
  complete,
  minimal,
  autoRegulated,
}

/// RPE (Rate of Perceived Exertion) configuration
class RPE {
  final double value; // 1-10 scale
  final int? repsInReserve; // RIR
  final String? description;

  RPE({
    required this.value,
    this.repsInReserve,
    this.description,
  });

  factory RPE.fromMap(Map<String, dynamic> map) {
    return RPE(
      value: map['value'].toDouble(),
      repsInReserve: map['repsInReserve'],
      description: map['description'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'value': value,
      'repsInReserve': repsInReserve,
      'description': description,
    };
  }
}

/// Progression level for calisthenics/skill work
class ProgressionLevel {
  final String name;
  final int level;
  final List<String> prerequisites;
  final String? nextProgression;

  ProgressionLevel({
    required this.name,
    required this.level,
    required this.prerequisites,
    this.nextProgression,
  });

  factory ProgressionLevel.fromMap(Map<String, dynamic> map) {
    return ProgressionLevel(
      name: map['name'],
      level: map['level'],
      prerequisites: List<String>.from(map['prerequisites']),
      nextProgression: map['nextProgression'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'level': level,
      'prerequisites': prerequisites,
      'nextProgression': nextProgression,
    };
  }
}