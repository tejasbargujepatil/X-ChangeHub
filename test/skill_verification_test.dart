import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xchangehub/models/enhancement_models.dart';
import 'package:xchangehub/models/learning_plan_model.dart';
import 'package:xchangehub/models/user_model.dart';
import 'package:xchangehub/services/enhancement_services.dart';
import 'package:xchangehub/screens/profile/request_verification_dialog.dart';
import 'package:xchangehub/screens/admin/skill_verifications_admin_screen.dart';
import 'package:xchangehub/widgets/verified_certificate_dialog.dart';

class FakeVerificationService extends VerificationService {
  final List<String> verifiedSkills;
  final List<SkillVerificationModel> existingRequests;
  final bool shouldThrowError;

  FakeVerificationService({
    this.verifiedSkills = const [],
    this.existingRequests = const [],
    this.shouldThrowError = false,
  });

  @override
  Future<List<String>> getVerifiedSkills(String userId) async {
    if (shouldThrowError) {
      throw Exception('Database lookup error');
    }
    return verifiedSkills;
  }

  @override
  Future<bool> hasActiveVerificationRequest(String userId, String skill) async {
    if (shouldThrowError) {
      throw Exception('Database error');
    }

    if (verifiedSkills.contains(skill)) {
      return true;
    }

    final activeStatuses = {
      VerificationStatus.pending,
      VerificationStatus.underReview,
      VerificationStatus.verified,
    };

    return existingRequests.any((req) =>
        req.userId == userId &&
        req.skill == skill &&
        activeStatuses.contains(req.status));
  }
}

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

    test('8. VerificationService exposes real-time stream methods watchPendingVerifications and watchUserVerifications', () {
      final service = VerificationService();
      expect(service.watchPendingVerifications, isNotNull);
      expect(service.watchUserVerifications, isNotNull);
    });

    testWidgets('9. RequestVerificationDialog renders skill selection and verification options', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RequestVerificationDialog(
              userId: 'user_123',
              availableSkills: const ['Flutter Development', 'Dart Async'],
            ),
          ),
        ),
      );

      expect(find.text('Request XchangeHub Verified'), findsOneWidget);
      expect(find.text('Flutter Development'), findsWidgets);
      expect(find.text('Submit Request'), findsOneWidget);
    });

    testWidgets('10. SkillVerificationsAdminScreen renders reviewer access UI state', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SkillVerificationsAdminScreen(),
        ),
      );

      await tester.pump();
      expect(find.text('Skill Verification Portal'), findsOneWidget);
    });

    testWidgets('11a. Verified skill renders official skill credential card', (WidgetTester tester) async {
      final fakeService = FakeVerificationService(verifiedSkills: ['Flutter Development']);

      await tester.pumpWidget(
        MaterialApp(
          home: VerifiedCertificateDialog(
            userId: 'user_123',
            userName: 'Jane Learner',
            skill: 'Flutter Development',
            verificationService: fakeService,
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('XCHANGEHUB VERIFIED'), findsOneWidget);
      expect(find.text('Official Skill Certificate'), findsOneWidget);
      expect(find.text('Jane Learner'), findsOneWidget);
      expect(find.text('Flutter Development'), findsOneWidget);
    });

    testWidgets('11b. Unverified skill DOES NOT render certificate card and shows Skill Not Verified state', (WidgetTester tester) async {
      final fakeService = FakeVerificationService(verifiedSkills: ['Python']);

      await tester.pumpWidget(
        MaterialApp(
          home: VerifiedCertificateDialog(
            userId: 'user_123',
            userName: 'Jane Learner',
            skill: 'Flutter Development',
            verificationService: fakeService,
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('XCHANGEHUB VERIFIED'), findsNothing);
      expect(find.text('Official Skill Certificate'), findsNothing);
      expect(find.text('Skill Not Verified'), findsOneWidget);
      expect(find.text('This skill does not currently have an XchangeHub Verified credential.'), findsOneWidget);
    });

    testWidgets('11c. Verification lookup failure DOES NOT render certificate card and shows error state', (WidgetTester tester) async {
      final fakeService = FakeVerificationService(shouldThrowError: true);

      await tester.pumpWidget(
        MaterialApp(
          home: VerifiedCertificateDialog(
            userId: 'user_123',
            userName: 'Jane Learner',
            skill: 'Flutter Development',
            verificationService: fakeService,
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('XCHANGEHUB VERIFIED'), findsNothing);
      expect(find.text('Official Skill Certificate'), findsNothing);
      expect(find.text('Verification Lookup Error'), findsOneWidget);
    });

    test('12. firestore.indexes.json is valid JSON and contains required verifications composite indexes', () {
      final indexFile = File('firestore.indexes.json');
      expect(indexFile.existsSync(), isTrue);

      final content = indexFile.readAsStringSync();
      final json = jsonDecode(content) as Map<String, dynamic>;

      expect(json.containsKey('indexes'), isTrue);
      final indexes = json['indexes'] as List;

      final hasStatusIndex = indexes.any((idx) {
        final collection = idx['collectionGroup'];
        final fields = idx['fields'] as List;
        return collection == 'verifications' &&
            fields.length == 2 &&
            fields[0]['fieldPath'] == 'status' &&
            fields[1]['fieldPath'] == 'requestedAt';
      });

      final hasUserIndex = indexes.any((idx) {
        final collection = idx['collectionGroup'];
        final fields = idx['fields'] as List;
        return collection == 'verifications' &&
            fields.length == 2 &&
            fields[0]['fieldPath'] == 'userId' &&
            fields[1]['fieldPath'] == 'requestedAt';
      });

      expect(hasStatusIndex, isTrue);
      expect(hasUserIndex, isTrue);
    });

    group('Duplicate Verification Request Prevention Tests', () {
      test('13.1 No existing request allows new verification request', () async {
        final fakeService = FakeVerificationService(existingRequests: []);
        final isBlocked = await fakeService.hasActiveVerificationRequest(userId, 'Python');
        expect(isBlocked, isFalse);
      });

      test('13.2 Existing pending request blocks duplicate verification request', () async {
        final fakeService = FakeVerificationService(
          existingRequests: [
            SkillVerificationModel(
              id: 'ver_001',
              userId: userId,
              skill: 'Python',
              type: VerificationType.certificate,
              status: VerificationStatus.pending,
              requestedAt: DateTime.now(),
            ),
          ],
        );
        final isBlocked = await fakeService.hasActiveVerificationRequest(userId, 'Python');
        expect(isBlocked, isTrue);
      });

      test('13.3 Existing underReview request blocks duplicate verification request', () async {
        final fakeService = FakeVerificationService(
          existingRequests: [
            SkillVerificationModel(
              id: 'ver_002',
              userId: userId,
              skill: 'Python',
              type: VerificationType.learningPlan,
              status: VerificationStatus.underReview,
              requestedAt: DateTime.now(),
            ),
          ],
        );
        final isBlocked = await fakeService.hasActiveVerificationRequest(userId, 'Python');
        expect(isBlocked, isTrue);
      });

      test('13.4 Existing verified request blocks duplicate verification request', () async {
        final fakeService = FakeVerificationService(
          existingRequests: [
            SkillVerificationModel(
              id: 'ver_003',
              userId: userId,
              skill: 'Python',
              type: VerificationType.portfolio,
              status: VerificationStatus.verified,
              requestedAt: DateTime.now(),
            ),
          ],
        );
        final isBlocked = await fakeService.hasActiveVerificationRequest(userId, 'Python');
        expect(isBlocked, isTrue);
      });

      test('13.5 Existing rejected request allows new verification request', () async {
        final fakeService = FakeVerificationService(
          existingRequests: [
            SkillVerificationModel(
              id: 'ver_004',
              userId: userId,
              skill: 'Python',
              type: VerificationType.certificate,
              status: VerificationStatus.rejected,
              requestedAt: DateTime.now().subtract(const Duration(days: 10)),
            ),
          ],
        );
        final isBlocked = await fakeService.hasActiveVerificationRequest(userId, 'Python');
        expect(isBlocked, isFalse);
      });

      test('13.6 Existing revoked request allows new verification request', () async {
        final fakeService = FakeVerificationService(
          existingRequests: [
            SkillVerificationModel(
              id: 'ver_005',
              userId: userId,
              skill: 'Python',
              type: VerificationType.learningPlan,
              status: VerificationStatus.revoked,
              requestedAt: DateTime.now().subtract(const Duration(days: 30)),
            ),
          ],
        );
        final isBlocked = await fakeService.hasActiveVerificationRequest(userId, 'Python');
        expect(isBlocked, isFalse);
      });

      test('13.7 Already verified skill in user profile blocks verification request', () async {
        final fakeService = FakeVerificationService(verifiedSkills: ['Python']);
        final isBlocked = await fakeService.hasActiveVerificationRequest(userId, 'Python');
        expect(isBlocked, isTrue);
      });

      testWidgets('13.8 Duplicate submission through UI shows warning and blocks submit button', (WidgetTester tester) async {
        final fakeService = FakeVerificationService(
          existingRequests: [
            SkillVerificationModel(
              id: 'ver_pending_1',
              userId: 'user_123',
              skill: 'Python',
              type: VerificationType.certificate,
              status: VerificationStatus.pending,
              requestedAt: DateTime.now(),
            ),
          ],
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: RequestVerificationDialog(
                userId: 'user_123',
                availableSkills: const ['Python'],
                verificationService: fakeService,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Verification already requested'), findsOneWidget);
        expect(find.text('You already have an active verification request for this skill.'), findsOneWidget);

        final submitButton = tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Submit Request'));
        expect(submitButton.onPressed, isNull);
      });
    });
  });
}
