import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../models/user_model.dart';
import 'user_service.dart';
import 'notification_service.dart';

enum PaymentStatus {
  pending,
  processing,
  completed,
  failed,
  refunded,
}

enum PaymentMethod {
  mock, // For testing
  upi,
  card,
  wallet,
}

class PaymentModel {
  final String id;
  final String fromUserId;
  final String toUserId;
  final double amount;
  final PaymentStatus status;
  final PaymentMethod method;
  final String? relatedId; // Project/Exchange ID
  final String? relatedType; // 'freelance_project', 'tip', etc.
  final DateTime createdAt;
  final DateTime? completedAt;

  PaymentModel({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.amount,
    required this.status,
    required this.method,
    this.relatedId,
    this.relatedType,
    required this.createdAt,
    this.completedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'amount': amount,
      'status': status.name,
      'method': method.name,
      'relatedId': relatedId,
      'relatedType': relatedType,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  factory PaymentModel.fromMap(Map<String, dynamic> map) {
    return PaymentModel(
      id: map['id'],
      fromUserId: map['fromUserId'],
      toUserId: map['toUserId'],
      amount: map['amount'].toDouble(),
      status: PaymentStatus.values.firstWhere((e) => e.name == map['status']),
      method: PaymentMethod.values.firstWhere((e) => e.name == map['method']),
      relatedId: map['relatedId'],
      relatedType: map['relatedType'],
      createdAt: DateTime.parse(map['createdAt']),
      completedAt:
          map['completedAt'] != null ? DateTime.parse(map['completedAt']) : null,
    );
  }
}

class PaymentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserService _userService = UserService();
  final NotificationService _notificationService = NotificationService();
  final Uuid _uuid = const Uuid();

  // Process payment (MOCK)
  Future<PaymentModel> processPayment({
    required String toUserId,
    required double amount,
    String? relatedId,
    String? relatedType,
    PaymentMethod method = PaymentMethod.mock,
  }) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) throw Exception('Not authenticated');

      final sender = await _userService.getUserById(uid);
      final receiver = await _userService.getUserById(toUserId);

      if (sender == null || receiver == null) {
        throw Exception('User not found');
      }

      final payment = PaymentModel(
        id: _uuid.v4(),
        fromUserId: uid,
        toUserId: toUserId,
        amount: amount,
        status: PaymentStatus.processing,
        method: method,
        relatedId: relatedId,
        relatedType: relatedType,
        createdAt: DateTime.now(),
      );

      // Save payment record
      await _firestore.collection('payments').doc(payment.id).set(payment.toMap());

      // MOCK: Instantly complete payment
      final completedPayment = await _mockProcessPayment(payment);

      // Send notification to receiver
      await _notificationService.createNotification(
        userId: toUserId,
        type: NotificationType.other,
        title: 'Payment Received!',
        message:
            'You received ₹${amount.toStringAsFixed(2)} from ${sender.fullName}',
        data: {
          'paymentId': completedPayment.id,
          'amount': amount.toString(),
        },
      );

      // Send confirmation to sender
      await _notificationService.createNotification(
        userId: uid,
        type: NotificationType.other,
        title: 'Payment Sent!',
        message:
            'Successfully sent ₹${amount.toStringAsFixed(2)} to ${receiver.fullName}',
        data: {
          'paymentId': completedPayment.id,
          'amount': amount.toString(),
        },
      );

      return completedPayment;
    } catch (e) {
      throw Exception('Failed to process payment: $e');
    }
  }

  // MOCK payment processing (simulates instant success)
  Future<PaymentModel> _mockProcessPayment(PaymentModel payment) async {
    // Simulate processing delay
    await Future.delayed(const Duration(seconds: 1));

    final completedPayment = PaymentModel(
      id: payment.id,
      fromUserId: payment.fromUserId,
      toUserId: payment.toUserId,
      amount: payment.amount,
      status: PaymentStatus.completed,
      method: payment.method,
      relatedId: payment.relatedId,
      relatedType: payment.relatedType,
      createdAt: payment.createdAt,
      completedAt: DateTime.now(),
    );

    await _firestore
        .collection('payments')
        .doc(payment.id)
        .update(completedPayment.toMap());

    return completedPayment;
  }

  // Get payment history for current user
  Stream<List<PaymentModel>> getUserPayments() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value([]);

    return _firestore
        .collection('payments')
        .where('toUserId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PaymentModel.fromMap(doc.data()))
            .toList());
  }

  // Get total earnings
  Future<double> getTotalEarnings() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return 0.0;

    final payments = await _firestore
        .collection('payments')
        .where('toUserId', isEqualTo: uid)
        .where('status', isEqualTo: PaymentStatus.completed.name)
        .get();

    double total = 0.0;
    for (var doc in payments.docs) {
      final payment = PaymentModel.fromMap(doc.data());
      total += payment.amount;
    }

    return total;
  }
}
