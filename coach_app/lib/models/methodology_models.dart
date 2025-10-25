/// Strength Method specific configuration (Westside Barbell style)
class StrengthMethodConfig {
  final MaxEffortConfig maxEffort;
  final DynamicEffortConfig dynamicEffort;
  final RepetitionEffortConfig repetitionEffort;
  final Map<String, List<String>> conjugateRotation; // Exercise rotation schedule
  final Map<String, dynamic> waveLoading;
  final List<String> specialMethods; // Accommodating resistance, chains, bands

  StrengthMethodConfig({
    required this.maxEffort,
    required this.dynamicEffort,
    required this.repetitionEffort,
    required this.conjugateRotation,
    required this.waveLoading,
    required this.specialMethods,
  });

  factory StrengthMethodConfig.fromMap(Map<String, dynamic> map) {
    return StrengthMethodConfig(
      maxEffort: MaxEffortConfig.fromMap(map['maxEffort']),
      dynamicEffort: DynamicEffortConfig.fromMap(map['dynamicEffort']),
      repetitionEffort: RepetitionEffortConfig.fromMap(map['repetitionEffort']),
      conjugateRotation: Map<String, List<String>>.from(
        map['conjugateRotation'].map(
          (key, value) => MapEntry(key, List<String>.from(value)),
        ),
      ),
      waveLoading: map['waveLoading'],
      specialMethods: List<String>.from(map['specialMethods']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'maxEffort': maxEffort.toMap(),
      'dynamicEffort': dynamicEffort.toMap(),
      'repetitionEffort': repetitionEffort.toMap(),
      'conjugateRotation': conjugateRotation,
      'waveLoading': waveLoading,
      'specialMethods': specialMethods,
    };
  }
}

class MaxEffortConfig {
  final List<String> movements; // Squat, bench, deadlift variations
  final Map<String, int> weeklyRotation;
  final double targetPercentage; // Usually 90-100%
  final int workUpSets;
  final int maxAttempts;

  MaxEffortConfig({
    required this.movements,
    required this.weeklyRotation,
    required this.targetPercentage,
    required this.workUpSets,
    required this.maxAttempts,
  });

  factory MaxEffortConfig.fromMap(Map<String, dynamic> map) {
    return MaxEffortConfig(
      movements: List<String>.from(map['movements']),
      weeklyRotation: Map<String, int>.from(map['weeklyRotation']),
      targetPercentage: map['targetPercentage'].toDouble(),
      workUpSets: map['workUpSets'],
      maxAttempts: map['maxAttempts'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'movements': movements,
      'weeklyRotation': weeklyRotation,
      'targetPercentage': targetPercentage,
      'workUpSets': workUpSets,
      'maxAttempts': maxAttempts,
    };
  }
}

class DynamicEffortConfig {
  final Map<String, WavePattern> wavePatterns;
  final double barSpeed; // m/s target
  final int boxHeights; // For box squats
  final Map<String, double> bandTension;
  final Map<String, double> chainWeight;
  final RestBetweenSets restProtocol;

  DynamicEffortConfig({
    required this.wavePatterns,
    required this.barSpeed,
    required this.boxHeights,
    required this.bandTension,
    required this.chainWeight,
    required this.restProtocol,
  });

  factory DynamicEffortConfig.fromMap(Map<String, dynamic> map) {
    return DynamicEffortConfig(
      wavePatterns: Map<String, WavePattern>.from(
        map['wavePatterns'].map(
          (key, value) => MapEntry(key, WavePattern.fromMap(value)),
        ),
      ),
      barSpeed: map['barSpeed'].toDouble(),
      boxHeights: map['boxHeights'],
      bandTension: Map<String, double>.from(map['bandTension']),
      chainWeight: Map<String, double>.from(map['chainWeight']),
      restProtocol: RestBetweenSets.fromMap(map['restProtocol']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'wavePatterns': wavePatterns.map((k, v) => MapEntry(k, v.toMap())),
      'barSpeed': barSpeed,
      'boxHeights': boxHeights,
      'bandTension': bandTension,
      'chainWeight': chainWeight,
      'restProtocol': restProtocol.toMap(),
    };
  }
}

class RepetitionEffortConfig {
  final Map<String, int> targetReps;
  final List<String> primaryExercises;
  final List<String> accessoryExercises;
  final String volumeProtocol; // High, moderate, low
  final Map<String, dynamic> dropSetProtocol;

