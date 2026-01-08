enum ReviewType {
  skillExchange,  // 1:1 sessions
  groupBatch,     // Group sessions
  freelanceWork,  // Freelance projects
}

class ReviewModel {
  final String id;
  final String reviewerId;
  final String reviewerName;
  final String? reviewerImageUrl;
  final String revieweeId; // Person being reviewed (tutor/freelancer)
  final String revieweeName;
  final ReviewType type;
  final String? relatedId; // Exchange/Batch/Project ID
  final int rating; // 1-5 stars
  final String? comment;
  final DateTime createdAt;

  ReviewModel({
    required this.id,
    required this.reviewerId,
    required this.reviewerName,
    this.reviewerImageUrl,
    required this.revieweeId,
    required this.revieweeName,
    required this.type,
    this.relatedId,
    required this.rating,
    this.comment,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'reviewerId': reviewerId,
      'reviewerName': reviewerName,
      'reviewerImageUrl': reviewerImageUrl,
      'revieweeId': revieweeId,
      'revieweeName': revieweeName,
      'type': type.name,
      'relatedId': relatedId,
      'rating': rating,
      'comment': comment,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ReviewModel.fromMap(Map<String, dynamic> map) {
    return ReviewModel(
      id: map['id'] ?? '',
      reviewerId: map['reviewerId'] ?? '',
      reviewerName: map['reviewerName'] ?? '',
      reviewerImageUrl: map['reviewerImageUrl'],
      revieweeId: map['revieweeId'] ?? '',
      revieweeName: map['revieweeName'] ?? '',
      type: ReviewType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => ReviewType.skillExchange,
      ),
      relatedId: map['relatedId'],
      rating: map['rating'] ?? 0,
      comment: map['comment'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}

// Stats for displaying average rating
class ReviewStats {
  final double averageRating;
  final int totalReviews;
  final Map<int, int> ratingCounts; // {5: 10, 4: 5, 3: 2, 2: 1, 1: 0}

  ReviewStats({
    required this.averageRating,
    required this.totalReviews,
    required this.ratingCounts,
  });
}
