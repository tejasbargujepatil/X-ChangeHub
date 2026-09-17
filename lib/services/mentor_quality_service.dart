import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/learning_issue_model.dart';
import '../models/learning_plan_model.dart';
import '../models/mentor_metrics_model.dart';

/// Service managing evidence-backed Mentor Quality & Reputation metrics.
/// Serves read operations for clients and performs calculations over validated outcomes.
class MentorQualityService {
  final FirebaseFirestore? _customFirestore;

  MentorQualityService({
    FirebaseFirestore? firestore,
  }) : _customFirestore = firestore;

  FirebaseFirestore get _firestore => _customFirestore ?? FirebaseFirestore.instance;

  /// Fetches the current [MentorMetricsModel] for a given mentor.
  Future<MentorMetricsModel?> getMentorMetrics(String mentorUserId) async {
    try {
      final doc = await _firestore.collection('mentor_metrics').doc(mentorUserId).get();
      if (doc.exists && doc.data() != null) {
        return MentorMetricsModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch mentor metrics: $e');
    }
  }

  /// Streams real-time [MentorMetricsModel] updates for a mentor profile.
  Stream<MentorMetricsModel?> watchMentorMetrics(String mentorUserId) {
    return _firestore
        .collection('mentor_metrics')
        .doc(mentorUserId)
        .snapshots()
        .map((doc) => doc.exists && doc.data() != null ? MentorMetricsModel.fromMap(doc.data()!) : null);
  }

  /// Pure helper to aggregate quality metrics from raw collection objects.
  /// Used for test assertions and backend Cloud Function aggregation.
  static MentorMetricsModel calculateMetricsFromData({
    required String mentorUserId,
    required List<LearningPlan> learningPlans,
    required List<LearningIssueModel> learningIssues,
    required List<LearningInterventionModel> interventions,
    required double learnerRatingAverage,
    required int learnerRatingCount,
    required int verifiedSkillCount,
    DateTime? existingCreatedAt,
  }) {
    int completedPlans = 0;
    int topicsAssigned = 0;
    int topicsTaught = 0;
    int topicsConfirmed = 0;
    int topicsPartially = 0;
    int topicsNeedHelp = 0;

    for (final plan in learningPlans) {
      if (plan.mentorId != mentorUserId) continue;

      if (plan.status == LearningPlanStatus.completed) {
        completedPlans++;
      }

      for (final module in plan.modules) {
        for (final topic in module.topics) {
          topicsAssigned++;

          if (topic.taughtByMentor) {
            topicsTaught++;
          }

          if (topic.learnerConfirmed) {
            switch (topic.learnerStatus) {
              case LearnerTopicStatus.completed:
                topicsConfirmed++;
                break;
              case LearnerTopicStatus.partiallyUnderstood:
                topicsPartially++;
                break;
              case LearnerTopicStatus.needHelp:
                topicsNeedHelp++;
                break;
              default:
                break;
            }
          }
        }
      }
    }

    // Filter Learning Issues: ONLY resolved issues (excluding dismissed) count as validated issues
    int validatedIssues = 0;
    int dismissedIssues = 0;

    for (final issue in learningIssues) {
      if (issue.reportedUserId != mentorUserId) continue;

      if (issue.status == LearningIssueStatus.dismissed ||
          issue.resolution == LearningIssueResolution.dismissed) {
        dismissedIssues++;
      } else if (issue.status == LearningIssueStatus.resolved) {
        validatedIssues++;
      }
      // Note: open / underReview issues are NOT counted as validated issues
    }

    // Interventions
    int correctiveInts = 0;
    int additionalTeachingInts = 0;
    int rematchInts = 0;

    for (final intv in interventions) {
      if (intv.targetUserId != mentorUserId) continue;
      switch (intv.action) {
        case LearningIssueResolution.correctiveSession:
          correctiveInts++;
          break;
        case LearningIssueResolution.additionalTeaching:
          additionalTeachingInts++;
          break;
        case LearningIssueResolution.rematch:
          rematchInts++;
          break;
        default:
          break;
      }
    }

    final totalExchanges = learningPlans.length;
    final successfulExchanges = (totalExchanges - validatedIssues).clamp(0, totalExchanges);
    final hasMinHistory = totalExchanges >= 3 || topicsTaught >= 5;

    final qualityScore = MentorMetricsModel.calculateScore(
      completedExchanges: totalExchanges,
      topicsTaught: topicsTaught,
      topicsLearnerConfirmed: topicsConfirmed,
      topicsPartiallyUnderstood: topicsPartially,
      validatedLearningIssues: validatedIssues,
      rematchInterventions: rematchInts,
      learnerRatingAverage: learnerRatingAverage,
      learnerRatingCount: learnerRatingCount,
    );

    final now = DateTime.now();

    return MentorMetricsModel(
      mentorUserId: mentorUserId,
      completedExchanges: totalExchanges,
      successfulExchanges: successfulExchanges,
      learningPlansCompleted: completedPlans,
      topicsAssigned: topicsAssigned,
      topicsTaught: topicsTaught,
      topicsLearnerConfirmed: topicsConfirmed,
      topicsPartiallyUnderstood: topicsPartially,
      topicsNeedHelp: topicsNeedHelp,
      validatedLearningIssues: validatedIssues,
      dismissedLearningIssues: dismissedIssues,
      correctiveInterventions: correctiveInts,
      additionalTeachingInterventions: additionalTeachingInts,
      rematchInterventions: rematchInts,
      learnerRatingAverage: learnerRatingAverage,
      learnerRatingCount: learnerRatingCount,
      verifiedSkillCount: verifiedSkillCount,
      qualityScore: qualityScore,
      sufficientHistory: hasMinHistory,
      createdAt: existingCreatedAt ?? now,
      updatedAt: now,
    );
  }
}
