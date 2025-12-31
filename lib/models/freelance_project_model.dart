enum ProjectStatus {
  open,
  inProgress,
  underReview,
  completed,
  cancelled
}

enum ProjectDifficulty {
  beginner,
  intermediate,
  advanced
}

class FreelanceProjectModel {
  final String id;
  final String clientId;
  final String clientName;
  final String? clientImageUrl;
  final String title;
  final String description;
  final List<String> requiredSkills;
  final ProjectDifficulty difficulty;
  final double budget;
  final int estimatedDuration; // in days
  final ProjectStatus status;
  final String? assignedToId;
  final String? assignedToName;
  final String? assignedToImageUrl;
  final DateTime createdAt;
  final DateTime? deadline;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final List<String> applicantIds;
  final String? deliverableUrl;
  final double? rating;
  final String? review;
  final bool isPaid;
  final double platformFee; // Commission percentage
  
  FreelanceProjectModel({
    required this.id,
    required this.clientId,
    required this.clientName,
    this.clientImageUrl,
    required this.title,
    required this.description,
    required this.requiredSkills,
    this.difficulty = ProjectDifficulty.beginner,
    required this.budget,
    required this.estimatedDuration,
    this.status = ProjectStatus.open,
    this.assignedToId,
    this.assignedToName,
    this.assignedToImageUrl,
    required this.createdAt,
    this.deadline,
    this.startedAt,
    this.completedAt,
    this.applicantIds = const [],
    this.deliverableUrl,
    this.rating,
    this.review,
    this.isPaid = false,
    this.platformFee = 10.0, // 10% default commission
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'clientId': clientId,
      'clientName': clientName,
      'clientImageUrl': clientImageUrl,
      'title': title,
      'description': description,
      'requiredSkills': requiredSkills,
      'difficulty': difficulty.name,
      'budget': budget,
      'estimatedDuration': estimatedDuration,
      'status': status.name,
      'assignedToId': assignedToId,
      'assignedToName': assignedToName,
      'assignedToImageUrl': assignedToImageUrl,
      'createdAt': createdAt.toIso8601String(),
      'deadline': deadline?.toIso8601String(),
      'startedAt': startedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'applicantIds': applicantIds,
      'deliverableUrl': deliverableUrl,
      'rating': rating,
      'review': review,
      'isPaid': isPaid,
      'platformFee': platformFee,
    };
  }

  factory FreelanceProjectModel.fromMap(Map<String, dynamic> map) {
    return FreelanceProjectModel(
      id: map['id'] ?? '',
      clientId: map['clientId'] ?? '',
      clientName: map['clientName'] ?? '',
      clientImageUrl: map['clientImageUrl'],
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      requiredSkills: List<String>.from(map['requiredSkills'] ?? []),
      difficulty: ProjectDifficulty.values.firstWhere(
        (e) => e.name == map['difficulty'],
        orElse: () => ProjectDifficulty.beginner,
      ),
      budget: (map['budget'] ?? 0).toDouble(),
      estimatedDuration: map['estimatedDuration'] ?? 0,
      status: ProjectStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => ProjectStatus.open,
      ),
      assignedToId: map['assignedToId'],
      assignedToName: map['assignedToName'],
      assignedToImageUrl: map['assignedToImageUrl'],
      createdAt: DateTime.parse(map['createdAt']),
      deadline: map['deadline'] != null ? DateTime.parse(map['deadline']) : null,
      startedAt: map['startedAt'] != null ? DateTime.parse(map['startedAt']) : null,
      completedAt: map['completedAt'] != null ? DateTime.parse(map['completedAt']) : null,
      applicantIds: List<String>.from(map['applicantIds'] ?? []),
      deliverableUrl: map['deliverableUrl'],
      rating: map['rating']?.toDouble(),
      review: map['review'],
      isPaid: map['isPaid'] ?? false,
      platformFee: (map['platformFee'] ?? 10.0).toDouble(),
    );
  }

  FreelanceProjectModel copyWith({
    String? id,
    String? clientId,
    String? clientName,
    String? clientImageUrl,
    String? title,
    String? description,
    List<String>? requiredSkills,
    ProjectDifficulty? difficulty,
    double? budget,
    int? estimatedDuration,
    ProjectStatus? status,
    String? assignedToId,
    String? assignedToName,
    String? assignedToImageUrl,
    DateTime? createdAt,
    DateTime? deadline,
    DateTime? startedAt,
    DateTime? completedAt,
    List<String>? applicantIds,
    String? deliverableUrl,
    double? rating,
    String? review,
    bool? isPaid,
    double? platformFee,
  }) {
    return FreelanceProjectModel(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      clientImageUrl: clientImageUrl ?? this.clientImageUrl,
      title: title ?? this.title,
      description: description ?? this.description,
      requiredSkills: requiredSkills ?? this.requiredSkills,
      difficulty: difficulty ?? this.difficulty,
      budget: budget ?? this.budget,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      status: status ?? this.status,
      assignedToId: assignedToId ?? this.assignedToId,
      assignedToName: assignedToName ?? this.assignedToName,
      assignedToImageUrl: assignedToImageUrl ?? this.assignedToImageUrl,
      createdAt: createdAt ?? this.createdAt,
      deadline: deadline ?? this.deadline,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      applicantIds: applicantIds ?? this.applicantIds,
      deliverableUrl: deliverableUrl ?? this.deliverableUrl,
      rating: rating ?? this.rating,
      review: review ?? this.review,
      isPaid: isPaid ?? this.isPaid,
      platformFee: platformFee ?? this.platformFee,
    );
  }
}