  RepetitionEffortConfig({
    required this.targetReps,
    required this.primaryExercises,
    required this.accessoryExercises,
    required this.volumeProtocol,
    required this.dropSetProtocol,
  });

  factory RepetitionEffortConfig.fromMap(Map<String, dynamic> map) {
    return RepetitionEffortConfig(
      targetReps: Map<String, int>.from(map['targetReps']),
      primaryExercises: List<String>.from(map['primaryExercises']),
      accessoryExercises: List<String>.from(map['accessoryExercises']),
      volumeProtocol: map['volumeProtocol'],
      dropSetProtocol: map['dropSetProtocol'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'targetReps': targetReps,
      'primaryExercises': primaryExercises,
      'accessoryExercises': accessoryExercises,
      'volumeProtocol': volumeProtocol,
      'dropSetProtocol': dropSetProtocol,
    };
  }
}

class WavePattern {
  final List<int> weeks;
  final List<double> percentages;
  final List<String> setsReps;

  WavePattern({
    required this.weeks,
    required this.percentages,
    required this.setsReps,
  });

  factory WavePattern.fromMap(Map<String, dynamic> map) {
    return WavePattern(
      weeks: List<int>.from(map['weeks']),
      percentages: List<double>.from(map['percentages']),
      setsReps: List<String>.from(map['setsReps']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'weeks': weeks,
      'percentages': percentages,
      'setsReps': setsReps,
    };
  }
}

class RestBetweenSets {
  final int seconds;
  final String type; // Complete, active, etc.

  RestBetweenSets({
    required this.seconds,
    required this.type,
  });

  factory RestBetweenSets.fromMap(Map<String, dynamic> map) {
    return RestBetweenSets(
      seconds: map['seconds'],
      type: map['type'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'seconds': seconds,
      'type': type,
    };
  }
}

/// RPE-based training configuration
class RPEConfig {
  final bool autoregulation;
  final Map<String, RPEZone> trainingZones;
  final Map<String, double> weeklyRPETargets;
  final FatigueManagement fatigueProtocol;
  final Map<String, dynamic> rirCalculation; // Reps in Reserve
  final bool velocityTracking;

  RPEConfig({
    required this.autoregulation,
    required this.trainingZones,
    required this.weeklyRPETargets,
    required this.fatigueProtocol,
    required this.rirCalculation,
    required this.velocityTracking,
  });

  factory RPEConfig.fromMap(Map<String, dynamic> map) {
    return RPEConfig(
      autoregulation: map['autoregulation'],
      trainingZones: Map<String, RPEZone>.from(
        map['trainingZones'].map(
          (key, value) => MapEntry(key, RPEZone.fromMap(value)),
        ),
      ),
      weeklyRPETargets: Map<String, double>.from(map['weeklyRPETargets']),
      fatigueProtocol: FatigueManagement.fromMap(map['fatigueProtocol']),
      rirCalculation: map['rirCalculation'],
      velocityTracking: map['velocityTracking'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'autoregulation': autoregulation,
      'trainingZones': trainingZones.map((k, v) => MapEntry(k, v.toMap())),
      'weeklyRPETargets': weeklyRPETargets,
      'fatigueProtocol': fatigueProtocol.toMap(),
      'rirCalculation': rirCalculation,
      'velocityTracking': velocityTracking,
    };
  }
}

class RPEZone {
  final double minRPE;
  final double maxRPE;
  final String purpose;
  final int repsInReserve;

  RPEZone({
    required this.minRPE,
    required this.maxRPE,
    required this.purpose,
    required this.repsInReserve,
  });

  factory RPEZone.fromMap(Map<String, dynamic> map) {
    return RPEZone(
      minRPE: map['minRPE'].toDouble(),
      maxRPE: map['maxRPE'].toDouble(),
      purpose: map['purpose'],
      repsInReserve: map['repsInReserve'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'minRPE': minRPE,
      'maxRPE': maxRPE,
      'purpose': purpose,
      'repsInReserve': repsInReserve,
    };
  }
}

class FatigueManagement {
  final double maxFatigueLevel;
  final String deloadTrigger;
  final Map<String, dynamic> recoveryMetrics;

