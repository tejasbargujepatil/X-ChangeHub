import 'package:flutter_test/flutter_test.dart';
import 'package:xchangehub/models/learning_plan_model.dart';

void main() {
  group('LearningPlanService Logic & Field Isolation Tests', () {
    late LearningPlan initialPlan;

    setUp(() {
      final module = LearningModule(
        moduleId: 'm1',
        title: 'Module 1: Flutter Fundamentals',
        order: 1,
        topics: [
          LearningTopic(
            topicId: 't1',
            title: 'Widget Tree & Context',
            expectedOutcome: 'Understand BuildContext',
          ),
          LearningTopic(
            topicId: 't2',
            title: 'State Management with Provider',
            expectedOutcome: 'Master ChangeNotifier',
          ),
        ],
      );

      initialPlan = LearningPlan(
        planId: 'ex_test_001',
        exchangeId: 'ex_test_001',
        mentorId: 'mentor_uid_123',
        learnerId: 'learner_uid_456',
        skillName: 'Flutter Development',
        status: LearningPlanStatus.active,
        modules: [module],
        createdAt: DateTime(2026, 9, 15, 10, 0),
        updatedAt: DateTime(2026, 9, 15, 10, 0),
      ).recalculateProgress();
    });

    test('Initial LearningPlan creation builds valid data and 0% progress', () {
      expect(initialPlan.planId, 'ex_test_001');
      expect(initialPlan.exchangeId, 'ex_test_001');
      expect(initialPlan.mentorId, 'mentor_uid_123');
      expect(initialPlan.learnerId, 'learner_uid_456');
      expect(initialPlan.totalTopics, 2);
      expect(initialPlan.completedTopics, 0);
      expect(initialPlan.overallProgressPercentage, 0.0);
    });

    test('Mentor marking topic as taught alters ONLY mentor-owned fields', () {
      final topic = initialPlan.modules.first.topics.first;

      // Mentor action simulation
      final updatedTopic = topic.copyWith(
        taughtByMentor: true,
        taughtAt: DateTime(2026, 9, 15, 11, 0),
        mentorNotes: 'Covered context.watch vs context.read',
      );

      // Verify mentor fields changed
      expect(updatedTopic.taughtByMentor, isTrue);
      expect(updatedTopic.taughtAt, isNotNull);
      expect(updatedTopic.mentorNotes, 'Covered context.watch vs context.read');

      // Verify learner fields remain UNTOUCHED
      expect(updatedTopic.learnerConfirmed, isFalse);
      expect(updatedTopic.learnerStatus, LearnerTopicStatus.pending);
      expect(updatedTopic.learnerConfirmedAt, isNull);
      expect(updatedTopic.learnerFeedback, isNull);
    });

    test('Learner confirming topic alters ONLY learner-owned fields', () {
      final topic = initialPlan.modules.first.topics.first;

      // Learner action simulation
      final updatedTopic = topic.copyWith(
        learnerConfirmed: true,
        learnerStatus: LearnerTopicStatus.completed,
        learnerConfirmedAt: DateTime(2026, 9, 15, 11, 15),
        learnerFeedback: 'Understood completely!',
      );

      // Verify learner fields changed
      expect(updatedTopic.learnerConfirmed, isTrue);
      expect(updatedTopic.learnerStatus, LearnerTopicStatus.completed);
      expect(updatedTopic.learnerConfirmedAt, isNotNull);
      expect(updatedTopic.learnerFeedback, 'Understood completely!');

      // Verify mentor fields remain UNTOUCHED
      expect(updatedTopic.taughtByMentor, isFalse);
      expect(updatedTopic.taughtAt, isNull);
      expect(updatedTopic.mentorNotes, isNull);
    });

    test('Progress recalculates accurately when topic is marked completed', () {
      final module = initialPlan.modules.first;
      final updatedTopics = [
        module.topics[0].copyWith(
          learnerConfirmed: true,
          learnerStatus: LearnerTopicStatus.completed,
        ),
        module.topics[1].copyWith(
          learnerConfirmed: true,
          learnerStatus: LearnerTopicStatus.partiallyUnderstood,
        ),
      ];

      final updatedPlan = initialPlan.copyWith(
        modules: [module.copyWith(topics: updatedTopics)],
      ).recalculateProgress();

      expect(updatedPlan.totalTopics, 2);
      expect(updatedPlan.completedTopics, 1);
      expect(updatedPlan.partiallyUnderstoodTopics, 1);
      expect(updatedPlan.needHelpTopics, 0);
      // 1 completed out of 2 total = 50.0%
      expect(updatedPlan.overallProgressPercentage, 50.0);
    });

    test('Immutable identity fields cannot be altered via copyWith protection', () {
      final plan = initialPlan;
      expect(plan.planId, 'ex_test_001');
      expect(plan.exchangeId, 'ex_test_001');
      expect(plan.mentorId, 'mentor_uid_123');
      expect(plan.learnerId, 'learner_uid_456');

      final safePlan = plan.copyWith(
        planId: plan.planId,
        exchangeId: plan.exchangeId,
        mentorId: plan.mentorId,
        learnerId: plan.learnerId,
        status: LearningPlanStatus.completed,
      );

      expect(safePlan.planId, plan.planId);
      expect(safePlan.exchangeId, plan.exchangeId);
      expect(safePlan.mentorId, plan.mentorId);
      expect(safePlan.learnerId, plan.learnerId);
      expect(safePlan.status, LearningPlanStatus.completed);
    });

    group('Structural Immutability & Lifecycle Hardening Tests', () {
      test('isStructurallyEqualTo returns true when only progress attributes change', () {
        final topicTaught = initialPlan.modules.first.topics.first.copyWith(
          taughtByMentor: true,
          mentorNotes: 'Taught topic 1',
        );

        final updatedPlan = initialPlan.copyWith(
          modules: [
            initialPlan.modules.first.copyWith(
              topics: [topicTaught, initialPlan.modules.first.topics[1]],
            ),
          ],
        );

        expect(initialPlan.isStructurallyEqualTo(updatedPlan), isTrue);
      });

      test('isStructurallyEqualTo returns false when module is added or removed', () {
        final newModule = LearningModule(
          moduleId: 'm2',
          title: 'Module 2: Advanced Animation',
          order: 2,
          topics: [],
        );

        final modifiedPlan = initialPlan.copyWith(
          modules: [...initialPlan.modules, newModule],
        );

        expect(initialPlan.isStructurallyEqualTo(modifiedPlan), isFalse);
      });

      test('isStructurallyEqualTo returns false when topic title is altered', () {
        final alteredTopic = initialPlan.modules.first.topics.first.copyWith(
          title: 'Tampered Topic Title',
        );

        final modifiedPlan = initialPlan.copyWith(
          modules: [
            initialPlan.modules.first.copyWith(
              topics: [alteredTopic, initialPlan.modules.first.topics[1]],
            ),
          ],
        );

        expect(initialPlan.isStructurallyEqualTo(modifiedPlan), isFalse);
      });

      test('isStructurallyEqualTo returns false when expected outcome is altered', () {
        final alteredTopic = initialPlan.modules.first.topics.first.copyWith(
          expectedOutcome: 'Tampered Expected Outcome',
        );

        final modifiedPlan = initialPlan.copyWith(
          modules: [
            initialPlan.modules.first.copyWith(
              topics: [alteredTopic, initialPlan.modules.first.topics[1]],
            ),
          ],
        );

        expect(initialPlan.isStructurallyEqualTo(modifiedPlan), isFalse);
      });

      test('isStructurallyEqualTo returns false when skillName is altered', () {
        final modifiedPlan = initialPlan.copyWith(
          skillName: 'Tampered Skill Name',
        );

        expect(initialPlan.isStructurallyEqualTo(modifiedPlan), isFalse);
      });
    });
  });
}
