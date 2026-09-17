import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/learning_issue_model.dart';
import '../models/learning_plan_model.dart';

class LearningIssueService {
  final FirebaseFirestore? _customFirestore;
  final FirebaseAuth? _customAuth;

  LearningIssueService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _customFirestore = firestore,
        _customAuth = auth;

  FirebaseFirestore get _firestore => _customFirestore ?? FirebaseFirestore.instance;
  FirebaseAuth get _auth => _customAuth ?? FirebaseAuth.instance;

  /// Creates a new evidence-backed Learning Issue for a topic in a Skill Exchange.
  Future<LearningIssueModel> createLearningIssue({
    required String exchangeId,
    required String moduleId,
    required String topicId,
    required LearningIssueType issueType,
    required String description,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('Unauthenticated: User must be signed in to report an issue');
      }

      // 1. Fetch Learning Plan for the exchange
      final planDoc = await _firestore.collection('learning_plans').doc(exchangeId).get();
      if (!planDoc.exists || planDoc.data() == null) {
        throw Exception('Learning Plan not found for exchange $exchangeId');
      }

      final plan = LearningPlan.fromMap(planDoc.data()!);

      // 2. Authorization: Reporter must belong to exchange
      if (currentUser.uid != plan.mentorId && currentUser.uid != plan.learnerId) {
        throw Exception('Unauthorized: You are not a participant in this exchange');
      }

      // 3. Authorization: Learner role requirement for topic reporting
      if (currentUser.uid != plan.learnerId) {
        throw Exception('Unauthorized: Only the learner can report a topic learning issue');
      }

      // 4. Topic Existence & Evidence Snapshot Extraction
      LearningTopic? targetTopic;
      for (final module in plan.modules) {
        if (module.moduleId == moduleId) {
          for (final topic in module.topics) {
            if (topic.topicId == topicId) {
              targetTopic = topic;
              break;
            }
          }
        }
      }

      if (targetTopic == null) {
        throw Exception('Topic $topicId in module $moduleId not found in Learning Plan');
      }

      // 5. Anti-spam Check: Prevent duplicate unresolved issues for same topic & reporter
      final existingIssuesSnap = await _firestore
          .collection('learning_issues')
          .where('exchangeId', isEqualTo: exchangeId)
          .where('topicId', isEqualTo: topicId)
          .where('reporterId', isEqualTo: currentUser.uid)
          .get();

      final hasActiveIssue = existingIssuesSnap.docs.any((doc) {
        final data = doc.data();
        final status = data['status'];
        return status == LearningIssueStatus.open.name ||
            status == LearningIssueStatus.underReview.name;
      });

      if (hasActiveIssue) {
        throw Exception('An unresolved Learning Issue already exists for this topic.');
      }

      // 6. Build Evidence Snapshot & Learning Issue Model
      final evidenceSnapshot = TopicEvidenceSnapshot.fromTopic(targetTopic);
      final issueId = 'issue_${DateTime.now().millisecondsSinceEpoch}';
      final now = DateTime.now();

      final newIssue = LearningIssueModel(
        issueId: issueId,
        exchangeId: exchangeId,
        learningPlanId: plan.planId,
        reporterId: currentUser.uid,
        reportedUserId: plan.mentorId,
        moduleId: moduleId,
        topicId: topicId,
        issueType: issueType,
        description: description.trim(),
        status: LearningIssueStatus.open,
        resolution: LearningIssueResolution.pending,
        evidenceSnapshot: evidenceSnapshot,
        createdAt: now,
        updatedAt: now,
      );

      // 7. Save to Firestore
      await _firestore.collection('learning_issues').doc(issueId).set(newIssue.toMap());

      return newIssue;
    } catch (e) {
      throw Exception('Failed to report Learning Issue: $e');
    }
  }

  /// Fetches a single Learning Issue by [issueId].
  Future<LearningIssueModel?> getLearningIssue(String issueId) async {
    try {
      final doc = await _firestore.collection('learning_issues').doc(issueId).get();
      if (doc.exists && doc.data() != null) {
        return LearningIssueModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get Learning Issue: $e');
    }
  }

  /// Streams Learning Issues filed for a specific exchange.
  Stream<List<LearningIssueModel>> watchLearningIssuesForExchange(String exchangeId) {
    return _firestore
        .collection('learning_issues')
        .where('exchangeId', isEqualTo: exchangeId)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => LearningIssueModel.fromMap(doc.data())).toList());
  }

  /// Streams all Learning Issues (Admin/Reviewer interface) optionally filtered by status.
  Stream<List<LearningIssueModel>> watchAllLearningIssues({LearningIssueStatus? status}) {
    Query query = _firestore.collection('learning_issues').orderBy('createdAt', descending: true);
    if (status != null) {
      query = query.where('status', isEqualTo: status.name);
    }
    return query.snapshots().map((snap) =>
        snap.docs.map((doc) => LearningIssueModel.fromMap(doc.data() as Map<String, dynamic>)).toList());
  }

  /// Checks if the current user has authorized reviewer or admin custom claims.
  Future<bool> isReviewer({bool forceRefresh = false}) async {
    final user = _auth.currentUser;
    if (user == null) return false;
    final tokenResult = await user.getIdTokenResult(forceRefresh);
    final claims = tokenResult.claims;
    if (claims == null) return false;
    return (claims['reviewer'] == true) || (claims['admin'] == true);
  }

  /// Resolves a Learning Issue and records an intervention if appropriate.
  Future<void> resolveLearningIssue({
    required String issueId,
    required LearningIssueResolution resolution,
    String? resolutionNotes,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('Unauthenticated: Reviewer must be signed in');
      }

      // Authorization Check: Verify caller is an authorized reviewer/admin via Custom Claims
      final reviewerAuthorized = await isReviewer();
      if (!reviewerAuthorized) {
        throw Exception('Unauthorized: Only authorized reviewers or admins can resolve learning issues');
      }

      final docRef = _firestore.collection('learning_issues').doc(issueId);
      final docSnap = await docRef.get();

      if (!docSnap.exists || docSnap.data() == null) {
        throw Exception('Learning Issue not found');
      }

      final existingIssue = LearningIssueModel.fromMap(docSnap.data()!);
      final now = DateTime.now();

      final updatedIssue = existingIssue.copyWith(
        status: resolution == LearningIssueResolution.dismissed
            ? LearningIssueStatus.dismissed
            : LearningIssueStatus.resolved,
        resolution: resolution,
        resolutionNotes: resolutionNotes,
        updatedAt: now,
        resolvedAt: now,
        resolvedBy: currentUser.uid,
      );

      await docRef.update(updatedIssue.toMap());

      // If resolution requires intervention (not dismissed), record intervention document
      if (resolution != LearningIssueResolution.dismissed &&
          resolution != LearningIssueResolution.pending) {
        final interventionId = 'int_${now.millisecondsSinceEpoch}';
        final intervention = LearningInterventionModel(
          interventionId: interventionId,
          issueId: issueId,
          exchangeId: existingIssue.exchangeId,
          targetUserId: existingIssue.reportedUserId,
          assignedBy: currentUser.uid,
          action: resolution,
          status: 'pending',
          notes: resolutionNotes,
          createdAt: now,
        );

        await _firestore
            .collection('learning_interventions')
            .doc(interventionId)
            .set(intervention.toMap());
      }
    } catch (e) {
      throw Exception('Failed to resolve Learning Issue: $e');
    }
  }

  /// Dismisses a Learning Issue as unsubstantiated.
  Future<void> dismissLearningIssue({
    required String issueId,
    String? notes,
  }) async {
    return resolveLearningIssue(
      issueId: issueId,
      resolution: LearningIssueResolution.dismissed,
      resolutionNotes: notes,
    );
  }
}
