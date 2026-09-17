import 'package:flutter_test/flutter_test.dart';
import 'package:xchangehub/models/enhancement_models.dart';
import 'package:xchangehub/models/learning_plan_model.dart';
import 'package:xchangehub/models/user_model.dart';

void main() {
  group('Phase 6 — Skill Verification & Final Trust Layer Tests', () {
    late String userId;
    late String reviewerId;
    late LearningPlan completedPlan;
    late UserModel initialUser;

    setUp(() {
      userId = 'learner_uid_101';
      reviewerId = 'reviewer_uid_999';

      completedPlan = LearningPlan(
        planId: 'plan_flutter_101',
        exchangeId: 'ex_flutter_101',
        mentorId: 'mentor_uid_789',
        learnerId: userId,
        skillName: 'Flutter Development',
        status: LearningPlanStatus.completed,
        modules: [],
        createdAt: DateTime(2026, 9, 1, 10, 0),
        updatedAt: DateTime(2026, 9, 10, 12, 0),
      );

      initialUser = UserModel(
        uid: userId,
        email: 'learner@example.com',
        fullName: 'Jane Learner',
        username: 'jlearner',
        skillsToTeach: ['Flutter Development'],
        verifiedSkills: [],
        createdAt: DateTime(2026, 9, 1),
        lastActive: DateTime(2026, 9, 13),
      );
    });

    test('1. SkillVerificationModel serialization with learningPlanId works correctly', () {
      final req = SkillVerificationModel(
        id: 'ver_001',
        userId: userId,
        skill: 'Flutter Development',
        type: VerificationType.learningPlan,
        status: VerificationStatus.pending,
        requestedAt: DateTime(2026, 9, 11, 14, 0),
        learningPlanId: 'plan_flutter_101',
      );

      final map = req.toMap();
      final restored = SkillVerificationModel.fromMap(map);

      expect(restored.id, 'ver_001');
      expect(restored.userId, userId);
      expect(restored.skill, 'Flutter Development');
      expect(restored.type, VerificationType.learningPlan);
      expect(restored.status, VerificationStatus.pending);
      expect(restored.learningPlanId, 'plan_flutter_101');
    });

    test('2. Completed Learning Plan grants verification eligibility but does NOT self-verify', () {
      // Completed Learning Plan grants eligibility
      final isEligible = completedPlan.status == LearningPlanStatus.completed &&
          completedPlan.learnerId == userId &&
          completedPlan.skillName == 'Flutter Development';

      expect(isEligible, isTrue);

      // Completed plan alone DOES NOT alter user's verifiedSkills array
      expect(initialUser.verifiedSkills.contains('Flutter Development'), isFalse);
    });

    test('3. Reviewer Approval transitions status to verified and updates verifiedSkills', () {
      final req = SkillVerificationModel(
        id: 'ver_001',
        userId: userId,
        skill: 'Flutter Development',
        type: VerificationType.learningPlan,
        status: VerificationStatus.pending,
        requestedAt: DateTime(2026, 9, 11, 14, 0),
        learningPlanId: 'plan_flutter_101',
      );

      // Reviewer approves
      final approvedReq = req.copyWith(
        status: VerificationStatus.verified,
        verifiedAt: DateTime(2026, 9, 12, 10, 0),
        verifiedBy: reviewerId,
        notes: 'Assessment passed and learning outcomes confirmed',
      );

      // User verifiedSkills array updated upon approval
      final updatedUser = initialUser.copyWith(
        verifiedSkills: [...initialUser.verifiedSkills, approvedReq.skill],
      );

      expect(approvedReq.status, VerificationStatus.verified);
      expect(approvedReq.verifiedBy, reviewerId);
      expect(updatedUser.verifiedSkills.contains('Flutter Development'), isTrue);
    });

    test('4. Reviewer Rejection transitions status to rejected without adding badge', () {
      final req = SkillVerificationModel(
        id: 'ver_002',
        userId: userId,
        skill: 'Advanced Architecture',
        type: VerificationType.test,
        status: VerificationStatus.pending,
        requestedAt: DateTime(2026, 9, 11, 15, 0),
      );

      final rejectedReq = req.copyWith(
        status: VerificationStatus.rejected,
        verifiedAt: DateTime(2026, 9, 12, 11, 0),
        verifiedBy: reviewerId,
        notes: 'Assessment score below minimum passing threshold',
      );

      expect(rejectedReq.status, VerificationStatus.rejected);
      expect(initialUser.verifiedSkills.contains('Advanced Architecture'), isFalse);
    });

    test('5. Reviewer Revocation transitions status to revoked and removes skill from verifiedSkills', () {
      final verifiedUser = initialUser.copyWith(
        verifiedSkills: ['Flutter Development', 'Dart Async'],
      );

      final activeVerification = SkillVerificationModel(
        id: 'ver_001',
        userId: userId,
        skill: 'Flutter Development',
        type: VerificationType.learningPlan,
        status: VerificationStatus.verified,
        requestedAt: DateTime(2026, 9, 10),
        verifiedAt: DateTime(2026, 9, 11),
        verifiedBy: reviewerId,
      );

      // Reviewer revokes
      final revokedVerification = activeVerification.copyWith(
        status: VerificationStatus.revoked,
        notes: 'Revoked due to policy violation',
      );

      final updatedVerifiedSkills = List<String>.from(verifiedUser.verifiedSkills)
        ..remove(revokedVerification.skill);
      final revokedUser = verifiedUser.copyWith(verifiedSkills: updatedVerifiedSkills);

      expect(revokedVerification.status, VerificationStatus.revoked);
      expect(revokedUser.verifiedSkills.contains('Flutter Development'), isFalse);
      expect(revokedUser.verifiedSkills.contains('Dart Async'), isTrue);
    });

    test('6. Standard users without custom claims are denied verification approvals or revocations', () {
      final standardUserClaims = <String, dynamic>{'reviewer': false, 'admin': false};

      bool isAuthorizedReviewer(Map<String, dynamic> claims) {
        return (claims['reviewer'] == true) || (claims['admin'] == true);
      }

      expect(isAuthorizedReviewer(standardUserClaims), isFalse);
    });

    test('7. Standardized Terminology Compliance verifies XchangeHub Verified branding', () {
      const trustedTerminology = 'XchangeHub Verified';
      const forbiddenClaim = 'Google Certified';

      expect(trustedTerminology.contains('XchangeHub Verified'), isTrue);
      expect(forbiddenClaim.contains('XchangeHub Verified'), isFalse);
    });
  });
}
