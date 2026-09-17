import 'package:flutter_test/flutter_test.dart';
import 'package:xchangehub/models/learning_plan_model.dart';

void main() {
  test('LearningPlan model initialization smoke test', () {
    final plan = LearningPlan(
      planId: 'smoke_test_plan',
      exchangeId: 'smoke_test_exchange',
      mentorId: 'mentor_1',
      learnerId: 'learner_1',
      skillName: 'Flutter',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    expect(plan.planId, 'smoke_test_plan');
    expect(plan.status, LearningPlanStatus.draft);
  });
}
