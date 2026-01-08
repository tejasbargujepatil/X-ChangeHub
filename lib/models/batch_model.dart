enum BatchStatus {
  open,      // Accepting enrollments
  ongoing,   // Started but still accepting
  closed,    // No longer accepting enrollments
  completed, // Finished
}

enum ScheduleType {
  daily,
  weekdays,  // Mon-Fri
  weekends,  // Sat-Sun
  custom,    // Specific days
}

class BatchModel {
  final String id;
  final String tutorId;
  final String tutorName;
  final String? tutorImageUrl;
  final String skillToTeach;
  final String title;
  final String description;
  final int maxStudents;
  final int currentEnrollments;
  final List<String> enrolledStudentIds;
  final DateTime startDate;
  final DateTime endDate;
  final String timeSlot; // e.g., "9:00 PM - 10:00 PM"
  final ScheduleType scheduleType;
  final List<int>? customDays; // For custom schedule (1=Mon, 7=Sun)
  final String? meetingLink;
  final BatchStatus status;
  final DateTime createdAt;
  final Map<String, dynamic>? metadata; // For additional info
  
  BatchModel({
    required this.id,
    required this.tutorId,
    required this.tutorName,
    this.tutorImageUrl,
    required this.skillToTeach,
    required this.title,
    required this.description,
    this.maxStudents = 20,
    this.currentEnrollments = 0,
    this.enrolledStudentIds = const [],
    required this.startDate,
    required this.endDate,
    required this.timeSlot,
    this.scheduleType = ScheduleType.daily,
    this.customDays,
    this.meetingLink,
    this.status = BatchStatus.open,
    required this.createdAt,
    this.metadata,
  });

  bool get isFull => currentEnrollments >= maxStudents;
  bool get isAcceptingEnrollments => 
      status == BatchStatus.open || status == BatchStatus.ongoing;
  
  int get availableSeats => maxStudents - currentEnrollments;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tutorId': tutorId,
      'tutorName': tutorName,
      'tutorImageUrl': tutorImageUrl,
      'skillToTeach': skillToTeach,
      'title': title,
      'description': description,
      'maxStudents': maxStudents,
      'currentEnrollments': currentEnrollments,
      'enrolledStudentIds': enrolledStudentIds,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'timeSlot': timeSlot,
      'scheduleType': scheduleType.name,
      'customDays': customDays,
      'meetingLink': meetingLink,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'metadata': metadata,
    };
  }

  factory BatchModel.fromMap(Map<String, dynamic> map) {
    return BatchModel(
      id: map['id'] ?? '',
      tutorId: map['tutorId'] ?? '',
      tutorName: map['tutorName'] ?? '',
      tutorImageUrl: map['tutorImageUrl'],
      skillToTeach: map['skillToTeach'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      maxStudents: map['maxStudents'] ?? 20,
      currentEnrollments: map['currentEnrollments'] ?? 0,
      enrolledStudentIds: List<String>.from(map['enrolledStudentIds'] ?? []),
      startDate: DateTime.parse(map['startDate']),
      endDate: DateTime.parse(map['endDate']),
      timeSlot: map['timeSlot'] ?? '',
      scheduleType: ScheduleType.values.firstWhere(
        (e) => e.name == map['scheduleType'],
        orElse: () => ScheduleType.daily,
      ),
      customDays: map['customDays'] != null 
          ? List<int>.from(map['customDays']) 
          : null,
      meetingLink: map['meetingLink'],
      status: BatchStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => BatchStatus.open,
      ),
      createdAt: DateTime.parse(map['createdAt']),
      metadata: map['metadata'],
    );
  }

  BatchModel copyWith({
    String? id,
    String? tutorId,
    String? tutorName,
    String? tutorImageUrl,
    String? skillToTeach,
    String? title,
    String? description,
    int? maxStudents,
    int? currentEnrollments,
    List<String>? enrolledStudentIds,
    DateTime? startDate,
    DateTime? endDate,
    String? timeSlot,
    ScheduleType? scheduleType,
    List<int>? customDays,
    String? meetingLink,
    BatchStatus? status,
    DateTime? createdAt,
    Map<String, dynamic>? metadata,
  }) {
    return BatchModel(
      id: id ?? this.id,
      tutorId: tutorId ?? this.tutorId,
      tutorName: tutorName ?? this.tutorName,
      tutorImageUrl: tutorImageUrl ?? this.tutorImageUrl,
      skillToTeach: skillToTeach ?? this.skillToTeach,
      title: title ?? this.title,
      description: description ?? this.description,
      maxStudents: maxStudents ?? this.maxStudents,
      currentEnrollments: currentEnrollments ?? this.currentEnrollments,
      enrolledStudentIds: enrolledStudentIds ?? this.enrolledStudentIds,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      timeSlot: timeSlot ?? this.timeSlot,
      scheduleType: scheduleType ?? this.scheduleType,
      customDays: customDays ?? this.customDays,
      meetingLink: meetingLink ?? this.meetingLink,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      metadata: metadata ?? this.metadata,
    );
  }
}
