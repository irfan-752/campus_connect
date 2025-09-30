class MentorModel {
  final String id;
  final String userId;
  final String name;
  final String email;
  final String department;
  final String designation;
  final String? avatarUrl;
  final List<String> studentIds;
  final String specialization;
  final String experience;
  final bool isAvailable;
  final DateTime createdAt;
  final DateTime updatedAt;

  MentorModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.email,
    required this.department,
    required this.designation,
    this.avatarUrl,
    this.studentIds = const [],
    this.specialization = '',
    this.experience = '',
    this.isAvailable = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MentorModel.fromMap(Map<String, dynamic> map, String id) {
    return MentorModel(
      id: id,
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      department: map['department'] ?? '',
      designation: map['designation'] ?? '',
      avatarUrl: map['avatarUrl'],
      studentIds: List<String>.from(map['studentIds'] ?? []),
      specialization: map['specialization'] ?? '',
      experience: map['experience'] ?? '',
      isAvailable: map['isAvailable'] ?? true,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] ?? 0),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'email': email,
      'department': department,
      'designation': designation,
      'avatarUrl': avatarUrl,
      'studentIds': studentIds,
      'specialization': specialization,
      'experience': experience,
      'isAvailable': isAvailable,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }
}

class MentorSession {
  final String id;
  final String mentorId;
  final String studentId;
  final String title;
  final String description;
  final DateTime scheduledDate;
  final int durationMinutes;
  final String status; // Scheduled, Completed, Cancelled
  final String? feedback;
  final String? notes;
  final DateTime createdAt;

  MentorSession({
    required this.id,
    required this.mentorId,
    required this.studentId,
    required this.title,
    required this.description,
    required this.scheduledDate,
    this.durationMinutes = 60,
    this.status = 'Scheduled',
    this.feedback,
    this.notes,
    required this.createdAt,
  });

  factory MentorSession.fromMap(Map<String, dynamic> map, String id) {
    return MentorSession(
      id: id,
      mentorId: map['mentorId'] ?? '',
      studentId: map['studentId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      scheduledDate: DateTime.fromMillisecondsSinceEpoch(
        map['scheduledDate'] ?? 0,
      ),
      durationMinutes: map['durationMinutes'] ?? 60,
      status: map['status'] ?? 'Scheduled',
      feedback: map['feedback'],
      notes: map['notes'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'mentorId': mentorId,
      'studentId': studentId,
      'title': title,
      'description': description,
      'scheduledDate': scheduledDate.millisecondsSinceEpoch,
      'durationMinutes': durationMinutes,
      'status': status,
      'feedback': feedback,
      'notes': notes,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }
}