  FatigueManagement({
    required this.maxFatigueLevel,
    required this.deloadTrigger,
    required this.recoveryMetrics,
  });

  factory FatigueManagement.fromMap(Map<String, dynamic> map) {
    return FatigueManagement(
      maxFatigueLevel: map['maxFatigueLevel'].toDouble(),
      deloadTrigger: map['deloadTrigger'],
      recoveryMetrics: map['recoveryMetrics'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'maxFatigueLevel': maxFatigueLevel,
      'deloadTrigger': deloadTrigger,
      'recoveryMetrics': recoveryMetrics,
    };
  }
}

/// Hyrox specific configuration
class HyroxConfig {
  final List<HyroxStation> stations;
  final Map<String, dynamic> transitionTraining;
  final Map<String, double> paceTargets;
  final CompetitionClass competitionClass;
  final Map<String, dynamic> simulations;

  HyroxConfig({
    required this.stations,
    required this.transitionTraining,
    required this.paceTargets,
    required this.competitionClass,
    required this.simulations,
  });

  factory HyroxConfig.fromMap(Map<String, dynamic> map) {
    return HyroxConfig(
      stations: (map['stations'] as List<dynamic>)
          .map((s) => HyroxStation.fromMap(s))
          .toList(),
      transitionTraining: map['transitionTraining'],
      paceTargets: Map<String, double>.from(map['paceTargets']),
      competitionClass: CompetitionClass.values.firstWhere(
        (e) => e.name == map['competitionClass'],
      ),
      simulations: map['simulations'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'stations': stations.map((s) => s.toMap()).toList(),
      'transitionTraining': transitionTraining,
      'paceTargets': paceTargets,
      'competitionClass': competitionClass.name,
      'simulations': simulations,
    };
  }
}

class HyroxStation {
  final String name;
  final int order;
  final double distance; // meters or reps
  final String equipment;
  final Map<String, dynamic> technique;
  final double targetTime; // seconds

  HyroxStation({
    required this.name,
    required this.order,
    required this.distance,
    required this.equipment,
    required this.technique,
    required this.targetTime,
  });

  factory HyroxStation.fromMap(Map<String, dynamic> map) {
    return HyroxStation(
      name: map['name'],
      order: map['order'],
      distance: map['distance'].toDouble(),
      equipment: map['equipment'],
      technique: map['technique'],
      targetTime: map['targetTime'].toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'order': order,
      'distance': distance,
      'equipment': equipment,
      'technique': technique,
      'targetTime': targetTime,
    };
  }
}

enum CompetitionClass {
  open,
  pro,
  doubles,
  relay,
}

/// CrossFit specific configuration
class CrossFitConfig {
  final WODGenerator wodGenerator;
  final Map<String, MetconDomain> energySystems;
  final OlympicLiftingProgression olympicProgression;
  final GymnasticsSkills gymnasticsSkills;
  final Map<String, dynamic> benchmarks; // Girls, Heroes, etc.
  final CompetitionPrep competitionPrep;

  CrossFitConfig({
    required this.wodGenerator,
    required this.energySystems,
    required this.olympicProgression,
    required this.gymnasticsSkills,
    required this.benchmarks,
    required this.competitionPrep,
  });

  factory CrossFitConfig.fromMap(Map<String, dynamic> map) {
    return CrossFitConfig(
      wodGenerator: WODGenerator.fromMap(map['wodGenerator']),
      energySystems: Map<String, MetconDomain>.from(
        map['energySystems'].map(
          (key, value) => MapEntry(key, MetconDomain.fromMap(value)),
        ),
      ),
      olympicProgression: OlympicLiftingProgression.fromMap(map['olympicProgression']),
      gymnasticsSkills: GymnasticsSkills.fromMap(map['gymnasticsSkills']),
      benchmarks: map['benchmarks'],
      competitionPrep: CompetitionPrep.fromMap(map['competitionPrep']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'wodGenerator': wodGenerator.toMap(),
      'energySystems': energySystems.map((k, v) => MapEntry(k, v.toMap())),
      'olympicProgression': olympicProgression.toMap(),
      'gymnasticsSkills': gymnasticsSkills.toMap(),
      'benchmarks': benchmarks,
      'competitionPrep': competitionPrep.toMap(),
    };
  }
}

class WODGenerator {
  final List<String> movements;
  final Map<String, int> movementWeights; // Probability weights
  final Map<String, dynamic> timeCapRanges;
  final List<String> formats; // AMRAP, For Time, EMOM, etc.
  final bool scalingOptions;

