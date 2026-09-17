import 'package:cloud_firestore/cloud_firestore.dart';

/// Data model representing evidence-based Mentor Quality & Reputation metrics.
/// Stored in the protected Firestore collection `mentor_metrics/{mentorUserId}`.
class MentorMetricsModel {
  final String mentorUserId;
  final int completedExchanges;
  final int successfulExchanges;
  final int learningPlansCompleted;
  final int topicsAssigned;
  final int topicsTaught;
  final int topicsLearnerConfirmed;
  final int topicsPartiallyUnderstood;
  final int topicsNeedHelp;
  final int validatedLearningIssues;
  final int dismissedLearningIssues;
  final int correctiveInterventions;
  final int additionalTeachingInterventions;
  final int rematchInterventions;
  final double learnerRatingAverage;
  final int learnerRatingCount;
  final int verifiedSkillCount;
  final double? qualityScore;
  final bool sufficientHistory;
  final DateTime createdAt;
  final DateTime updatedAt;

  MentorMetricsModel({
    required this.mentorUserId,
    this.completedExchanges = 0,
    this.successfulExchanges = 0,
    this.learningPlansCompleted = 0,
    this.topicsAssigned = 0,
    this.topicsTaught = 0,
    this.topicsLearnerConfirmed = 0,
    this.topicsPartiallyUnderstood = 0,
    this.topicsNeedHelp = 0,
    this.validatedLearningIssues = 0,
    this.dismissedLearningIssues = 0,
    this.correctiveInterventions = 0,
    this.additionalTeachingInterventions = 0,
    this.rematchInterventions = 0,
    this.learnerRatingAverage = 0.0,
    this.learnerRatingCount = 0,
    this.verifiedSkillCount = 0,
    this.qualityScore,
    this.sufficientHistory = false,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Topic Delivery Confirmation Rate (0.0 to 100.0%)
  double get topicDeliveryRate {
    if (topicsTaught == 0) return 0.0;
    final effectiveConfirmed = topicsLearnerConfirmed + (0.5 * topicsPartiallyUnderstood);
    return ((effectiveConfirmed / topicsTaught) * 100.0).clamp(0.0, 100.0);
  }

  /// Calculates a transparent, defensible Quality Score (0.0 to 100.0)
  /// Returns null if [sufficientHistory] is false.
  static double? calculateScore({
    required int completedExchanges,
    required int topicsTaught,
    required int topicsLearnerConfirmed,
    required int topicsPartiallyUnderstood,
    required int validatedLearningIssues,
    required int rematchInterventions,
    required double learnerRatingAverage,
    required int learnerRatingCount,
  }) {
    final hasMinHistory = completedExchanges >= 3 || topicsTaught >= 5;
    if (!hasMinHistory) return null;

    // 1. Topic Delivery Confirmation Rate (40% weight)
    final deliveryRate = topicsTaught > 0
        ? (((topicsLearnerConfirmed + (0.5 * topicsPartiallyUnderstood)) / topicsTaught) * 100.0).clamp(0.0, 100.0)
        : 80.0;

    // 2. Accountability Score (30% weight) - Deducts ONLY for validated issues & rematches
    final accountabilityPenalty = (validatedLearningIssues * 15.0) + (rematchInterventions * 20.0);
    final accountabilityScore = (100.0 - accountabilityPenalty).clamp(0.0, 100.0);

    // 3. Normalized Learner Rating (30% weight)
    final normalizedRatingScore = learnerRatingCount > 0
        ? ((learnerRatingAverage / 5.0) * 100.0).clamp(0.0, 100.0)
        : 80.0; // Default baseline if no reviews yet

    final rawScore = (0.40 * deliveryRate) + (0.30 * accountabilityScore) + (0.30 * normalizedRatingScore);
    return double.parse(rawScore.toStringAsFixed(1));
  }

  Map<String, dynamic> toMap() {
    return {
      'mentorUserId': mentorUserId,
      'completedExchanges': completedExchanges,
      'successfulExchanges': successfulExchanges,
      'learningPlansCompleted': learningPlansCompleted,
      'topicsAssigned': topicsAssigned,
      'topicsTaught': topicsTaught,
      'topicsLearnerConfirmed': topicsLearnerConfirmed,
      'topicsPartiallyUnderstood': topicsPartiallyUnderstood,
      'topicsNeedHelp': topicsNeedHelp,
      'validatedLearningIssues': validatedLearningIssues,
      'dismissedLearningIssues': dismissedLearningIssues,
      'correctiveInterventions': correctiveInterventions,
      'additionalTeachingInterventions': additionalTeachingInterventions,
      'rematchInterventions': rematchInterventions,
      'learnerRatingAverage': learnerRatingAverage,
      'learnerRatingCount': learnerRatingCount,
      'verifiedSkillCount': verifiedSkillCount,
      'qualityScore': qualityScore,
      'sufficientHistory': sufficientHistory,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory MentorMetricsModel.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.parse(value);
      return DateTime.now();
    }

    return MentorMetricsModel(
      mentorUserId: map['mentorUserId'] ?? '',
      completedExchanges: map['completedExchanges'] ?? 0,
      successfulExchanges: map['successfulExchanges'] ?? 0,
      learningPlansCompleted: map['learningPlansCompleted'] ?? 0,
      topicsAssigned: map['topicsAssigned'] ?? 0,
      topicsTaught: map['topicsTaught'] ?? 0,
      topicsLearnerConfirmed: map['topicsLearnerConfirmed'] ?? 0,
      topicsPartiallyUnderstood: map['topicsPartiallyUnderstood'] ?? 0,
      topicsNeedHelp: map['topicsNeedHelp'] ?? 0,
      validatedLearningIssues: map['validatedLearningIssues'] ?? 0,
      dismissedLearningIssues: map['dismissedLearningIssues'] ?? 0,
      correctiveInterventions: map['correctiveInterventions'] ?? 0,
      additionalTeachingInterventions: map['additionalTeachingInterventions'] ?? 0,
      rematchInterventions: map['rematchInterventions'] ?? 0,
      learnerRatingAverage: (map['learnerRatingAverage'] ?? 0.0).toDouble(),
      learnerRatingCount: map['learnerRatingCount'] ?? 0,
      verifiedSkillCount: map['verifiedSkillCount'] ?? 0,
      qualityScore: map['qualityScore'] != null ? (map['qualityScore'] as num).toDouble() : null,
      sufficientHistory: map['sufficientHistory'] ?? false,
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
    );
  }

  MentorMetricsModel copyWith({
    String? mentorUserId,
    int? completedExchanges,
    int? successfulExchanges,
    int? learningPlansCompleted,
    int? topicsAssigned,
    int? topicsTaught,
    int? topicsLearnerConfirmed,
    int? topicsPartiallyUnderstood,
    int? topicsNeedHelp,
    int? validatedLearningIssues,
    int? dismissedLearningIssues,
    int? correctiveInterventions,
    int? additionalTeachingInterventions,
    int? rematchInterventions,
    double? learnerRatingAverage,
    int? learnerRatingCount,
    int? verifiedSkillCount,
    double? qualityScore,
    bool? sufficientHistory,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MentorMetricsModel(
      mentorUserId: mentorUserId ?? this.mentorUserId,
      completedExchanges: completedExchanges ?? this.completedExchanges,
      successfulExchanges: successfulExchanges ?? this.successfulExchanges,
      learningPlansCompleted: learningPlansCompleted ?? this.learningPlansCompleted,
      topicsAssigned: topicsAssigned ?? this.topicsAssigned,
      topicsTaught: topicsTaught ?? this.topicsTaught,
      topicsLearnerConfirmed: topicsLearnerConfirmed ?? this.topicsLearnerConfirmed,
      topicsPartiallyUnderstood: topicsPartiallyUnderstood ?? this.topicsPartiallyUnderstood,
      topicsNeedHelp: topicsNeedHelp ?? this.topicsNeedHelp,
      validatedLearningIssues: validatedLearningIssues ?? this.validatedLearningIssues,
      dismissedLearningIssues: dismissedLearningIssues ?? this.dismissedLearningIssues,
      correctiveInterventions: correctiveInterventions ?? this.correctiveInterventions,
      additionalTeachingInterventions: additionalTeachingInterventions ?? this.additionalTeachingInterventions,
      rematchInterventions: rematchInterventions ?? this.rematchInterventions,
      learnerRatingAverage: learnerRatingAverage ?? this.learnerRatingAverage,
      learnerRatingCount: learnerRatingCount ?? this.learnerRatingCount,
      verifiedSkillCount: verifiedSkillCount ?? this.verifiedSkillCount,
      qualityScore: qualityScore ?? this.qualityScore,
      sufficientHistory: sufficientHistory ?? this.sufficientHistory,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
