import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum NotificationType {
  exchangeRejected,
  exchangeAccepted,
  exchangeCompleted,
  newExchangeRequest,
  general,
}

class NotificationModel {
  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String message;
  final DateTime createdAt;
  final bool isRead;
  final Map<String, dynamic>? data;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    required this.createdAt,
    this.isRead = false,
    this.data,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'type': type.name,
      'title': title,
      'message': message,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
      'data': data,
    };
  }

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => NotificationType.general,
      ),
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      createdAt: DateTime.parse(map['createdAt']),
      isRead: map['isRead'] ?? false,
      data: map['data'],
    );
  }
}

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Create a notification
  Future<void> createNotification({
    required String userId,
    required NotificationType type,
    required String title,
    required String message,
    Map<String, dynamic>? data,
  }) async {
    try {
      final notification = NotificationModel(
        id: _firestore.collection('notifications').doc().id,
        userId: userId,
        type: type,
        title: title,
        message: message,
        createdAt: DateTime.now(),
        data: data,
      );

      await _firestore
          .collection('notifications')
          .doc(notification.id)
          .set(notification.toMap());
    } catch (e) {
      throw Exception('Failed to create notification: $e');
    }
  }

  // Get notifications for current user
  Stream<List<NotificationModel>> getNotifications() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value([]);

    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationModel.fromMap(doc.data()))
            .toList());
  }

  // Get unread count
  Stream<int> getUnreadCount() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value(0);

    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: uid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      throw Exception('Failed to mark notification as read: $e');
    }
  }

  // Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return;

      final unreadNotifications = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: uid)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (var doc in unreadNotifications.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to mark all as read: $e');
    }
  }

  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();
    } catch (e) {
      throw Exception('Failed to delete notification: $e');
    }
  }

  // Send exchange rejection notification
  Future<void> sendExchangeRejectionNotification({
    required String learnerId,
    required String teacherName,
    required String skillRequested,
  }) async {
    await createNotification(
      userId: learnerId,
      type: NotificationType.exchangeRejected,
      title: 'Exchange Request Rejected',
      message: '$teacherName has declined your request to learn $skillRequested. You can apply for another exchange!',
      data: {
        'teacherName': teacherName,
        'skillRequested': skillRequested,
      },
    );
  }

  // Send exchange acceptance notification
  Future<void> sendExchangeAcceptanceNotification({
    required String learnerId,
    required String teacherName,
    required String skillRequested,
    required DateTime scheduledTime,
  }) async {
    await createNotification(
      userId: learnerId,
      type: NotificationType.exchangeAccepted,
      title: 'Exchange Request Accepted! 🎉',
      message: '$teacherName has accepted your request! Your exchange is scheduled.',
      data: {
        'teacherName': teacherName,
        'skillRequested': skillRequested,
        'scheduledTime': scheduledTime.toIso8601String(),
      },
    );
  }

  // Send new exchange request notification
  Future<void> sendNewExchangeRequestNotification({
    required String teacherId,
    required String learnerName,
    required String skillRequested,
    required String? skillOffered,
  }) async {
    await createNotification(
      userId: teacherId,
      type: NotificationType.newExchangeRequest,
      title: 'New Exchange Request',
      message: skillOffered != null && skillOffered != 'Free Exchange'
          ? '$learnerName wants to learn $skillRequested and will teach $skillOffered'
          : '$learnerName wants to learn $skillRequested (Free Exchange)',
      data: {
        'learnerName': learnerName,
        'skillRequested': skillRequested,
        'skillOffered': skillOffered,
      },
    );
  }
}