  WODGenerator({
    required this.movements,
    required this.movementWeights,
    required this.timeCapRanges,
    required this.formats,
    required this.scalingOptions,
  });

  factory WODGenerator.fromMap(Map<String, dynamic> map) {
    return WODGenerator(
      movements: List<String>.from(map['movements']),
      movementWeights: Map<String, int>.from(map['movementWeights']),
      timeCapRanges: map['timeCapRanges'],
      formats: List<String>.from(map['formats']),
      scalingOptions: map['scalingOptions'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'movements': movements,
      'movementWeights': movementWeights,
      'timeCapRanges': timeCapRanges,
      'formats': formats,
      'scalingOptions': scalingOptions,
    };
  }
}

class MetconDomain {
  final String name; // Phosphagen, Glycolytic, Oxidative
  final int durationRange; // seconds
  final int workRestRatio;
  final double intensity;

  MetconDomain({
    required this.name,
    required this.durationRange,
    required this.workRestRatio,
    required this.intensity,
  });

  factory MetconDomain.fromMap(Map<String, dynamic> map) {
    return MetconDomain(
      name: map['name'],
      durationRange: map['durationRange'],
      workRestRatio: map['workRestRatio'],
      intensity: map['intensity'].toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'durationRange': durationRange,
      'workRestRatio': workRestRatio,
      'intensity': intensity,
    };
  }
}

class OlympicLiftingProgression {
  final Map<String, List<String>> progressions;
  final Map<String, dynamic> technique;
  final Map<String, double> percentages;

  OlympicLiftingProgression({
    required this.progressions,
    required this.technique,
    required this.percentages,
  });

  factory OlympicLiftingProgression.fromMap(Map<String, dynamic> map) {
    return OlympicLiftingProgression(
      progressions: Map<String, List<String>>.from(
        map['progressions'].map(
          (key, value) => MapEntry(key, List<String>.from(value)),
        ),
      ),
      technique: map['technique'],
      percentages: Map<String, double>.from(map['percentages']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'progressions': progressions,
      'technique': technique,
      'percentages': percentages,
    };
  }
}

class GymnasticsSkills {
  final Map<String, List<String>> skillProgressions;
  final Map<String, int> skillLevels;
  final Map<String, dynamic> drills;

  GymnasticsSkills({
    required this.skillProgressions,
    required this.skillLevels,
    required this.drills,
  });

  factory GymnasticsSkills.fromMap(Map<String, dynamic> map) {
    return GymnasticsSkills(
      skillProgressions: Map<String, List<String>>.from(
        map['skillProgressions'].map(
          (key, value) => MapEntry(key, List<String>.from(value)),
        ),
      ),
      skillLevels: Map<String, int>.from(map['skillLevels']),
      drills: map['drills'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'skillProgressions': skillProgressions,
      'skillLevels': skillLevels,
      'drills': drills,
    };
  }
}

class CompetitionPrep {
  final String phase;
  final Map<String, dynamic> peaking;
  final Map<String, dynamic> strategy;

  CompetitionPrep({
    required this.phase,
    required this.peaking,
    required this.strategy,
  });

  factory CompetitionPrep.fromMap(Map<String, dynamic> map) {
    return CompetitionPrep(
      phase: map['phase'],
      peaking: map['peaking'],
      strategy: map['strategy'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'phase': phase,
      'peaking': peaking,
      'strategy': strategy,
    };
  }
}

/// Calisthenics specific configuration
class CalisthenicsConfig {
  final Map<String, SkillProgression> skills;
  final Map<String, int> currentLevels;
  final Map<String, dynamic> mobilityWork;
  final Map<String, dynamic> strengthStandards;
  final IsometricTraining isometrics;

  CalisthenicsConfig({
    required this.skills,
    required this.currentLevels,
    required this.mobilityWork,
    required this.strengthStandards,
    required this.isometrics,
  });

