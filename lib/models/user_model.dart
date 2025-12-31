class UserModel {
  final String uid;
  final String email;
  final String fullName;
  final String username;
  final String? profileImageUrl;
  final String? bio;
  final List<String> skillsToTeach;
  final List<String> skillsToLearn;
  final int xpPoints;
  final int level;
  final List<String> badges;
  final double averageRating;
  final int totalRatings;
  final int completedExchanges;
  final int completedProjects;
  final DateTime createdAt;
  final DateTime lastActive;
  final bool isVerified;
  
  UserModel({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.username,
    this.profileImageUrl,
    this.bio,
    this.skillsToTeach = const [],
    this.skillsToLearn = const [],
    this.xpPoints = 0,
    this.level = 1,
    this.badges = const [],
    this.averageRating = 0.0,
    this.totalRatings = 0,
    this.completedExchanges = 0,
    this.completedProjects = 0,
    required this.createdAt,
    required this.lastActive,
    this.isVerified = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'fullName': fullName,
      'username': username,
      'profileImageUrl': profileImageUrl,
      'bio': bio,
      'skillsToTeach': skillsToTeach,
      'skillsToLearn': skillsToLearn,
      'xpPoints': xpPoints,
      'level': level,
      'badges': badges,
      'averageRating': averageRating,
      'totalRatings': totalRatings,
      'completedExchanges': completedExchanges,
      'completedProjects': completedProjects,
      'createdAt': createdAt.toIso8601String(),
      'lastActive': lastActive.toIso8601String(),
      'isVerified': isVerified,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      fullName: map['fullName'] ?? '',
      username: map['username'] ?? '',
      profileImageUrl: map['profileImageUrl'],
      bio: map['bio'],
      skillsToTeach: List<String>.from(map['skillsToTeach'] ?? []),
      skillsToLearn: List<String>.from(map['skillsToLearn'] ?? []),
      xpPoints: map['xpPoints'] ?? 0,
      level: map['level'] ?? 1,
      badges: List<String>.from(map['badges'] ?? []),
      averageRating: (map['averageRating'] ?? 0.0).toDouble(),
      totalRatings: map['totalRatings'] ?? 0,
      completedExchanges: map['completedExchanges'] ?? 0,
      completedProjects: map['completedProjects'] ?? 0,
      createdAt: DateTime.parse(map['createdAt']),
      lastActive: DateTime.parse(map['lastActive']),
      isVerified: map['isVerified'] ?? false,
    );
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? fullName,
    String? username,
    String? profileImageUrl,
    String? bio,
    List<String>? skillsToTeach,
    List<String>? skillsToLearn,
    int? xpPoints,
    int? level,
    List<String>? badges,
    double? averageRating,
    int? totalRatings,
    int? completedExchanges,
    int? completedProjects,
    DateTime? createdAt,
    DateTime? lastActive,
    bool? isVerified,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      username: username ?? this.username,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      bio: bio ?? this.bio,
      skillsToTeach: skillsToTeach ?? this.skillsToTeach,
      skillsToLearn: skillsToLearn ?? this.skillsToLearn,
      xpPoints: xpPoints ?? this.xpPoints,
      level: level ?? this.level,
      badges: badges ?? this.badges,
      averageRating: averageRating ?? this.averageRating,
      totalRatings: totalRatings ?? this.totalRatings,
      completedExchanges: completedExchanges ?? this.completedExchanges,
      completedProjects: completedProjects ?? this.completedProjects,
      createdAt: createdAt ?? this.createdAt,
      lastActive: lastActive ?? this.lastActive,
      isVerified: isVerified ?? this.isVerified,
    );
  }
}
