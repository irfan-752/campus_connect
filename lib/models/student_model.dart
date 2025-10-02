class StudentModel {
  final String id;
  final String userId;
  final String name;
  final String email;
  final String rollNumber;
  final String department;
  final String semester;
  final String? avatarUrl;
  final double attendance;
  final double gpa;
  final int eventsParticipated;
  final List<String> courses;
  final String? mentorId;
  final String? parentEmail;
  final String? phoneNumber;
  final String? address;
  final String? emergencyContact;
  final String? bloodGroup;
  final DateTime createdAt;
  final DateTime updatedAt;

  StudentModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.email,
    required this.rollNumber,
    required this.department,
    required this.semester,
    this.avatarUrl,
    this.attendance = 0.0,
    this.gpa = 0.0,
    this.eventsParticipated = 0,
    this.courses = const [],
    this.mentorId,
    this.parentEmail,
    this.phoneNumber,
    this.address,
    this.emergencyContact,
    this.bloodGroup,
    required this.createdAt,
    required this.updatedAt,
  });

  factory StudentModel.fromMap(Map<String, dynamic> map, String id) {
    return StudentModel(
      id: id,
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      rollNumber: map['rollNumber'] ?? '',
      department: map['department'] ?? '',
      semester: map['semester'] ?? '',
      avatarUrl: map['avatarUrl'],
      attendance: (map['attendance'] ?? 0.0).toDouble(),
      gpa: (map['gpa'] ?? 0.0).toDouble(),
      eventsParticipated: map['eventsParticipated'] ?? 0,
      courses: List<String>.from(map['courses'] ?? []),
      mentorId: map['mentorId'],
      parentEmail: map['parentEmail'],
      phoneNumber: map['phoneNumber'],
      address: map['address'],
      emergencyContact: map['emergencyContact'],
      bloodGroup: map['bloodGroup'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] ?? 0),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'email': email,
      'rollNumber': rollNumber,
      'department': department,
      'semester': semester,
      'avatarUrl': avatarUrl,
      'attendance': attendance,
      'gpa': gpa,
      'eventsParticipated': eventsParticipated,
      'courses': courses,
      'mentorId': mentorId,
      'parentEmail': parentEmail,
      'phoneNumber': phoneNumber,
      'address': address,
      'emergencyContact': emergencyContact,
      'bloodGroup': bloodGroup,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }
}
