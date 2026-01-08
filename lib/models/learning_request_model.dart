enum LearningRequestStatus {
  open,      // Available for tutors to accept
  accepted,  // A tutor has accepted
  completed, // Exchange completed
  cancelled, // Learner cancelled
}

class LearningRequestModel {
  final String id;
  final String learnerId;
  final String learnerName;
  final String? learnerImageUrl;
  final String skillRequested;
  final String? skillOffered; // Can be null for free exchanges
  final String? message;
  final List<String>? preferredTimeSlots; // Optional time preferences
  final DateTime? preferredDate; // Specific date preference
  final String? preferredTime; // Specific time preference (e.g., "9:00 PM")
  final int? sessionDuration; // Duration in minutes
  final LearningRequestStatus status;
  final DateTime createdAt;
  
  // When accepted
  final String? acceptedByTutorId;
  final String? acceptedByTutorName;
  final DateTime? acceptedAt;
  final String? exchangeId; // Link to created exchange
  
  LearningRequestModel({
    required this.id,
    required this.learnerId,
    required this.learnerName,
    this.learnerImageUrl,
    required this.skillRequested,
    this.skillOffered,
    this.message,
    this.preferredTimeSlots,
    this.preferredDate,
    this.preferredTime,
    this.sessionDuration,
    this.status = LearningRequestStatus.open,
    required this.createdAt,
    this.acceptedByTutorId,
    this.acceptedByTutorName,
    this.acceptedAt,
    this.exchangeId,
  });

  bool get isOpen => status == LearningRequestStatus.open;
  bool get isFreeExchange => skillOffered == null || skillOffered == 'Free Exchange';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'learnerId': learnerId,
      'learnerName': learnerName,
      'learnerImageUrl': learnerImageUrl,
      'skillRequested': skillRequested,
      'skillOffered': skillOffered,
      'message': message,
      'preferredTimeSlots': preferredTimeSlots,
      'preferredDate': preferredDate?.toIso8601String(),
      'preferredTime': preferredTime,
      'sessionDuration': sessionDuration,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'acceptedByTutorId': acceptedByTutorId,
      'acceptedByTutorName': acceptedByTutorName,
      'acceptedAt': acceptedAt?.toIso8601String(),
      'exchangeId': exchangeId,
    };
  }

  factory LearningRequestModel.fromMap(Map<String, dynamic> map) {
    return LearningRequestModel(
      id: map['id'] ?? '',
      learnerId: map['learnerId'] ?? '',
      learnerName: map['learnerName'] ?? '',
      learnerImageUrl: map['learnerImageUrl'],
      skillRequested: map['skillRequested'] ?? '',
      skillOffered: map['skillOffered'],
      message: map['message'],
      preferredTimeSlots: map['preferredTimeSlots'] != null
          ? List<String>.from(map['preferredTimeSlots'])
          : null,
      preferredDate: map['preferredDate'] != null
          ? DateTime.parse(map['preferredDate'])
          : null,
      preferredTime: map['preferredTime'],
      sessionDuration: map['sessionDuration'],
      status: LearningRequestStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => LearningRequestStatus.open,
      ),
      createdAt: DateTime.parse(map['createdAt']),
      acceptedByTutorId: map['acceptedByTutorId'],
      acceptedByTutorName: map['acceptedByTutorName'],
      acceptedAt: map['acceptedAt'] != null
          ? DateTime.parse(map['acceptedAt'])
          : null,
      exchangeId: map['exchangeId'],
    );
  }

  LearningRequestModel copyWith({
    String? id,
    String? learnerId,
    String? learnerName,
    String? learnerImageUrl,
    String? skillRequested,
    String? skillOffered,
    String? message,
    List<String>? preferredTimeSlots,
    LearningRequestStatus? status,
    DateTime? createdAt,
    String? acceptedByTutorId,
    String? acceptedByTutorName,
    DateTime? acceptedAt,
    String? exchangeId,
  }) {
    return LearningRequestModel(
      id: id ?? this.id,
      learnerId: learnerId ?? this.learnerId,
      learnerName: learnerName ?? this.learnerName,
      learnerImageUrl: learnerImageUrl ?? this.learnerImageUrl,
      skillRequested: skillRequested ?? this.skillRequested,
      skillOffered: skillOffered ?? this.skillOffered,
      message: message ?? this.message,
      preferredTimeSlots: preferredTimeSlots ?? this.preferredTimeSlots,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      acceptedByTutorId: acceptedByTutorId ?? this.acceptedByTutorId,
      acceptedByTutorName: acceptedByTutorName ?? this.acceptedByTutorName,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      exchangeId: exchangeId ?? this.exchangeId,
    );
  }
}
