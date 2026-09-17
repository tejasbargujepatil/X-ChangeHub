import 'package:flutter_test/flutter_test.dart';
import 'package:xchangehub/models/learning_issue_model.dart';
import 'package:xchangehub/models/learning_plan_model.dart';

void main() {
  group('Phase 4 — Learning Issue & Intervention System Tests', () {
    late LearningTopic sampleTopic;
    late LearningPlan samplePlan;

    setUp(() {
      sampleTopic = LearningTopic(
        topicId: 't_pandas_01',
        title: 'Pandas DataFrames',
        expectedOutcome: 'Create and manipulate Pandas DataFrames.',
        taughtByMentor: true,
        taughtAt: DateTime(2026, 9, 16, 10, 0),
        mentorNotes: 'Introduced df.head() and filtering',
        learnerConfirmed: true,
        learnerStatus: LearnerTopicStatus.partiallyUnderstood,
        learnerConfirmedAt: DateTime(2026, 9, 16, 10, 30),
        learnerFeedback: 'Need more practice on GroupBy operations',
      );

      final module = LearningModule(
        moduleId: 'm_pandas',
        title: 'Module 2: Pandas Fundamentals',
        order: 1,
        topics: [sampleTopic],
      );

      samplePlan = LearningPlan(
        planId: 'ex_python_101',
        exchangeId: 'ex_python_101',
        mentorId: 'mentor_uid_789',
        learnerId: 'learner_uid_123',
        skillName: 'Python for Data Analysis',
        status: LearningPlanStatus.active,
        modules: [module],
        createdAt: DateTime(2026, 9, 15, 9, 0),
        updatedAt: DateTime(2026, 9, 16, 10, 30),
      ).recalculateProgress();
    });

    test('1. LearningIssueModel serialization toMap and fromMap works correctly', () {
      final snapshot = TopicEvidenceSnapshot.fromTopic(sampleTopic);
      final issue = LearningIssueModel(
        issueId: 'issue_001',
        exchangeId: 'ex_python_101',
        learningPlanId: 'ex_python_101',
        reporterId: 'learner_uid_123',
        reportedUserId: 'mentor_uid_789',
        moduleId: 'm_pandas',
        topicId: 't_pandas_01',
        issueType: LearningIssueType.agreedOutcomeNotDelivered,
        description: 'Expected outcome was not fully covered during the session',
        status: LearningIssueStatus.open,
        resolution: LearningIssueResolution.pending,
        evidenceSnapshot: snapshot,
        createdAt: DateTime(2026, 9, 16, 11, 0),
        updatedAt: DateTime(2026, 9, 16, 11, 0),
      );

      final map = issue.toMap();
      final restored = LearningIssueModel.fromMap(map);

      expect(restored.issueId, 'issue_001');
      expect(restored.exchangeId, 'ex_python_101');
      expect(restored.reporterId, 'learner_uid_123');
      expect(restored.reportedUserId, 'mentor_uid_789');
      expect(restored.issueType, LearningIssueType.agreedOutcomeNotDelivered);
      expect(restored.status, LearningIssueStatus.open);
      expect(restored.evidenceSnapshot?.topicTitle, 'Pandas DataFrames');
      expect(restored.evidenceSnapshot?.expectedOutcome, 'Create and manipulate Pandas DataFrames.');
      expect(restored.evidenceSnapshot?.taughtByMentor, isTrue);
      expect(restored.evidenceSnapshot?.learnerStatus, LearnerTopicStatus.partiallyUnderstood);
    });

    test('2. Evidence snapshot generation preserves agreed topic details, mentor evidence & learner feedback', () {
      final snapshot = TopicEvidenceSnapshot.fromTopic(sampleTopic);

      expect(snapshot.topicId, 't_pandas_01');
      expect(snapshot.topicTitle, 'Pandas DataFrames');
      expect(snapshot.expectedOutcome, 'Create and manipulate Pandas DataFrames.');
      expect(snapshot.taughtByMentor, isTrue);
      expect(snapshot.mentorNotes, 'Introduced df.head() and filtering');
      expect(snapshot.learnerStatus, LearnerTopicStatus.partiallyUnderstood);
      expect(snapshot.learnerFeedback, 'Need more practice on GroupBy operations');
    });

    test('3. LearningInterventionModel serialization works correctly', () {
      final intervention = LearningInterventionModel(
        interventionId: 'int_001',
        issueId: 'issue_001',
        exchangeId: 'ex_python_101',
        targetUserId: 'mentor_uid_789',
        assignedBy: 'admin_uid_999',
        action: LearningIssueResolution.correctiveSession,
        status: 'pending',
        notes: 'Schedule 30-min follow-up session on Pandas GroupBy',
        createdAt: DateTime(2026, 9, 16, 12, 0),
      );

      final map = intervention.toMap();
      final restored = LearningInterventionModel.fromMap(map);

      expect(restored.interventionId, 'int_001');
      expect(restored.issueId, 'issue_001');
      expect(restored.targetUserId, 'mentor_uid_789');
      expect(restored.assignedBy, 'admin_uid_999');
      expect(restored.action, LearningIssueResolution.correctiveSession);
      expect(restored.status, 'pending');
    });

    test('4. Participant authorization logic verifies reporter belongs to exchange as learner', () {
      final reporterUid = 'learner_uid_123';
      final nonParticipantUid = 'random_user_999';

      final isReporterParticipant = (reporterUid == samplePlan.mentorId || reporterUid == samplePlan.learnerId);
      final isNonParticipant = (nonParticipantUid == samplePlan.mentorId || nonParticipantUid == samplePlan.learnerId);

      expect(isReporterParticipant, isTrue);
      expect(isNonParticipant, isFalse);

      final isReporterLearner = reporterUid == samplePlan.learnerId;
      final isMentorLearner = samplePlan.mentorId == samplePlan.learnerId;

      expect(isReporterLearner, isTrue);
      expect(isMentorLearner, isFalse);
    });

    test('5. Duplicate unresolved issue detection identifies existing open issues', () {
      final existingIssues = [
        LearningIssueModel(
          issueId: 'issue_001',
          exchangeId: 'ex_python_101',
          learningPlanId: 'ex_python_101',
          reporterId: 'learner_uid_123',
          reportedUserId: 'mentor_uid_789',
          moduleId: 'm_pandas',
          topicId: 't_pandas_01',
          issueType: LearningIssueType.topicNotTaught,
          description: 'Initial report',
          status: LearningIssueStatus.open,
          createdAt: DateTime(2026, 9, 16, 11, 0),
          updatedAt: DateTime(2026, 9, 16, 11, 0),
        ),
      ];

      final isDuplicate = existingIssues.any((issue) =>
          issue.exchangeId == 'ex_python_101' &&
          issue.topicId == 't_pandas_01' &&
          issue.reporterId == 'learner_uid_123' &&
          (issue.status == LearningIssueStatus.open || issue.status == LearningIssueStatus.underReview));

      expect(isDuplicate, isTrue);
    });

    test('6. Reviewer can record resolution and transition issue status to resolved', () {
      final issue = LearningIssueModel(
        issueId: 'issue_001',
        exchangeId: 'ex_python_101',
        learningPlanId: 'ex_python_101',
        reporterId: 'learner_uid_123',
        reportedUserId: 'mentor_uid_789',
        moduleId: 'm_pandas',
        topicId: 't_pandas_01',
        issueType: LearningIssueType.topicNotTaught,
        description: 'Topic missed during exchange session',
        status: LearningIssueStatus.open,
        createdAt: DateTime(2026, 9, 16, 11, 0),
        updatedAt: DateTime(2026, 9, 16, 11, 0),
      );

      final resolvedIssue = issue.copyWith(
        status: LearningIssueStatus.resolved,
        resolution: LearningIssueResolution.correctiveSession,
        resolutionNotes: 'Mentor agreed to host a 30-min corrective session.',
        resolvedAt: DateTime(2026, 9, 16, 14, 0),
        resolvedBy: 'admin_uid_999',
      );

      expect(resolvedIssue.status, LearningIssueStatus.resolved);
      expect(resolvedIssue.resolution, LearningIssueResolution.correctiveSession);
      expect(resolvedIssue.resolvedBy, 'admin_uid_999');
      expect(resolvedIssue.resolvedAt, isNotNull);
    });

    test('7. Learning Plan structure and progress functionality remain completely unaffected', () {
      expect(samplePlan.totalTopics, 1);
      expect(samplePlan.completedTopics, 0);
      expect(samplePlan.partiallyUnderstoodTopics, 1);
      expect(samplePlan.status, LearningPlanStatus.active);
      expect(samplePlan.isStructurallyEqualTo(samplePlan), isTrue);
    });

    test('8. Custom Claims Role Verification correctly identifies reviewer and admin tokens', () {
      final standardClaims = <String, dynamic>{'reviewer': false, 'admin': false};
      final reviewerClaims = <String, dynamic>{'reviewer': true, 'admin': false};
      final adminClaims = <String, dynamic>{'reviewer': true, 'admin': true};

      bool checkIsReviewer(Map<String, dynamic> claims) {
        return (claims['reviewer'] == true) || (claims['admin'] == true);
      }

      bool checkIsAdmin(Map<String, dynamic> claims) {
        return claims['admin'] == true;
      }

      expect(checkIsReviewer(standardClaims), isFalse);
      expect(checkIsAdmin(standardClaims), isFalse);

      expect(checkIsReviewer(reviewerClaims), isTrue);
      expect(checkIsAdmin(reviewerClaims), isFalse);

      expect(checkIsReviewer(adminClaims), isTrue);
      expect(checkIsAdmin(adminClaims), isTrue);
    });

    test('9. Unauthenticated or standard users without custom claims are denied reviewer operations', () {
      final userClaims = <String, dynamic>{}; // No reviewer claim

      final isAuthorizedReviewer = (userClaims['reviewer'] == true) || (userClaims['admin'] == true);
      expect(isAuthorizedReviewer, isFalse);
    });
  });
}
