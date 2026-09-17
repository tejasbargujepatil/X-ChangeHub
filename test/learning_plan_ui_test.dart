import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xchangehub/models/learning_plan_model.dart';
import 'package:xchangehub/services/learning_plan_service.dart';
import 'package:xchangehub/widgets/topic_progress_tile.dart';

// Fake LearningPlanService for UI testing without network/firebase calls
class FakeLearningPlanService extends LearningPlanService {
  bool markAsTaughtCalled = false;
  bool confirmTopicCalled = false;

  @override
  Future<void> markTopicAsTaught({
    required String exchangeId,
    required String moduleId,
    required String topicId,
    String? mentorNotes,
  }) async {
    markAsTaughtCalled = true;
  }

  @override
  Future<void> confirmTopic({
    required String exchangeId,
    required String moduleId,
    required String topicId,
    required LearnerTopicStatus status,
    String? feedback,
  }) async {
    confirmTopicCalled = true;
  }
}

void main() {
  group('Phase 3 - TopicProgressTile UI & Accessibility Tests', () {
    late FakeLearningPlanService fakeService;

    setUp(() {
      fakeService = FakeLearningPlanService();
    });

    final sampleTopic = LearningTopic(
      topicId: 't_001',
      title: 'Variables & Data Types',
      expectedOutcome: 'Understand Python variables and common data types.',
      taughtByMentor: true,
      learnerStatus: LearnerTopicStatus.pending,
    );

    testWidgets('Renders topic title, expected outcome, and taught status badge', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TopicProgressTile(
              topic: sampleTopic,
              moduleId: 'm_001',
              exchangeId: 'ex_123',
              isMentor: false,
              isLearner: true,
              planService: fakeService,
            ),
          ),
        ),
      );

      expect(find.text('Variables & Data Types'), findsOneWidget);
      expect(find.text('Understand Python variables and common data types.'), findsOneWidget);
      expect(find.text('◉ Taught'), findsOneWidget);
      expect(find.byIcon(Icons.adjust), findsOneWidget);
    });

    testWidgets('Exposes mentor action button ("Mark as Taught") ONLY for mentor role', (WidgetTester tester) async {
      final untaughtTopic = LearningTopic(
        topicId: 't_002',
        title: 'Functions',
        expectedOutcome: 'Write reusable functions',
        taughtByMentor: false,
      );

      // Render as Mentor
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TopicProgressTile(
              topic: untaughtTopic,
              moduleId: 'm_001',
              exchangeId: 'ex_123',
              isMentor: true,
              isLearner: false,
              planService: fakeService,
            ),
          ),
        ),
      );

      expect(find.text('Mark as Taught'), findsOneWidget);
      expect(find.text('Confirm your understanding:'), findsNothing);
    });

    testWidgets('Exposes learner confirmation buttons ONLY for learner role', (WidgetTester tester) async {
      // Render as Learner on taught topic
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TopicProgressTile(
              topic: sampleTopic,
              moduleId: 'm_001',
              exchangeId: 'ex_123',
              isMentor: false,
              isLearner: true,
              planService: fakeService,
            ),
          ),
        ),
      );

      expect(find.text('Mark as Taught'), findsNothing);
      expect(find.text('Confirm your understanding:'), findsOneWidget);
      expect(find.text('✓ Completed'), findsOneWidget);
      expect(find.text('◐ Partially'), findsOneWidget);
      expect(find.text('? Need Help'), findsOneWidget);
    });

    testWidgets('Status badges render unique icons for accessibility across all statuses', (WidgetTester tester) async {
      final statuses = [
        (LearnerTopicStatus.pending, Icons.circle_outlined, '○ Not Started'),
        (LearnerTopicStatus.completed, Icons.check_circle, '✓ Completed'),
        (LearnerTopicStatus.partiallyUnderstood, Icons.pie_chart_outline, '◐ Partially Understood'),
        (LearnerTopicStatus.needHelp, Icons.help_outline, '? Need Help'),
      ];

      for (final (status, icon, label) in statuses) {
        final topic = LearningTopic(
          topicId: 't_test',
          title: 'Topic Title',
          expectedOutcome: 'Outcome',
          taughtByMentor: status != LearnerTopicStatus.pending,
          learnerStatus: status,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: TopicProgressTile(
                topic: topic,
                moduleId: 'm_001',
                exchangeId: 'ex_123',
                isMentor: false,
                isLearner: false,
                planService: fakeService,
              ),
            ),
          ),
        );

        expect(find.byIcon(icon), findsWidgets, reason: 'Icon for $label missing');
        expect(find.text(label), findsWidgets, reason: 'Label $label missing');
      }
    });
  });
}
