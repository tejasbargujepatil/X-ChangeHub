import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../models/learning_request_model.dart';
import '../models/user_model.dart';
import '../models/skill_exchange_model.dart';
import 'user_service.dart';
import 'skill_exchange_service.dart';
import 'notification_service.dart';

class LearningRequestService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserService _userService = UserService();
  final SkillExchangeService _exchangeService = SkillExchangeService();
  final NotificationService _notificationService = NotificationService();
  final Uuid _uuid = const Uuid();

  // Create a public learning request
  Future<LearningRequestModel> createLearningRequest({
    required String skillRequested,
    String? skillOffered,
    String? message,
    List<String>? preferredTimeSlots,
    DateTime? preferredDate,
    String? preferredTime,
    int? sessionDuration,
  }) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) throw Exception('Not authenticated');

      final learner = await _userService.getUserById(uid);
      if (learner == null) throw Exception('User not found');

      final request = LearningRequestModel(
        id: _uuid.v4(),
        learnerId: uid,
        learnerName: learner.fullName,
        learnerImageUrl: learner.profileImageUrl,
        skillRequested: skillRequested,
        skillOffered: skillOffered,
        message: message,
        preferredTimeSlots: preferredTimeSlots,
        preferredDate: preferredDate,
        preferredTime: preferredTime,
        sessionDuration: sessionDuration,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('learning_requests')
          .doc(request.id)
          .set(request.toMap());

      return request;
    } catch (e) {
      throw Exception('Failed to create learning request: $e');
    }
  }

  // Get all open learning requests
  Stream<List<LearningRequestModel>> getOpenRequests() {
    return _firestore
        .collection('learning_requests')
        .where('status', isEqualTo: LearningRequestStatus.open.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => LearningRequestModel.fromMap(doc.data()))
            .toList());
  }

  // Get open requests for a specific skill
  Stream<List<LearningRequestModel>> getOpenRequestsBySkill(String skill) {
    return _firestore
        .collection('learning_requests')
        .where('status', isEqualTo: LearningRequestStatus.open.name)
        .where('skillRequested', isEqualTo: skill)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => LearningRequestModel.fromMap(doc.data()))
            .toList());
  }

  // Get user's own learning requests
  Stream<List<LearningRequestModel>> getMyLearningRequests() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value([]);

    return _firestore
        .collection('learning_requests')
        .where('learnerId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => LearningRequestModel.fromMap(doc.data()))
            .toList());
  }

  // Accept a learning request (FCFS - first tutor to accept wins)
  Future<void> acceptLearningRequest(String requestId) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) throw Exception('Not authenticated');

      final tutor = await _userService.getUserById(uid);
      if (tutor == null) throw Exception('User not found');

      // Get the request
      final requestDoc = await _firestore
          .collection('learning_requests')
          .doc(requestId)
          .get();

      if (!requestDoc.exists) {
        throw Exception('Learning request not found');
      }

      final request = LearningRequestModel.fromMap(requestDoc.data()!);

      // Check if still open (FCFS check)
      if (request.status != LearningRequestStatus.open) {
        throw Exception('This request has already been accepted by another tutor');
      }

      // Get learner details
      final learner = await _userService.getUserById(request.learnerId);
      if (learner == null) throw Exception('Learner not found');

      // Create exchange manually with correct user roles
      // Learner = requester, Tutor = teacher
      final exchangeId = const Uuid().v4();
      
      // Automatically accept the exchange with scheduling information
      // Combine date and time into DateTime for scheduledTime parameter
      DateTime scheduledDateTime;
      if (request.preferredDate != null && request.preferredTime != null) {
        // Parse the time string (e.g., "9:00 PM") and combine with date
        final timeParts = request.preferredTime!.split(':');
        final hour = int.parse(timeParts[0]);
        final isPM = request.preferredTime!.contains('PM');
        final adjustedHour = isPM && hour != 12 ? hour + 12 : (hour == 12 && !isPM ? 0 : hour);
        scheduledDateTime = DateTime(
          request.preferredDate!.year,
          request.preferredDate!.month,
          request.preferredDate!.day,
          adjustedHour,
          timeParts.length > 1 ? int.parse(timeParts[1].replaceAll(RegExp(r'[^0-9]'), '')) : 0,
        );
      } else if (request.preferredDate != null) {
        scheduledDateTime = DateTime(
          request.preferredDate!.year,
          request.preferredDate!.month,
          request.preferredDate!.day,
          21, // Default to 9 PM
        );
      } else {
        scheduledDateTime = DateTime.now().add(const Duration(days: 1, hours: 21));
      }

      // Create exchange document directly (already accepted status)
      await _firestore.collection('skill_exchanges').doc(exchangeId).set({
        'id': exchangeId,
        'requesterId': request.learnerId, // Learner is the requester
        'requesterName': request.learnerName,
        'requesterImageUrl': request.learnerImageUrl,
        'teacherId': uid, // Tutor is the teacher
        'teacherName': tutor.fullName,
        'teacherImageUrl': tutor.profileImageUrl,
        'skillOffered': request.skillOffered ?? 'Free Exchange',
        'skillRequested': request.skillRequested,
        'message': request.message,
        'status': ExchangeStatus.accepted.name, // Immediately accepted!
        'scheduledTime': scheduledDateTime.toIso8601String(),
        'duration': request.sessionDuration ?? 60,
        'meetingLink': null,
        'createdAt': DateTime.now().toIso8601String(),
      });

      // Update request as accepted
      await _firestore.collection('learning_requests').doc(requestId).update({
        'status': LearningRequestStatus.accepted.name,
        'acceptedByTutorId': uid,
        'acceptedByTutorName': tutor.fullName,
        'acceptedAt': DateTime.now().toIso8601String(),
        'exchangeId': exchangeId,
      });

      // Send notification to learner
      await _notificationService.createNotification(
        userId: request.learnerId,
        type: NotificationType.exchangeAccepted,
        title: 'Your Learning Request Accepted!',
        message: '${tutor.fullName} has accepted your request to learn ${request.skillRequested}!',
        data: {
          'requestId': requestId,
          'tutorId': uid,
          'tutorName': tutor.fullName,
          'exchangeId': exchangeId,
        },
      );
    } catch (e) {
      throw Exception('Failed to accept learning request: $e');
    }
  }

  // Cancel a learning request (by learner)
  Future<void> cancelLearningRequest(String requestId) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) throw Exception('Not authenticated');

      final requestDoc = await _firestore
          .collection('learning_requests')
          .doc(requestId)
          .get();

      if (!requestDoc.exists) {
        throw Exception('Learning request not found');
      }

      final request = LearningRequestModel.fromMap(requestDoc.data()!);

      // Only learner can cancel their own request
      if (request.learnerId != uid) {
        throw Exception('You can only cancel your own requests');
      }

      // Can only cancel if still open
      if (request.status != LearningRequestStatus.open) {
        throw Exception('Can only cancel open requests');
      }

      await _firestore.collection('learning_requests').doc(requestId).update({
        'status': LearningRequestStatus.cancelled.name,
      });
    } catch (e) {
      throw Exception('Failed to cancel learning request: $e');
    }
  }

  // Delete old completed/cancelled requests (cleanup)
  Future<void> deleteOldRequests({int daysOld = 30}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));

      final oldRequests = await _firestore
          .collection('learning_requests')
          .where('status', whereIn: [
            LearningRequestStatus.completed.name,
            LearningRequestStatus.cancelled.name,
          ])
          .where('createdAt', isLessThan: cutoffDate.toIso8601String())
          .get();

      final batch = _firestore.batch();
      for (var doc in oldRequests.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to delete old requests: $e');
    }
  }
}