  factory CalisthenicsConfig.fromMap(Map<String, dynamic> map) {
    return CalisthenicsConfig(
      skills: Map<String, SkillProgression>.from(
        map['skills'].map(
          (key, value) => MapEntry(key, SkillProgression.fromMap(value)),
        ),
      ),
      currentLevels: Map<String, int>.from(map['currentLevels']),
      mobilityWork: map['mobilityWork'],
      strengthStandards: map['strengthStandards'],
      isometrics: IsometricTraining.fromMap(map['isometrics']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'skills': skills.map((k, v) => MapEntry(k, v.toMap())),
      'currentLevels': currentLevels,
      'mobilityWork': mobilityWork,
      'strengthStandards': strengthStandards,
      'isometrics': isometrics.toMap(),
    };
  }
}

class SkillProgression {
  final String skillName;
  final List<String> progressions;
  final int currentLevel;
  final Map<String, dynamic> prerequisites;
  final Map<String, dynamic> drills;

  SkillProgression({
    required this.skillName,
    required this.progressions,
    required this.currentLevel,
    required this.prerequisites,
    required this.drills,
  });

  factory SkillProgression.fromMap(Map<String, dynamic> map) {
    return SkillProgression(
      skillName: map['skillName'],
      progressions: List<String>.from(map['progressions']),
      currentLevel: map['currentLevel'],
      prerequisites: map['prerequisites'],
      drills: map['drills'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'skillName': skillName,
      'progressions': progressions,
      'currentLevel': currentLevel,
      'prerequisites': prerequisites,
      'drills': drills,
    };
  }
}

class IsometricTraining {
  final Map<String, int> holdTimes;
  final Map<String, dynamic> positions;

  IsometricTraining({
    required this.holdTimes,
    required this.positions,
  });

  factory IsometricTraining.fromMap(Map<String, dynamic> map) {
    return IsometricTraining(
      holdTimes: Map<String, int>.from(map['holdTimes']),
      positions: map['positions'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'holdTimes': holdTimes,
      'positions': positions,
    };
  }
}

/// Powerlifting specific configuration
class PowerliftingConfig {
  final PeriodizationModel periodization;
  final Map<String, LiftSpecifics> mainLifts;
  final Map<String, dynamic> accessoryWork;
  final PeakingProtocol peaking;
  final Map<String, dynamic> technique;

  PowerliftingConfig({
    required this.periodization,
    required this.mainLifts,
    required this.accessoryWork,
    required this.peaking,
    required this.technique,
  });

  factory PowerliftingConfig.fromMap(Map<String, dynamic> map) {
    return PowerliftingConfig(
      periodization: PeriodizationModel.fromMap(map['periodization']),
      mainLifts: Map<String, LiftSpecifics>.from(
        map['mainLifts'].map(
          (key, value) => MapEntry(key, LiftSpecifics.fromMap(value)),
        ),
      ),
      accessoryWork: map['accessoryWork'],
      peaking: PeakingProtocol.fromMap(map['peaking']),
      technique: map['technique'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'periodization': periodization.toMap(),
      'mainLifts': mainLifts.map((k, v) => MapEntry(k, v.toMap())),
      'accessoryWork': accessoryWork,
      'peaking': peaking.toMap(),
      'technique': technique,
    };
  }
}

class PeriodizationModel {
  final String type; // Linear, Block, DUP, Conjugate
  final Map<String, dynamic> phases;
  final Map<String, dynamic> volumeProgression;
  final Map<String, dynamic> intensityProgression;

  PeriodizationModel({
    required this.type,
    required this.phases,
    required this.volumeProgression,
    required this.intensityProgression,
  });

  factory PeriodizationModel.fromMap(Map<String, dynamic> map) {
    return PeriodizationModel(
      type: map['type'],
      phases: map['phases'],
      volumeProgression: map['volumeProgression'],
      intensityProgression: map['intensityProgression'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'phases': phases,
      'volumeProgression': volumeProgression,
      'intensityProgression': intensityProgression,
    };
  }
}

class LiftSpecifics {
  final String liftName;
  final double currentMax;
  final Map<String, dynamic> variations;
  final Map<String, dynamic> weakPoints;
  final Map<String, dynamic> techniqueFocus;

