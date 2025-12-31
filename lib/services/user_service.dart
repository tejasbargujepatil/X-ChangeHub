import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../models/portfolio_item_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get user by ID
  Future<UserModel?> getUserById(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user: $e');
    }
  }

  // Get current user data
  Future<UserModel?> getCurrentUser() async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return null;
      return getUserById(uid);
    } catch (e) {
      throw Exception('Failed to get current user: $e');
    }
  }

  // Update user profile
  Future<void> updateUserProfile(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.uid).update(user.toMap());
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  // Update skills to teach
  Future<void> updateSkillsToTeach(List<String> skills) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) throw Exception('Not authenticated');

      await _firestore.collection('users').doc(uid).update({
        'skillsToTeach': skills,
      });
    } catch (e) {
      throw Exception('Failed to update skills: $e');
    }
  }

  // Update skills to learn
  Future<void> updateSkillsToLearn(List<String> skills) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) throw Exception('Not authenticated');

      await _firestore.collection('users').doc(uid).update({
        'skillsToLearn': skills,
      });
    } catch (e) {
      throw Exception('Failed to update skills: $e');
    }
  }

  // Add XP points and calculate level
  Future<void> addXP(String uid, int xp, {String? badgeId}) async {
    try {
      final userDoc = await _firestore.collection('users').doc(uid).get();
      final user = UserModel.fromMap(userDoc.data()!);
      
      final newXP = user.xpPoints + xp;
      final newLevel = _calculateLevel(newXP);
      
      final updates = <String, dynamic>{
        'xpPoints': newXP,
        'level': newLevel,
      };

      // Add badge if earned
      if (badgeId != null && !user.badges.contains(badgeId)) {
        updates['badges'] = FieldValue.arrayUnion([badgeId]);
      }

      await _firestore.collection('users').doc(uid).update(updates);
    } catch (e) {
      throw Exception('Failed to add XP: $e');
    }
  }

  // Calculate level from XP
  int _calculateLevel(int xp) {
    // Level = sqrt(XP / 100)
    return sqrt(xp / 100).floor() + 1;
  }

  // Update rating
  Future<void> updateRating(String uid, double newRating) async {
    try {
      final userDoc = await _firestore.collection('users').doc(uid).get();
      final user = UserModel.fromMap(userDoc.data()!);
      
      final totalRatings = user.totalRatings + 1;
      final avgRating = ((user.averageRating * user.totalRatings) + newRating) / totalRatings;

      await _firestore.collection('users').doc(uid).update({
        'averageRating': avgRating,
        'totalRatings': totalRatings,
      });
    } catch (e) {
      throw Exception('Failed to update rating: $e');
    }
  }

  // Increment completed exchanges
  Future<void> incrementCompletedExchanges(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'completedExchanges': FieldValue.increment(1),
      });
    } catch (e) {
      throw Exception('Failed to update exchanges: $e');
    }
  }

  // Increment completed projects
  Future<void> incrementCompletedProjects(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'completedProjects': FieldValue.increment(1),
      });
    } catch (e) {
      throw Exception('Failed to update projects: $e');
    }
  }

  // Search users by skills
  Future<List<UserModel>> searchUsersBySkill(String skill) async {
    try {
      final query = await _firestore
          .collection('users')
          .where('skillsToTeach', arrayContains: skill)
          .limit(50)
          .get();

      return query.docs.map((doc) => UserModel.fromMap(doc.data())).toList();
    } catch (e) {
      throw Exception('Failed to search users: $e');
    }
  }

  // Get leaderboard (top users by XP)
  Future<List<UserModel>> getLeaderboard({int limit = 100}) async {
    try {
      final query = await _firestore
          .collection('users')
          .orderBy('xpPoints', descending: true)
          .limit(limit)
          .get();

      return query.docs.map((doc) => UserModel.fromMap(doc.data())).toList();
    } catch (e) {
      throw Exception('Failed to get leaderboard: $e');
    }
  }

  // Get user's portfolio items
  Future<List<PortfolioItemModel>> getUserPortfolio(String uid) async {
    try {
      final query = await _firestore
          .collection('portfolio')
          .where('userId', isEqualTo: uid)
          .orderBy('completedAt', descending: true)
          .get();

      return query.docs.map((doc) => PortfolioItemModel.fromMap(doc.data())).toList();
    } catch (e) {
      throw Exception('Failed to get portfolio: $e');
    }
  }
}
