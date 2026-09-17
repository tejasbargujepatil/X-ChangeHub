enum LearnerTopicStatus {
  pending,
  taught,
  completed,
  partiallyUnderstood,
  needHelp;

  static LearnerTopicStatus fromMap(String? status) {
    if (status == null) return LearnerTopicStatus.pending;
    return LearnerTopicStatus.values.firstWhere(
      (e) => e.name == status,
      orElse: () => LearnerTopicStatus.pending,
    );
  }
}

enum LearningPlanStatus {
  draft,
  active,
  completed,
  disputed,
  cancelled;

  static LearningPlanStatus fromMap(String? status) {
    if (status == null) return LearningPlanStatus.draft;
    return LearningPlanStatus.values.firstWhere(
      (e) => e.name == status,
      orElse: () => LearningPlanStatus.draft,
    );
  }
}

class LearningTopic {
  final String topicId;
  final String title;
  final String? expectedOutcome;
  final bool taughtByMentor;
  final DateTime? taughtAt;
  final String? mentorNotes;
  final bool learnerConfirmed;
  final LearnerTopicStatus learnerStatus;
  final DateTime? learnerConfirmedAt;
  final String? learnerFeedback;

  LearningTopic({
    required this.topicId,
    required this.title,
    this.expectedOutcome,
    this.taughtByMentor = false,
    this.taughtAt,
    this.mentorNotes,
    this.learnerConfirmed = false,
    this.learnerStatus = LearnerTopicStatus.pending,
    this.learnerConfirmedAt,
    this.learnerFeedback,
  });

  Map<String, dynamic> toMap() {
    return {
      'topicId': topicId,
      'title': title,
      'expectedOutcome': expectedOutcome,
      'taughtByMentor': taughtByMentor,
      'taughtAt': taughtAt?.toIso8601String(),
      'mentorNotes': mentorNotes,
      'learnerConfirmed': learnerConfirmed,
      'learnerStatus': learnerStatus.name,
      'learnerConfirmedAt': learnerConfirmedAt?.toIso8601String(),
      'learnerFeedback': learnerFeedback,
    };
  }

  factory LearningTopic.fromMap(Map<String, dynamic> map) {
    return LearningTopic(
      topicId: map['topicId'] ?? '',
      title: map['title'] ?? '',
      expectedOutcome: map['expectedOutcome'],
      taughtByMentor: map['taughtByMentor'] ?? false,
      taughtAt: map['taughtAt'] != null ? _parseDateTime(map['taughtAt']) : null,
      mentorNotes: map['mentorNotes'],
      learnerConfirmed: map['learnerConfirmed'] ?? false,
      learnerStatus: LearnerTopicStatus.fromMap(map['learnerStatus']),
      learnerConfirmedAt: map['learnerConfirmedAt'] != null
          ? _parseDateTime(map['learnerConfirmedAt'])
          : null,
      learnerFeedback: map['learnerFeedback'],
    );
  }

  LearningTopic copyWith({
    String? topicId,
    String? title,
    String? expectedOutcome,
    bool? taughtByMentor,
    DateTime? taughtAt,
    String? mentorNotes,
    bool? learnerConfirmed,
    LearnerTopicStatus? learnerStatus,
    DateTime? learnerConfirmedAt,
    String? learnerFeedback,
  }) {
    return LearningTopic(
      topicId: topicId ?? this.topicId,
      title: title ?? this.title,
      expectedOutcome: expectedOutcome ?? this.expectedOutcome,
      taughtByMentor: taughtByMentor ?? this.taughtByMentor,
      taughtAt: taughtAt ?? this.taughtAt,
      mentorNotes: mentorNotes ?? this.mentorNotes,
      learnerConfirmed: learnerConfirmed ?? this.learnerConfirmed,
      learnerStatus: learnerStatus ?? this.learnerStatus,
      learnerConfirmedAt: learnerConfirmedAt ?? this.learnerConfirmedAt,
      learnerFeedback: learnerFeedback ?? this.learnerFeedback,
    );
  }

  static DateTime _parseDateTime(dynamic val) {
    if (val is String) return DateTime.parse(val);
    if (val != null && val.runtimeType.toString() == 'Timestamp') {
      return (val as dynamic).toDate();
    }
    return DateTime.now();
  }
}

class LearningModule {
  final String moduleId;
  final String title;
  final int order;
  final List<LearningTopic> topics;

  LearningModule({
    required this.moduleId,
    required this.title,
    required this.order,
    this.topics = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'moduleId': moduleId,
      'title': title,
      'order': order,
      'topics': topics.map((t) => t.toMap()).toList(),
    };
  }

  factory LearningModule.fromMap(Map<String, dynamic> map) {
    return LearningModule(
      moduleId: map['moduleId'] ?? '',
      title: map['title'] ?? '',
      order: map['order'] ?? 0,
      topics: map['topics'] != null
          ? (map['topics'] as List)
              .map((t) => LearningTopic.fromMap(Map<String, dynamic>.from(t)))
              .toList()
          : [],
    );
  }

  LearningModule copyWith({
    String? moduleId,
    String? title,
    int? order,
    List<LearningTopic>? topics,
  }) {
    return LearningModule(
      moduleId: moduleId ?? this.moduleId,
      title: title ?? this.title,
      order: order ?? this.order,
      topics: topics ?? this.topics,
    );
  }
}

class LearningPlan {
  final String planId;
  final String exchangeId;
  final String mentorId;
  final String learnerId;
  final String skillName;
  final LearningPlanStatus status;
  final int totalTopics;
  final int completedTopics;
  final int partiallyUnderstoodTopics;
  final int needHelpTopics;
  final double overallProgressPercentage;
  final List<LearningModule> modules;
  final DateTime createdAt;
  final DateTime updatedAt;

