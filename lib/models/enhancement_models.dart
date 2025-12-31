import 'package:cloud_firestore/cloud_firestore.dart';

/// Message model for in-app chat
class ChatMessageModel {
  final String id;
  final String exchangeId;
  final String senderId;
  final String senderName;
  final String? senderImageUrl;
  final String receiverId;
  final String message;
  final DateTime timestamp;
  final bool isRead;
  final MessageType type;
  final String? mediaUrl;

  ChatMessageModel({
    required this.id,
    required this.exchangeId,
    required this.senderId,
    required this.senderName,
    this.senderImageUrl,
    required this.receiverId,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    this.type = MessageType.text,
    this.mediaUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'exchangeId': exchangeId,
      'senderId': senderId,
      'senderName': senderName,
      'senderImageUrl': senderImageUrl,
      'receiverId': receiverId,
      'message': message,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
      'type': type.name,
      'mediaUrl': mediaUrl,
    };
  }

  factory ChatMessageModel.fromMap(Map<String, dynamic> map) {
    return ChatMessageModel(
      id: map['id'] ?? '',
      exchangeId: map['exchangeId'] ?? '',
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      senderImageUrl: map['senderImageUrl'],
      receiverId: map['receiverId'] ?? '',
      message: map['message'] ?? '',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      isRead: map['isRead'] ?? false,
      type: MessageType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => MessageType.text,
      ),
      mediaUrl: map['mediaUrl'],
    );
  }
}

enum MessageType {
  text,
  image,
  file,
  system,
}

/// Report model for abuse reporting
class ReportModel {
  final String id;
  final String reporterId;
  final String reporterName;
  final String reportedUserId;
  final String reportedUserName;
  final String? exchangeId;
  final ReportReason reason;
  final String description;
  final DateTime createdAt;
  final ReportStatus status;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final String? adminNotes;
  final List<String> evidence; // URLs to screenshots, etc.

  ReportModel({
    required this.id,
    required this.reporterId,
    required this.reporterName,
    required this.reportedUserId,
    required this.reportedUserName,
    this.exchangeId,
    required this.reason,
    required this.description,
    required this.createdAt,
    this.status = ReportStatus.pending,
    this.reviewedBy,
    this.reviewedAt,
    this.adminNotes,
    this.evidence = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'reporterId': reporterId,
      'reporterName': reporterName,
      'reportedUserId': reportedUserId,
      'reportedUserName': reportedUserName,
      'exchangeId': exchangeId,
      'reason': reason.name,
      'description': description,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status.name,
      'reviewedBy': reviewedBy,
      'reviewedAt': reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
      'adminNotes': adminNotes,
      'evidence': evidence,
    };
  }

  factory ReportModel.fromMap(Map<String, dynamic> map) {
    return ReportModel(
      id: map['id'] ?? '',
      reporterId: map['reporterId'] ?? '',
      reporterName: map['reporterName'] ?? '',
      reportedUserId: map['reportedUserId'] ?? '',
      reportedUserName: map['reportedUserName'] ?? '',
      exchangeId: map['exchangeId'],
      reason: ReportReason.values.firstWhere(
        (e) => e.name == map['reason'],
        orElse: () => ReportReason.other,
      ),
      description: map['description'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      status: ReportStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => ReportStatus.pending,
      ),
      reviewedBy: map['reviewedBy'],
      reviewedAt: map['reviewedAt'] != null
          ? (map['reviewedAt'] as Timestamp).toDate()
          : null,
      adminNotes: map['adminNotes'],
      evidence: List<String>.from(map['evidence'] ?? []),
    );
  }
}

enum ReportReason {
  harassment,
  inappropriateContent,
  spam,
  noShow,
  poorQuality,
  fraud,
  other,
}

enum ReportStatus {
  pending,
  underReview,
  resolved,
  dismissed,
}

/// Ban model for user suspensions
class UserBanModel {
  final String id;
  final String userId;
  final String bannedBy;
  final String reason;
  final DateTime bannedAt;
  final DateTime? expiresAt;
  final bool isPermanent;
  final String? reportId;

