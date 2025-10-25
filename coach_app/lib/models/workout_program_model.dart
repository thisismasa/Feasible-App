import 'package:flutter/foundation.dart';

/// Custom Workout Program
class WorkoutProgram {
  final String id;
  final String name;
  final String description;
  final String clientId;
  final String trainerId;
  final DateTime createdDate;
  final DateTime? startDate;
  final DateTime? endDate;
  final int durationWeeks;
  final ProgramStatus status;
  final List<WorkoutWeek> weeks;
  final String? notes;

  WorkoutProgram({
    required this.id,
    required this.name,
    required this.description,
    required this.clientId,
    required this.trainerId,
    required this.createdDate,
    this.startDate,
    this.endDate,
    required this.durationWeeks,
    this.status = ProgramStatus.draft,
    this.weeks = const [],
    this.notes,
  });

  int get currentWeek {
    if (startDate == null) return 0;
    final daysSinceStart = DateTime.now().difference(startDate!).inDays;
    return (daysSinceStart / 7).floor() + 1;
  }

  double get completionRate {
    if (weeks.isEmpty) return 0;
    final completedWorkouts = weeks
        .expand((w) => w.workouts)
        .where((w) => w.completed)
        .length;
    final totalWorkouts = weeks.expand((w) => w.workouts).length;
    return totalWorkouts > 0 ? completedWorkouts / totalWorkouts : 0;
  }
}

enum ProgramStatus {
  draft,
  active,
  paused,
  completed,
  archived,
}

/// Workout Week
class WorkoutWeek {
  final int weekNumber;
  final String? focus;
  final List<Workout> workouts;
  final String? notes;

  WorkoutWeek({
    required this.weekNumber,
    this.focus,
    this.workouts = const [],
    this.notes,
  });
}

/// Individual Workout
class Workout {
  final String id;
  final String name;
  final String? description;
  final int dayOfWeek; // 1-7 (Monday-Sunday)
  final WorkoutType type;
  final int estimatedDuration; // minutes
  final List<Exercise> exercises;
  final bool completed;
  final DateTime? completedDate;
  final String? completionNotes;

  Workout({
    required this.id,
    required this.name,
    this.description,
    required this.dayOfWeek,
    required this.type,
    required this.estimatedDuration,
    this.exercises = const [],
    this.completed = false,
    this.completedDate,
    this.completionNotes,
  });
}

enum WorkoutType {
  strength,
  cardio,
  flexibility,
  hiit,
  functional,
  recovery,
  custom,
}

/// Exercise
class Exercise {
  final String id;
  final String name;
  final String? description;
  final ExerciseCategory category;
  final String? videoUrl;
  final String? imageUrl;
  final List<ExerciseSet> sets;
  final String? notes;
  final int restSeconds;
  final String? equipment;

  Exercise({
    required this.id,
    required this.name,
    this.description,
    required this.category,
    this.videoUrl,
    this.imageUrl,
    this.sets = const [],
    this.notes,
    this.restSeconds = 60,
    this.equipment,
  });
}

enum ExerciseCategory {
  chest,
  back,
  shoulders,
  arms,
  legs,
  core,
  cardio,
  fullBody,
}

/// Exercise Set
class ExerciseSet {
  final int setNumber;
  final int? targetReps;
  final double? targetWeight;
  final int? targetDuration; // seconds
  final String? targetDistance;

  // Actual performance
  final int? actualReps;
  final double? actualWeight;
  final int? actualDuration;
  final String? actualDistance;
  final bool completed;

  ExerciseSet({
    required this.setNumber,
    this.targetReps,
    this.targetWeight,
    this.targetDuration,
    this.targetDistance,
    this.actualReps,
    this.actualWeight,
    this.actualDuration,
    this.actualDistance,
    this.completed = false,
  });
}

/// Exercise Library
class ExerciseLibrary {
  final String id;
  final String name;
  final String description;
  final ExerciseCategory category;
  final DifficultyLevel difficulty;
  final List<String> muscleGroups;
  final String? videoUrl;
  final String? thumbnailUrl;
  final List<String> equipment;
  final String? instructions;
  final List<String> tags;

  ExerciseLibrary({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.difficulty,
    required this.muscleGroups,
    this.videoUrl,
    this.thumbnailUrl,
    this.equipment = const [],
    this.instructions,
    this.tags = const [],
  });
}

enum DifficultyLevel {
  beginner,
  intermediate,
  advanced,
  expert,
}
