// ============================================================================
// ENTERPRISE CLIENT MANAGEMENT SYSTEM
// Version: 2.0.0
// Architecture: Domain-Driven Design with Clean Architecture
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'dart:convert';
import 'package:rxdart/rxdart.dart';
import '../services/database_service.dart';

// ============================================================================
// DOMAIN LAYER - Core Business Models
// ============================================================================

/// Enumeration for client status lifecycle
enum ClientStatus {
  prospect,
  onboarding,
  active,
  inactive,
  suspended,
  terminated,
  vip,
  premium
}

/// Enumeration for client risk levels
enum RiskLevel {
  low,
  medium,
  high,
  critical
}

/// Enumeration for fitness goals
enum FitnessGoal {
  weightLoss,
  muscleGain,
  endurance,
  flexibility,
  generalFitness,
  rehabilitation,
  athletic,
  bodybuilding
}

/// Base entity class with common properties
abstract class BaseEntity {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;
  final String? updatedBy;
  final Map<String, dynamic> metadata;
  final bool isDeleted;

  BaseEntity({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.updatedBy,
    Map<String, dynamic>? metadata,
    this.isDeleted = false,
  }) : metadata = metadata ?? {};
}

/// Medical condition entity
class MedicalCondition {
  final String name;
  final String severity;
  final DateTime? diagnosedDate;
  final String? medication;
  final String? restrictions;
  final bool requiresMonitoring;

  const MedicalCondition({
    required this.name,
    required this.severity,
    this.diagnosedDate,
    this.medication,
    this.restrictions,
    this.requiresMonitoring = false,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'severity': severity,
    'diagnosedDate': diagnosedDate?.toIso8601String(),
    'medication': medication,
    'restrictions': restrictions,
    'requiresMonitoring': requiresMonitoring,
  };
}

/// Emergency contact entity
class EmergencyContact {
  final String name;
  final String relationship;
  final String phone;
  final String? alternativePhone;
  final String? email;
  final bool isPrimary;

  const EmergencyContact({
    required this.name,
    required this.relationship,
    required this.phone,
    this.alternativePhone,
    this.email,
    this.isPrimary = false,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'relationship': relationship,
    'phone': phone,
    'alternativePhone': alternativePhone,
    'email': email,
    'isPrimary': isPrimary,
  };
}

/// Body measurements entity
class BodyMeasurements {
  final double? weight;
  final double? height;
  final double? bodyFatPercentage;
  final double? muscleMass;
  final double? bmi;
  final double? waist;
  final double? chest;
  final double? arms;
  final double? thighs;
  final double? calves;
  final DateTime measurementDate;
  final String? notes;

  const BodyMeasurements({
    this.weight,
    this.height,
    this.bodyFatPercentage,
    this.muscleMass,
    this.bmi,
    this.waist,
    this.chest,
    this.arms,
    this.thighs,
    this.calves,
    required this.measurementDate,
    this.notes,
  });

  double? calculateBMI() {
    if (weight != null && height != null && height! > 0) {
      return weight! / ((height! / 100) * (height! / 100));
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
    'weight': weight,
    'height': height,
    'bodyFatPercentage': bodyFatPercentage,
    'muscleMass': muscleMass,
    'bmi': bmi ?? calculateBMI(),
    'waist': waist,
    'chest': chest,
    'arms': arms,
    'thighs': thighs,
    'calves': calves,
    'measurementDate': measurementDate.toIso8601String(),
    'notes': notes,
  };
}

/// Subscription plan entity
class SubscriptionPlan {
  final String id;
  final String name;
  final double price;
  final int durationDays;
  final List<String> features;
  final int sessionsPerMonth;
  final bool hasNutritionPlan;
  final bool hasOnlineSupport;
  final bool hasPriorityBooking;

  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.price,
    required this.durationDays,
    required this.features,
    required this.sessionsPerMonth,
    this.hasNutritionPlan = false,
    this.hasOnlineSupport = false,
    this.hasPriorityBooking = false,
  });
}

/// Client preferences entity
class ClientPreferences {
  final List<String> preferredTrainingTimes;
  final List<String> preferredTrainers;
  final String communicationPreference;
  final bool receivesPromotions;
  final bool receivesReminders;
  final String languagePreference;
  final Map<String, bool> notificationSettings;

  const ClientPreferences({
    required this.preferredTrainingTimes,
    required this.preferredTrainers,
    this.communicationPreference = 'email',
    this.receivesPromotions = true,
    this.receivesReminders = true,
    this.languagePreference = 'en',
    required this.notificationSettings,
  });
}

/// Main Client Entity with all business logic
class Client extends BaseEntity {
  // Personal Information
  final String fullName;
  final String email;
  final String phone;
  final String? alternativePhone;
  final DateTime birthDate;
  final String gender;
  final String? profileImageUrl;

  // Address Information
  final String? addressLine1;
  final String? addressLine2;
  final String? city;
  final String? state;
  final String? zipCode;
  final String? country;

  // Professional Information
  final String? occupation;
  final String? company;
  final String? workPhone;

  // Fitness Information
  final List<FitnessGoal> fitnessGoals;
  final String fitnessLevel;
  final String? currentGym;
  final int? yearsOfExperience;
  final List<String> preferredActivities;

  // Medical Information
  final List<MedicalCondition> medicalConditions;
  final List<String> allergies;
  final List<String> injuries;
  final String bloodType;
  final bool hasHealthInsurance;
  final String? insuranceProvider;
  final String? insuranceNumber;

  // Emergency Information
  final List<EmergencyContact> emergencyContacts;

  // Measurements & Progress
  final List<BodyMeasurements> measurementHistory;
  final BodyMeasurements? currentMeasurements;

  // Subscription & Billing
  final ClientStatus status;
  final SubscriptionPlan? currentPlan;
  final DateTime? subscriptionStartDate;
  final DateTime? subscriptionEndDate;
  final double accountBalance;
  final List<String> paymentMethods;

  // Preferences
  final ClientPreferences preferences;

