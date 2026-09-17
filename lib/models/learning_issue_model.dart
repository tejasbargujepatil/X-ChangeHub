import 'package:cloud_firestore/cloud_firestore.dart';
import 'learning_plan_model.dart';

enum LearningIssueStatus {
  open,
  underReview,
  resolved,
  dismissed;

  static LearningIssueStatus fromMap(String? status) {
    if (status == null) return LearningIssueStatus.open;
    return LearningIssueStatus.values.firstWhere(
      (e) => e.name == status,
      orElse: () => LearningIssueStatus.open,
    );
  }
}

enum LearningIssueType {
  topicNotTaught,
  topicPoorlyUnderstood,
  incorrectExplanation,
  agreedOutcomeNotDelivered,
  repeatedLearningIssue,
  other;

  static LearningIssueType fromMap(String? type) {
    if (type == null) return LearningIssueType.other;
    return LearningIssueType.values.firstWhere(
      (e) => e.name == type,
      orElse: () => LearningIssueType.other,
    );
  }

  String get displayName {
    switch (this) {
      case LearningIssueType.topicNotTaught:
        return 'Topic was not taught';
      case LearningIssueType.topicPoorlyUnderstood:
        return 'Topic was poorly understood';
      case LearningIssueType.incorrectExplanation:
        return 'Explanation was unclear / incorrect';
      case LearningIssueType.agreedOutcomeNotDelivered:
        return 'Agreed outcome was not delivered';
      case LearningIssueType.repeatedLearningIssue:
        return 'Repeated learning issue';
      case LearningIssueType.other:
        return 'Other issue';
    }
  }
}

enum LearningIssueResolution {
  pending,
  correctiveSession,
  additionalTeaching,
  rematch,
  warning,
  dismissed,
  other;

  static LearningIssueResolution fromMap(String? res) {
    if (res == null) return LearningIssueResolution.pending;
    return LearningIssueResolution.values.firstWhere(
      (e) => e.name == res,
      orElse: () => LearningIssueResolution.pending,
    );
  }

  String get displayName {
    switch (this) {
      case LearningIssueResolution.pending:
        return 'Pending Review';
      case LearningIssueResolution.correctiveSession:
        return 'Schedule Corrective Session';
      case LearningIssueResolution.additionalTeaching:
        return 'Require Additional Teaching';
      case LearningIssueResolution.rematch:
        return 'Offer Peer Rematch';
      case LearningIssueResolution.warning:
        return 'Issue Formal Warning';
      case LearningIssueResolution.dismissed:
        return 'Dismiss Issue';
      case LearningIssueResolution.other:
        return 'Other Action';
    }
  }
}

/// Immutable evidence snapshot captured at the time of reporting a Learning Issue.
class TopicEvidenceSnapshot {
  final String topicId;
  final String topicTitle;
  final String? expectedOutcome;
  final bool taughtByMentor;
  final DateTime? taughtAt;
  final String? mentorNotes;
  final LearnerTopicStatus learnerStatus;
  final DateTime? learnerConfirmedAt;
  final String? learnerFeedback;

  TopicEvidenceSnapshot({
    required this.topicId,
    required this.topicTitle,
    this.expectedOutcome,
    required this.taughtByMentor,
    this.taughtAt,
    this.mentorNotes,
    required this.learnerStatus,
    this.learnerConfirmedAt,
    this.learnerFeedback,
  });

  Map<String, dynamic> toMap() {
    return {
      'topicId': topicId,
      'topicTitle': topicTitle,
      'expectedOutcome': expectedOutcome,
      'taughtByMentor': taughtByMentor,
      'taughtAt': taughtAt?.toIso8601String(),
      'mentorNotes': mentorNotes,
      'learnerStatus': learnerStatus.name,
      'learnerConfirmedAt': learnerConfirmedAt?.toIso8601String(),
      'learnerFeedback': learnerFeedback,
    };
  }

