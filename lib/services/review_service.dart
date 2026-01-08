import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../models/review_model.dart';
import '../models/user_model.dart';
import 'user_service.dart';
import 'notification_service.dart';

class ReviewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserService _userService = UserService();
  final NotificationService _notificationService = NotificationService();
  final Uuid _uuid = const Uuid();

  // Submit a review
  Future<void> submitReview({
    required String revieweeId,
    required ReviewType type,
    required int rating,
    String? comment,
    String? relatedId,
  }) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) throw Exception('Not authenticated');

      final reviewer = await _userService.getUserById(uid);
      final reviewee = await _userService.getUserById(revieweeId);

      if (reviewer == null || reviewee == null) {
        throw Exception('User not found');
      }

      final review = ReviewModel(
        id: _uuid.v4(),
        reviewerId: uid,
        reviewerName: reviewer.fullName,
        reviewerImageUrl: reviewer.profileImageUrl,
        revieweeId: revieweeId,
        revieweeName: reviewee.fullName,
        type: type,
        relatedId: relatedId,
        rating: rating,
        comment: comment,
        createdAt: DateTime.now(),
      );

      await _firestore.collection('reviews').doc(review.id).set(review.toMap());

      // Update reviewee's average rating
      await _updateUserRating(revieweeId);

      // Send notification
      await _notificationService.createNotification(
        userId: revieweeId,
        type: NotificationType.other,
        title: 'New Review Received!',
        message: '${reviewer.fullName} left you a $rating-star review!',
        data: {
          'reviewId': review.id,
          'rating': rating.toString(),
        },
      );
    } catch (e) {
      throw Exception('Failed to submit review: $e');
    }
  }

  // Get reviews for a user
  Stream<List<ReviewModel>> getUserReviews(String userId) {
    return _firestore
        .collection('reviews')
        .where('revieweeId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ReviewModel.fromMap(doc.data()))
            .toList());
  }

  // Get review stats for a user
  Future<ReviewStats> getUserReviewStats(String userId) async {
    try {
      final reviews = await _firestore
          .collection('reviews')
          .where('revieweeId', isEqualTo: userId)
          .get();

      if (reviews.docs.isEmpty) {
        return ReviewStats(
          averageRating: 0.0,
          totalReviews: 0,
          ratingCounts: {5: 0, 4: 0, 3: 0, 2: 0, 1: 0},
        );
      }

      final ratingCounts = <int, int>{5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
      int totalRating = 0;

      for (var doc in reviews.docs) {
        final review = ReviewModel.fromMap(doc.data());
        ratingCounts[review.rating] = (ratingCounts[review.rating] ?? 0) + 1;
        totalRating += review.rating;
      }

      return ReviewStats(
        averageRating: totalRating / reviews.docs.length,
        totalReviews: reviews.docs.length,
        ratingCounts: ratingCounts,
      );
    } catch (e) {
      throw Exception('Failed to get review stats: $e');
    }
  }

  // Check if user can review (hasn't reviewed this item yet)
  Future<bool> canReview({
    required String revieweeId,
    required String relatedId,
  }) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return false;

      final existingReview = await _firestore
          .collection('reviews')
          .where('reviewerId', isEqualTo: uid)
          .where('revieweeId', isEqualTo: revieweeId)
          .where('relatedId', isEqualTo: relatedId)
          .get();

      return existingReview.docs.isEmpty;
    } catch (e) {
      return false;
    }
  }

  // Update user's average rating
  Future<void> _updateUserRating(String userId) async {
    try {
      final stats = await getUserReviewStats(userId);
      await _firestore.collection('users').doc(userId).update({
        'averageRating': stats.averageRating,
        'totalRatings': stats.totalReviews,
      });
    } catch (e) {
      // Silently fail if user update fails
      print('Failed to update user rating: $e');
    }
  }
}
