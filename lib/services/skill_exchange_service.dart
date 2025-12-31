import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../models/skill_exchange_model.dart';
import '../models/user_model.dart';
import '../models/portfolio_item_model.dart';
import 'user_service.dart';

class SkillExchangeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserService _userService = UserService();
  final Uuid _uuid = const Uuid();

  // Create exchange request
  Future<SkillExchangeModel> createExchangeRequest({
    required String teacherId,
    required String skillOffered,
    required String skillRequested,
    String? message,
  }) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) throw Exception('Not authenticated');

      final requester = await _userService.getUserById(uid);
      final teacher = await _userService.getUserById(teacherId);

      if (requester == null || teacher == null) {
        throw Exception('User not found');
      }

      final exchange = SkillExchangeModel(
        id: _uuid.v4(),
        requesterId: uid,
        requesterName: requester.fullName,
        requesterImageUrl: requester.profileImageUrl,
        teacherId: teacherId,
        teacherName: teacher.fullName,
        teacherImageUrl: teacher.profileImageUrl,
        skillOffered: skillOffered,
        skillRequested: skillRequested,
        message: message,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('skill_exchanges')
          .doc(exchange.id)
          .set(exchange.toMap());

      return exchange;
    } catch (e) {
      throw Exception('Failed to create exchange request: $e');
    }
  }

  // Get pending requests (as teacher)
  Stream<List<SkillExchangeModel>> getPendingRequests() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value([]);

    return _firestore
        .collection('skill_exchanges')
        .where('teacherId', isEqualTo: uid)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SkillExchangeModel.fromMap(doc.data()))
            .toList());
  }

  // Get my exchange requests (as requester)
  Stream<List<SkillExchangeModel>> getMyRequests() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value([]);

    return _firestore
        .collection('skill_exchanges')
        .where('requesterId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SkillExchangeModel.fromMap(doc.data()))
            .toList());
  }

  // Get all my exchanges (both as teacher and requester)
  Stream<List<SkillExchangeModel>> getAllMyExchanges() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value([]);

    return _firestore
        .collection('skill_exchanges')
        .where('teacherId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .asyncMap((teacherSnapshot) async {
      final teacherExchanges = teacherSnapshot.docs
          .map((doc) => SkillExchangeModel.fromMap(doc.data()))
          .toList();

      final requesterSnapshot = await _firestore
          .collection('skill_exchanges')
          .where('requesterId', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .get();

      final requesterExchanges = requesterSnapshot.docs
          .map((doc) => SkillExchangeModel.fromMap(doc.data()))
          .toList();

      final allExchanges = [...teacherExchanges, ...requesterExchanges];
      allExchanges.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return allExchanges;
    });
  }

  // Accept exchange request
  Future<void> acceptExchangeRequest({
    required String exchangeId,
    required DateTime scheduledTime,
    required int duration,
    String? meetingLink,
  }) async {
    try {
      await _firestore.collection('skill_exchanges').doc(exchangeId).update({
        'status': ExchangeStatus.accepted.name,
        'scheduledTime': scheduledTime.toIso8601String(),
        'duration': duration,
        'meetingLink': meetingLink,
      });
    } catch (e) {
      throw Exception('Failed to accept exchange: $e');
    }
  }

  // Reject exchange request
  Future<void> rejectExchangeRequest(String exchangeId) async {
    try {
      await _firestore.collection('skill_exchanges').doc(exchangeId).update({
        'status': ExchangeStatus.rejected.name,
      });
    } catch (e) {
      throw Exception('Failed to reject exchange: $e');
    }
  }

  // Start exchange (mark as in progress)
  Future<void> startExchange(String exchangeId) async {
    try {
      await _firestore.collection('skill_exchanges').doc(exchangeId).update({
        'status': ExchangeStatus.inProgress.name,
      });
    } catch (e) {
      throw Exception('Failed to start exchange: $e');
    }
  }

  // Complete exchange with ratings
  Future<void> completeExchange({
    required String exchangeId,
    required bool isRequester,
    required double rating,
    String? review,
  }) async {
    try {
      final exchangeDoc = await _firestore
          .collection('skill_exchanges')
          .doc(exchangeId)
          .get();
      
      final exchange = SkillExchangeModel.fromMap(exchangeDoc.data()!);

      final updates = <String, dynamic>{
        'completedAt': DateTime.now().toIso8601String(),
      };

      if (isRequester) {
        updates['requesterRating'] = rating;
        updates['requesterReview'] = review;
        
        // Update teacher's rating
        await _userService.updateRating(exchange.teacherId, rating);
        await _userService.addXP(exchange.teacherId, 50); // 50 XP for teaching
      } else {
        updates['teacherRating'] = rating;
        updates['teacherReview'] = review;
        
        // Update requester's rating
        await _userService.updateRating(exchange.requesterId, rating);
        await _userService.addXP(exchange.requesterId, 30); // 30 XP for learning
      }

      // Mark as completed immediately (don't wait for both ratings)
      updates['status'] = ExchangeStatus.completed.name;
      
      // Increment completed exchanges for both parties
      await _userService.incrementCompletedExchanges(exchange.requesterId);
      await _userService.incrementCompletedExchanges(exchange.teacherId);

      // Add to portfolio for the person who completed
      await _addToPortfolio(exchange, isRequester, rating, review);

      await _firestore.collection('skill_exchanges').doc(exchangeId).update(updates);
    } catch (e) {
      throw Exception('Failed to complete exchange: $e');
    }
  }

  // Add completed exchange to portfolio
  Future<void> _addToPortfolio(
    SkillExchangeModel exchange,
    bool isRequester,
    double rating,
    String? review,
  ) async {
    try {
      final uid = isRequester ? exchange.requesterId : exchange.teacherId;
      final skill = isRequester ? exchange.skillRequested : exchange.skillOffered;
      final otherParty = isRequester ? exchange.teacherName : exchange.requesterName;

      final portfolioItem = PortfolioItemModel(
        id: _uuid.v4(),
        userId: uid,
        type: 'exchange',
        title: 'Skill Exchange: $skill',
        description: isRequester
            ? 'Learned $skill from $otherParty'
            : 'Taught $skill to $otherParty',
        skills: [skill],
        completedAt: DateTime.now(),
        rating: rating,
        review: review,
        metadata: {
          'exchangeId': exchange.id,
          'role': isRequester ? 'learner' : 'teacher',
          'partnerName': otherParty,
        },
      );

      await _firestore
          .collection('portfolio')
          .doc(portfolioItem.id)
          .set(portfolioItem.toMap());
    } catch (e) {
      throw Exception('Failed to add to portfolio: $e');
    }
  }

  // Cancel exchange
  Future<void> cancelExchange(String exchangeId) async {
    try {
      await _firestore.collection('skill_exchanges').doc(exchangeId).update({
        'status': ExchangeStatus.cancelled.name,
      });
    } catch (e) {
      throw Exception('Failed to cancel exchange: $e');
    }
  }

  // Find matching users for skill exchange
  Future<List<UserModel>> findMatchingUsers(String skillToLearn) async {
    try {
      final users = await _userService.searchUsersBySkill(skillToLearn);
      final uid = _auth.currentUser?.uid;
      
      // Filter out current user
      return users.where((user) => user.uid != uid).toList();
    } catch (e) {
      throw Exception('Failed to find matches: $e');
    }
  }

  // Get active exchanges (accepted and in progress)
  Stream<List<SkillExchangeModel>> getActiveExchanges() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value([]);

    return _firestore
        .collection('skill_exchanges')
        .where('status', whereIn: [ExchangeStatus.accepted.name, ExchangeStatus.inProgress.name])
        .orderBy('scheduledTime', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => SkillExchangeModel.fromMap(doc.data()))
          .where((exchange) =>
              exchange.teacherId == uid || exchange.requesterId == uid)
          .toList();
    });
  }

  // Get completed exchanges
  Stream<List<SkillExchangeModel>> getCompletedExchanges() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value([]);

    return _firestore
        .collection('skill_exchanges')
        .where('status', isEqualTo: ExchangeStatus.completed.name)
        .orderBy('completedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => SkillExchangeModel.fromMap(doc.data()))
          .where((exchange) =>
              exchange.teacherId == uid || exchange.requesterId == uid)
          .toList();
    });
  }
}