  LearningPlan({
    required this.planId,
    required this.exchangeId,
    required this.mentorId,
    required this.learnerId,
    required this.skillName,
    this.status = LearningPlanStatus.draft,
    this.totalTopics = 0,
    this.completedTopics = 0,
    this.partiallyUnderstoodTopics = 0,
    this.needHelpTopics = 0,
    this.overallProgressPercentage = 0.0,
    this.modules = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'planId': planId,
      'exchangeId': exchangeId,
      'mentorId': mentorId,
      'learnerId': learnerId,
      'skillName': skillName,
      'status': status.name,
      'totalTopics': totalTopics,
      'completedTopics': completedTopics,
      'partiallyUnderstoodTopics': partiallyUnderstoodTopics,
      'needHelpTopics': needHelpTopics,
      'overallProgressPercentage': overallProgressPercentage,
      'modules': modules.map((m) => m.toMap()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory LearningPlan.fromMap(Map<String, dynamic> map) {
    final modulesList = map['modules'] != null
        ? (map['modules'] as List)
            .map((m) => LearningModule.fromMap(Map<String, dynamic>.from(m)))
            .toList()
        : <LearningModule>[];

    final plan = LearningPlan(
      planId: map['planId'] ?? '',
      exchangeId: map['exchangeId'] ?? '',
      mentorId: map['mentorId'] ?? '',
      learnerId: map['learnerId'] ?? '',
      skillName: map['skillName'] ?? '',
      status: LearningPlanStatus.fromMap(map['status']),
      totalTopics: map['totalTopics'] ?? 0,
      completedTopics: map['completedTopics'] ?? 0,
      partiallyUnderstoodTopics: map['partiallyUnderstoodTopics'] ?? 0,
      needHelpTopics: map['needHelpTopics'] ?? 0,
      overallProgressPercentage: (map['overallProgressPercentage'] ?? 0.0).toDouble(),
      modules: modulesList,
      createdAt: map['createdAt'] != null
          ? LearningTopic._parseDateTime(map['createdAt'])
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? LearningTopic._parseDateTime(map['updatedAt'])
          : DateTime.now(),
    );

    if (map['totalTopics'] == null && modulesList.isNotEmpty) {
      return plan.recalculateProgress();
    }

    return plan;
  }

  /// Recalculates topic counters and progress percentage from current modules and topics.
  /// Safely handles empty topic list (no division by zero).
  LearningPlan recalculateProgress() {
    int total = 0;
    int completed = 0;
    int partiallyUnderstood = 0;
    int needHelp = 0;

    for (final module in modules) {
      for (final topic in module.topics) {
        total++;
        switch (topic.learnerStatus) {
          case LearnerTopicStatus.completed:
            completed++;
            break;
          case LearnerTopicStatus.partiallyUnderstood:
            partiallyUnderstood++;
            break;
          case LearnerTopicStatus.needHelp:
            needHelp++;
            break;
          case LearnerTopicStatus.pending:
          case LearnerTopicStatus.taught:
            break;
        }
      }
    }

    final double progress = total > 0
        ? double.parse(((completed / total) * 100.0).toStringAsFixed(1))
        : 0.0;

    return copyWith(
      totalTopics: total,
      completedTopics: completed,
      partiallyUnderstoodTopics: partiallyUnderstood,
      needHelpTopics: needHelp,
      overallProgressPercentage: progress,
    );
  }

  LearningPlan copyWith({
    String? planId,
    String? exchangeId,
    String? mentorId,
    String? learnerId,
    String? skillName,
    LearningPlanStatus? status,
    int? totalTopics,
    int? completedTopics,
    int? partiallyUnderstoodTopics,
    int? needHelpTopics,
    double? overallProgressPercentage,
    List<LearningModule>? modules,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LearningPlan(
      planId: planId ?? this.planId,
      exchangeId: exchangeId ?? this.exchangeId,
      mentorId: mentorId ?? this.mentorId,
      learnerId: learnerId ?? this.learnerId,
      skillName: skillName ?? this.skillName,
      status: status ?? this.status,
      totalTopics: totalTopics ?? this.totalTopics,
      completedTopics: completedTopics ?? this.completedTopics,
      partiallyUnderstoodTopics: partiallyUnderstoodTopics ?? this.partiallyUnderstoodTopics,
      needHelpTopics: needHelpTopics ?? this.needHelpTopics,
      overallProgressPercentage: overallProgressPercentage ?? this.overallProgressPercentage,
      modules: modules ?? this.modules,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Checks whether two LearningPlan instances share identical curriculum structure
  /// (skillName, module IDs/titles/order, topic IDs/titles/expectedOutcomes).
  bool isStructurallyEqualTo(LearningPlan other) {
    if (skillName != other.skillName) return false;
    if (modules.length != other.modules.length) return false;

    for (int i = 0; i < modules.length; i++) {
      final m1 = modules[i];
      final m2 = other.modules[i];

      if (m1.moduleId != m2.moduleId || m1.title != m2.title || m1.order != m2.order) {
        return false;
      }
      if (m1.topics.length != m2.topics.length) return false;

      for (int j = 0; j < m1.topics.length; j++) {
        final t1 = m1.topics[j];
        final t2 = m2.topics[j];

        if (t1.topicId != t2.topicId ||
            t1.title != t2.title ||
            t1.expectedOutcome != t2.expectedOutcome) {
          return false;
        }
      }
    }

    return true;
  }
}
