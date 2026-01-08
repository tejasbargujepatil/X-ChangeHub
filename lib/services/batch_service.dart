import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../models/batch_model.dart';
import '../models/user_model.dart';
import 'user_service.dart';
import 'notification_service.dart';

class BatchService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserService _userService = UserService();
  final NotificationService _notificationService = NotificationService();
  final Uuid _uuid = const Uuid();

  // Create a new batch
  Future<BatchModel> createBatch({
    required String skillToTeach,
    required String title,
    required String description,
    required int maxStudents,
    required DateTime startDate,
    required DateTime endDate,
    required String timeSlot,
    required ScheduleType scheduleType,
    List<int>? customDays,
    String? meetingLink,
  }) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) throw Exception('Not authenticated');

      final tutor = await _userService.getUserById(uid);
      if (tutor == null) throw Exception('User not found');

      // Use default Google Meet link if not provided
      final defaultMeetLink = meetingLink ?? 'https://meet.google.com/mqd-mrrv-afq';

      final batch = BatchModel(
        id: _uuid.v4(),
        tutorId: uid,
        tutorName: tutor.fullName,
        tutorImageUrl: tutor.profileImageUrl,
        skillToTeach: skillToTeach,
        title: title,
        description: description,
        maxStudents: maxStudents,
        startDate: startDate,
        endDate: endDate,
        timeSlot: timeSlot,
        scheduleType: scheduleType,
        customDays: customDays,
        meetingLink: defaultMeetLink,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('batches')
          .doc(batch.id)
          .set(batch.toMap());

      return batch;
    } catch (e) {
      throw Exception('Failed to create batch: $e');
    }
  }

  // Get all active batches
  Stream<List<BatchModel>> getActiveBatches() {
    return _firestore
        .collection('batches')
        .where('status', whereIn: [BatchStatus.open.name, BatchStatus.ongoing.name])
        .orderBy('startDate', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BatchModel.fromMap(doc.data()))
            .toList());
  }

  // Get batches by skill
  Stream<List<BatchModel>> getBatchesBySkill(String skill) {
    return _firestore
        .collection('batches')
        .where('skillToTeach', isEqualTo: skill)
        .where('status', whereIn: [BatchStatus.open.name, BatchStatus.ongoing.name])
        .orderBy('startDate', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BatchModel.fromMap(doc.data()))
            .toList());
  }

  // Get batches created by tutor
  Stream<List<BatchModel>> getMyBatches() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value([]);

    return _firestore
        .collection('batches')
        .where('tutorId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BatchModel.fromMap(doc.data()))
            .toList());
  }

  // Get batches enrolled by student
  Stream<List<BatchModel>> getMyEnrolledBatches() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value([]);

    return _firestore
        .collection('batches')
        .where('enrolledStudentIds', arrayContains: uid)
        .orderBy('startDate', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BatchModel.fromMap(doc.data()))
            .toList());
  }

  // Enroll in a batch
  Future<void> enrollInBatch(String batchId) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) throw Exception('Not authenticated');

      final batchDoc = await _firestore.collection('batches').doc(batchId).get();
      final batch = BatchModel.fromMap(batchDoc.data()!);

      if (batch.isFull) {
        throw Exception('Batch is full');
      }

      if (!batch.isAcceptingEnrollments) {
        throw Exception('Batch is not accepting enrollments');
      }

      if (batch.enrolledStudentIds.contains(uid)) {
        throw Exception('Already enrolled in this batch');
      }

      final student = await _userService.getUserById(uid);
      if (student == null) throw Exception('User not found');

      await _firestore.collection('batches').doc(batchId).update({
        'enrolledStudentIds': FieldValue.arrayUnion([uid]),
        'currentEnrollments': FieldValue.increment(1),
      });

      // Send notification to tutor
      await _notificationService.createNotification(
        userId: batch.tutorId,
        type: NotificationType.general,
        title: 'New Batch Enrollment',
        message: '${student.fullName} has enrolled in your batch "${batch.title}"',
        data: {
          'batchId': batchId,
          'studentId': uid,
          'studentName': student.fullName,
        },
      );
    } catch (e) {
      throw Exception('Failed to enroll in batch: $e');
    }
  }

  // Leave a batch
  Future<void> leaveBatch(String batchId) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) throw Exception('Not authenticated');

      await _firestore.collection('batches').doc(batchId).update({
        'enrolledStudentIds': FieldValue.arrayRemove([uid]),
        'currentEnrollments': FieldValue.increment(-1),
      });
    } catch (e) {
      throw Exception('Failed to leave batch: $e');
    }
  }

  // Update batch status
  Future<void> updateBatchStatus(String batchId, BatchStatus status) async {
    try {
      await _firestore.collection('batches').doc(batchId).update({
        'status': status.name,
      });
    } catch (e) {
      throw Exception('Failed to update batch status: $e');
    }
  }

  // Update batch details (only by tutor)
  Future<void> updateBatch({
    required String batchId,
    String? title,
    String? description,
    int? maxStudents,
    String? meetingLink,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (title != null) updates['title'] = title;
      if (description != null) updates['description'] = description;
      if (maxStudents != null) updates['maxStudents'] = maxStudents;
      if (meetingLink != null) updates['meetingLink'] = meetingLink;

      if (updates.isNotEmpty) {
        await _firestore.collection('batches').doc(batchId).update(updates);
      }
    } catch (e) {
      throw Exception('Failed to update batch: $e');
    }
  }

  // Delete batch (only if no enrollments)
  Future<void> deleteBatch(String batchId) async {
    try {
      final batchDoc = await _firestore.collection('batches').doc(batchId).get();
      final batch = BatchModel.fromMap(batchDoc.data()!);

      if (batch.currentEnrollments > 0) {
        throw Exception('Cannot delete batch with enrolled students');
      }

      await _firestore.collection('batches').doc(batchId).delete();
    } catch (e) {
      throw Exception('Failed to delete batch: $e');
    }
  }

  // Get batch by ID
  Future<BatchModel?> getBatchById(String batchId) async {
    try {
      final doc = await _firestore.collection('batches').doc(batchId).get();
      if (doc.exists) {
        return BatchModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get batch: $e');
    }
  }
}