  LiftSpecifics({
    required this.liftName,
    required this.currentMax,
    required this.variations,
    required this.weakPoints,
    required this.techniqueFocus,
  });

  factory LiftSpecifics.fromMap(Map<String, dynamic> map) {
    return LiftSpecifics(
      liftName: map['liftName'],
      currentMax: map['currentMax'].toDouble(),
      variations: map['variations'],
      weakPoints: map['weakPoints'],
      techniqueFocus: map['techniqueFocus'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'liftName': liftName,
      'currentMax': currentMax,
      'variations': variations,
      'weakPoints': weakPoints,
      'techniqueFocus': techniqueFocus,
    };
  }
}

class PeakingProtocol {
  final int weeksOut;
  final Map<String, dynamic> taperSchedule;
  final Map<String, dynamic> openerSelection;

  PeakingProtocol({
    required this.weeksOut,
    required this.taperSchedule,
    required this.openerSelection,
  });

  factory PeakingProtocol.fromMap(Map<String, dynamic> map) {
    return PeakingProtocol(
      weeksOut: map['weeksOut'],
      taperSchedule: map['taperSchedule'],
      openerSelection: map['openerSelection'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'weeksOut': weeksOut,
      'taperSchedule': taperSchedule,
      'openerSelection': openerSelection,
    };
  }
}

/// Strongman specific configuration
class StrongmanConfig {
  final List<StrongmanEvent> events;
  final Map<String, ImplementTraining> implements;
  final Map<String, dynamic> conditioningWork;
  final Map<String, dynamic> strengthBase;
  final EventSimulation eventSim;

  StrongmanConfig({
    required this.events,
    required this.implements,
    required this.conditioningWork,
    required this.strengthBase,
    required this.eventSim,
  });

  factory StrongmanConfig.fromMap(Map<String, dynamic> map) {
    return StrongmanConfig(
      events: (map['events'] as List<dynamic>)
          .map((e) => StrongmanEvent.fromMap(e))
          .toList(),
      implements: Map<String, ImplementTraining>.from(
        map['implements'].map(
          (key, value) => MapEntry(key, ImplementTraining.fromMap(value)),
        ),
      ),
      conditioningWork: map['conditioningWork'],
      strengthBase: map['strengthBase'],
      eventSim: EventSimulation.fromMap(map['eventSim']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'events': events.map((e) => e.toMap()).toList(),
      'implements': implements.map((k, v) => MapEntry(k, v.toMap())),
      'conditioningWork': conditioningWork,
      'strengthBase': strengthBase,
      'eventSim': eventSim.toMap(),
    };
  }
}

class StrongmanEvent {
  final String name;
  final String type; // Max, reps, time, medley
  final Map<String, dynamic> implements;
  final Map<String, dynamic> technique;
  final Map<String, dynamic> training;

  StrongmanEvent({
    required this.name,
    required this.type,
    required this.implements,
    required this.technique,
    required this.training,
  });

  factory StrongmanEvent.fromMap(Map<String, dynamic> map) {
    return StrongmanEvent(
      name: map['name'],
      type: map['type'],
      implements: map['implements'],
      technique: map['technique'],
      training: map['training'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'type': type,
      'implements': implements,
      'technique': technique,
      'training': training,
    };
  }
}

class ImplementTraining {
  final String implementName;
  final Map<String, dynamic> progressions;
  final Map<String, dynamic> technique;

  ImplementTraining({
    required this.implementName,
    required this.progressions,
    required this.technique,
  });

  factory ImplementTraining.fromMap(Map<String, dynamic> map) {
    return ImplementTraining(
      implementName: map['implementName'],
      progressions: map['progressions'],
      technique: map['technique'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'implementName': implementName,
      'progressions': progressions,
      'technique': technique,
    };
  }
}

class EventSimulation {
  final Map<String, dynamic> competitionSetup;
  final Map<String, dynamic> mockMeets;

  EventSimulation({
    required this.competitionSetup,
    required this.mockMeets,
  });

  factory EventSimulation.fromMap(Map<String, dynamic> map) {
    return EventSimulation(
      competitionSetup: map['competitionSetup'],
      mockMeets: map['mockMeets'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'competitionSetup': competitionSetup,
      'mockMeets': mockMeets,
    };
  }
}