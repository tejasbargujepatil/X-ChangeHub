import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../models/enhancement_models.dart';

/// Service for in-app chat functionality
class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Uuid _uuid = const Uuid();

  /// Send a text message
  Future<void> sendMessage({
    required String exchangeId,
    required String receiverId,
    required String receiverName,
    required String? receiverImageUrl,
    required String message,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('Not authenticated');

    final chatMessage = ChatMessageModel(
      id: _uuid.v4(),
      exchangeId: exchangeId,
      senderId: currentUser.uid,
      senderName: receiverName, // Will be replaced with actual user name
      receiverId: receiverId,
      message: message,
      timestamp: DateTime.now(),
      type: MessageType.text,
    );

    await _firestore
        .collection('chats')
        .doc(exchangeId)
        .collection('messages')
        .doc(chatMessage.id)
        .set(chatMessage.toMap());

    // Update last message in exchange chat
    await _firestore.collection('chats').doc(exchangeId).set({
      'lastMessage': message,
      'lastMessageTime': Timestamp.fromDate(chatMessage.timestamp),
      'participants': [currentUser.uid, receiverId],
    }, SetOptions(merge: true));
  }

  /// Get messages stream for an exchange
  Stream<List<ChatMessageModel>> getMessages(String exchangeId) {
    return _firestore
        .collection('chats')
        .doc(exchangeId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ChatMessageModel.fromMap(doc.data()))
          .toList();
    });
  }

  /// Mark messages as read
  Future<void> markAsRead(String exchangeId, List<String> messageIds) async {
    final batch = _firestore.batch();

    for (final messageId in messageIds) {
      batch.update(
        _firestore
            .collection('chats')
            .doc(exchangeId)
            .collection('messages')
            .doc(messageId),
        {'isRead': true},
      );
    }

    await batch.commit();
  }

  /// Get unread message count
  Future<int> getUnreadCount(String exchangeId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return 0;

    final snapshot = await _firestore
        .collection('chats')
        .doc(exchangeId)
        .collection('messages')
        .where('receiverId', isEqualTo: currentUser.uid)
        .where('isRead', isEqualTo: false)
        .get();

    return snapshot.docs.length;
  }
}

