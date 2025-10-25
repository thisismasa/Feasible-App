import 'package:flutter/foundation.dart';

/// Comprehensive Client Profile for PT Coach App
class ClientProfile {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? profileImage;
  final DateTime joinedDate;
  final bool isActive;

  // Onboarding Information
  final OnboardingInfo onboarding;

  // Progress Tracking
  final List<ProgressPhoto> progressPhotos;
  final List<Measurement> measurements;
  final List<Assessment> assessments;

  // Health & Medical
  final HealthProfile healthProfile;

  // Session & Workout
  final int totalSessions;
  final int completedSessions;
  final int canceledSessions;
  final double attendanceRate;
  final String? currentWorkoutProgram;

  // Habits & Goals
  final List<DailyHabit> habits;
  final List<ClientGoal> goals;
  final int currentStreak;
  final int longestStreak;

  // Communication
  final DateTime? lastCheckIn;
  final int unreadMessages;
  final List<RewardBadge> badges;

  ClientProfile({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.profileImage,
    required this.joinedDate,
    required this.isActive,
    required this.onboarding,
    this.progressPhotos = const [],
    this.measurements = const [],
    this.assessments = const [],
    required this.healthProfile,
    this.totalSessions = 0,
    this.completedSessions = 0,
    this.canceledSessions = 0,
    this.attendanceRate = 0.0,
    this.currentWorkoutProgram,
    this.habits = const [],
    this.goals = const [],
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastCheckIn,
    this.unreadMessages = 0,
    this.badges = const [],
  });
}

/// Onboarding Information
class OnboardingInfo {
  final DateTime completedDate;
  final FitnessGoal primaryGoal;
  final List<String> injuries;
  final List<String> preferences;
  final String? notes;
  final int experienceLevel; // 1-5
  final List<String> availableDays;
  final String? preferredTime;

  OnboardingInfo({
    required this.completedDate,
    required this.primaryGoal,
    this.injuries = const [],
    this.preferences = const [],
    this.notes,
    required this.experienceLevel,
    this.availableDays = const [],
    this.preferredTime,
  });
}

enum FitnessGoal {
  weightLoss,
  muscleGain,
  generalFitness,
  strength,
  endurance,
  flexibility,
  rehabilitation,
  sports,
}

/// Progress Photos with Timeline
class ProgressPhoto {
  final String id;
  final String imageUrl;
  final DateTime takenDate;
  final double? weight;
  final String? notes;
  final PhotoType type;

  ProgressPhoto({
    required this.id,
    required this.imageUrl,
    required this.takenDate,
    this.weight,
    this.notes,
    required this.type,
  });
}

enum PhotoType {
  front,
  back,
  side,
  other,
}

/// Body Measurements
class Measurement {
  final String id;
  final DateTime date;
  final double weight;
  final double? bodyFat;
  final double? chest;
  final double? waist;
  final double? hips;
  final double? thigh;
  final double? arm;
  final String? notes;

  Measurement({
    required this.id,
    required this.date,
    required this.weight,
    this.bodyFat,
    this.chest,
    this.waist,
    this.hips,
    this.thigh,
    this.arm,
    this.notes,
  });

  double get bmi {
    // Assuming height is stored elsewhere or passed in
    // This is a placeholder calculation
    return weight / 1.75 / 1.75;
  }
}

/// Assessment (Strength, Flexibility, etc.)
class Assessment {
  final String id;
  final DateTime date;
  final AssessmentType type;
  final Map<String, dynamic> results;
  final String? notes;

  Assessment({
    required this.id,
    required this.date,
    required this.type,
    required this.results,
    this.notes,
  });
}

enum AssessmentType {
  strength,
  flexibility,
  endurance,
  functional,
}

/// Health Profile & Medical Info
class HealthProfile {
  final List<String> medicalConditions;
  final List<String> medications;
  final List<String> allergies;
  final bool clearanceRequired;
  final DateTime? lastClearanceDate;
  final String? emergencyContact;
  final String? emergencyPhone;
  final String? specialNotes;

  HealthProfile({
    this.medicalConditions = const [],
    this.medications = const [],
    this.allergies = const [],
    this.clearanceRequired = false,
    this.lastClearanceDate,
    this.emergencyContact,
    this.emergencyPhone,
    this.specialNotes,
  });

  bool get hasHealthConcerns =>
      medicalConditions.isNotEmpty ||
      medications.isNotEmpty ||
      allergies.isNotEmpty;
}

/// Daily Habits Tracking
class DailyHabit {
  final String id;
  final String name;
  final String icon;
  final int targetValue;
  final String unit;
  final int currentValue;
  final DateTime date;
  final bool completed;

  DailyHabit({
    required this.id,
    required this.name,
    required this.icon,
    required this.targetValue,
    required this.unit,
    this.currentValue = 0,
    required this.date,
    this.completed = false,
  });

  double get progress => currentValue / targetValue;
}

/// Client Goals
class ClientGoal {
  final String id;
  final String title;
  final String description;
  final GoalType type;
  final DateTime startDate;
  final DateTime targetDate;
  final double targetValue;
  final double currentValue;
  final String unit;
  final GoalStatus status;

  ClientGoal({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.startDate,
    required this.targetDate,
    required this.targetValue,
    this.currentValue = 0,
    required this.unit,
    this.status = GoalStatus.active,
  });

  double get progress => currentValue / targetValue;
  int get daysRemaining => targetDate.difference(DateTime.now()).inDays;
}

enum GoalType {
  weight,
  strength,
  endurance,
  habit,
  custom,
}

enum GoalStatus {
  active,
  completed,
  paused,
  failed,
}

/// Reward Badges
class RewardBadge {
  final String id;
  final String name;
  final String description;
  final String icon;
  final DateTime earnedDate;
  final BadgeCategory category;

  RewardBadge({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.earnedDate,
    required this.category,
  });
}

enum BadgeCategory {
  attendance,
  streak,
  milestone,
  achievement,
  special,
}

/// Weekly Check-In
class WeeklyCheckIn {
  final String id;
  final String clientId;
  final DateTime date;
  final int weekNumber;
  final Map<String, dynamic> responses;
  final double? overallRating;
  final String? trainerNotes;

  WeeklyCheckIn({
    required this.id,
    required this.clientId,
    required this.date,
    required this.weekNumber,
    required this.responses,
    this.overallRating,
    this.trainerNotes,
  });
}

/// Check-In Template (for creating weekly check-ins)
class CheckInTemplate {
  final String id;
  final String name;
  final List<CheckInQuestion> questions;

  CheckInTemplate({
    required this.id,
    required this.name,
    required this.questions,
  });
}

class CheckInQuestion {
  final String id;
  final String question;
  final QuestionType type;
  final List<String>? options;
  final bool required;

  CheckInQuestion({
    required this.id,
    required this.question,
    required this.type,
    this.options,
    this.required = true,
  });
}

enum QuestionType {
  rating,
  text,
  multipleChoice,
  yesNo,
  number,
}