  // Risk & Compliance
  final RiskLevel riskLevel;
  final bool hasSignedWaiver;
  final DateTime? waiverSignedDate;
  final bool hasCompletedPARQ;
  final DateTime? parqCompletedDate;

  // Relationship
  final String trainerId;
  final String? nutritionistId;
  final String? physiotherapistId;
  final List<String> groupIds;

  // Analytics & Tracking
  final int totalSessions;
  final int completedSessions;
  final double attendanceRate;
  final DateTime? lastSessionDate;
  final double satisfactionScore;
  final Map<String, dynamic> customFields;

  // Audit & Compliance
  final List<String> tags;
  final String? referralSource;
  final String? referredBy;
  final bool gdprConsent;
  final DateTime? gdprConsentDate;

  Client({
    required String id,
    required DateTime createdAt,
    required DateTime updatedAt,
    String? createdBy,
    String? updatedBy,
    Map<String, dynamic>? metadata,
    bool isDeleted = false,
    required this.fullName,
    required this.email,
    required this.phone,
    this.alternativePhone,
    required this.birthDate,
    required this.gender,
    this.profileImageUrl,
    this.addressLine1,
    this.addressLine2,
    this.city,
    this.state,
    this.zipCode,
    this.country,
    this.occupation,
    this.company,
    this.workPhone,
    required this.fitnessGoals,
    this.fitnessLevel = 'beginner',
    this.currentGym,
    this.yearsOfExperience,
    this.preferredActivities = const [],
    this.medicalConditions = const [],
    this.allergies = const [],
    this.injuries = const [],
    this.bloodType = 'Unknown',
    this.hasHealthInsurance = false,
    this.insuranceProvider,
    this.insuranceNumber,
    this.emergencyContacts = const [],
    this.measurementHistory = const [],
    this.currentMeasurements,
    this.status = ClientStatus.prospect,
    this.currentPlan,
    this.subscriptionStartDate,
    this.subscriptionEndDate,
    this.accountBalance = 0.0,
    this.paymentMethods = const [],
    required this.preferences,
    this.riskLevel = RiskLevel.low,
    this.hasSignedWaiver = false,
    this.waiverSignedDate,
    this.hasCompletedPARQ = false,
    this.parqCompletedDate,
    required this.trainerId,
    this.nutritionistId,
    this.physiotherapistId,
    this.groupIds = const [],
    this.totalSessions = 0,
    this.completedSessions = 0,
    this.attendanceRate = 0.0,
    this.lastSessionDate,
    this.satisfactionScore = 0.0,
    Map<String, dynamic>? customFields,
    this.tags = const [],
    this.referralSource,
    this.referredBy,
    this.gdprConsent = false,
    this.gdprConsentDate,
  }) : customFields = customFields ?? {},
       super(
          id: id,
          createdAt: createdAt,
          updatedAt: updatedAt,
          createdBy: createdBy,
          updatedBy: updatedBy,
          metadata: metadata,
          isDeleted: isDeleted,
        );

  // Business Logic Methods

  int get age {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  bool get isMinor => age < 18;

  bool get isSubscriptionActive {
    if (subscriptionEndDate == null) return false;
    return DateTime.now().isBefore(subscriptionEndDate!);
  }

  int get daysUntilSubscriptionExpiry {
    if (subscriptionEndDate == null) return 0;
    return subscriptionEndDate!.difference(DateTime.now()).inDays;
  }

  bool get requiresMedicalClearance {
    return riskLevel == RiskLevel.high ||
           riskLevel == RiskLevel.critical ||
           medicalConditions.any((c) => c.requiresMonitoring) ||
           age > 65 ||
           injuries.isNotEmpty;
  }

  String get membershipTier {
    if (status == ClientStatus.vip) return 'VIP';
    if (status == ClientStatus.premium) return 'Premium';
    if (currentPlan?.price != null) {
      if (currentPlan!.price > 500) return 'Gold';
      if (currentPlan!.price > 200) return 'Silver';
      return 'Bronze';
    }
    return 'Basic';
  }

  double calculateAttendanceRate() {
    if (totalSessions == 0) return 0.0;
    return (completedSessions / totalSessions) * 100;
  }

  bool canBookSession() {
    return status == ClientStatus.active &&
           isSubscriptionActive &&
           hasSignedWaiver &&
           (!requiresMedicalClearance || hasCompletedPARQ);
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'createdBy': createdBy,
    'updatedBy': updatedBy,
    'metadata': metadata,
    'isDeleted': isDeleted,
    'fullName': fullName,
    'email': email,
    'phone': phone,
    'alternativePhone': alternativePhone,
    'birthDate': birthDate.toIso8601String(),
    'gender': gender,
    'profileImageUrl': profileImageUrl,
    'addressLine1': addressLine1,
    'addressLine2': addressLine2,
    'city': city,
    'state': state,
    'zipCode': zipCode,
    'country': country,
    'occupation': occupation,
    'company': company,
    'workPhone': workPhone,
    'fitnessGoals': fitnessGoals.map((g) => g.toString()).toList(),
    'fitnessLevel': fitnessLevel,
    'currentGym': currentGym,
    'yearsOfExperience': yearsOfExperience,
    'preferredActivities': preferredActivities,
    'medicalConditions': medicalConditions.map((m) => m.toJson()).toList(),
    'allergies': allergies,
    'injuries': injuries,
    'bloodType': bloodType,
    'hasHealthInsurance': hasHealthInsurance,
    'insuranceProvider': insuranceProvider,
    'insuranceNumber': insuranceNumber,
    'emergencyContacts': emergencyContacts.map((e) => e.toJson()).toList(),
    'measurementHistory': measurementHistory.map((m) => m.toJson()).toList(),
    'currentMeasurements': currentMeasurements?.toJson(),
    'status': status.toString(),
    'currentPlan': currentPlan != null ? {
      'id': currentPlan!.id,
      'name': currentPlan!.name,
      'price': currentPlan!.price,
    } : null,
    'subscriptionStartDate': subscriptionStartDate?.toIso8601String(),
    'subscriptionEndDate': subscriptionEndDate?.toIso8601String(),
    'accountBalance': accountBalance,
    'paymentMethods': paymentMethods,
    'riskLevel': riskLevel.toString(),
    'hasSignedWaiver': hasSignedWaiver,
    'waiverSignedDate': waiverSignedDate?.toIso8601String(),
    'hasCompletedPARQ': hasCompletedPARQ,
    'parqCompletedDate': parqCompletedDate?.toIso8601String(),
    'trainerId': trainerId,
    'nutritionistId': nutritionistId,
    'physiotherapistId': physiotherapistId,
    'groupIds': groupIds,
    'totalSessions': totalSessions,
    'completedSessions': completedSessions,
    'attendanceRate': attendanceRate,
    'lastSessionDate': lastSessionDate?.toIso8601String(),
    'satisfactionScore': satisfactionScore,
    'customFields': customFields,
    'tags': tags,
    'referralSource': referralSource,
    'referredBy': referredBy,
    'gdprConsent': gdprConsent,
    'gdprConsentDate': gdprConsentDate?.toIso8601String(),
  };
}

// ============================================================================
// APPLICATION LAYER - Services & Business Rules
// ============================================================================

/// Service for client validation
class ClientValidationService {
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  static final RegExp _phoneRegex = RegExp(
    r'^\+?[\d\s\-\(\)]+$',
  );