  factory TopicEvidenceSnapshot.fromMap(Map<String, dynamic> map) {
    return TopicEvidenceSnapshot(
      topicId: map['topicId'] ?? '',
      topicTitle: map['topicTitle'] ?? '',
      expectedOutcome: map['expectedOutcome'],
      taughtByMentor: map['taughtByMentor'] ?? false,
      taughtAt: map['taughtAt'] != null ? _parseDateTime(map['taughtAt']) : null,
      mentorNotes: map['mentorNotes'],
      learnerStatus: LearnerTopicStatus.fromMap(map['learnerStatus']),
      learnerConfirmedAt: map['learnerConfirmedAt'] != null
          ? _parseDateTime(map['learnerConfirmedAt'])
          : null,
      learnerFeedback: map['learnerFeedback'],
    );
  }

  factory TopicEvidenceSnapshot.fromTopic(LearningTopic topic) {
    return TopicEvidenceSnapshot(
      topicId: topic.topicId,
      topicTitle: topic.title,
      expectedOutcome: topic.expectedOutcome,
      taughtByMentor: topic.taughtByMentor,
      taughtAt: topic.taughtAt,
      mentorNotes: topic.mentorNotes,
      learnerStatus: topic.learnerStatus,
      learnerConfirmedAt: topic.learnerConfirmedAt,
      learnerFeedback: topic.learnerFeedback,
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

/// Represents an evidence-backed Learning Issue filed for a skill exchange topic.
class LearningIssueModel {
  final String issueId;
  final String exchangeId;
  final String learningPlanId;
  final String reporterId;
  final String reportedUserId;
  final String moduleId;
  final String topicId;
  final LearningIssueType issueType;
  final String description;
  final LearningIssueStatus status;
  final LearningIssueResolution resolution;
  final String? resolutionNotes;
  final TopicEvidenceSnapshot? evidenceSnapshot;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? resolvedAt;
  final String? resolvedBy;

  LearningIssueModel({
    required this.issueId,
    required this.exchangeId,
    required this.learningPlanId,
    required this.reporterId,
    required this.reportedUserId,
    required this.moduleId,
    required this.topicId,
    required this.issueType,
    required this.description,
    this.status = LearningIssueStatus.open,
    this.resolution = LearningIssueResolution.pending,
    this.resolutionNotes,
    this.evidenceSnapshot,
    required this.createdAt,
    required this.updatedAt,
    this.resolvedAt,
    this.resolvedBy,
  });

  Map<String, dynamic> toMap() {
    return {
      'issueId': issueId,
      'exchangeId': exchangeId,
      'learningPlanId': learningPlanId,
      'reporterId': reporterId,
      'reportedUserId': reportedUserId,
      'moduleId': moduleId,
      'topicId': topicId,
      'issueType': issueType.name,
      'description': description,
      'status': status.name,
      'resolution': resolution.name,
      'resolutionNotes': resolutionNotes,
      'evidenceSnapshot': evidenceSnapshot?.toMap(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'resolvedAt': resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
      'resolvedBy': resolvedBy,
    };
  }

  factory LearningIssueModel.fromMap(Map<String, dynamic> map) {
    return LearningIssueModel(
      issueId: map['issueId'] ?? '',
      exchangeId: map['exchangeId'] ?? '',
      learningPlanId: map['learningPlanId'] ?? '',
      reporterId: map['reporterId'] ?? '',
      reportedUserId: map['reportedUserId'] ?? '',
      moduleId: map['moduleId'] ?? '',
      topicId: map['topicId'] ?? '',
      issueType: LearningIssueType.fromMap(map['issueType']),
      description: map['description'] ?? '',
      status: LearningIssueStatus.fromMap(map['status']),
      resolution: LearningIssueResolution.fromMap(map['resolution']),
      resolutionNotes: map['resolutionNotes'],
      evidenceSnapshot: map['evidenceSnapshot'] != null
          ? TopicEvidenceSnapshot.fromMap(Map<String, dynamic>.from(map['evidenceSnapshot']))
          : null,
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.parse(map['createdAt'].toString()),
      updatedAt: map['updatedAt'] is Timestamp
          ? (map['updatedAt'] as Timestamp).toDate()
          : DateTime.parse(map['updatedAt'].toString()),
      resolvedAt: map['resolvedAt'] != null
          ? (map['resolvedAt'] is Timestamp
              ? (map['resolvedAt'] as Timestamp).toDate()
              : DateTime.parse(map['resolvedAt'].toString()))
          : null,
      resolvedBy: map['resolvedBy'],
    );
  }

  LearningIssueModel copyWith({
    String? issueId,
    String? exchangeId,
    String? learningPlanId,
    String? reporterId,
    String? reportedUserId,
    String? moduleId,
    String? topicId,
    LearningIssueType? issueType,
    String? description,
    LearningIssueStatus? status,
    LearningIssueResolution? resolution,
    String? resolutionNotes,
    TopicEvidenceSnapshot? evidenceSnapshot,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? resolvedAt,
    String? resolvedBy,
  }) {
    return LearningIssueModel(
      issueId: issueId ?? this.issueId,
      exchangeId: exchangeId ?? this.exchangeId,
      learningPlanId: learningPlanId ?? this.learningPlanId,
      reporterId: reporterId ?? this.reporterId,
      reportedUserId: reportedUserId ?? this.reportedUserId,
      moduleId: moduleId ?? this.moduleId,
      topicId: topicId ?? this.topicId,
      issueType: issueType ?? this.issueType,
      description: description ?? this.description,
      status: status ?? this.status,
      resolution: resolution ?? this.resolution,
      resolutionNotes: resolutionNotes ?? this.resolutionNotes,
      evidenceSnapshot: evidenceSnapshot ?? this.evidenceSnapshot,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      resolvedBy: resolvedBy ?? this.resolvedBy,
    );
  }
}

/// Intervention record linked to a resolved Learning Issue.
class LearningInterventionModel {
  final String interventionId;
  final String issueId;
  final String exchangeId;
  final String targetUserId;
  final String assignedBy;
  final LearningIssueResolution action;
  final String status; // 'pending', 'completed', 'cancelled'
  final String? notes;
  final DateTime createdAt;
  final DateTime? dueAt;
  final DateTime? resolvedAt;
  final String? resolvedBy;

  LearningInterventionModel({
    required this.interventionId,
    required this.issueId,
    required this.exchangeId,
    required this.targetUserId,
    required this.assignedBy,
    required this.action,
    this.status = 'pending',
    this.notes,
    required this.createdAt,
    this.dueAt,
    this.resolvedAt,
    this.resolvedBy,
  });

  Map<String, dynamic> toMap() {
    return {
      'interventionId': interventionId,
      'issueId': issueId,
      'exchangeId': exchangeId,
      'targetUserId': targetUserId,
      'assignedBy': assignedBy,
      'action': action.name,
      'status': status,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'dueAt': dueAt != null ? Timestamp.fromDate(dueAt!) : null,
      'resolvedAt': resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
      'resolvedBy': resolvedBy,
    };
  }

  factory LearningInterventionModel.fromMap(Map<String, dynamic> map) {
    return LearningInterventionModel(
      interventionId: map['interventionId'] ?? '',
      issueId: map['issueId'] ?? '',
      exchangeId: map['exchangeId'] ?? '',
      targetUserId: map['targetUserId'] ?? '',
      assignedBy: map['assignedBy'] ?? '',
      action: LearningIssueResolution.fromMap(map['action']),
      status: map['status'] ?? 'pending',
      notes: map['notes'],
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.parse(map['createdAt'].toString()),
      dueAt: map['dueAt'] != null
          ? (map['dueAt'] is Timestamp
              ? (map['dueAt'] as Timestamp).toDate()
              : DateTime.parse(map['dueAt'].toString()))
          : null,
      resolvedAt: map['resolvedAt'] != null
          ? (map['resolvedAt'] is Timestamp
              ? (map['resolvedAt'] as Timestamp).toDate()
              : DateTime.parse(map['resolvedAt'].toString()))
          : null,
      resolvedBy: map['resolvedBy'],
    );
  }
}
