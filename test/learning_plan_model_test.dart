import 'package:flutter_test/flutter_test.dart';
import 'package:xchangehub/models/learning_plan_model.dart';
import 'package:xchangehub/models/skill_exchange_model.dart';

void main() {
  group('LearnerTopicStatus Enum', () {
    test('serializes and deserializes correctly', () {
      expect(LearnerTopicStatus.pending.name, 'pending');
      expect(LearnerTopicStatus.taught.name, 'taught');
      expect(LearnerTopicStatus.completed.name, 'completed');
      expect(LearnerTopicStatus.partiallyUnderstood.name, 'partiallyUnderstood');
      expect(LearnerTopicStatus.needHelp.name, 'needHelp');

      expect(LearnerTopicStatus.fromMap('completed'), LearnerTopicStatus.completed);
      expect(LearnerTopicStatus.fromMap('partiallyUnderstood'), LearnerTopicStatus.partiallyUnderstood);
      expect(LearnerTopicStatus.fromMap('needHelp'), LearnerTopicStatus.needHelp);
      expect(LearnerTopicStatus.fromMap('unknown_status'), LearnerTopicStatus.pending);
      expect(LearnerTopicStatus.fromMap(null), LearnerTopicStatus.pending);
    });
  });

  group('LearningPlanStatus Enum', () {
    test('serializes and deserializes correctly', () {
      expect(LearningPlanStatus.draft.name, 'draft');
      expect(LearningPlanStatus.active.name, 'active');
      expect(LearningPlanStatus.completed.name, 'completed');
      expect(LearningPlanStatus.disputed.name, 'disputed');
      expect(LearningPlanStatus.cancelled.name, 'cancelled');

      expect(LearningPlanStatus.fromMap('active'), LearningPlanStatus.active);
      expect(LearningPlanStatus.fromMap('disputed'), LearningPlanStatus.disputed);
      expect(LearningPlanStatus.fromMap('invalid_status'), LearningPlanStatus.draft);
      expect(LearningPlanStatus.fromMap(null), LearningPlanStatus.draft);
    });
  });

  group('LearningTopic Model', () {
    test('serialization toMap and fromMap works correctly', () {
      final now = DateTime.now();
      final topic = LearningTopic(
        topicId: 'topic_1',
        title: 'State Management Overview',
        expectedOutcome: 'Understand Provider pattern',
        taughtByMentor: true,
        taughtAt: now,
        mentorNotes: 'Covered ChangeNotifier',
        learnerConfirmed: true,
        learnerStatus: LearnerTopicStatus.completed,
        learnerConfirmedAt: now,
        learnerFeedback: 'Great explanation!',
      );

      final map = topic.toMap();
      expect(map['topicId'], 'topic_1');
      expect(map['title'], 'State Management Overview');
      expect(map['expectedOutcome'], 'Understand Provider pattern');
      expect(map['taughtByMentor'], isTrue);
      expect(map['learnerStatus'], 'completed');

      final deserialized = LearningTopic.fromMap(map);
      expect(deserialized.topicId, 'topic_1');
      expect(deserialized.title, 'State Management Overview');
      expect(deserialized.taughtByMentor, isTrue);
      expect(deserialized.learnerStatus, LearnerTopicStatus.completed);
      expect(deserialized.learnerFeedback, 'Great explanation!');
    });

    test('copyWith creates modified copy', () {
      final topic = LearningTopic(
        topicId: 't1',
        title: 'Title 1',
      );

      final updated = topic.copyWith(
        taughtByMentor: true,
        learnerStatus: LearnerTopicStatus.partiallyUnderstood,
      );

      expect(updated.topicId, 't1');
      expect(updated.title, 'Title 1');
      expect(updated.taughtByMentor, isTrue);
      expect(updated.learnerStatus, LearnerTopicStatus.partiallyUnderstood);
    });
  });

  group('LearningModule Model', () {
    test('serialization toMap and fromMap with nested topics', () {
      final module = LearningModule(
        moduleId: 'mod_1',
        title: 'Module 1: Basics',
        order: 1,
        topics: [
          LearningTopic(topicId: 't1', title: 'Topic 1'),
          LearningTopic(topicId: 't2', title: 'Topic 2'),
        ],
      );

      final map = module.toMap();
      expect(map['moduleId'], 'mod_1');
      expect(map['order'], 1);
      expect((map['topics'] as List).length, 2);

      final deserialized = LearningModule.fromMap(map);
      expect(deserialized.moduleId, 'mod_1');
      expect(deserialized.topics.length, 2);
      expect(deserialized.topics.first.topicId, 't1');
    });
  });

  group('LearningPlan Model & Progress Calculation', () {
    test('recalculateProgress handles empty topic list without division by zero', () {
      final plan = LearningPlan(
        planId: 'p1',
        exchangeId: 'ex1',
        mentorId: 'm1',
        learnerId: 'l1',
        skillName: 'Flutter',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final calculated = plan.recalculateProgress();
      expect(calculated.totalTopics, 0);
      expect(calculated.completedTopics, 0);
      expect(calculated.partiallyUnderstoodTopics, 0);
      expect(calculated.needHelpTopics, 0);
      expect(calculated.overallProgressPercentage, 0.0);
    });

    test('recalculateProgress accurately counts statuses and calculates progress percentage', () {
      final module1 = LearningModule(
        moduleId: 'm1',
        title: 'Module 1',
        order: 1,
        topics: [
          LearningTopic(
            topicId: 't1',
            title: 'Topic 1',
            learnerStatus: LearnerTopicStatus.completed,
          ),
          LearningTopic(
            topicId: 't2',
            title: 'Topic 2',
            learnerStatus: LearnerTopicStatus.completed,
          ),
        ],
      );

      final module2 = LearningModule(
        moduleId: 'm2',
        title: 'Module 2',
        order: 2,
        topics: [
          LearningTopic(
            topicId: 't3',
            title: 'Topic 3',
            learnerStatus: LearnerTopicStatus.partiallyUnderstood,
          ),
          LearningTopic(
            topicId: 't4',
            title: 'Topic 4',
            learnerStatus: LearnerTopicStatus.needHelp,
          ),
        ],
      );

      final plan = LearningPlan(
        planId: 'p1',
        exchangeId: 'ex1',
        mentorId: 'm1',
        learnerId: 'l1',
        skillName: 'Flutter',
        modules: [module1, module2],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final calculated = plan.recalculateProgress();

      expect(calculated.totalTopics, 4);
      expect(calculated.completedTopics, 2);
      expect(calculated.partiallyUnderstoodTopics, 1);
      expect(calculated.needHelpTopics, 1);
      // 2 / 4 * 100 = 50.0%
      expect(calculated.overallProgressPercentage, 50.0);
    });

    test('fromMap automatically recalculates progress when totalTopics is null', () {
      final map = {
        'planId': 'plan_100',
        'exchangeId': 'ex_100',
        'mentorId': 'mentor_1',
        'learnerId': 'learner_1',
        'skillName': 'Dart',
        'status': 'active',
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
        'modules': [
          {
            'moduleId': 'm1',
            'title': 'Module A',
            'order': 1,
            'topics': [
              {
                'topicId': 't1',
                'title': 'Topic A1',
                'learnerStatus': 'completed',
              },
              {
                'topicId': 't2',
                'title': 'Topic A2',
                'learnerStatus': 'pending',
              },
            ],
          }
        ],
      };

      final plan = LearningPlan.fromMap(map);
      expect(plan.totalTopics, 2);
      expect(plan.completedTopics, 1);
      expect(plan.overallProgressPercentage, 50.0);
    });
  });

  group('SkillExchangeModel Backward Compatibility', () {
    test('SkillExchangeModel deserializes existing document without learningPlanId safely', () {
      final existingDocMap = {
        'id': 'ex_legacy_001',
        'requesterId': 'req_1',
        'requesterName': 'Alice',
        'teacherId': 'teach_1',
        'teacherName': 'Bob',
        'skillOffered': 'Python',
        'skillRequested': 'Flutter',
        'status': 'accepted',
        'createdAt': DateTime.now().toIso8601String(),
      };

      final model = SkillExchangeModel.fromMap(existingDocMap);
      expect(model.id, 'ex_legacy_001');
      expect(model.learningPlanId, isNull);
    });

    test('SkillExchangeModel supports optional learningPlanId when provided', () {
      final newDocMap = {
        'id': 'ex_new_002',
        'requesterId': 'req_1',
        'requesterName': 'Alice',
        'teacherId': 'teach_1',
        'teacherName': 'Bob',
        'skillOffered': 'Python',
        'skillRequested': 'Flutter',
        'status': 'accepted',
        'learningPlanId': 'ex_new_002',
        'createdAt': DateTime.now().toIso8601String(),
      };

      final model = SkillExchangeModel.fromMap(newDocMap);
      expect(model.id, 'ex_new_002');
      expect(model.learningPlanId, 'ex_new_002');

      final map = model.toMap();
      expect(map['learningPlanId'], 'ex_new_002');
    });
  });
}
