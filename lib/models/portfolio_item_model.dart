class PortfolioItemModel {
  final String id;
  final String userId;
  final String type; // 'exchange', 'project', 'course', 'certification'
  final String title;
  final String description;
  final List<String> skills;
  final DateTime completedAt;
  final double? rating;
  final String? review;
  final String? imageUrl;
  final String? certificateUrl;
  final Map<String, dynamic>? metadata;
  
  PortfolioItemModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.description,
    required this.skills,
    required this.completedAt,
    this.rating,
    this.review,
    this.imageUrl,
    this.certificateUrl,
    this.metadata,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'type': type,
      'title': title,
      'description': description,
      'skills': skills,
      'completedAt': completedAt.toIso8601String(),
      'rating': rating,
      'review': review,
      'imageUrl': imageUrl,
      'certificateUrl': certificateUrl,
      'metadata': metadata,
    };
  }

  factory PortfolioItemModel.fromMap(Map<String, dynamic> map) {
    return PortfolioItemModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      type: map['type'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      skills: List<String>.from(map['skills'] ?? []),
      completedAt: DateTime.parse(map['completedAt']),
      rating: map['rating']?.toDouble(),
      review: map['review'],
      imageUrl: map['imageUrl'],
      certificateUrl: map['certificateUrl'],
      metadata: map['metadata'] != null ? Map<String, dynamic>.from(map['metadata']) : null,
    );
  }
}
