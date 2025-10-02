class CourseAssignmentModel {
  final String id;
  final String teacherId;
  final String teacherName;
  final String courseId;
  final String courseName;
  final String department;
  final String semester;
  final List<String> studentIds;
  final DateTime assignedAt;
  final DateTime updatedAt;
  final bool isActive;

  CourseAssignmentModel({
    required this.id,
    required this.teacherId,
    required this.teacherName,
    required this.courseId,
    required this.courseName,
    required this.department,
    required this.semester,
    this.studentIds = const [],
    required this.assignedAt,
    required this.updatedAt,
    this.isActive = true,
  });

  factory CourseAssignmentModel.fromMap(Map<String, dynamic> map, String id) {
    return CourseAssignmentModel(
      id: id,
      teacherId: map['teacherId'] ?? '',
      teacherName: map['teacherName'] ?? '',
      courseId: map['courseId'] ?? '',
      courseName: map['courseName'] ?? '',
      department: map['department'] ?? '',
      semester: map['semester'] ?? '',
      studentIds: List<String>.from(map['studentIds'] ?? []),
      assignedAt: DateTime.fromMillisecondsSinceEpoch(map['assignedAt'] ?? 0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] ?? 0),
      isActive: map['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'teacherId': teacherId,
      'teacherName': teacherName,
      'courseId': courseId,
      'courseName': courseName,
      'department': department,
      'semester': semester,
      'studentIds': studentIds,
      'assignedAt': assignedAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'isActive': isActive,
    };
  }
}

class CourseModel {
  final String id;
  final String name;
  final String code;
  final String department;
  final String semester;
  final String description;
  final int credits;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  CourseModel({
    required this.id,
    required this.name,
    required this.code,
    required this.department,
    required this.semester,
    this.description = '',
    this.credits = 3,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CourseModel.fromMap(Map<String, dynamic> map, String id) {
    return CourseModel(
      id: id,
      name: map['name'] ?? '',
      code: map['code'] ?? '',
      department: map['department'] ?? '',
      semester: map['semester'] ?? '',
      description: map['description'] ?? '',
      credits: map['credits'] ?? 3,
      isActive: map['isActive'] ?? true,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] ?? 0),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'code': code,
      'department': department,
      'semester': semester,
      'description': description,
      'credits': credits,
      'isActive': isActive,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }
}
