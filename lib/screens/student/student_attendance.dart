import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../utils/app_theme.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/empty_state_widget.dart';
import '../../models/attendance_model.dart';

class StudentAttendanceScreen extends StatefulWidget {
  const StudentAttendanceScreen({super.key});

  @override
  State<StudentAttendanceScreen> createState() =>
      _StudentAttendanceScreenState();
}

class _StudentAttendanceScreenState extends State<StudentAttendanceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedSubject = 'All';
  List<String> _subjects = ['All'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadSubjects();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadSubjects() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final studentDoc = await FirebaseFirestore.instance
        .collection('students')
        .doc(userId)
        .get();

    if (studentDoc.exists) {
      final data = studentDoc.data() as Map<String, dynamic>;
      final courses = List<String>.from(data['courses'] ?? []);
      setState(() {
        _subjects = ['All', ...courses];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: const CustomAppBar(title: "Attendance"),
      body: Column(
        children: [
          _buildSubjectFilter(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildOverview(), _buildDetailedView()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectFilter() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingM),
        itemCount: _subjects.length,
        itemBuilder: (context, index) {
          final subject = _subjects[index];
          final isSelected = subject == _selectedSubject;

          return Padding(
            padding: const EdgeInsets.only(right: AppTheme.spacingS),
            child: FilterChip(
              label: Text(
                subject,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? Colors.white : AppTheme.primaryColor,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedSubject = subject;
                });
              },
              backgroundColor: Colors.white,
              selectedColor: AppTheme.primaryColor,
              checkmarkColor: Colors.white,
              side: const BorderSide(color: AppTheme.primaryColor),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppTheme.dividerColor)),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: AppTheme.primaryColor,
        unselectedLabelColor: AppTheme.secondaryTextColor,
        labelStyle: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.normal,
        ),
        indicatorColor: AppTheme.primaryColor,
        tabs: const [
          Tab(text: "Overview"),
          Tab(text: "Detailed View"),
        ],
      ),
    );
  }

  Widget _buildOverview() {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOverallStats(userId),
            const SizedBox(height: AppTheme.spacingL),
            _buildSubjectWiseAttendance(userId),
            const SizedBox(height: AppTheme.spacingL),
            _buildAttendanceGoal(),
            const SizedBox(height: AppTheme.spacingL),
            _buildTips(),
            // Add bottom padding to prevent overflow
            SizedBox(
              height:
                  MediaQuery.of(context).padding.bottom + AppTheme.spacingXL,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverallStats(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('attendance')
          .where('studentId', isEqualTo: userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingWidget();
        }

        if (!snapshot.hasData) {
          return const EmptyStateWidget(
            title: "No attendance data",
            subtitle: "Your attendance records will appear here",
            icon: Icons.check_circle,
          );
        }

        final attendanceRecords = snapshot.data!.docs.map((doc) {
          return AttendanceModel.fromMap(
            doc.data() as Map<String, dynamic>,
            doc.id,
          );
        }).toList();

        final totalClasses = attendanceRecords.length;
        final presentClasses = attendanceRecords
            .where((record) => record.isPresent)
            .length;
        final attendancePercentage = totalClasses > 0
            ? (presentClasses / totalClasses) * 100
            : 0.0;

        return CustomCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Overall Attendance",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryTextColor,
                ),
              ),
              const SizedBox(height: AppTheme.spacingL),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _getAttendanceColor(
                              attendancePercentage,
                            ).withOpacity(0.1),
                          ),
                          child: Center(
                            child: Text(
                              "${attendancePercentage.toStringAsFixed(1)}%",
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: _getAttendanceColor(
                                  attendancePercentage,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingS),
                        Text(
                          "Attendance Rate",
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppTheme.secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        _buildStatItem(
                          "Total Classes",
                          "$totalClasses",
                          Icons.book,
                        ),
                        const SizedBox(height: AppTheme.spacingS),
                        _buildStatItem(
                          "Present",
                          "$presentClasses",
                          Icons.check_circle,
                        ),
                        const SizedBox(height: AppTheme.spacingS),
                        _buildStatItem(
                          "Absent",
                          "${totalClasses - presentClasses}",
                          Icons.cancel,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.secondaryTextColor),
        const SizedBox(width: AppTheme.spacingS),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryTextColor,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: AppTheme.secondaryTextColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSubjectWiseAttendance(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('attendance')
          .where('studentId', isEqualTo: userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingWidget();
        }

        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final attendanceRecords = snapshot.data!.docs.map((doc) {
          return AttendanceModel.fromMap(
            doc.data() as Map<String, dynamic>,
            doc.id,
          );
        }).toList();

        // Group by subject
        final Map<String, List<AttendanceModel>> subjectGroups = {};
        for (final record in attendanceRecords) {
          if (!subjectGroups.containsKey(record.subjectName)) {
            subjectGroups[record.subjectName] = [];
          }
          subjectGroups[record.subjectName]!.add(record);
        }

        final summaries = subjectGroups.entries.map((entry) {
          final subjectName = entry.key;
          final records = entry.value;
          final totalClasses = records.length;
          final attendedClasses = records.where((r) => r.isPresent).length;

          return AttendanceSummary(
            studentId: userId,
            subjectId: records.first.subjectId,
            subjectName: subjectName,
            totalClasses: totalClasses,
            attendedClasses: attendedClasses,
          );
        }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Subject-wise Attendance",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryTextColor,
              ),
            ),
            const SizedBox(height: AppTheme.spacingM),
            ...summaries.map((summary) => _buildSubjectCard(summary)),
          ],
        );
      },
    );
  }

  Widget _buildSubjectCard(AttendanceSummary summary) {
    return CustomCard(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingS),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  summary.subjectName,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryTextColor,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingXS),
                Text(
                  "${summary.attendedClasses}/${summary.totalClasses} classes",
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppTheme.secondaryTextColor,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingS),
                LinearProgressIndicator(
                  value: summary.percentage / 100,
                  backgroundColor: AppTheme.surfaceColor,
                  valueColor: AlwaysStoppedAnimation(
                    _getAttendanceColor(summary.percentage),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppTheme.spacingM),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _getAttendanceColor(summary.percentage).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "${summary.percentage.toStringAsFixed(1)}%",
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: _getAttendanceColor(summary.percentage),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceGoal() {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flag, color: AppTheme.primaryColor, size: 24),
              const SizedBox(width: AppTheme.spacingS),
              Text(
                "Attendance Goal",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryTextColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingM),
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
            ),
            child: Column(
              children: [
                Text(
                  "Maintain 75% attendance to be eligible for exams",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppTheme.primaryTextColor,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingS),
                Text(
                  "Keep attending classes regularly to stay on track!",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppTheme.secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTips() {
    final tips = [
      "Set reminders for your classes to avoid missing them",
      "Communicate with teachers if you need to miss a class",
      "Keep track of your attendance regularly",
      "Aim for 100% attendance when possible",
    ];

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb, color: AppTheme.warningColor, size: 24),
              const SizedBox(width: AppTheme.spacingS),
              Text(
                "Tips for Better Attendance",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryTextColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingM),
          ...tips.map(
            (tip) => Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.spacingS),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(top: 6),
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingS),
                  Expanded(
                    child: Text(
                      tip,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: AppTheme.primaryTextColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedView() {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    return StreamBuilder<QuerySnapshot>(
      stream: _getAttendanceStream(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingWidget(message: "Loading attendance records...");
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const EmptyStateWidget(
            title: "No attendance records",
            subtitle: "Your attendance records will appear here",
            icon: Icons.check_circle,
          );
        }

        final records = snapshot.data!.docs.map((doc) {
          return AttendanceModel.fromMap(
            doc.data() as Map<String, dynamic>,
            doc.id,
          );
        }).toList();

        return SafeArea(
          child: ListView.builder(
            padding: EdgeInsets.only(
              left: AppTheme.spacingM,
              right: AppTheme.spacingM,
              top: AppTheme.spacingM,
              bottom:
                  MediaQuery.of(context).padding.bottom + AppTheme.spacingXL,
            ),
            itemCount: records.length,
            itemBuilder: (context, index) {
              final record = records[index];
              return _buildAttendanceRecord(record);
            },
          ),
        );
      },
    );
  }

  Widget _buildAttendanceRecord(AttendanceModel record) {
    return CustomCard(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingS),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: record.isPresent
                  ? AppTheme.successColor.withOpacity(0.1)
                  : AppTheme.errorColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              record.isPresent ? Icons.check : Icons.close,
              color: record.isPresent
                  ? AppTheme.successColor
                  : AppTheme.errorColor,
              size: 20,
            ),
          ),
          const SizedBox(width: AppTheme.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.subjectName,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryTextColor,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingXS),
                Text(
                  DateFormat('MMM dd, yyyy').format(record.date),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppTheme.secondaryTextColor,
                  ),
                ),
                if (record.remarks != null) ...[
                  const SizedBox(height: AppTheme.spacingXS),
                  Text(
                    record.remarks!,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppTheme.secondaryTextColor,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: record.isPresent
                  ? AppTheme.successColor
                  : AppTheme.errorColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              record.isPresent ? "Present" : "Absent",
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Stream<QuerySnapshot> _getAttendanceStream(String userId) {
    Query query = FirebaseFirestore.instance
        .collection('attendance')
        .where('studentId', isEqualTo: userId);

    if (_selectedSubject != 'All') {
      query = query.where('subjectName', isEqualTo: _selectedSubject);
    }

    return query.orderBy('date', descending: true).snapshots();
  }

  Color _getAttendanceColor(double percentage) {
    if (percentage >= 85) {
      return AppTheme.successColor;
    } else if (percentage >= 75) {
      return AppTheme.warningColor;
    } else {
      return AppTheme.errorColor;
    }
  }
}
