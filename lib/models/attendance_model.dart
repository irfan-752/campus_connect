class AttendanceModel {
  final String id;
  final String studentId;
  final String studentName;
  final String teacherId;
  final DateTime date;
  final String status; // 'Present', 'Absent', 'Late'
  final String? remarks;
  final String? subjectId;
  final String? subjectName;
  final bool isPresent;
  final DateTime createdAt;
  final DateTime updatedAt;

  AttendanceModel({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.teacherId,
    required this.date,
    required this.status,
    this.remarks,
    this.subjectId,
    this.subjectName,
    required this.isPresent,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AttendanceModel.fromMap(Map<String, dynamic> map, String id) {
    return AttendanceModel(
      id: id,
      studentId: map['studentId'] ?? '',
      studentName: map['studentName'] ?? '',
      teacherId: map['teacherId'] ?? '',
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] ?? 0),
      status: map['status'] ?? 'Absent',
      remarks: map['remarks'],
      subjectId: map['subjectId'],
      subjectName: map['subjectName'],
      isPresent: map['isPresent'] ?? false,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] ?? 0),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'teacherId': teacherId,
      'date': date.millisecondsSinceEpoch,
      'status': status,
      'remarks': remarks,
      'subjectId': subjectId,
      'subjectName': subjectName,
      'isPresent': isPresent,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }
}
