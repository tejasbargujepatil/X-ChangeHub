import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/learning_plan_model.dart';

class LearningPlanService {
  final FirebaseFirestore? _customFirestore;
  final FirebaseAuth? _customAuth;

  LearningPlanService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _customFirestore = firestore,
        _customAuth = auth;

  FirebaseFirestore get _firestore => _customFirestore ?? FirebaseFirestore.instance;
  FirebaseAuth get _auth => _customAuth ?? FirebaseAuth.instance;

  /// Creates a new Learning Plan for an exchange.
  /// If a plan already exists for [exchangeId], returns the existing plan safely.
  Future<LearningPlan> createLearningPlan({
    required String exchangeId,
    required String mentorId,
    required String learnerId,
    required String skillName,
    List<LearningModule> modules = const [],
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('Unauthenticated: User must be signed in');
      }

      if (currentUser.uid != mentorId && currentUser.uid != learnerId) {
        throw Exception('Unauthorized: User is not a participant in this exchange');
      }

      final docRef = _firestore.collection('learning_plans').doc(exchangeId);
      final docSnap = await docRef.get();

      if (docSnap.exists && docSnap.data() != null) {
        return LearningPlan.fromMap(docSnap.data()!);
      }

      final planId = exchangeId;
      final now = DateTime.now();

      final initialPlan = LearningPlan(
        planId: planId,
        exchangeId: exchangeId,
        mentorId: mentorId,
        learnerId: learnerId,
        skillName: skillName,
        status: LearningPlanStatus.active,
        modules: modules,
        createdAt: now,
        updatedAt: now,
      ).recalculateProgress();

      await docRef.set(initialPlan.toMap());

      // Attempt to link learningPlanId to skill_exchanges document if it exists
      try {
        await _firestore.collection('skill_exchanges').doc(exchangeId).update({
          'learningPlanId': planId,
        });
      } catch (_) {
        // Fallback: Silent continuation if exchange document doesn't exist yet
      }

      return initialPlan;
    } catch (e) {
      throw Exception('Failed to create learning plan: $e');
    }
  }

  /// Fetches a Learning Plan by [exchangeId].
  /// Returns null if document does not exist.
  Future<LearningPlan?> getLearningPlan(String exchangeId) async {
    try {
      final doc = await _firestore.collection('learning_plans').doc(exchangeId).get();
      if (doc.exists && doc.data() != null) {
        return LearningPlan.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get learning plan: $e');
    }
  }

  /// Stream real-time changes to a Learning Plan for [exchangeId].
  Stream<LearningPlan?> watchLearningPlan(String exchangeId) {
    return _firestore
        .collection('learning_plans')
        .doc(exchangeId)
        .snapshots()
        .map((doc) {
      if (doc.exists && doc.data() != null) {
        try {
          return LearningPlan.fromMap(doc.data()!);
        } catch (_) {
          return null;
        }
      }
      return null;
    });
  }

  /// Updates plan structure while strictly protecting immutable identity fields.
  Future<void> updateLearningPlan(LearningPlan plan) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('Unauthenticated: User must be signed in');
      }

      if (currentUser.uid != plan.mentorId && currentUser.uid != plan.learnerId) {
        throw Exception('Unauthorized: User is not a participant in this exchange');
      }

      final docRef = _firestore.collection('learning_plans').doc(plan.exchangeId);
      final docSnap = await docRef.get();

      if (!docSnap.exists || docSnap.data() == null) {
        throw Exception('Learning plan not found');
      }

      final existingPlan = LearningPlan.fromMap(docSnap.data()!);

      // Enforce immutability of identity fields
      if (existingPlan.planId != plan.planId ||
          existingPlan.exchangeId != plan.exchangeId ||
          existingPlan.mentorId != plan.mentorId ||
          existingPlan.learnerId != plan.learnerId) {
        throw Exception('Cannot modify immutable identity fields');
      }

      // Enforce structural immutability and lifecycle transitions for non-draft plans
      if (existingPlan.status != LearningPlanStatus.draft) {
        if (plan.status == LearningPlanStatus.draft) {
          throw Exception('Cannot revert an active or completed Learning Plan to draft status.');
        }

        if (existingPlan.status == LearningPlanStatus.completed &&
            plan.status != LearningPlanStatus.completed) {
          throw Exception('Cannot modify status of a completed Learning Plan.');
        }

        if (!existingPlan.isStructurallyEqualTo(plan)) {
          throw Exception('Cannot modify the structure of an active or completed Learning Plan.');
        }
      }

      final updatedPlan = plan.copyWith(
        planId: existingPlan.planId,
        exchangeId: existingPlan.exchangeId,
        mentorId: existingPlan.mentorId,
        learnerId: existingPlan.learnerId,
        updatedAt: DateTime.now(),
      ).recalculateProgress();

      await docRef.set(updatedPlan.toMap(), SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to update learning plan: $e');
    }
  }

  /// Mentor marks a specific topic as taught.
  /// Modifies ONLY mentor-owned fields via atomic Firestore Transaction.
  Future<void> markTopicAsTaught({
    required String exchangeId,
    required String moduleId,
    required String topicId,
    String? mentorNotes,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('Unauthenticated: User must be signed in');
      }

      final docRef = _firestore.collection('learning_plans').doc(exchangeId);

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists || snapshot.data() == null) {
          throw Exception('Learning plan not found');
        }

        final plan = LearningPlan.fromMap(snapshot.data()!);

        if (plan.mentorId != currentUser.uid) {
          throw Exception('Unauthorized: Only the mentor can mark a topic as taught');
        }

        bool topicFound = false;
        final updatedModules = plan.modules.map((module) {
          if (module.moduleId == moduleId) {
            final updatedTopics = module.topics.map((topic) {
              if (topic.topicId == topicId) {
                topicFound = true;
                // Modify ONLY mentor-owned fields
                return topic.copyWith(
                  taughtByMentor: true,
                  taughtAt: DateTime.now(),
                  mentorNotes: mentorNotes ?? topic.mentorNotes,
                  // Preserve learner-owned fields untouched
                  learnerConfirmed: topic.learnerConfirmed,
                  learnerStatus: topic.learnerStatus,
                  learnerConfirmedAt: topic.learnerConfirmedAt,
                  learnerFeedback: topic.learnerFeedback,
                );
              }
              return topic;
            }).toList();
            return module.copyWith(topics: updatedTopics);
          }
          return module;
        }).toList();

        if (!topicFound) {
          throw Exception('Topic $topicId in module $moduleId not found');
        }

        final updatedPlan = plan.copyWith(
          modules: updatedModules,
          updatedAt: DateTime.now(),
        ).recalculateProgress();

        transaction.update(docRef, updatedPlan.toMap());
      });
    } catch (e) {
      throw Exception('Failed to mark topic as taught: $e');
    }
  }

  /// Learner confirms understanding of a topic.
  /// Modifies ONLY learner-owned fields via atomic Firestore Transaction.
  Future<void> confirmTopic({
    required String exchangeId,
    required String moduleId,
    required String topicId,
    required LearnerTopicStatus status,
    String? feedback,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('Unauthenticated: User must be signed in');
      }

      if (status == LearnerTopicStatus.pending || status == LearnerTopicStatus.taught) {
        throw Exception('Invalid status: Must be completed, partiallyUnderstood, or needHelp');
      }

      final docRef = _firestore.collection('learning_plans').doc(exchangeId);

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists || snapshot.data() == null) {
          throw Exception('Learning plan not found');
        }

        final plan = LearningPlan.fromMap(snapshot.data()!);

        if (plan.learnerId != currentUser.uid) {
          throw Exception('Unauthorized: Only the learner can confirm topic status');
        }

        bool topicFound = false;
        final updatedModules = plan.modules.map((module) {
          if (module.moduleId == moduleId) {
            final updatedTopics = module.topics.map((topic) {
              if (topic.topicId == topicId) {
                topicFound = true;
                // Modify ONLY learner-owned fields
                return topic.copyWith(
                  learnerConfirmed: true,
                  learnerStatus: status,
                  learnerConfirmedAt: DateTime.now(),
                  learnerFeedback: feedback ?? topic.learnerFeedback,
                  // Preserve mentor-owned fields untouched
                  taughtByMentor: topic.taughtByMentor,
                  taughtAt: topic.taughtAt,
                  mentorNotes: topic.mentorNotes,
                );
              }
              return topic;
            }).toList();
            return module.copyWith(topics: updatedTopics);
          }
          return module;
        }).toList();

        if (!topicFound) {
          throw Exception('Topic $topicId in module $moduleId not found');
        }

        final updatedPlan = plan.copyWith(
          modules: updatedModules,
          updatedAt: DateTime.now(),
        ).recalculateProgress();

        transaction.update(docRef, updatedPlan.toMap());
      });
    } catch (e) {
      throw Exception('Failed to confirm topic: $e');
    }
  }

  /// Activates a Learning Plan for [exchangeId].
  Future<void> activateLearningPlan(String exchangeId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('Unauthenticated: User must be signed in');
      }

      final docRef = _firestore.collection('learning_plans').doc(exchangeId);
      final docSnap = await docRef.get();

      if (!docSnap.exists || docSnap.data() == null) {
        throw Exception('Learning plan not found');
      }

      final plan = LearningPlan.fromMap(docSnap.data()!);

      if (currentUser.uid != plan.mentorId && currentUser.uid != plan.learnerId) {
        throw Exception('Unauthorized: User is not a participant in this exchange');
      }

      if (plan.status != LearningPlanStatus.draft) {
        throw Exception('Only draft Learning Plans can be activated.');
      }

      final updatedPlan = plan.copyWith(
        status: LearningPlanStatus.active,
        updatedAt: DateTime.now(),
      );

      await docRef.set(updatedPlan.toMap(), SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to activate learning plan: $e');
    }
  }
}
