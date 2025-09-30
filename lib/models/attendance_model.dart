class AttendanceModel {
  final String id;
  final String studentId;
  final String subjectId;
  final String subjectName;
  final DateTime date;
  final bool isPresent;
  final String? remarks;
  final String teacherId;
  final DateTime createdAt;

  AttendanceModel({
    required this.id,
    required this.studentId,
    required this.subjectId,
    required this.subjectName,
    required this.date,
    required this.isPresent,
    this.remarks,
    required this.teacherId,
    required this.createdAt,
  });

  factory AttendanceModel.fromMap(Map<String, dynamic> map, String id) {
    return AttendanceModel(
      id: id,
      studentId: map['studentId'] ?? '',
      subjectId: map['subjectId'] ?? '',
      subjectName: map['subjectName'] ?? '',
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] ?? 0),
      isPresent: map['isPresent'] ?? false,
      remarks: map['remarks'],
      teacherId: map['teacherId'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'subjectId': subjectId,
      'subjectName': subjectName,
      'date': date.millisecondsSinceEpoch,
      'isPresent': isPresent,
      'remarks': remarks,
      'teacherId': teacherId,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }
}

class AttendanceSummary {
  final String studentId;
  final String subjectId;
  final String subjectName;
  final int totalClasses;
  final int attendedClasses;
  final double percentage;

  AttendanceSummary({
    required this.studentId,
    required this.subjectId,
    required this.subjectName,
    required this.totalClasses,
    required this.attendedClasses,
  }) : percentage = totalClasses > 0
           ? (attendedClasses / totalClasses) * 100
           : 0.0;

  factory AttendanceSummary.fromMap(Map<String, dynamic> map) {
    return AttendanceSummary(
      studentId: map['studentId'] ?? '',
      subjectId: map['subjectId'] ?? '',
      subjectName: map['subjectName'] ?? '',
      totalClasses: map['totalClasses'] ?? 0,
      attendedClasses: map['attendedClasses'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'subjectId': subjectId,
      'subjectName': subjectName,
      'totalClasses': totalClasses,
      'attendedClasses': attendedClasses,
      'percentage': percentage,
    };
  }
}