  ValidationResult validateClient(Client client) {
    final errors = <String, String>{};

    // Name validation
    if (client.fullName.trim().isEmpty) {
      errors['fullName'] = 'Full name is required';
    } else if (client.fullName.length < 2) {
      errors['fullName'] = 'Name must be at least 2 characters';
    } else if (client.fullName.length > 100) {
      errors['fullName'] = 'Name must not exceed 100 characters';
    }

    // Email validation
    if (client.email.trim().isEmpty) {
      errors['email'] = 'Email is required';
    } else if (!_emailRegex.hasMatch(client.email)) {
      errors['email'] = 'Invalid email format';
    }

    // Phone validation
    if (client.phone.trim().isEmpty) {
      errors['phone'] = 'Phone number is required';
    } else if (!_phoneRegex.hasMatch(client.phone)) {
      errors['phone'] = 'Invalid phone format';
    } else if (client.phone.replaceAll(RegExp(r'\D'), '').length < 10) {
      errors['phone'] = 'Phone number must be at least 10 digits';
    }

    // Age validation
    if (client.age < 16) {
      errors['birthDate'] = 'Client must be at least 16 years old';
    } else if (client.age > 100) {
      errors['birthDate'] = 'Invalid birth date';
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
    );
  }

  bool isEmailUnique(String email, List<Client> existingClients, [String? excludeId]) {
    return !existingClients.any((c) =>
      c.email.toLowerCase() == email.toLowerCase() &&
      c.id != excludeId
    );
  }

  bool isPhoneUnique(String phone, List<Client> existingClients, [String? excludeId]) {
    final normalizedPhone = phone.replaceAll(RegExp(r'\D'), '');
    return !existingClients.any((c) {
      final existingPhone = c.phone.replaceAll(RegExp(r'\D'), '');
      return existingPhone == normalizedPhone && c.id != excludeId;
    });
  }
}

class ValidationResult {
  final bool isValid;
  final Map<String, String> errors;

  const ValidationResult({
    required this.isValid,
    required this.errors,
  });
}

/// Service for risk assessment
class RiskAssessmentService {
  RiskLevel assessClientRisk(Client client) {
    int riskScore = 0;

    // Age factors
    if (client.age > 65) riskScore += 3;
    else if (client.age > 50) riskScore += 2;
    else if (client.age < 18) riskScore += 1;

    // Medical conditions
    for (final condition in client.medicalConditions) {
      if (condition.severity == 'critical') riskScore += 5;
      else if (condition.severity == 'high') riskScore += 3;
      else if (condition.severity == 'medium') riskScore += 1;

      if (condition.requiresMonitoring) riskScore += 2;
    }

    // Injuries
    riskScore += client.injuries.length * 2;

    // Fitness level
    if (client.fitnessLevel == 'sedentary') riskScore += 2;
    else if (client.fitnessLevel == 'beginner') riskScore += 1;

    // BMI consideration
    if (client.currentMeasurements != null) {
      final bmi = client.currentMeasurements!.calculateBMI();
      if (bmi != null) {
        if (bmi > 35 || bmi < 17) riskScore += 3;
        else if (bmi > 30 || bmi < 18.5) riskScore += 2;
        else if (bmi > 28 || bmi < 19) riskScore += 1;
      }
    }

    // Determine risk level
    if (riskScore >= 10) return RiskLevel.critical;
    if (riskScore >= 7) return RiskLevel.high;
    if (riskScore >= 4) return RiskLevel.medium;
    return RiskLevel.low;
  }

  List<String> generateRiskRecommendations(Client client, RiskLevel riskLevel) {
    final recommendations = <String>[];

    switch (riskLevel) {
      case RiskLevel.critical:
        recommendations.add('Require medical clearance before any training');
        recommendations.add('Mandatory supervision during all sessions');
        recommendations.add('Limit to low-intensity activities initially');
        recommendations.add('Weekly health check-ins required');
        break;
      case RiskLevel.high:
        recommendations.add('Medical clearance recommended');
        recommendations.add('Start with supervised sessions');
        recommendations.add('Gradual progression protocol required');
        recommendations.add('Bi-weekly progress monitoring');
        break;
      case RiskLevel.medium:
        recommendations.add('Complete PAR-Q assessment');
        recommendations.add('Monitor vital signs during intense sessions');
        recommendations.add('Monthly progress reviews');
        break;
      case RiskLevel.low:
        recommendations.add('Standard training protocols apply');
        recommendations.add('Regular progress tracking');
        break;
    }

    // Age-specific recommendations
    if (client.age > 65) {
      recommendations.add('Focus on balance and flexibility');
      recommendations.add('Include fall prevention exercises');
    }
    if (client.isMinor) {
      recommendations.add('Parental consent required');
      recommendations.add('Age-appropriate training programs');
    }

    return recommendations;
  }
}

// ============================================================================
// INFRASTRUCTURE LAYER - Repository & Data Access
// ============================================================================

abstract class IClientRepository {
  Future<Client?> getById(String id);
  Future<List<Client>> getAll();
  Future<List<Client>> getByTrainer(String trainerId);
  Future<List<Client>> search(String query);
  Future<Client> create(Client client);
  Future<Client> update(Client client);
  Future<bool> delete(String id);
  Future<bool> exists(String id);
  Future<int> count();
  Stream<List<Client>> watchAll();
  Stream<Client?> watchById(String id);
}

class ClientRepository implements IClientRepository {
  final Map<String, Client> _cache = {};
  final BehaviorSubject<List<Client>> _clientsSubject = BehaviorSubject.seeded([]);

