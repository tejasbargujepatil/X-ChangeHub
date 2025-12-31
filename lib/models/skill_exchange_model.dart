enum ExchangeStatus {
  pending,
  accepted,
  inProgress,
  completed,
  cancelled,
  rejected
}

class SkillExchangeModel {
  final String id;
  final String requesterId;
  final String requesterName;
  final String? requesterImageUrl;
  final String teacherId;
  final String teacherName;
  final String? teacherImageUrl;
  final String skillOffered; // What requester will teach
  final String skillRequested; // What requester wants to learn
  final ExchangeStatus status;
  final String? message;
  final DateTime? scheduledTime;
  final int? duration; // in minutes
  final String? meetingLink;
  final DateTime createdAt;
  final DateTime? completedAt;
  final double? requesterRating;
  final double? teacherRating;
  final String? requesterReview;
  final String? teacherReview;
  
  SkillExchangeModel({
    required this.id,
    required this.requesterId,
    required this.requesterName,
    this.requesterImageUrl,
    required this.teacherId,
    required this.teacherName,
    this.teacherImageUrl,
    required this.skillOffered,
    required this.skillRequested,
    this.status = ExchangeStatus.pending,
    this.message,
    this.scheduledTime,
    this.duration,
    this.meetingLink,
    required this.createdAt,
    this.completedAt,
    this.requesterRating,
    this.teacherRating,
    this.requesterReview,
    this.teacherReview,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'requesterId': requesterId,
      'requesterName': requesterName,
      'requesterImageUrl': requesterImageUrl,
      'teacherId': teacherId,
      'teacherName': teacherName,
      'teacherImageUrl': teacherImageUrl,
      'skillOffered': skillOffered,
      'skillRequested': skillRequested,
      'status': status.name,
      'message': message,
      'scheduledTime': scheduledTime?.toIso8601String(),
      'duration': duration,
      'meetingLink': meetingLink,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'requesterRating': requesterRating,
      'teacherRating': teacherRating,
      'requesterReview': requesterReview,
      'teacherReview': teacherReview,
    };
  }

  factory SkillExchangeModel.fromMap(Map<String, dynamic> map) {
    return SkillExchangeModel(
      id: map['id'] ?? '',
      requesterId: map['requesterId'] ?? '',
      requesterName: map['requesterName'] ?? '',
      requesterImageUrl: map['requesterImageUrl'],
      teacherId: map['teacherId'] ?? '',
      teacherName: map['teacherName'] ?? '',
      teacherImageUrl: map['teacherImageUrl'],
      skillOffered: map['skillOffered'] ?? '',
      skillRequested: map['skillRequested'] ?? '',
      status: ExchangeStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => ExchangeStatus.pending,
      ),
      message: map['message'],
      scheduledTime: map['scheduledTime'] != null 
          ? DateTime.parse(map['scheduledTime']) 
          : null,
      duration: map['duration'],
      meetingLink: map['meetingLink'],
      createdAt: DateTime.parse(map['createdAt']),
      completedAt: map['completedAt'] != null 
          ? DateTime.parse(map['completedAt']) 
          : null,
      requesterRating: map['requesterRating']?.toDouble(),
      teacherRating: map['teacherRating']?.toDouble(),
      requesterReview: map['requesterReview'],
      teacherReview: map['teacherReview'],
    );
  }
}
