import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/training_program_model.dart';
import '../models/methodology_models.dart';
import 'package:uuid/uuid.dart';

class TrainingProgramService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  /// Create a new training program
  Future<String> createProgram({
    required String name,
    required String description,
    required String createdBy,
    String? assignedTo,
    required TrainingMethodology methodology,
    required DateTime startDate,
    required int durationWeeks,
    required int sessionsPerWeek,
    required Map<String, dynamic> methodologySettings,
    bool isTemplate = false,
  }) async {
    try {
      final programId = _uuid.v4();
      final endDate = startDate.add(Duration(days: durationWeeks * 7));

      // Generate phases based on methodology and duration
      final phases = _generatePhases(
        methodology: methodology,
        durationWeeks: durationWeeks,
        sessionsPerWeek: sessionsPerWeek,
        methodologySettings: methodologySettings,
      );

      // Generate progression rules
      final progressionRules = _generateProgressionRules(
        methodology: methodology,
        methodologySettings: methodologySettings,
      );

      final program = TrainingProgramModel(
        id: programId,
        name: name,
        description: description,
        createdBy: createdBy,
        assignedTo: assignedTo,
        methodology: methodology,
        status: ProgramStatus.draft,
        startDate: startDate,
        endDate: endDate,
        durationWeeks: durationWeeks,
        sessionsPerWeek: sessionsPerWeek,
        methodologySettings: methodologySettings,
        phases: phases,
        progressionRules: progressionRules,
        createdAt: DateTime.now(),
        isTemplate: isTemplate,
      );

      await _firestore.collection('training_programs').doc(programId).set(
        program.toMap(),
      );

      return programId;
    } catch (e) {
      throw Exception('Failed to create training program: $e');
    }
  }

  /// Generate phases based on methodology
  List<TrainingPhase> _generatePhases({
    required TrainingMethodology methodology,
    required int durationWeeks,
    required int sessionsPerWeek,
    required Map<String, dynamic> methodologySettings,
  }) {
    switch (methodology) {
      case TrainingMethodology.strengthMethod:
        return _generateStrengthMethodPhases(durationWeeks, sessionsPerWeek, methodologySettings);
      case TrainingMethodology.powerlifting:
        return _generatePowerliftingPhases(durationWeeks, sessionsPerWeek, methodologySettings);
      case TrainingMethodology.hyrox:
        return _generateHyroxPhases(durationWeeks, sessionsPerWeek, methodologySettings);
      case TrainingMethodology.crossfit:
        return _generateCrossFitPhases(durationWeeks, sessionsPerWeek, methodologySettings);
      case TrainingMethodology.calisthenics:
        return _generateCalisthenicsPhases(durationWeeks, sessionsPerWeek, methodologySettings);
      case TrainingMethodology.strongman:
        return _generateStrongmanPhases(durationWeeks, sessionsPerWeek, methodologySettings);
      case TrainingMethodology.rpe:
        return _generateRPEPhases(durationWeeks, sessionsPerWeek, methodologySettings);
      default:
        return _generateGeneralPhases(durationWeeks, sessionsPerWeek);
    }
  }

  /// Generate Strength Method phases (Westside Barbell style)
  List<TrainingPhase> _generateStrengthMethodPhases(
    int durationWeeks,
    int sessionsPerWeek,
    Map<String, dynamic> settings,
  ) {
    List<TrainingPhase> phases = [];
    int weeksPerPhase = 3; // 3-week waves
    int currentWeek = 1;

    while (currentWeek <= durationWeeks) {
      int phaseDuration = min(weeksPerPhase, durationWeeks - currentWeek + 1);

      phases.add(TrainingPhase(
        name: 'Wave ${phases.length + 1}',
        weekNumber: currentWeek,
        duration: phaseDuration,
        type: PhaseType.intensification,
        goals: {
          'maxEffort': 'Work up to 90-100% on ME days',
          'dynamicEffort': 'Maintain 50-60% with bands/chains',
          'repetitionEffort': 'Build muscle mass and address weak points',
        },
        weeks: _generateStrengthMethodWeeks(currentWeek, phaseDuration, sessionsPerWeek),
      ));

      currentWeek += phaseDuration;

      // Add deload week every 4th week
      if (currentWeek <= durationWeeks && phases.length % 4 == 3) {
        phases.add(TrainingPhase(
          name: 'Deload',
          weekNumber: currentWeek,
          duration: 1,
          type: PhaseType.deload,
          goals: {
            'recovery': 'Reduce volume by 40-50%',
            'technique': 'Focus on movement quality',
          },
          weeks: _generateDeloadWeek(currentWeek, sessionsPerWeek),
        ));
        currentWeek++;
      }
    }

    return phases;
  }

  /// Generate Strength Method training weeks
  List<TrainingWeek> _generateStrengthMethodWeeks(int startWeek, int duration, int sessionsPerWeek) {
    List<TrainingWeek> weeks = [];

    for (int i = 0; i < duration; i++) {
      List<TrainingDay> days = [];

      // Max Effort Lower
      days.add(TrainingDay(
        dayNumber: 1,
        name: 'Max Effort Lower',
        type: DayType.training,
        focusAreas: ['Squat', 'Deadlift', 'Lower Body'],
        workouts: [
          Workout(
            id: _uuid.v4(),
            name: 'ME Lower Body',
            type: WorkoutType.maxEffort,
            exercises: _generateMaxEffortLowerExercises(startWeek + i),
          ),
        ],
      ));

      // Max Effort Upper
      days.add(TrainingDay(
        dayNumber: 2,
        name: 'Max Effort Upper',
        type: DayType.training,
        focusAreas: ['Bench Press', 'Upper Body'],
        workouts: [
          Workout(
            id: _uuid.v4(),
            name: 'ME Upper Body',
            type: WorkoutType.maxEffort,
            exercises: _generateMaxEffortUpperExercises(startWeek + i),
          ),
        ],
      ));

      // Dynamic Effort Lower
      days.add(TrainingDay(
        dayNumber: 3,
        name: 'Dynamic Effort Lower',
        type: DayType.training,
        focusAreas: ['Speed', 'Power', 'Lower Body'],
        workouts: [
          Workout(
            id: _uuid.v4(),
            name: 'DE Lower Body',
            type: WorkoutType.dynamicEffort,
            exercises: _generateDynamicEffortLowerExercises(startWeek + i),
          ),
        ],
      ));

      // Dynamic Effort Upper
      days.add(TrainingDay(
        dayNumber: 4,
        name: 'Dynamic Effort Upper',
        type: DayType.training,
        focusAreas: ['Speed', 'Power', 'Upper Body'],
        workouts: [
          Workout(
            id: _uuid.v4(),
            name: 'DE Upper Body',
            type: WorkoutType.dynamicEffort,
            exercises: _generateDynamicEffortUpperExercises(startWeek + i),
          ),
        ],
      ));

      // Add recovery days
      if (sessionsPerWeek < 7) {
        for (int j = days.length + 1; j <= 7; j++) {
          days.add(TrainingDay(
            dayNumber: j,
            name: 'Recovery',
            type: DayType.activeRecovery,
            workouts: [],
            notes: 'Light cardio, stretching, mobility work',
          ));
        }
      }

      weeks.add(TrainingWeek(
        weekNumber: startWeek + i,
        type: WeekType.regular,
        days: days,
        weekSettings: {
          'waveWeek': (i % 3) + 1,
          'intensity': [50, 55, 60][i % 3], // Dynamic effort percentages
        },
      ));
    }

    return weeks;
  }

  /// Generate Max Effort Lower exercises
  List<Exercise> _generateMaxEffortLowerExercises(int weekNumber) {
    // Rotate main movements every 1-3 weeks
    final mainMovements = [
      'Low Box Squat',
      'Floor Press Deadlift',
      'Good Morning',
      'Front Squat',
      'Sumo Deadlift',
      'Safety Squat Bar Squat',
    ];

    final mainMovement = mainMovements[weekNumber % mainMovements.length];

    return [
      Exercise(
        id: _uuid.v4(),
        name: mainMovement,
        category: ExerciseCategory.compound,
        sets: [
          ExerciseSet(setNumber: 1, type: SetType.warmup, reps: 5, weight: 50),
          ExerciseSet(setNumber: 2, type: SetType.warmup, reps: 3, weight: 60),
          ExerciseSet(setNumber: 3, type: SetType.warmup, reps: 1, weight: 70),
          ExerciseSet(setNumber: 4, type: SetType.warmup, reps: 1, weight: 80),
          ExerciseSet(setNumber: 5, type: SetType.working, reps: 1, weight: 90),
          ExerciseSet(setNumber: 6, type: SetType.maxEffort, reps: 1, weight: 95),
          ExerciseSet(setNumber: 7, type: SetType.maxEffort, reps: 1, weight: 100),
        ],
        rest: RestPeriod(minSeconds: 180, maxSeconds: 300, type: RestType.complete),
        percentageOf1RM: 100,
        notes: 'Work up to a max single. Stop if form breaks down.',
      ),
      Exercise(
        id: _uuid.v4(),
        name: 'Belt Squat',
        category: ExerciseCategory.compound,
        sets: List.generate(4, (i) => ExerciseSet(
          setNumber: i + 1,
          type: SetType.working,
          reps: 12,
        )),
        rest: RestPeriod(minSeconds: 90, maxSeconds: 120, type: RestType.standard),
      ),
      Exercise(
        id: _uuid.v4(),
        name: 'Reverse Hyper',
        category: ExerciseCategory.accessory,
        sets: List.generate(4, (i) => ExerciseSet(
          setNumber: i + 1,
          type: SetType.working,
          reps: 25,
        )),
        rest: RestPeriod(minSeconds: 60, maxSeconds: 90, type: RestType.standard),
      ),
      Exercise(
        id: _uuid.v4(),
        name: 'Abs Circuit',
        category: ExerciseCategory.core,
        sets: List.generate(3, (i) => ExerciseSet(
          setNumber: i + 1,
          type: SetType.working,
          time: 60,
        )),
        rest: RestPeriod(minSeconds: 60, maxSeconds: 60, type: RestType.minimal),
      ),
    ];
  }

  /// Generate Max Effort Upper exercises
  List<Exercise> _generateMaxEffortUpperExercises(int weekNumber) {
    final mainMovements = [
      'Floor Press',
      'Close Grip Bench Press',
      '2-Board Press',
      'Incline Barbell Press',
      'Slingshot Bench Press',
      'Reverse Band Bench Press',
    ];

    final mainMovement = mainMovements[weekNumber % mainMovements.length];

    return [
      Exercise(
        id: _uuid.v4(),
        name: mainMovement,
        category: ExerciseCategory.compound,
        sets: [
          ExerciseSet(setNumber: 1, type: SetType.warmup, reps: 5, weight: 50),
          ExerciseSet(setNumber: 2, type: SetType.warmup, reps: 3, weight: 60),
          ExerciseSet(setNumber: 3, type: SetType.warmup, reps: 1, weight: 70),
          ExerciseSet(setNumber: 4, type: SetType.warmup, reps: 1, weight: 80),
          ExerciseSet(setNumber: 5, type: SetType.working, reps: 1, weight: 90),
          ExerciseSet(setNumber: 6, type: SetType.maxEffort, reps: 1, weight: 95),
          ExerciseSet(setNumber: 7, type: SetType.maxEffort, reps: 1, weight: 100),
        ],
        rest: RestPeriod(minSeconds: 180, maxSeconds: 300, type: RestType.complete),
        percentageOf1RM: 100,
      ),
      Exercise(
        id: _uuid.v4(),
        name: 'JM Press',
        category: ExerciseCategory.accessory,
        sets: List.generate(4, (i) => ExerciseSet(
          setNumber: i + 1,
          type: SetType.working,
          reps: 15,
        )),
        rest: RestPeriod(minSeconds: 90, maxSeconds: 120, type: RestType.standard),
      ),
      Exercise(
        id: _uuid.v4(),
        name: 'Barbell Row',
        category: ExerciseCategory.compound,
        sets: List.generate(4, (i) => ExerciseSet(
          setNumber: i + 1,
          type: SetType.working,
          reps: 10,
        )),
        rest: RestPeriod(minSeconds: 90, maxSeconds: 120, type: RestType.standard),
      ),
      Exercise(
        id: _uuid.v4(),
        name: 'Face Pulls',
        category: ExerciseCategory.accessory,
        sets: List.generate(4, (i) => ExerciseSet(
          setNumber: i + 1,
          type: SetType.working,
          reps: 20,
        )),
        rest: RestPeriod(minSeconds: 60, maxSeconds: 90, type: RestType.standard),
      ),
    ];
  }

  /// Generate Dynamic Effort Lower exercises
  List<Exercise> _generateDynamicEffortLowerExercises(int weekNumber) {
    final waveWeek = (weekNumber % 3) + 1;
    final percentage = [50, 55, 60][waveWeek - 1];

    return [
      Exercise(
        id: _uuid.v4(),
        name: 'Box Squat with Bands',
        category: ExerciseCategory.power,
        sets: List.generate(10, (i) => ExerciseSet(
          setNumber: i + 1,
          type: SetType.speedWork,
          reps: 2,
          weight: percentage.toDouble(),
          additionalParams: {
            'bandTension': '25% at top',
            'boxHeight': '1 inch below parallel',
          },
        )),
        rest: RestPeriod(minSeconds: 45, maxSeconds: 60, type: RestType.minimal),
        percentageOf1RM: percentage.toDouble(),
        equipment: 'Bands, Box',
        notes: 'Focus on speed off the box. 0.8-1.0 m/s bar speed.',
      ),
      Exercise(
        id: _uuid.v4(),
        name: 'Speed Deadlifts',
        category: ExerciseCategory.power,
        sets: List.generate(6, (i) => ExerciseSet(
          setNumber: i + 1,
          type: SetType.speedWork,
          reps: 1,
          weight: 60,
        )),
        rest: RestPeriod(minSeconds: 60, maxSeconds: 90, type: RestType.standard),
        percentageOf1RM: 60,
      ),
      Exercise(
        id: _uuid.v4(),
        name: 'Walking Lunges',
        category: ExerciseCategory.accessory,
        sets: List.generate(3, (i) => ExerciseSet(
          setNumber: i + 1,
          type: SetType.working,
          reps: 20,
        )),
        rest: RestPeriod(minSeconds: 90, maxSeconds: 120, type: RestType.standard),
      ),
      Exercise(
        id: _uuid.v4(),
        name: 'GHR',
        category: ExerciseCategory.accessory,
        sets: List.generate(4, (i) => ExerciseSet(
          setNumber: i + 1,
          type: SetType.working,
          reps: 15,
        )),
        rest: RestPeriod(minSeconds: 60, maxSeconds: 90, type: RestType.standard),
      ),
    ];
  }

  /// Generate Dynamic Effort Upper exercises
  List<Exercise> _generateDynamicEffortUpperExercises(int weekNumber) {
    final waveWeek = (weekNumber % 3) + 1;
    final percentage = [50, 55, 60][waveWeek - 1];

    return [
      Exercise(
        id: _uuid.v4(),
        name: 'Speed Bench with Bands',
        category: ExerciseCategory.power,
        sets: List.generate(9, (i) => ExerciseSet(
          setNumber: i + 1,
          type: SetType.speedWork,
          reps: 3,
          weight: percentage.toDouble(),
          additionalParams: {
            'bandTension': '25% at lockout',
            'grip': i < 3 ? 'close' : i < 6 ? 'medium' : 'wide',
          },
        )),
        rest: RestPeriod(minSeconds: 45, maxSeconds: 60, type: RestType.minimal),
        percentageOf1RM: percentage.toDouble(),
        equipment: 'Bands',
        notes: 'Explosive press. Control descent.',
      ),
      Exercise(
        id: _uuid.v4(),
        name: 'Overhead Press',
        category: ExerciseCategory.compound,
        sets: List.generate(4, (i) => ExerciseSet(
          setNumber: i + 1,
          type: SetType.working,
          reps: 8,
        )),
        rest: RestPeriod(minSeconds: 90, maxSeconds: 120, type: RestType.standard),
      ),
      Exercise(
        id: _uuid.v4(),
        name: 'Dumbbell Row',
        category: ExerciseCategory.accessory,
        sets: List.generate(4, (i) => ExerciseSet(
          setNumber: i + 1,
          type: SetType.working,
          reps: 12,
        )),
        rest: RestPeriod(minSeconds: 60, maxSeconds: 90, type: RestType.standard),
      ),
      Exercise(
        id: _uuid.v4(),
        name: 'Tricep Extensions',
        category: ExerciseCategory.isolation,
        sets: List.generate(4, (i) => ExerciseSet(
          setNumber: i + 1,
          type: SetType.working,
          reps: 20,
        )),
        rest: RestPeriod(minSeconds: 60, maxSeconds: 60, type: RestType.minimal),
      ),
    ];
  }

  /// Generate Powerlifting phases
  List<TrainingPhase> _generatePowerliftingPhases(
    int durationWeeks,
    int sessionsPerWeek,
    Map<String, dynamic> settings,
  ) {
    List<TrainingPhase> phases = [];

    // Determine periodization model
    final periodizationType = settings['periodization'] ?? 'block';

    if (periodizationType == 'block') {
      // Block Periodization
      int remainingWeeks = durationWeeks;

      // Accumulation Phase (40% of program)
      int accumulationWeeks = (durationWeeks * 0.4).round();
      if (accumulationWeeks > 0 && remainingWeeks > 0) {
        phases.add(TrainingPhase(
          name: 'Accumulation',
          weekNumber: 1,
          duration: min(accumulationWeeks, remainingWeeks),
          type: PhaseType.accumulation,
          goals: {
            'volume': 'High volume, moderate intensity',
            'hypertrophy': 'Build muscle mass',
            'workCapacity': 'Increase work capacity',
          },
          weeks: _generatePowerliftingWeeks(
            1,
            min(accumulationWeeks, remainingWeeks),
            sessionsPerWeek,
            'accumulation',
          ),
        ));
        remainingWeeks -= accumulationWeeks;
      }

      // Intensification Phase (30% of program)
      int intensificationWeeks = (durationWeeks * 0.3).round();
      if (intensificationWeeks > 0 && remainingWeeks > 0) {
        phases.add(TrainingPhase(
          name: 'Intensification',
          weekNumber: phases.last.weekNumber + phases.last.duration,
          duration: min(intensificationWeeks, remainingWeeks),
          type: PhaseType.intensification,
          goals: {
            'strength': 'Increase maximal strength',
            'technique': 'Perfect competition lifts',
          },
          weeks: _generatePowerliftingWeeks(
            phases.last.weekNumber + phases.last.duration,
            min(intensificationWeeks, remainingWeeks),
            sessionsPerWeek,
            'intensification',
          ),
        ));
        remainingWeeks -= intensificationWeeks;
      }

      // Realization/Peak Phase (20% of program)
      int realizationWeeks = (durationWeeks * 0.2).round();
      if (realizationWeeks > 0 && remainingWeeks > 0) {
        phases.add(TrainingPhase(
          name: 'Realization',
          weekNumber: phases.last.weekNumber + phases.last.duration,
          duration: min(realizationWeeks, remainingWeeks),
          type: PhaseType.realization,
          goals: {
            'peak': 'Peak for competition',
            'openers': 'Establish opening attempts',
          },
          weeks: _generatePowerliftingWeeks(
            phases.last.weekNumber + phases.last.duration,
            min(realizationWeeks, remainingWeeks),
            sessionsPerWeek,
            'realization',
          ),
        ));
        remainingWeeks -= realizationWeeks;
      }

      // Taper/Competition Week (10% of program)
      if (remainingWeeks > 0) {
        phases.add(TrainingPhase(
          name: 'Competition',
          weekNumber: phases.last.weekNumber + phases.last.duration,
          duration: remainingWeeks,
          type: PhaseType.competition,
          goals: {
            'recovery': 'Full recovery',
            'competition': 'Competition or testing',
          },
          weeks: _generatePowerliftingWeeks(
            phases.last.weekNumber + phases.last.duration,
            remainingWeeks,
            sessionsPerWeek,
            'competition',
          ),
        ));
      }
    }

    return phases;
  }

  /// Generate Powerlifting training weeks
  List<TrainingWeek> _generatePowerliftingWeeks(
    int startWeek,
    int duration,
    int sessionsPerWeek,
    String phaseType,
  ) {
    List<TrainingWeek> weeks = [];

    for (int i = 0; i < duration; i++) {
      List<TrainingDay> days = [];

      if (sessionsPerWeek >= 4) {
        // 4-day split
        days.add(_generatePowerliftingDay('Squat', 1, phaseType, startWeek + i));
        days.add(_generatePowerliftingDay('Bench', 2, phaseType, startWeek + i));
        days.add(_generatePowerliftingDay('Deadlift', 3, phaseType, startWeek + i));
        days.add(_generatePowerliftingDay('Accessories', 4, phaseType, startWeek + i));
      } else if (sessionsPerWeek == 3) {
        // 3-day split
        days.add(_generatePowerliftingDay('Squat', 1, phaseType, startWeek + i));
        days.add(_generatePowerliftingDay('Bench', 2, phaseType, startWeek + i));
        days.add(_generatePowerliftingDay('Deadlift', 3, phaseType, startWeek + i));
      }

      // Add rest days
      for (int j = days.length + 1; j <= 7; j++) {
        days.add(TrainingDay(
          dayNumber: j,
          name: 'Rest',
          type: DayType.rest,
          workouts: [],
        ));
      }

      weeks.add(TrainingWeek(
        weekNumber: startWeek + i,
        type: phaseType == 'competition' && i == duration - 1
          ? WeekType.competition
          : WeekType.regular,
        days: days,
      ));
    }

    return weeks;
  }

  /// Generate a powerlifting training day
  TrainingDay _generatePowerliftingDay(String focus, int dayNumber, String phaseType, int weekNumber) {
    List<Exercise> exercises = [];

    // Adjust intensity and volume based on phase
    double intensity;
    int volume;

    switch (phaseType) {
      case 'accumulation':
        intensity = 65 + (weekNumber % 4) * 5; // 65-80%
        volume = 5; // Higher rep ranges
        break;
      case 'intensification':
        intensity = 75 + (weekNumber % 4) * 5; // 75-90%
        volume = 3; // Medium rep ranges
        break;
      case 'realization':
        intensity = 85 + (weekNumber % 3) * 5; // 85-95%
        volume = 2; // Low rep ranges
        break;
      case 'competition':
        intensity = 70; // Opener work
        volume = 1; // Singles only
        break;
      default:
        intensity = 75;
        volume = 3;
    }

    switch (focus) {
      case 'Squat':
        exercises = [
          Exercise(
            id: _uuid.v4(),
            name: 'Competition Squat',
            category: ExerciseCategory.compound,
            sets: _generatePowerliftingSets(intensity, volume, phaseType),
            rest: RestPeriod(minSeconds: 180, maxSeconds: 300, type: RestType.complete),
            percentageOf1RM: intensity,
          ),
          Exercise(
            id: _uuid.v4(),
            name: 'Pause Squat',
            category: ExerciseCategory.compound,
            sets: List.generate(3, (i) => ExerciseSet(
              setNumber: i + 1,
              type: SetType.working,
              reps: 3,
              weight: intensity - 10,
            )),
            rest: RestPeriod(minSeconds: 120, maxSeconds: 180, type: RestType.standard),
          ),
          Exercise(
            id: _uuid.v4(),
            name: 'Leg Press',
            category: ExerciseCategory.accessory,
            sets: List.generate(4, (i) => ExerciseSet(
              setNumber: i + 1,
              type: SetType.working,
              reps: 12,
            )),
            rest: RestPeriod(minSeconds: 90, maxSeconds: 120, type: RestType.standard),
          ),
        ];
        break;

      case 'Bench':
        exercises = [
          Exercise(
            id: _uuid.v4(),
            name: 'Competition Bench Press',
            category: ExerciseCategory.compound,
            sets: _generatePowerliftingSets(intensity, volume, phaseType),
            rest: RestPeriod(minSeconds: 180, maxSeconds: 300, type: RestType.complete),
            percentageOf1RM: intensity,
          ),
          Exercise(
            id: _uuid.v4(),
            name: 'Close Grip Bench Press',
            category: ExerciseCategory.compound,
            sets: List.generate(4, (i) => ExerciseSet(
              setNumber: i + 1,
              type: SetType.working,
              reps: 5,
              weight: intensity - 15,
            )),
            rest: RestPeriod(minSeconds: 120, maxSeconds: 180, type: RestType.standard),
          ),
          Exercise(
            id: _uuid.v4(),
            name: 'Dumbbell Press',
            category: ExerciseCategory.accessory,
            sets: List.generate(4, (i) => ExerciseSet(
              setNumber: i + 1,
              type: SetType.working,
              reps: 10,
            )),
            rest: RestPeriod(minSeconds: 90, maxSeconds: 120, type: RestType.standard),
          ),
        ];
        break;

      case 'Deadlift':
        exercises = [
          Exercise(
            id: _uuid.v4(),
            name: 'Competition Deadlift',
            category: ExerciseCategory.compound,
            sets: _generatePowerliftingSets(intensity, volume, phaseType),
            rest: RestPeriod(minSeconds: 180, maxSeconds: 300, type: RestType.complete),
            percentageOf1RM: intensity,
          ),
          Exercise(
            id: _uuid.v4(),
            name: 'Block Pulls',
            category: ExerciseCategory.compound,
            sets: List.generate(3, (i) => ExerciseSet(
              setNumber: i + 1,
              type: SetType.working,
              reps: 3,
              weight: intensity + 5,
            )),
            rest: RestPeriod(minSeconds: 120, maxSeconds: 180, type: RestType.standard),
          ),
          Exercise(
            id: _uuid.v4(),
            name: 'Romanian Deadlift',
            category: ExerciseCategory.accessory,
            sets: List.generate(4, (i) => ExerciseSet(
              setNumber: i + 1,
              type: SetType.working,
              reps: 8,
            )),
            rest: RestPeriod(minSeconds: 90, maxSeconds: 120, type: RestType.standard),
          ),
        ];
        break;

      case 'Accessories':
        exercises = [
          Exercise(
            id: _uuid.v4(),
            name: 'Pull-ups',
            category: ExerciseCategory.compound,
            sets: List.generate(4, (i) => ExerciseSet(
              setNumber: i + 1,
              type: SetType.working,
              reps: 8,
            )),
            rest: RestPeriod(minSeconds: 90, maxSeconds: 120, type: RestType.standard),
          ),
          Exercise(
            id: _uuid.v4(),
            name: 'Dips',
            category: ExerciseCategory.compound,
            sets: List.generate(4, (i) => ExerciseSet(
              setNumber: i + 1,
              type: SetType.working,
              reps: 10,
            )),
            rest: RestPeriod(minSeconds: 90, maxSeconds: 120, type: RestType.standard),
          ),
          Exercise(
            id: _uuid.v4(),
            name: 'Ab Wheel',
            category: ExerciseCategory.core,
            sets: List.generate(3, (i) => ExerciseSet(
              setNumber: i + 1,
              type: SetType.working,
              reps: 15,
            )),
            rest: RestPeriod(minSeconds: 60, maxSeconds: 90, type: RestType.standard),
          ),
        ];
        break;
    }

    return TrainingDay(
      dayNumber: dayNumber,
      name: '$focus Day',
      type: DayType.training,
      focusAreas: [focus],
      workouts: [
        Workout(
          id: _uuid.v4(),
          name: '$focus Training',
          type: WorkoutType.standard,
          exercises: exercises,
        ),
      ],
    );
  }

  /// Generate powerlifting sets based on phase
  List<ExerciseSet> _generatePowerliftingSets(double intensity, int repTarget, String phaseType) {
    List<ExerciseSet> sets = [];

    // Warmup sets
    sets.add(ExerciseSet(setNumber: 1, type: SetType.warmup, reps: 5, weight: 50));
    sets.add(ExerciseSet(setNumber: 2, type: SetType.warmup, reps: 3, weight: 60));
    sets.add(ExerciseSet(setNumber: 3, type: SetType.warmup, reps: 2, weight: 70));

    // Working sets based on phase
    switch (phaseType) {
      case 'accumulation':
        // 5x5 @ 75%
        for (int i = 0; i < 5; i++) {
          sets.add(ExerciseSet(
            setNumber: sets.length + 1,
            type: SetType.working,
            reps: 5,
            weight: intensity,
          ));
        }
        break;

      case 'intensification':
        // 5x3 @ 85%
        for (int i = 0; i < 5; i++) {
          sets.add(ExerciseSet(
            setNumber: sets.length + 1,
            type: SetType.working,
            reps: 3,
            weight: intensity,
          ));
        }
        break;

      case 'realization':
        // Singles building to opener
        sets.add(ExerciseSet(setNumber: sets.length + 1, type: SetType.working, reps: 1, weight: 85));
        sets.add(ExerciseSet(setNumber: sets.length + 1, type: SetType.working, reps: 1, weight: 90));
        sets.add(ExerciseSet(setNumber: sets.length + 1, type: SetType.working, reps: 1, weight: 95));
        break;

      case 'competition':
        // Opener practice
        sets.add(ExerciseSet(setNumber: sets.length + 1, type: SetType.working, reps: 1, weight: 87.5));
        sets.add(ExerciseSet(setNumber: sets.length + 1, type: SetType.working, reps: 1, weight: 92.5));
        break;
    }

    return sets;
  }

  /// Continue with other methodology phase generators...
  List<TrainingPhase> _generateHyroxPhases(
    int durationWeeks,
    int sessionsPerWeek,
    Map<String, dynamic> settings,
  ) {
    // Hyrox-specific phase generation
    // Implementation would include station-specific training, running, transitions
    return [];
  }

  List<TrainingPhase> _generateCrossFitPhases(
    int durationWeeks,
    int sessionsPerWeek,
    Map<String, dynamic> settings,
  ) {
    // CrossFit-specific phase generation
    // Would include MetCon, Olympic lifting, gymnastics progression
    return [];
  }

  List<TrainingPhase> _generateCalisthenicsPhases(
    int durationWeeks,
    int sessionsPerWeek,
    Map<String, dynamic> settings,
  ) {
    // Calisthenics-specific phase generation
    // Would include skill progressions, isometric holds, strength standards
    return [];
  }

  List<TrainingPhase> _generateStrongmanPhases(
    int durationWeeks,
    int sessionsPerWeek,
    Map<String, dynamic> settings,
  ) {
    // Strongman-specific phase generation
    // Would include event training, implement work, conditioning
    return [];
  }

  List<TrainingPhase> _generateRPEPhases(
    int durationWeeks,
    int sessionsPerWeek,
    Map<String, dynamic> settings,
  ) {
    // RPE-based phase generation with autoregulation
    return [];
  }

  List<TrainingPhase> _generateGeneralPhases(int durationWeeks, int sessionsPerWeek) {
    // General training phase generation
    return [];
  }

  /// Generate deload week
  List<TrainingWeek> _generateDeloadWeek(int weekNumber, int sessionsPerWeek) {
    List<TrainingDay> days = [];

    for (int i = 1; i <= sessionsPerWeek; i++) {
      days.add(TrainingDay(
        dayNumber: i,
        name: 'Light Training Day $i',
        type: DayType.training,
        workouts: [
          Workout(
            id: _uuid.v4(),
            name: 'Deload Workout',
            type: WorkoutType.standard,
            exercises: [
              Exercise(
                id: _uuid.v4(),
                name: 'Light Movement Work',
                category: ExerciseCategory.compound,
                sets: List.generate(3, (i) => ExerciseSet(
                  setNumber: i + 1,
                  type: SetType.working,
                  reps: 10,
                  weight: 60,
                )),
                rest: RestPeriod(minSeconds: 60, maxSeconds: 90, type: RestType.standard),
                notes: 'Focus on form and recovery',
              ),
            ],
            notes: 'Reduce volume by 40-50%, maintain movement patterns',
          ),
        ],
      ));
    }

    // Fill rest of week with recovery
    for (int i = sessionsPerWeek + 1; i <= 7; i++) {
      days.add(TrainingDay(
        dayNumber: i,
        name: 'Recovery',
        type: DayType.activeRecovery,
        workouts: [],
      ));
    }

    return [
      TrainingWeek(
        weekNumber: weekNumber,
        type: WeekType.deload,
        days: days,
        notes: 'Recovery week - reduce intensity and volume',
      ),
    ];
  }

  /// Generate progression rules based on methodology
  Map<String, dynamic> _generateProgressionRules({
    required TrainingMethodology methodology,
    required Map<String, dynamic> methodologySettings,
  }) {
    switch (methodology) {
      case TrainingMethodology.strengthMethod:
        return {
          'maxEffort': {
            'rotation': 'Change main movement every 1-3 weeks',
            'intensity': 'Work up to 90-100% 1RM',
            'volume': 'Low volume, high intensity',
          },
          'dynamicEffort': {
            'waves': '3-week waves: 50%, 55%, 60%',
            'accommodatingResistance': 'Add 25% band/chain tension',
            'speed': 'Maintain 0.8-1.0 m/s bar speed',
          },
          'repetitionEffort': {
            'progression': 'Add reps or weight weekly',
            'failure': 'Train to near failure on final sets',
          },
        };

      case TrainingMethodology.rpe:
        return {
          'autoregulation': true,
          'rpeProgression': {
            'week1': 'RPE 7-8',
            'week2': 'RPE 8-9',
            'week3': 'RPE 9-10',
            'deload': 'RPE 6-7',
          },
          'adjustments': 'Modify load based on daily readiness',
        };

      case TrainingMethodology.powerlifting:
        return {
          'linear': 'Add 2.5-5kg weekly',
          'undulating': 'Vary intensity/volume daily',
          'block': 'Progress through accumulation → intensification → realization',
        };

      default:
        return {
          'standard': 'Progressive overload',
          'volume': 'Increase sets/reps before weight',
          'intensity': 'Increase weight when rep target achieved',
        };
    }
  }

  /// Get all programs for a trainer
  Stream<List<TrainingProgramModel>> getTrainerPrograms(String trainerId) {
    return _firestore
        .collection('training_programs')
        .where('createdBy', isEqualTo: trainerId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TrainingProgramModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Get programs assigned to a client
  Stream<List<TrainingProgramModel>> getClientPrograms(String clientId) {
    return _firestore
        .collection('training_programs')
        .where('assignedTo', isEqualTo: clientId)
        .where('status', whereIn: ['active', 'paused'])
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TrainingProgramModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Get program templates
  Stream<List<TrainingProgramModel>> getProgramTemplates() {
    return _firestore
        .collection('training_programs')
        .where('isTemplate', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TrainingProgramModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Update program status
  Future<void> updateProgramStatus(String programId, ProgramStatus status) async {
    await _firestore.collection('training_programs').doc(programId).update({
      'status': status.name,
      'updatedAt': Timestamp.now(),
    });
  }

  /// Record workout completion
  Future<void> recordWorkoutCompletion({
    required String programId,
    required String workoutId,
    required Map<String, dynamic> results,
  }) async {
    // Implementation for recording workout results
  }

  /// Generate WOD (Workout of the Day) for CrossFit
  Workout generateCrossFitWOD({
    required List<String> availableMovements,
    required String wodType,
    int? timeCap,
  }) {
    final random = Random();
    List<Exercise> exercises = [];

    // Select 2-4 movements
    final movementCount = 2 + random.nextInt(3);
    final selectedMovements = <String>[];

    for (int i = 0; i < movementCount && i < availableMovements.length; i++) {
      final movement = availableMovements[random.nextInt(availableMovements.length)];
      if (!selectedMovements.contains(movement)) {
        selectedMovements.add(movement);
      }
    }

    // Generate exercises based on WOD type
    switch (wodType) {
      case 'amrap':
        exercises = selectedMovements.map((movement) => Exercise(
          id: _uuid.v4(),
          name: movement,
          category: ExerciseCategory.compound,
          sets: [ExerciseSet(
            setNumber: 1,
            type: SetType.amrap,
            reps: 10 + random.nextInt(11), // 10-20 reps
          )],
        )).toList();
        break;

      case 'forTime':
        final rounds = 3 + random.nextInt(3); // 3-5 rounds
        exercises = selectedMovements.map((movement) => Exercise(
          id: _uuid.v4(),
          name: movement,
          category: ExerciseCategory.compound,
          sets: List.generate(rounds, (i) => ExerciseSet(
            setNumber: i + 1,
            type: SetType.standard,
            reps: 10 + random.nextInt(11),
          )),
        )).toList();
        break;

      case 'emom':
        exercises = selectedMovements.map((movement) => Exercise(
          id: _uuid.v4(),
          name: movement,
          category: ExerciseCategory.compound,
          sets: [ExerciseSet(
            setNumber: 1,
            type: SetType.emom,
            reps: 5 + random.nextInt(6), // 5-10 reps
            time: 60, // Every minute
          )],
        )).toList();
        break;
    }

    return Workout(
      id: _uuid.v4(),
      name: 'WOD - ${DateTime.now().toString().split(' ')[0]}',
      type: WorkoutType.wod,
      exercises: exercises,
      targetDuration: timeCap,
      notes: 'Scale as needed. Record time/rounds completed.',
    );
  }
}