  @override
  Future<Client?> getById(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _cache[id];
  }

  @override
  Future<List<Client>> getAll() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _cache.values.toList();
  }

  @override
  Future<List<Client>> getByTrainer(String trainerId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _cache.values.where((c) => c.trainerId == trainerId).toList();
  }

  @override
  Future<List<Client>> search(String query) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final lowerQuery = query.toLowerCase();
    return _cache.values.where((c) =>
      c.fullName.toLowerCase().contains(lowerQuery) ||
      c.email.toLowerCase().contains(lowerQuery) ||
      c.phone.contains(query)
    ).toList();
  }

  @override
  Future<Client> create(Client client) async {
    try {
      // Save to Supabase database using DatabaseService
      debugPrint('💾 Saving client to database: ${client.fullName}');

      // Get the current trainer ID (from logged-in user or fallback to demo)
      final trainerId = DatabaseService.instance.currentUserId ?? client.trainerId ?? 'demo-trainer';
      debugPrint('🔑 Creating client with trainer ID: $trainerId');

      final clientId = await DatabaseService.instance.createClient(
        email: client.email,
        fullName: client.fullName,
        phone: client.phone,
        trainerId: trainerId,
        notes: 'Created via Add Client form',
      );

      debugPrint('✅ Client saved to database with ID: $clientId');

      // Also save to local cache for immediate UI updates
      final updatedClient = Client(
        id: clientId, // Use the database ID
        createdAt: client.createdAt,
        updatedAt: client.updatedAt,
        createdBy: client.createdBy,
        updatedBy: client.updatedBy,
        fullName: client.fullName,
        email: client.email,
        phone: client.phone,
        alternativePhone: client.alternativePhone,
        birthDate: client.birthDate,
        gender: client.gender,
        addressLine1: client.addressLine1,
        addressLine2: client.addressLine2,
        city: client.city,
        state: client.state,
        zipCode: client.zipCode,
        country: client.country,
        occupation: client.occupation,
        company: client.company,
        fitnessGoals: client.fitnessGoals,
        fitnessLevel: client.fitnessLevel,
        preferredActivities: client.preferredActivities,
        medicalConditions: client.medicalConditions,
        allergies: client.allergies,
        injuries: client.injuries,
        bloodType: client.bloodType,
        hasHealthInsurance: client.hasHealthInsurance,
        insuranceProvider: client.insuranceProvider,
        insuranceNumber: client.insuranceNumber,
        emergencyContacts: client.emergencyContacts,
        measurementHistory: client.measurementHistory,
        currentMeasurements: client.currentMeasurements,
        status: client.status,
        trainerId: client.trainerId,
        preferences: client.preferences,
        riskLevel: client.riskLevel,
        hasSignedWaiver: client.hasSignedWaiver,
        waiverSignedDate: client.waiverSignedDate,
        hasCompletedPARQ: client.hasCompletedPARQ,
        parqCompletedDate: client.parqCompletedDate,
        gdprConsent: client.gdprConsent,
        gdprConsentDate: client.gdprConsentDate,
      );

      _cache[clientId] = updatedClient;
      _clientsSubject.add(_cache.values.toList());
      return updatedClient;
    } catch (e) {
      debugPrint('❌ Error saving client to database: $e');
      rethrow;
    }
  }

  @override
  Future<Client> update(Client client) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _cache[client.id] = client;
    _clientsSubject.add(_cache.values.toList());
    return client;
  }

  @override
  Future<bool> delete(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final removed = _cache.remove(id) != null;
    if (removed) {
      _clientsSubject.add(_cache.values.toList());
    }
    return removed;
  }

  @override
  Future<bool> exists(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _cache.containsKey(id);
  }

  @override
  Future<int> count() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _cache.length;
  }

  @override
  Stream<List<Client>> watchAll() {
    return _clientsSubject.stream;
  }

  @override
  Stream<Client?> watchById(String id) {
    return _clientsSubject.stream.map((clients) =>
      clients.cast<Client?>().firstWhere((c) => c?.id == id, orElse: () => null)
    );
  }
}

// ============================================================================
// PRESENTATION LAYER - Simple Wrapper for Dashboard
// ============================================================================

/// Simple wrapper that the dashboard uses - creates enterprise version with services
class AddClientScreenEnhanced extends StatelessWidget {
  final String trainerId;

  const AddClientScreenEnhanced({
    Key? key,
    required this.trainerId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return EnterpriseAddClientScreen(
      trainerId: trainerId,
      repository: ClientRepository(),
      validationService: ClientValidationService(),
      riskAssessmentService: RiskAssessmentService(),
    );
  }
}

// ============================================================================
// PRESENTATION LAYER - Enterprise UI with Full Business Logic
// ============================================================================

class EnterpriseAddClientScreen extends StatefulWidget {
  final String trainerId;
  final IClientRepository repository;
  final ClientValidationService validationService;
  final RiskAssessmentService riskAssessmentService;

