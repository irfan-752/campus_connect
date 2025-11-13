class AlumniModel {
  final String id;
  final String userId;
  final String name;
  final String email;
  final String? avatarUrl;
  final String department;
  final String graduationYear;
  final String? currentCompany;
  final String? currentPosition;
  final String? linkedInUrl;
  final String? bio;
  final List<String> skills;
  final List<String> achievements;
  final bool isVerified;
  final DateTime createdAt;
  final DateTime updatedAt;

  AlumniModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.email,
    this.avatarUrl,
    required this.department,
    required this.graduationYear,
    this.currentCompany,
    this.currentPosition,
    this.linkedInUrl,
    this.bio,
    this.skills = const [],
    this.achievements = const [],
    this.isVerified = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AlumniModel.fromMap(Map<String, dynamic> map, String id) {
    return AlumniModel(
      id: id,
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      avatarUrl: map['avatarUrl'],
      department: map['department'] ?? '',
      graduationYear: map['graduationYear'] ?? '',
      currentCompany: map['currentCompany'],
      currentPosition: map['currentPosition'],
      linkedInUrl: map['linkedInUrl'],
      bio: map['bio'],
      skills: List<String>.from(map['skills'] ?? []),
      achievements: List<String>.from(map['achievements'] ?? []),
      isVerified: map['isVerified'] ?? false,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] ?? 0),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'email': email,
      'avatarUrl': avatarUrl,
      'department': department,
      'graduationYear': graduationYear,
      'currentCompany': currentCompany,
      'currentPosition': currentPosition,
      'linkedInUrl': linkedInUrl,
      'bio': bio,
      'skills': skills,
      'achievements': achievements,
      'isVerified': isVerified,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }
}