/// Service for reporting abuse and banning users
class ModerationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Uuid _uuid = const Uuid();

  /// Submit a report
  Future<String> submitReport({
    required String reportedUserId,
    required String reportedUserName,
    String? exchangeId,
    required ReportReason reason,
    required String description,
    List<String> evidence = const [],
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('Not authenticated');

    // Get current user name from Firestore
    final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
    final userName = userDoc.data()?['fullName'] ?? 'Unknown';

    final report = ReportModel(
      id: _uuid.v4(),
      reporterId: currentUser.uid,
      reporterName: userName,
      reportedUserId: reportedUserId,
      reportedUserName: reportedUserName,
      exchangeId: exchangeId,
      reason: reason,
      description: description,
      createdAt: DateTime.now(),
      evidence: evidence,
    );

    await _firestore.collection('reports').doc(report.id).set(report.toMap());

    return report.id;
  }

  /// Check if user is banned
  Future<UserBanModel?> checkUserBan(String userId) async {
    final snapshot = await _firestore
        .collection('bans')
        .where('userId', isEqualTo: userId)
        .orderBy('bannedAt', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;

    final ban = UserBanModel.fromMap(snapshot.docs.first.data());
    return ban.isActive ? ban : null;
  }

  /// Ban a user (admin function)
  Future<void> banUser({
    required String userId,
    required String reason,
    required Duration? duration,
    bool isPermanent = false,
    String? reportId,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('Not authenticated');

    final ban = UserBanModel(
      id: _uuid.v4(),
      userId: userId,
      bannedBy: currentUser.uid,
      reason: reason,
      bannedAt: DateTime.now(),
      expiresAt: duration != null ? DateTime.now().add(duration) : null,
      isPermanent: isPermanent,
      reportId: reportId,
    );

    await _firestore.collection('bans').doc(ban.id).set(ban.toMap());

    // Update user document
    await _firestore.collection('users').doc(userId).update({
      'isBanned': true,
      'bannedUntil': ban.expiresAt,
    });

    // If related to a report, update report status
    if (reportId != null) {
      await _firestore.collection('reports').doc(reportId).update({
        'status': ReportStatus.resolved.name,
        'reviewedBy': currentUser.uid,
        'reviewedAt': Timestamp.fromDate(DateTime.now()),
        'adminNotes': 'User banned: $reason',
      });
    }
  }

  /// Unban a user (admin function)
  Future<void> unbanUser(String userId) async {
    await _firestore.collection('users').doc(userId).update({
      'isBanned': false,
      'bannedUntil': null,
    });
  }

  /// Get all reports (admin function)
  Stream<List<ReportModel>> getReports({ReportStatus? status}) {
    Query query = _firestore.collection('reports').orderBy('createdAt', descending: true);

    if (status != null) {
      query = query.where('status', isEqualTo: status.name);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => ReportModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    });
  }
}

/// Service for skill verification
class VerificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Uuid _uuid = const Uuid();

  /// Checks if current user has reviewer or admin custom claim
  Future<bool> isReviewer({bool forceRefresh = false}) async {
    final user = _auth.currentUser;
    if (user == null) return false;
    final idTokenResult = await user.getIdTokenResult(forceRefresh);
    final claims = idTokenResult.claims;
    if (claims == null) return false;
    return (claims['reviewer'] == true) || (claims['admin'] == true);
  }

  /// Check if a user is eligible for skill verification via completed Learning Plan
  Future<bool> checkVerificationEligibility(String userId, String skill) async {
    try {
      final snapshot = await _firestore
          .collection('learning_plans')
          .where('learnerId', isEqualTo: userId)
          .where('skillName', isEqualTo: skill)
          .where('status', isEqualTo: 'completed')
          .limit(1)
          .get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Request skill verification
  Future<String> requestVerification({
    required String skill,
    required VerificationType type,
    String? certificateUrl,
    String? learningPlanId,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('Not authenticated');

    final verification = SkillVerificationModel(
      id: _uuid.v4(),
      userId: currentUser.uid,
      skill: skill,
      type: type,
      status: VerificationStatus.pending,
      requestedAt: DateTime.now(),
      certificateUrl: certificateUrl,
      learningPlanId: learningPlanId,
    );

    await _firestore.collection('verifications').doc(verification.id).set(verification.toMap());

    return verification.id;
  }

  /// Get user's verified skills
  Future<List<String>> getVerifiedSkills(String userId) async {
    final snapshot = await _firestore
        .collection('verifications')
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: VerificationStatus.verified.name)
        .get();

    return snapshot.docs
        .map((doc) => SkillVerificationModel.fromMap(doc.data()).skill)
        .toList();
  }

  /// Check if skill is verified
  Future<bool> isSkillVerified(String userId, String skill) async {
    final snapshot = await _firestore
        .collection('verifications')
        .where('userId', isEqualTo: userId)
        .where('skill', isEqualTo: skill)
        .where('status', isEqualTo: VerificationStatus.verified.name)
        .limit(1)
        .get();

    return snapshot.docs.isNotEmpty;
  }

  /// Verify a skill (admin/reviewer function requiring Custom Claims)
  Future<void> verifySkill({
    required String verificationId,
    required bool approve,
    String? notes,
    String? testScore,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('Not authenticated');

    final authorized = await isReviewer();
    if (!authorized) {
      throw Exception('Unauthorized: Only reviewers or administrators can approve or reject skill verifications');
    }

    await _firestore.collection('verifications').doc(verificationId).update({
      'status': approve ? VerificationStatus.verified.name : VerificationStatus.rejected.name,
      'verifiedAt': Timestamp.fromDate(DateTime.now()),
      'verifiedBy': currentUser.uid,
      'notes': notes,
      'testScore': testScore,
    });

    // If approved, update user's verified skills list
    if (approve) {
      final verification = await _firestore
          .collection('verifications')
          .doc(verificationId)
          .get();
      
      final data = verification.data();
      if (data != null) {
        final userId = data['userId'];
        final skill = data['skill'];

        await _firestore.collection('users').doc(userId).update({
          'verifiedSkills': FieldValue.arrayUnion([skill]),
        });
      }
    }
  }

  /// Revokes an existing skill verification (admin/reviewer function)
  Future<void> revokeVerification({
    required String verificationId,
    required String reason,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('Not authenticated');

    final authorized = await isReviewer();
    if (!authorized) {
      throw Exception('Unauthorized: Only reviewers or administrators can revoke skill verifications');
    }

    final docRef = _firestore.collection('verifications').doc(verificationId);
    final docSnap = await docRef.get();
    if (!docSnap.exists || docSnap.data() == null) {
      throw Exception('Verification record not found');
    }

    final verification = SkillVerificationModel.fromMap(docSnap.data()!);

    await docRef.update({
      'status': VerificationStatus.revoked.name,
      'notes': 'Revoked by reviewer: $reason',
      'verifiedBy': currentUser.uid,
      'verifiedAt': Timestamp.fromDate(DateTime.now()),
    });

    // Remove from user's verifiedSkills array
    await _firestore.collection('users').doc(verification.userId).update({
      'verifiedSkills': FieldValue.arrayRemove([verification.skill]),
    });
  }
}

/// Service for notifications and reminders
class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  /// Schedule a reminder for an exchange
  Future<void> scheduleReminder({
    required String userId,
    required String exchangeId,
    required DateTime exchangeTime,
    String? customTitle,
    String? customBody,
  }) async {
    // Schedule reminder 1 hour before
    final reminderTime = exchangeTime.subtract(const Duration(hours: 1));

    final reminder = ReminderModel(
      id: _uuid.v4(),
      userId: userId,
      exchangeId: exchangeId,
      title: customTitle ?? 'Upcoming Skill Exchange',
      body: customBody ?? 'Your exchange session starts in 1 hour!',
      scheduledFor: reminderTime,
    );

    await _firestore.collection('reminders').doc(reminder.id).set(reminder.toMap());
  }

  /// Get pending reminders
  Stream<List<ReminderModel>> getPendingReminders(String userId) {
    return _firestore
        .collection('reminders')
        .where('userId', isEqualTo: userId)
        .where('isSent', isEqualTo: false)
        .where('scheduledFor', isGreaterThan: Timestamp.fromDate(DateTime.now()))
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ReminderModel.fromMap(doc.data()))
          .toList();
    });
  }

  /// Mark reminder as sent
  Future<void> markReminderSent(String reminderId) async {
    await _firestore.collection('reminders').doc(reminderId).update({
      'isSent': true,
      'sentAt': Timestamp.fromDate(DateTime.now()),
    });
  }
}