  const EnterpriseAddClientScreen({
    Key? key,
    required this.trainerId,
    required this.repository,
    required this.validationService,
    required this.riskAssessmentService,
  }) : super(key: key);

  @override
  State<EnterpriseAddClientScreen> createState() => _EnterpriseAddClientScreenState();
}

class _EnterpriseAddClientScreenState extends State<EnterpriseAddClientScreen>
    with TickerProviderStateMixin {
  // Form Controllers
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  late TabController _tabController;

  // Personal Info Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _alternativePhoneController = TextEditingController();
  final _occupationController = TextEditingController();
  final _companyController = TextEditingController();

  // Address Controllers
  final _addressLine1Controller = TextEditingController();
  final _addressLine2Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipCodeController = TextEditingController();
  final _countryController = TextEditingController();

  // Medical Controllers
  final _bloodTypeController = TextEditingController();
  final _insuranceProviderController = TextEditingController();
  final _insuranceNumberController = TextEditingController();

  // Emergency Contact Controllers
  final _emergencyNameController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();
  final _emergencyRelationshipController = TextEditingController();
  final _emergencyEmailController = TextEditingController();

  // Measurement Controllers
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _bodyFatController = TextEditingController();
  final _waistController = TextEditingController();
  final _chestController = TextEditingController();

  // State Variables
  DateTime? _birthDate;
  String _gender = 'Male';
  String _fitnessLevel = 'beginner';
  ClientStatus _status = ClientStatus.prospect;
  final Set<FitnessGoal> _selectedGoals = {};
  final List<MedicalCondition> _medicalConditions = [];
  final List<String> _allergies = [];
  final List<String> _injuries = [];
  final List<EmergencyContact> _emergencyContacts = [];
  final List<String> _preferredActivities = [];
  bool _hasHealthInsurance = false;
  bool _hasSignedWaiver = false;
  bool _hasCompletedPARQ = false;
  bool _gdprConsent = false;
  bool _receivesPromotions = true;
  bool _receivesReminders = true;

  // UI State
  bool _isLoading = false;
  int _currentStep = 0;
  RiskLevel? _calculatedRisk;
  List<String> _riskRecommendations = [];
  Map<String, String> _validationErrors = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _tabController.dispose();
    // Dispose all controllers
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _alternativePhoneController.dispose();
    _occupationController.dispose();
    _companyController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipCodeController.dispose();
    _countryController.dispose();
    _bloodTypeController.dispose();
    _insuranceProviderController.dispose();
    _insuranceNumberController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    _emergencyRelationshipController.dispose();
    _emergencyEmailController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _bodyFatController.dispose();
    _waistController.dispose();
    _chestController.dispose();
    super.dispose();
  }

