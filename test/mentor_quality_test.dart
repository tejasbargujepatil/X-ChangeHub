import 'package:flutter_test/flutter_test.dart';
import 'package:xchangehub/models/learning_issue_model.dart';
import 'package:xchangehub/models/learning_plan_model.dart';
import 'package:xchangehub/models/mentor_metrics_model.dart';
import 'package:xchangehub/services/mentor_quality_service.dart';

void main() {
  group('Phase 5 — Mentor Quality & Reputation System Tests', () {
    late String mentorId;
    late LearningPlan completedPlan;
    late LearningPlan activePlan;

    setUp(() {
      mentorId = 'mentor_uid_789';

      final topic1 = LearningTopic(
        topicId: 't_01',
        title: 'Topic 1: Basics',
        expectedOutcome: 'Understand basics',
        taughtByMentor: true,
        learnerConfirmed: true,
        learnerStatus: LearnerTopicStatus.completed,
      );

      final topic2 = LearningTopic(
        topicId: 't_02',
        title: 'Topic 2: Advanced',
        expectedOutcome: 'Master advanced concepts',
        taughtByMentor: true,
        learnerConfirmed: true,
        learnerStatus: LearnerTopicStatus.partiallyUnderstood,
      );

      final topic3 = LearningTopic(
        topicId: 't_03',
        title: 'Topic 3: Practice',
        expectedOutcome: 'Complete hands-on lab',
        taughtByMentor: true,
        learnerConfirmed: true,
        learnerStatus: LearnerTopicStatus.needHelp,
      );

      final module = LearningModule(
        moduleId: 'm_01',
        title: 'Module 1',
        order: 1,
        topics: [topic1, topic2, topic3],
      );

      completedPlan = LearningPlan(
        planId: 'plan_001',
        exchangeId: 'ex_001',
        mentorId: mentorId,
        learnerId: 'learner_101',
        skillName: 'Flutter Development',
        status: LearningPlanStatus.completed,
        modules: [module],
        createdAt: DateTime(2026, 9, 10),
        updatedAt: DateTime(2026, 9, 12),
      );

      activePlan = LearningPlan(
        planId: 'plan_002',
        exchangeId: 'ex_002',
        mentorId: mentorId,
        learnerId: 'learner_102',
        skillName: 'Dart Async',
        status: LearningPlanStatus.active,
        modules: [module],
        createdAt: DateTime(2026, 9, 13),
        updatedAt: DateTime(2026, 9, 13),
      );
    });

    test('1. MentorMetricsModel serialization toMap and fromMap works accurately', () {
      final now = DateTime.now();
      final metrics = MentorMetricsModel(
        mentorUserId: mentorId,
        completedExchanges: 5,
        successfulExchanges: 4,
        learningPlansCompleted: 3,
        topicsAssigned: 10,
        topicsTaught: 8,
        topicsLearnerConfirmed: 6,
        topicsPartiallyUnderstood: 2,
        validatedLearningIssues: 1,
        learnerRatingAverage: 4.8,
        learnerRatingCount: 10,
        qualityScore: 92.5,
        sufficientHistory: true,
        createdAt: now,
        updatedAt: now,
      );

      final map = metrics.toMap();
      final restored = MentorMetricsModel.fromMap(map);

      expect(restored.mentorUserId, mentorId);
      expect(restored.completedExchanges, 5);
      expect(restored.successfulExchanges, 4);
      expect(restored.learningPlansCompleted, 3);
      expect(restored.topicsTaught, 8);
      expect(restored.topicsLearnerConfirmed, 6);
      expect(restored.validatedLearningIssues, 1);
      expect(restored.qualityScore, 92.5);
      expect(restored.sufficientHistory, isTrue);
    });

    test('2. Raw complaints, open issues, and dismissed issues DO NOT reduce mentor quality score', () {
      final rawOpenIssue = LearningIssueModel(
        issueId: 'iss_001',
        exchangeId: 'ex_001',
        learningPlanId: 'plan_001',
        reporterId: 'learner_101',
        reportedUserId: mentorId,
        moduleId: 'm_01',
        topicId: 't_03',
        issueType: LearningIssueType.agreedOutcomeNotDelivered,
        description: 'Raw unreviewed complaint',
        status: LearningIssueStatus.open,
        resolution: LearningIssueResolution.pending,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final dismissedIssue = LearningIssueModel(
        issueId: 'iss_002',
        exchangeId: 'ex_001',
        learningPlanId: 'plan_001',
        reporterId: 'learner_101',
        reportedUserId: mentorId,
        moduleId: 'm_01',
        topicId: 't_03',
        issueType: LearningIssueType.topicNotTaught,
        description: 'Unsubstantiated claim',
        status: LearningIssueStatus.dismissed,
        resolution: LearningIssueResolution.dismissed,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final metrics = MentorQualityService.calculateMetricsFromData(
        mentorUserId: mentorId,
        learningPlans: [completedPlan, activePlan],
        learningIssues: [rawOpenIssue, dismissedIssue],
        interventions: [],
        learnerRatingAverage: 5.0,
        learnerRatingCount: 5,
        verifiedSkillCount: 2,
      );

      expect(metrics.validatedLearningIssues, 0);
      expect(metrics.dismissedLearningIssues, 1);
      // Because open & dismissed issues do not count as validated issues, successfulExchanges remains 2
      expect(metrics.successfulExchanges, 2);
    });

    test('3. Reviewer-validated resolved issues DO increment penalty metrics', () {
      final validatedIssue = LearningIssueModel(
        issueId: 'iss_003',
        exchangeId: 'ex_001',
        learningPlanId: 'plan_001',
        reporterId: 'learner_101',
        reportedUserId: mentorId,
        moduleId: 'm_01',
        topicId: 't_03',
        issueType: LearningIssueType.agreedOutcomeNotDelivered,
        description: 'Validated issue by reviewer',
        status: LearningIssueStatus.resolved,
        resolution: LearningIssueResolution.correctiveSession,
        resolvedBy: 'reviewer_001',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final metrics = MentorQualityService.calculateMetricsFromData(
        mentorUserId: mentorId,
        learningPlans: [completedPlan, activePlan, activePlan], // 3 plans
        learningIssues: [validatedIssue],
        interventions: [],
        learnerRatingAverage: 4.0,
        learnerRatingCount: 5,
        verifiedSkillCount: 1,
      );

      expect(metrics.validatedLearningIssues, 1);
      expect(metrics.successfulExchanges, 2); // 3 total - 1 validated issue = 2 successful
      expect(metrics.qualityScore, isNotNull);
      // Quality score must reflect penalty for validated issue
      expect(metrics.qualityScore! < 100.0, isTrue);
    });

    test('4. Minimum sample size threshold (sufficientHistory) prevents premature quality scoring', () {
      final singlePlan = LearningPlan(
        planId: 'plan_single',
        exchangeId: 'ex_single',
        mentorId: mentorId,
        learnerId: 'learner_101',
        skillName: 'Single Topic Skill',
        status: LearningPlanStatus.active,
        modules: [
          LearningModule(
            moduleId: 'm_single',
            title: 'Mod 1',
            order: 1,
            topics: [
              LearningTopic(
                topicId: 't_single',
                title: 'Only 1 Topic',
                taughtByMentor: true,
                learnerConfirmed: true,
                learnerStatus: LearnerTopicStatus.completed,
              )
            ],
          )
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final metrics = MentorQualityService.calculateMetricsFromData(
        mentorUserId: mentorId,
        learningPlans: [singlePlan], // Only 1 plan and 1 topic taught
        learningIssues: [],
        interventions: [],
        learnerRatingAverage: 5.0,
        learnerRatingCount: 1,
        verifiedSkillCount: 0,
      );

      expect(metrics.sufficientHistory, isFalse);
      expect(metrics.qualityScore, isNull);
    });

    test('5. Topic Delivery Rate is accurately calculated from learner confirmations', () {
      final metrics = MentorQualityService.calculateMetricsFromData(
        mentorUserId: mentorId,
        learningPlans: [completedPlan, activePlan],
        learningIssues: [],
        interventions: [],
        learnerRatingAverage: 5.0,
        learnerRatingCount: 2,
        verifiedSkillCount: 1,
      );

      // 6 topics taught total across the 2 plans:
      // 2 completed (1.0 each), 2 partially understood (0.5 each), 2 need help (0.0 each)
      // Effective confirmed = 2 + 1.0 = 3.0 out of 6 taught = 50.0%
      expect(metrics.topicsTaught, 6);
      expect(metrics.topicsLearnerConfirmed, 2);
      expect(metrics.topicsPartiallyUnderstood, 2);
      expect(metrics.topicDeliveryRate, 50.0);
    });
  });
}
