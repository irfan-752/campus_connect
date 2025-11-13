import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceAnalyticsService {
  final FirebaseFirestore _db;

  AttendanceAnalyticsService({
    FirebaseFirestore? db,
  })  : _db = db ?? FirebaseFirestore.instance;

  Future<Map<String, dynamic>> getStudentAttendanceAnalytics(
    String studentId,
  ) async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final startOfSemester = DateTime(now.year, now.month < 7 ? 1 : 7, 1);

    // Get all attendance records
    final allRecords = await _db
        .collection('attendance')
        .where('studentId', isEqualTo: studentId)
        .get();

    final monthlyRecords = allRecords.docs.where((doc) {
      final date = DateTime.fromMillisecondsSinceEpoch(doc.data()['date']);
      return date.isAfter(startOfMonth);
    }).toList();

    final semesterRecords = allRecords.docs.where((doc) {
      final date = DateTime.fromMillisecondsSinceEpoch(doc.data()['date']);
      return date.isAfter(startOfSemester);
    }).toList();

    // Calculate percentages
    final totalAll = allRecords.docs.length;
    final presentAll = allRecords.docs
        .where((doc) => doc.data()['isPresent'] == true)
        .length;
    final overallPercentage =
        totalAll > 0 ? (presentAll / totalAll) * 100 : 0.0;

    final totalMonthly = monthlyRecords.length;
    final presentMonthly =
        monthlyRecords.where((doc) => doc.data()['isPresent'] == true).length;
    final monthlyPercentage =
        totalMonthly > 0 ? (presentMonthly / totalMonthly) * 100 : 0.0;

    final totalSemester = semesterRecords.length;
    final presentSemester =
        semesterRecords.where((doc) => doc.data()['isPresent'] == true).length;
    final semesterPercentage =
        totalSemester > 0 ? (presentSemester / totalSemester) * 100 : 0.0;

    // Calculate trends
    final lastWeekRecords = allRecords.docs.where((doc) {
      final date = DateTime.fromMillisecondsSinceEpoch(doc.data()['date']);
      return date.isAfter(now.subtract(const Duration(days: 7)));
    }).toList();

    final lastWeekTotal = lastWeekRecords.length;
    final lastWeekPresent =
        lastWeekRecords.where((doc) => doc.data()['isPresent'] == true).length;
    final lastWeekPercentage =
        lastWeekTotal > 0 ? (lastWeekPresent / lastWeekTotal) * 100 : 0.0;

    // AI Predictions (simulated based on patterns)
    final predictedPercentage = _predictAttendance(
      overallPercentage,
      monthlyPercentage,
      lastWeekPercentage,
    );

    final riskLevel = _calculateRiskLevel(overallPercentage);
    final recommendations = _generateRecommendations(
      overallPercentage,
      monthlyPercentage,
      lastWeekPercentage,
    );

    // Subject-wise breakdown
    final subjectBreakdown = <String, Map<String, dynamic>>{};
    for (final doc in allRecords.docs) {
      final data = doc.data();
      final subject = data['subjectName'] ?? 'Unknown';
      if (!subjectBreakdown.containsKey(subject)) {
        subjectBreakdown[subject] = {'total': 0, 'present': 0};
      }
      subjectBreakdown[subject]!['total'] =
          (subjectBreakdown[subject]!['total'] as int) + 1;
      if (data['isPresent'] == true) {
        subjectBreakdown[subject]!['present'] =
            (subjectBreakdown[subject]!['present'] as int) + 1;
      }
    }

    final subjectPercentages = <String, double>{};
    subjectBreakdown.forEach((subject, data) {
      final total = data['total'] as int;
      final present = data['present'] as int;
      subjectPercentages[subject] = total > 0 ? (present / total) * 100 : 0.0;
    });

    return {
      'overallPercentage': overallPercentage,
      'monthlyPercentage': monthlyPercentage,
      'semesterPercentage': semesterPercentage,
      'lastWeekPercentage': lastWeekPercentage,
      'predictedPercentage': predictedPercentage,
      'riskLevel': riskLevel,
      'recommendations': recommendations,
      'subjectBreakdown': subjectPercentages,
      'totalClasses': totalAll,
      'presentClasses': presentAll,
      'absentClasses': totalAll - presentAll,
    };
  }

  double _predictAttendance(
    double overall,
    double monthly,
    double lastWeek,
  ) {
    // Simple weighted prediction: recent performance weighted more
    if (lastWeek > 0) {
      return (overall * 0.3 + monthly * 0.4 + lastWeek * 0.3);
    }
    return (overall * 0.5 + monthly * 0.5);
  }

  String _calculateRiskLevel(double percentage) {
    if (percentage >= 85) return 'low';
    if (percentage >= 75) return 'medium';
    if (percentage >= 60) return 'high';
    return 'critical';
  }

  List<String> _generateRecommendations(
    double overall,
    double monthly,
    double lastWeek,
  ) {
    final recommendations = <String>[];

    if (overall < 75) {
      recommendations.add(
        'Your overall attendance is below 75%. Focus on attending all classes.',
      );
    }

    if (monthly < overall) {
      recommendations.add(
        'Your attendance has decreased this month. Try to improve consistency.',
      );
    } else if (monthly > overall + 5) {
      recommendations.add(
        'Great improvement this month! Keep up the good work.',
      );
    }

    if (lastWeek < 70) {
      recommendations.add(
        'Your attendance last week was low. Make sure to attend upcoming classes.',
      );
    }

    if (overall >= 90) {
      recommendations.add(
        'Excellent attendance! You\'re setting a great example.',
      );
    }

    if (recommendations.isEmpty) {
      recommendations.add('Maintain your current attendance level.');
    }

    return recommendations;
  }

  Future<List<Map<String, dynamic>>> getAttendanceHistory(
    String studentId, {
    int days = 30,
  }) async {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    final records = await _db
        .collection('attendance')
        .where('studentId', isEqualTo: studentId)
        .get();
    
    final filtered = records.docs.where((doc) {
      final date = DateTime.fromMillisecondsSinceEpoch(doc.data()['date']);
      return date.isAfter(cutoff);
    }).toList();
    
    filtered.sort((a, b) {
      final dateA = DateTime.fromMillisecondsSinceEpoch(a.data()['date']);
      final dateB = DateTime.fromMillisecondsSinceEpoch(b.data()['date']);
      return dateB.compareTo(dateA);
    });

    return filtered.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'date': DateTime.fromMillisecondsSinceEpoch(data['date']),
        'status': data['status'] ?? 'Absent',
        'isPresent': data['isPresent'] ?? false,
        'subjectName': data['subjectName'] ?? 'Unknown',
        'remarks': data['remarks'],
      };
    }).toList();
  }
}

