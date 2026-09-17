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
  final String? learningPlanId;
  
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
    this.learningPlanId,
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
      'learningPlanId': learningPlanId,
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
      learningPlanId: map['learningPlanId'],
    );
  }

  SkillExchangeModel copyWith({
    String? id,
    String? requesterId,
    String? requesterName,
    String? requesterImageUrl,
    String? teacherId,
    String? teacherName,
    String? teacherImageUrl,
    String? skillOffered,
    String? skillRequested,
    ExchangeStatus? status,
    String? message,
    DateTime? scheduledTime,
    int? duration,
    String? meetingLink,
    DateTime? createdAt,
    DateTime? completedAt,
    double? requesterRating,
    double? teacherRating,
    String? requesterReview,
    String? teacherReview,
    String? learningPlanId,
  }) {
    return SkillExchangeModel(
      id: id ?? this.id,
      requesterId: requesterId ?? this.requesterId,
      requesterName: requesterName ?? this.requesterName,
      requesterImageUrl: requesterImageUrl ?? this.requesterImageUrl,
      teacherId: teacherId ?? this.teacherId,
      teacherName: teacherName ?? this.teacherName,
      teacherImageUrl: teacherImageUrl ?? this.teacherImageUrl,
      skillOffered: skillOffered ?? this.skillOffered,
      skillRequested: skillRequested ?? this.skillRequested,
      status: status ?? this.status,
      message: message ?? this.message,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      duration: duration ?? this.duration,
      meetingLink: meetingLink ?? this.meetingLink,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      requesterRating: requesterRating ?? this.requesterRating,
      teacherRating: teacherRating ?? this.teacherRating,
      requesterReview: requesterReview ?? this.requesterReview,
      teacherReview: teacherReview ?? this.teacherReview,
      learningPlanId: learningPlanId ?? this.learningPlanId,
    );
  }
}