  UserBanModel({
    required this.id,
    required this.userId,
    required this.bannedBy,
    required this.reason,
    required this.bannedAt,
    this.expiresAt,
    this.isPermanent = false,
    this.reportId,
  });

  bool get isActive {
    if (isPermanent) return true;
    if (expiresAt == null) return false;
    return DateTime.now().isBefore(expiresAt!);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'bannedBy': bannedBy,
      'reason': reason,
      'bannedAt': Timestamp.fromDate(bannedAt),
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
      'isPermanent': isPermanent,
      'reportId': reportId,
    };
  }

  factory UserBanModel.fromMap(Map<String, dynamic> map) {
    return UserBanModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      bannedBy: map['bannedBy'] ?? '',
      reason: map['reason'] ?? '',
      bannedAt: (map['bannedAt'] as Timestamp).toDate(),
      expiresAt: map['expiresAt'] != null
          ? (map['expiresAt'] as Timestamp).toDate()
          : null,
      isPermanent: map['isPermanent'] ?? false,
      reportId: map['reportId'],
    );
  }
}

/// Skill verification model
class SkillVerificationModel {
  final String id;
  final String userId;
  final String skill;
  final VerificationType type;
  final VerificationStatus status;
  final DateTime requestedAt;
  final DateTime? verifiedAt;
  final String? certificateUrl;
  final String? testScore;
  final String? verifiedBy;
  final String? notes;

  SkillVerificationModel({
    required this.id,
    required this.userId,
    required this.skill,
    required this.type,
    this.status = VerificationStatus.pending,
    required this.requestedAt,
    this.verifiedAt,
    this.certificateUrl,
    this.testScore,
    this.verifiedBy,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'skill': skill,
      'type': type.name,
      'status': status.name,
      'requestedAt': Timestamp.fromDate(requestedAt),
      'verifiedAt': verifiedAt != null ? Timestamp.fromDate(verifiedAt!) : null,
      'certificateUrl': certificateUrl,
      'testScore': testScore,
      'verifiedBy': verifiedBy,
      'notes': notes,
    };
  }

  factory SkillVerificationModel.fromMap(Map<String, dynamic> map) {
    return SkillVerificationModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      skill: map['skill'] ?? '',
      type: VerificationType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => VerificationType.certificate,
      ),
      status: VerificationStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => VerificationStatus.pending,
      ),
      requestedAt: (map['requestedAt'] as Timestamp).toDate(),
      verifiedAt: map['verifiedAt'] != null
          ? (map['verifiedAt'] as Timestamp).toDate()
          : null,
      certificateUrl: map['certificateUrl'],
      testScore: map['testScore'],
      verifiedBy: map['verifiedBy'],
      notes: map['notes'],
    );
  }
}

enum VerificationType {
  certificate,
  test,
  portfolio,
  endorsement,
}

enum VerificationStatus {
  pending,
  underReview,
  verified,
  rejected,
}

/// Notification reminder model
class ReminderModel {
  final String id;
  final String userId;
  final String exchangeId;
  final String title;
  final String body;
  final DateTime scheduledFor;
  final bool isSent;
  final DateTime? sentAt;

  ReminderModel({
    required this.id,
    required this.userId,
    required this.exchangeId,
    required this.title,
    required this.body,
    required this.scheduledFor,
    this.isSent = false,
    this.sentAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'exchangeId': exchangeId,
      'title': title,
      'body': body,
      'scheduledFor': Timestamp.fromDate(scheduledFor),
      'isSent': isSent,
      'sentAt': sentAt != null ? Timestamp.fromDate(sentAt!) : null,
    };
  }

  factory ReminderModel.fromMap(Map<String, dynamic> map) {
    return ReminderModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      exchangeId: map['exchangeId'] ?? '',
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      scheduledFor: (map['scheduledFor'] as Timestamp).toDate(),
      isSent: map['isSent'] ?? false,
      sentAt: map['sentAt'] != null ? (map['sentAt'] as Timestamp).toDate() : null,
    );
  }
}