  Future<void> _selectBirthDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 25)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: const Color(0xFF6C5CE7),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _birthDate = picked;
        _performRiskAssessment();
      });
    }
  }

  void _performRiskAssessment() {
    if (_birthDate == null) return;

    // Create temporary client for risk assessment
    final tempClient = Client(
      id: 'temp',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      fullName: _nameController.text,
      email: _emailController.text,
      phone: _phoneController.text,
      birthDate: _birthDate!,
      gender: _gender,
      trainerId: widget.trainerId,
      fitnessGoals: _selectedGoals.toList(),
      fitnessLevel: _fitnessLevel,
      medicalConditions: _medicalConditions,
      allergies: _allergies,
      injuries: _injuries,
      emergencyContacts: _emergencyContacts,
      preferences: ClientPreferences(
        preferredTrainingTimes: [],
        preferredTrainers: [],
        notificationSettings: {},
      ),
      hasHealthInsurance: _hasHealthInsurance,
      currentMeasurements: _createCurrentMeasurements(),
    );

    setState(() {
      _calculatedRisk = widget.riskAssessmentService.assessClientRisk(tempClient);
      _riskRecommendations = widget.riskAssessmentService
          .generateRiskRecommendations(tempClient, _calculatedRisk!);
    });
  }

  BodyMeasurements? _createCurrentMeasurements() {
    final weight = double.tryParse(_weightController.text);
    final height = double.tryParse(_heightController.text);

    if (weight == null && height == null) return null;

    return BodyMeasurements(
      weight: weight,
      height: height,
      bodyFatPercentage: double.tryParse(_bodyFatController.text),
      waist: double.tryParse(_waistController.text),
      chest: double.tryParse(_chestController.text),
      measurementDate: DateTime.now(),
    );
  }

  Future<void> _saveClient() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_birthDate == null) {
      _showError('Please select date of birth');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final newClient = Client(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: widget.trainerId,
        fullName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        alternativePhone: _alternativePhoneController.text.trim(),
        birthDate: _birthDate!,
        gender: _gender,
        addressLine1: _addressLine1Controller.text.trim(),
        addressLine2: _addressLine2Controller.text.trim(),
        city: _cityController.text.trim(),
        state: _stateController.text.trim(),
        zipCode: _zipCodeController.text.trim(),
        country: _countryController.text.trim(),
        occupation: _occupationController.text.trim(),
        company: _companyController.text.trim(),
        fitnessGoals: _selectedGoals.toList(),
        fitnessLevel: _fitnessLevel,
        preferredActivities: _preferredActivities,
        medicalConditions: _medicalConditions,
        allergies: _allergies,
        injuries: _injuries,
        bloodType: _bloodTypeController.text.trim(),
        hasHealthInsurance: _hasHealthInsurance,
        insuranceProvider: _insuranceProviderController.text.trim(),
        insuranceNumber: _insuranceNumberController.text.trim(),
        emergencyContacts: _emergencyContacts,
        measurementHistory: _createCurrentMeasurements() != null
            ? [_createCurrentMeasurements()!]
            : [],
        currentMeasurements: _createCurrentMeasurements(),
        status: _status,
        trainerId: widget.trainerId,
        preferences: ClientPreferences(
          preferredTrainingTimes: [],
          preferredTrainers: [widget.trainerId],
          receivesPromotions: _receivesPromotions,
          receivesReminders: _receivesReminders,
          notificationSettings: {
            'email': true,
            'sms': _receivesReminders,
            'push': true,
          },
        ),
        riskLevel: _calculatedRisk ?? RiskLevel.low,
        hasSignedWaiver: _hasSignedWaiver,
        waiverSignedDate: _hasSignedWaiver ? DateTime.now() : null,
        hasCompletedPARQ: _hasCompletedPARQ,
        parqCompletedDate: _hasCompletedPARQ ? DateTime.now() : null,
        gdprConsent: _gdprConsent,
        gdprConsentDate: _gdprConsent ? DateTime.now() : null,
      );

      // Validate client
      final validationResult = widget.validationService.validateClient(newClient);
      if (!validationResult.isValid) {
        setState(() {
          _validationErrors = validationResult.errors;
          _isLoading = false;
        });
        _showError('Please fix validation errors: ${validationResult.errors.values.first}');
        return;
      }

      // Check uniqueness
      final existingClients = await widget.repository.getAll();
      if (!widget.validationService.isEmailUnique(
        newClient.email,
        existingClients
      )) {
        _showError('Email already exists');
        setState(() => _isLoading = false);
        return;
      }

      // Save to repository
      await widget.repository.create(newClient);

      if (mounted) {
        _showSuccess('Client created successfully!');
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      _showError('Error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF6C5CE7),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Enterprise Client Management',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Personal'),
            Tab(text: 'Contact'),
            Tab(text: 'Fitness'),
            Tab(text: 'Medical'),
            Tab(text: 'Measurements'),
            Tab(text: 'Compliance'),
          ],
        ),
      ),
      body: Form(
        key: _formKey,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildPersonalInfoTab(),
            _buildContactInfoTab(),
            _buildFitnessInfoTab(),
            _buildMedicalInfoTab(),
            _buildMeasurementsTab(),
            _buildComplianceTab(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildPersonalInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo at the top
          Center(
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFF6C5CE7).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.fitness_center,
                size: 60,
                color: Color(0xFF6C5CE7),
              ),
            ),
          ),
          const SizedBox(height: 32),

          _buildSectionHeader('Basic Information'),
          const SizedBox(height: 16),
          TextFormField(
            controller: _nameController,
            decoration: _inputDecoration('Full Name', Icons.person),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter full name';
              }
              if (value.length < 2) {
                return 'Name must be at least 2 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _emailController,
            decoration: _inputDecoration('Email', Icons.email),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter email';
              }
              if (!value.contains('@')) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _phoneController,
                  decoration: _inputDecoration('Primary Phone', Icons.phone),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Required';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _alternativePhoneController,
                  decoration: _inputDecoration('Alternative', Icons.phone_android),
                  keyboardType: TextInputType.phone,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: _selectBirthDate,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, color: Color(0xFF6C5CE7)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _birthDate == null
                          ? 'Select Date of Birth'
                          : DateFormat('MMM dd, yyyy').format(_birthDate!),
                      style: TextStyle(
                        fontSize: 16,
                        color: _birthDate == null ? Colors.grey : Colors.black,
                      ),
                    ),
                  ),
                  if (_birthDate != null)
                    Text(
                      '${DateTime.now().year - _birthDate!.year} years',
                      style: const TextStyle(
                        color: Color(0xFF6C5CE7),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildGenderSelector(),
          const SizedBox(height: 24),
          _buildSectionHeader('Professional Information'),
          const SizedBox(height: 16),
          TextFormField(
            controller: _occupationController,
            decoration: _inputDecoration('Occupation', Icons.work),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _companyController,
            decoration: _inputDecoration('Company', Icons.business),
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Address Information'),
          const SizedBox(height: 16),
          TextFormField(
            controller: _addressLine1Controller,
            decoration: _inputDecoration('Address Line 1', Icons.home),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _addressLine2Controller,
            decoration: _inputDecoration('Address Line 2', Icons.home_work),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _cityController,
                  decoration: _inputDecoration('City', Icons.location_city),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _stateController,
                  decoration: _inputDecoration('State', Icons.map),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _zipCodeController,
                  decoration: _inputDecoration('ZIP Code', Icons.pin_drop),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _countryController,
                  decoration: _inputDecoration('Country', Icons.public),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Emergency Contacts'),
          const SizedBox(height: 16),
          _buildEmergencyContactForm(),
          const SizedBox(height: 16),
          ..._emergencyContacts.map((contact) => _buildEmergencyContactCard(contact)),
        ],
      ),
    );
  }

  Widget _buildFitnessInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Fitness Goals'),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: FitnessGoal.values.map((goal) {
              final isSelected = _selectedGoals.contains(goal);
              return FilterChip(
                label: Text(_formatEnumName(goal.toString())),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedGoals.add(goal);
                    } else {
                      _selectedGoals.remove(goal);
                    }
                  });
                },
                selectedColor: const Color(0xFF6C5CE7).withOpacity(0.2),
                checkmarkColor: const Color(0xFF6C5CE7),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Fitness Level'),
          const SizedBox(height: 16),
          _buildFitnessLevelSelector(),
          const SizedBox(height: 24),
          _buildSectionHeader('Preferred Activities'),
          const SizedBox(height: 16),
          _buildActivitySelector(),
        ],
      ),
    );
  }

  Widget _buildMedicalInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_calculatedRisk != null) _buildRiskAssessmentCard(),
          if (_calculatedRisk != null) const SizedBox(height: 16),
          _buildSectionHeader('Health Information'),
          const SizedBox(height: 16),
          TextFormField(
            controller: _bloodTypeController,
            decoration: _inputDecoration('Blood Type', Icons.water_drop),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Has Health Insurance'),
            value: _hasHealthInsurance,
            onChanged: (value) => setState(() => _hasHealthInsurance = value),
            activeColor: const Color(0xFF6C5CE7),
          ),
          if (_hasHealthInsurance) ...[
            const SizedBox(height: 16),
            TextFormField(
              controller: _insuranceProviderController,
              decoration: _inputDecoration('Insurance Provider', Icons.shield),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _insuranceNumberController,
              decoration: _inputDecoration('Insurance Number', Icons.numbers),
            ),
          ],
          const SizedBox(height: 24),
          _buildSectionHeader('Medical Conditions'),
          const SizedBox(height: 16),
          _buildMedicalConditionsList(),
          const SizedBox(height: 24),
          _buildSectionHeader('Allergies'),
          const SizedBox(height: 16),
          _buildAllergiesList(),
          const SizedBox(height: 24),
          _buildSectionHeader('Injuries'),
          const SizedBox(height: 16),
          _buildInjuriesList(),
        ],
      ),
    );
  }

  Widget _buildMeasurementsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Body Measurements'),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _weightController,
                  decoration: _inputDecoration('Weight (kg)', Icons.monitor_weight),
                  keyboardType: TextInputType.number,
                  onChanged: (_) => _performRiskAssessment(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _heightController,
                  decoration: _inputDecoration('Height (cm)', Icons.height),
                  keyboardType: TextInputType.number,
                  onChanged: (_) => _performRiskAssessment(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _bodyFatController,
            decoration: _inputDecoration('Body Fat %', Icons.percent),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _waistController,
                  decoration: _inputDecoration('Waist (cm)', Icons.straighten),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _chestController,
                  decoration: _inputDecoration('Chest (cm)', Icons.straighten),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          if (_createCurrentMeasurements()?.calculateBMI() != null) ...[
            const SizedBox(height: 24),
            _buildBMICard(),
          ],
        ],
      ),
    );
  }

  Widget _buildComplianceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Client Status'),
          const SizedBox(height: 16),
          _buildStatusSelector(),
          const SizedBox(height: 24),
          _buildSectionHeader('Legal Compliance'),
          const SizedBox(height: 16),
          CheckboxListTile(
            title: const Text('Waiver Signed'),
            subtitle: const Text('Client has signed liability waiver'),
            value: _hasSignedWaiver,
            onChanged: (value) => setState(() => _hasSignedWaiver = value!),
            activeColor: const Color(0xFF6C5CE7),
          ),
          CheckboxListTile(
            title: const Text('PAR-Q Completed'),
            subtitle: const Text('Physical Activity Readiness Questionnaire'),
            value: _hasCompletedPARQ,
            onChanged: (value) => setState(() => _hasCompletedPARQ = value!),
            activeColor: const Color(0xFF6C5CE7),
          ),
          CheckboxListTile(
            title: const Text('GDPR Consent'),
            subtitle: const Text('Data protection and privacy consent'),
            value: _gdprConsent,
            onChanged: (value) => setState(() => _gdprConsent = value!),
            activeColor: const Color(0xFF6C5CE7),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Communication Preferences'),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Promotional Emails'),
            subtitle: const Text('Receive offers and promotions'),
            value: _receivesPromotions,
            onChanged: (value) => setState(() => _receivesPromotions = value),
            activeColor: const Color(0xFF6C5CE7),
          ),
          SwitchListTile(
            title: const Text('Session Reminders'),
            subtitle: const Text('SMS and email reminders'),
            value: _receivesReminders,
            onChanged: (value) => setState(() => _receivesReminders = value),
            activeColor: const Color(0xFF6C5CE7),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_tabController.index > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  _tabController.animateTo(_tabController.index - 1);
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Previous'),
              ),
            ),
          if (_tabController.index > 0) const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : (_tabController.index < 5
                      ? () {
                          _tabController.animateTo(_tabController.index + 1);
                        }
                      : _saveClient),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C5CE7),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      _tabController.index < 5 ? 'Next' : 'Create Client',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF6C5CE7),
      ),
    );
  }

  Widget _buildGenderSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Gender',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: ['Male', 'Female', 'Other'].map((gender) {
              return Expanded(
                child: RadioListTile<String>(
                  title: Text(gender),
                  value: gender,
                  groupValue: _gender,
                  activeColor: const Color(0xFF6C5CE7),
                  onChanged: (value) => setState(() => _gender = value!),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFitnessLevelSelector() {
    final levels = ['sedentary', 'beginner', 'intermediate', 'advanced', 'elite'];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Current Fitness Level',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          ...levels.map((level) {
            return RadioListTile<String>(
              title: Text(_formatEnumName(level)),
              value: level,
              groupValue: _fitnessLevel,
              activeColor: const Color(0xFF6C5CE7),
              onChanged: (value) {
                setState(() {
                  _fitnessLevel = value!;
                  _performRiskAssessment();
                });
              },
              contentPadding: EdgeInsets.zero,
              dense: true,
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildActivitySelector() {
    final activities = [
      'Running', 'Swimming', 'Cycling', 'Yoga', 'Pilates',
      'CrossFit', 'Boxing', 'Dance', 'Martial Arts', 'Tennis'
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: activities.map((activity) {
        final isSelected = _preferredActivities.contains(activity);
        return FilterChip(
          label: Text(activity),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _preferredActivities.add(activity);
              } else {
                _preferredActivities.remove(activity);
              }
            });
          },
          selectedColor: const Color(0xFF6C5CE7).withOpacity(0.2),
          checkmarkColor: const Color(0xFF6C5CE7),
        );
      }).toList(),
    );
  }

  Widget _buildStatusSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ClientStatus.values.map((status) {
        final isSelected = _status == status;
        return ChoiceChip(
          label: Text(_formatEnumName(status.toString())),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) {
              setState(() => _status = status);
            }
          },
          selectedColor: const Color(0xFF6C5CE7),
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmergencyContactForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          TextFormField(
            controller: _emergencyNameController,
            decoration: _inputDecoration('Contact Name', Icons.person),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _emergencyPhoneController,
                  decoration: _inputDecoration('Phone', Icons.phone),
                  keyboardType: TextInputType.phone,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _emergencyRelationshipController,
                  decoration: _inputDecoration('Relationship', Icons.group),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _emergencyEmailController,
            decoration: _inputDecoration('Email (Optional)', Icons.email),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _addEmergencyContact,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('Add Emergency Contact'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C5CE7),
            ),
          ),
        ],
      ),
    );
  }

  void _addEmergencyContact() {
    if (_emergencyNameController.text.isEmpty ||
        _emergencyPhoneController.text.isEmpty ||
        _emergencyRelationshipController.text.isEmpty) {
      _showError('Please fill all required fields');
      return;
    }

    setState(() {
      _emergencyContacts.add(EmergencyContact(
        name: _emergencyNameController.text,
        phone: _emergencyPhoneController.text,
        relationship: _emergencyRelationshipController.text,
        email: _emergencyEmailController.text,
        isPrimary: _emergencyContacts.isEmpty,
      ));
      _emergencyNameController.clear();
      _emergencyPhoneController.clear();
      _emergencyRelationshipController.clear();
      _emergencyEmailController.clear();
    });
  }

  Widget _buildEmergencyContactCard(EmergencyContact contact) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: contact.isPrimary
              ? const Color(0xFF6C5CE7)
              : Colors.grey,
          child: const Icon(Icons.person, color: Colors.white),
        ),
        title: Text(contact.name),
        subtitle: Text('${contact.relationship} • ${contact.phone}'),
        trailing: IconButton(
          icon: const Icon(Icons.delete),
          onPressed: () {
            setState(() {
              _emergencyContacts.remove(contact);
            });
          },
        ),
      ),
    );
  }

  Widget _buildRiskAssessmentCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getRiskColor(_calculatedRisk!).withOpacity(0.1),
        border: Border.all(color: _getRiskColor(_calculatedRisk!)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning,
                color: _getRiskColor(_calculatedRisk!),
              ),
              const SizedBox(width: 8),
              Text(
                'Risk Assessment: ${_formatEnumName(_calculatedRisk.toString())}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _getRiskColor(_calculatedRisk!),
                ),
              ),
            ],
          ),
          if (_riskRecommendations.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'Recommendations:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ..._riskRecommendations.map((rec) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(fontSize: 16)),
                  Expanded(child: Text(rec)),
                ],
              ),
            )),
          ],
        ],
      ),
    );
  }

  Widget _buildBMICard() {
    final bmi = _createCurrentMeasurements()?.calculateBMI() ?? 0;
    String category;
    Color color;

    if (bmi < 18.5) {
      category = 'Underweight';
      color = Colors.orange;
    } else if (bmi < 25) {
      category = 'Normal';
      color = Colors.green;
    } else if (bmi < 30) {
      category = 'Overweight';
      color = Colors.orange;
    } else {
      category = 'Obese';
      color = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'BMI',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              Text(
                bmi.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              category,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicalConditionsList() {
    return Column(
      children: [
        if (_medicalConditions.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text('No medical conditions added'),
            ),
          ),
        ..._medicalConditions.map((condition) => Card(
          child: ListTile(
            title: Text(condition.name),
            subtitle: Text('Severity: ${condition.severity}'),
            trailing: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                setState(() {
                  _medicalConditions.remove(condition);
                  _performRiskAssessment();
                });
              },
            ),
          ),
        )),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: _showAddMedicalConditionDialog,
          icon: const Icon(Icons.add),
          label: const Text('Add Medical Condition'),
        ),
      ],
    );
  }

  Widget _buildAllergiesList() {
    return Column(
      children: [
        Wrap(
          spacing: 8,
          children: _allergies.map((allergy) => Chip(
            label: Text(allergy),
            onDeleted: () {
              setState(() => _allergies.remove(allergy));
            },
          )).toList(),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: _showAddAllergyDialog,
          icon: const Icon(Icons.add),
          label: const Text('Add Allergy'),
        ),
      ],
    );
  }

  Widget _buildInjuriesList() {
    return Column(
      children: [
        Wrap(
          spacing: 8,
          children: _injuries.map((injury) => Chip(
            label: Text(injury),
            backgroundColor: Colors.orange[100],
            onDeleted: () {
              setState(() {
                _injuries.remove(injury);
                _performRiskAssessment();
              });
            },
          )).toList(),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: _showAddInjuryDialog,
          icon: const Icon(Icons.add),
          label: const Text('Add Injury'),
        ),
      ],
    );
  }

  void _showAddMedicalConditionDialog() {
    final nameController = TextEditingController();
    String severity = 'low';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Medical Condition'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Condition Name',
                hintText: 'e.g., Diabetes, Hypertension',
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: severity,
              decoration: const InputDecoration(labelText: 'Severity'),
              items: ['low', 'medium', 'high', 'critical'].map((s) {
                return DropdownMenuItem(value: s, child: Text(s.toUpperCase()));
              }).toList(),
              onChanged: (value) {
                severity = value!;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                setState(() {
                  _medicalConditions.add(MedicalCondition(
                    name: nameController.text,
                    severity: severity,
                  ));
                  _performRiskAssessment();
                });
              }
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showAddAllergyDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Allergy'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Allergy',
            hintText: 'e.g., Peanuts, Dust',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                setState(() => _allergies.add(controller.text));
              }
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showAddInjuryDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Injury'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Injury',
            hintText: 'e.g., Lower back pain, Knee injury',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                setState(() {
                  _injuries.add(controller.text);
                  _performRiskAssessment();
                });
              }
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFF6C5CE7)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF6C5CE7), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  String _formatEnumName(String enumString) {
    final name = enumString.split('.').last;
    return name[0].toUpperCase() +
           name.substring(1).replaceAllMapped(
             RegExp(r'[A-Z]'),
             (match) => ' ${match.group(0)}'
           );
  }

  Color _getRiskColor(RiskLevel level) {
    switch (level) {
      case RiskLevel.low:
        return Colors.green;
      case RiskLevel.medium:
        return Colors.orange;
      case RiskLevel.high:
        return Colors.deepOrange;
      case RiskLevel.critical:
        return Colors.red;
    }
  }
}
