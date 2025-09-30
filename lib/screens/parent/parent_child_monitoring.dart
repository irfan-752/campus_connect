import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../utils/app_theme.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/empty_state_widget.dart';
import '../../models/student_model.dart';
import '../../models/event_model.dart';

class ParentChildMonitoring extends StatefulWidget {
  const ParentChildMonitoring({super.key});

  @override
  State<ParentChildMonitoring> createState() => _ParentChildMonitoringState();
}

class _ParentChildMonitoringState extends State<ParentChildMonitoring>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  StudentModel? _selectedChild;
  List<StudentModel> _children = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadChildren();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadChildren() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final snapshot = await FirebaseFirestore.instance
          .collection('students')
          .where('parentId', isEqualTo: user.uid)
          .get();

      setState(() {
        _children = snapshot.docs.map((doc) {
          return StudentModel.fromMap(doc.data(), doc.id);
        }).toList();

        if (_children.isNotEmpty) {
          _selectedChild = _children.first;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: const CustomAppBar(title: "Child Monitoring"),
      body: _children.isEmpty
          ? _buildNoChildrenView()
          : Column(
              children: [
                _buildChildSelector(),
                _buildTabBar(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOverviewTab(),
                      _buildAcademicTab(),
                      _buildAttendanceTab(),
                      _buildActivitiesTab(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildNoChildrenView() {
    return const Center(
      child: EmptyStateWidget(
        title: "No Children Found",
        subtitle:
            "Please contact the administration to link your child's account",
        icon: Icons.family_restroom,
      ),
    );
  }

  Widget _buildChildSelector() {
    if (_children.length <= 1) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Select Child",
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryTextColor,
            ),
          ),
          const SizedBox(height: AppTheme.spacingS),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _children.map((child) {
                final isSelected = _selectedChild?.id == child.id;
                return Padding(
                  padding: const EdgeInsets.only(right: AppTheme.spacingS),
                  child: FilterChip(
                    label: Text(
                      child.name,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: isSelected
                            ? Colors.white
                            : AppTheme.primaryColor,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedChild = child;
                      });
                    },
                    backgroundColor: Colors.white,
                    selectedColor: AppTheme.primaryColor,
                    checkmarkColor: Colors.white,
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: AppTheme.primaryColor,
        unselectedLabelColor: AppTheme.secondaryTextColor,
        labelStyle: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.normal,
        ),
        indicatorColor: AppTheme.primaryColor,
        isScrollable: true,
        tabs: const [
          Tab(text: 'Overview'),
          Tab(text: 'Academic'),
          Tab(text: 'Attendance'),
          Tab(text: 'Activities'),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    if (_selectedChild == null) return const SizedBox();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildChildProfile(_selectedChild!),
          const SizedBox(height: AppTheme.spacingL),
          _buildQuickStats(_selectedChild!),
          const SizedBox(height: AppTheme.spacingL),
          _buildRecentActivity(_selectedChild!),
          const SizedBox(height: AppTheme.spacingL),
          _buildBehaviorNotes(_selectedChild!),
        ],
      ),
    );
  }

  Widget _buildChildProfile(StudentModel child) {
    return CustomCard(
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundImage: child.avatarUrl != null
                ? NetworkImage(child.avatarUrl!)
                : null,
            backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
            child: child.avatarUrl == null
                ? Text(
                    child.name.isNotEmpty ? child.name[0].toUpperCase() : 'S',
                    style: GoogleFonts.poppins(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: AppTheme.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  child.name,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryTextColor,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingXS),
                Text(
                  "Roll No: ${child.rollNumber}",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppTheme.secondaryTextColor,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingXS),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "${child.department} • ${child.semester}",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(StudentModel child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Quick Stats",
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryTextColor,
          ),
        ),
        const SizedBox(height: AppTheme.spacingM),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                "Overall Attendance",
                "${child.attendance.toStringAsFixed(1)}%",
                Icons.check_circle,
                child.attendance >= 75
                    ? AppTheme.successColor
                    : AppTheme.errorColor,
              ),
            ),
            const SizedBox(width: AppTheme.spacingS),
            Expanded(
              child: _buildStatCard(
                "Current GPA",
                child.gpa.toStringAsFixed(2),
                Icons.grade,
                AppTheme.primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingS),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                "Events Participated",
                "${child.eventsParticipated}",
                Icons.event,
                AppTheme.warningColor,
              ),
            ),
            const SizedBox(width: AppTheme.spacingS),
            Expanded(
              child: _buildStatCard(
                "Active Courses",
                "${child.courses.length}",
                Icons.book,
                AppTheme.accentColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return CustomCard(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: AppTheme.spacingM),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryTextColor,
            ),
          ),
          const SizedBox(height: AppTheme.spacingXS),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: AppTheme.secondaryTextColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity(StudentModel child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Recent Activity",
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryTextColor,
          ),
        ),
        const SizedBox(height: AppTheme.spacingM),
        CustomCard(
          child: Column(
            children: [
              _buildActivityItem(
                "Attended Math Class",
                "Today, 10:00 AM",
                Icons.check_circle,
                AppTheme.successColor,
              ),
              _buildActivityItem(
                "Submitted Physics Assignment",
                "Yesterday, 2:30 PM",
                Icons.assignment_turned_in,
                AppTheme.primaryColor,
              ),
              _buildActivityItem(
                "Participated in Science Fair",
                "2 days ago",
                Icons.event,
                AppTheme.warningColor,
              ),
              _buildActivityItem(
                "Missed Chemistry Lab",
                "3 days ago",
                Icons.cancel,
                AppTheme.errorColor,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActivityItem(
    String title,
    String time,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingM),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: AppTheme.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.primaryTextColor,
                  ),
                ),
                Text(
                  time,
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

  Widget _buildBehaviorNotes(StudentModel child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Behavior & Notes",
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryTextColor,
          ),
        ),
        const SizedBox(height: AppTheme.spacingM),
        CustomCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.successColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.star,
                      color: AppTheme.successColor,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Excellent Performance",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryTextColor,
                          ),
                        ),
                        Text(
                          "Shows consistent improvement in academics and participation.",
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppTheme.secondaryTextColor,
                          ),
                        ),
                        Text(
                          "- Math Teacher • 2 days ago",
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: AppTheme.lightTextColor,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: AppTheme.spacingL),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.warningColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.info,
                      color: AppTheme.warningColor,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Needs Attention",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryTextColor,
                          ),
                        ),
                        Text(
                          "Could improve punctuality in morning classes.",
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppTheme.secondaryTextColor,
                          ),
                        ),
                        Text(
                          "- Class Teacher • 1 week ago",
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: AppTheme.lightTextColor,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAcademicTab() {
    if (_selectedChild == null) return const SizedBox();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAcademicOverview(_selectedChild!),
          const SizedBox(height: AppTheme.spacingL),
          _buildSubjectWisePerformance(_selectedChild!),
          const SizedBox(height: AppTheme.spacingL),
          _buildUpcomingExams(_selectedChild!),
        ],
      ),
    );
  }

  Widget _buildAcademicOverview(StudentModel child) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Academic Overview",
            style: GoogleFonts.poppins(
              fontSize: 16,
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
                        color: AppTheme.primaryColor.withOpacity(0.1),
                      ),
                      child: Center(
                        child: Text(
                          child.gpa.toStringAsFixed(2),
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingS),
                    Text(
                      "Current GPA",
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
                    _buildAcademicStat(
                      "Total Courses",
                      "${child.courses.length}",
                    ),
                    const SizedBox(height: AppTheme.spacingS),
                    _buildAcademicStat("Completed", "12"),
                    const SizedBox(height: AppTheme.spacingS),
                    _buildAcademicStat(
                      "In Progress",
                      "${child.courses.length}",
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAcademicStat(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: AppTheme.secondaryTextColor,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryTextColor,
          ),
        ),
      ],
    );
  }

  Widget _buildSubjectWisePerformance(StudentModel child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Subject-wise Performance",
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryTextColor,
          ),
        ),
        const SizedBox(height: AppTheme.spacingM),
        ...child.courses.map((course) {
          // Generate random grades for demo
          final grade = (3.0 + (course.hashCode % 100) / 100).clamp(2.0, 4.0);
          return _buildSubjectCard(course, grade);
        }).toList(),
      ],
    );
  }

  Widget _buildSubjectCard(String subject, double grade) {
    return CustomCard(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingS),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subject,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryTextColor,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingXS),
                Text(
                  "Current Grade: ${grade.toStringAsFixed(1)}",
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppTheme.secondaryTextColor,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingS),
                LinearProgressIndicator(
                  value: grade / 4.0,
                  backgroundColor: AppTheme.surfaceColor,
                  valueColor: AlwaysStoppedAnimation(_getGradeColor(grade)),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppTheme.spacingM),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _getGradeColor(grade).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _getGradeLetter(grade),
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: _getGradeColor(grade),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingExams(StudentModel child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Upcoming Exams",
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryTextColor,
          ),
        ),
        const SizedBox(height: AppTheme.spacingM),
        CustomCard(
          child: Column(
            children: [
              _buildExamItem("Mathematics", "Mid-term Exam", "March 15, 2024"),
              _buildExamItem("Physics", "Unit Test", "March 18, 2024"),
              _buildExamItem("Chemistry", "Lab Practical", "March 22, 2024"),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExamItem(String subject, String examType, String date) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingM),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.warningColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.quiz,
              color: AppTheme.warningColor,
              size: 16,
            ),
          ),
          const SizedBox(width: AppTheme.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "$subject - $examType",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryTextColor,
                  ),
                ),
                Text(
                  date,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppTheme.secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios,
            size: 12,
            color: AppTheme.lightTextColor,
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceTab() {
    if (_selectedChild == null) return const SizedBox();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAttendanceOverview(_selectedChild!),
          const SizedBox(height: AppTheme.spacingL),
          _buildMonthlyAttendance(_selectedChild!),
          const SizedBox(height: AppTheme.spacingL),
          _buildAttendanceAlerts(_selectedChild!),
        ],
      ),
    );
  }

  Widget _buildAttendanceOverview(StudentModel child) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Attendance Overview",
            style: GoogleFonts.poppins(
              fontSize: 16,
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
                          child.attendance,
                        ).withOpacity(0.1),
                      ),
                      child: Center(
                        child: Text(
                          "${child.attendance.toStringAsFixed(1)}%",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _getAttendanceColor(child.attendance),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingS),
                    Text(
                      "Overall Attendance",
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
                    _buildAttendanceStat("Total Classes", "120"),
                    const SizedBox(height: AppTheme.spacingS),
                    _buildAttendanceStat("Present", "95"),
                    const SizedBox(height: AppTheme.spacingS),
                    _buildAttendanceStat("Absent", "25"),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceStat(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: AppTheme.secondaryTextColor,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryTextColor,
          ),
        ),
      ],
    );
  }

  Widget _buildMonthlyAttendance(StudentModel child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Monthly Attendance",
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryTextColor,
          ),
        ),
        const SizedBox(height: AppTheme.spacingM),
        CustomCard(
          child: Column(
            children: [
              _buildMonthlyAttendanceItem("March 2024", 85.5, 23, 20, 3),
              _buildMonthlyAttendanceItem("February 2024", 92.0, 25, 23, 2),
              _buildMonthlyAttendanceItem("January 2024", 88.0, 25, 22, 3),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMonthlyAttendanceItem(
    String month,
    double percentage,
    int total,
    int present,
    int absent,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                month,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryTextColor,
                ),
              ),
              Text(
                "${percentage.toStringAsFixed(1)}%",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: _getAttendanceColor(percentage),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingXS),
          Text(
            "$present/$total classes attended • $absent absent",
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppTheme.secondaryTextColor,
            ),
          ),
          const SizedBox(height: AppTheme.spacingS),
          LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: AppTheme.surfaceColor,
            valueColor: AlwaysStoppedAnimation(_getAttendanceColor(percentage)),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceAlerts(StudentModel child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Attendance Alerts",
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryTextColor,
          ),
        ),
        const SizedBox(height: AppTheme.spacingM),
        if (child.attendance < 75)
          CustomCard(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.warning,
                    color: AppTheme.errorColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Low Attendance Warning",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.errorColor,
                        ),
                      ),
                      Text(
                        "Attendance is below the required 75%. Please ensure regular attendance.",
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
          )
        else
          CustomCard(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.successColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: AppTheme.successColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Good Attendance",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.successColor,
                        ),
                      ),
                      Text(
                        "Attendance is above the required threshold. Keep it up!",
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
          ),
      ],
    );
  }

  Widget _buildActivitiesTab() {
    if (_selectedChild == null) return const SizedBox();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildEventParticipation(_selectedChild!),
          const SizedBox(height: AppTheme.spacingL),
          _buildUpcomingEvents(),
          const SizedBox(height: AppTheme.spacingL),
          _buildExtracurricularActivities(_selectedChild!),
        ],
      ),
    );
  }

  Widget _buildEventParticipation(StudentModel child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Event Participation",
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryTextColor,
          ),
        ),
        const SizedBox(height: AppTheme.spacingM),
        CustomCard(
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.event,
                      color: AppTheme.primaryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${child.eventsParticipated} Events",
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryTextColor,
                          ),
                        ),
                        Text(
                          "Total participation this year",
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
              const SizedBox(height: AppTheme.spacingM),
              _buildParticipationItem(
                "Science Fair 2024",
                "Participated",
                "2 weeks ago",
                AppTheme.successColor,
              ),
              _buildParticipationItem(
                "Cultural Fest",
                "Registered",
                "Upcoming",
                AppTheme.warningColor,
              ),
              _buildParticipationItem(
                "Sports Day",
                "Won 2nd Prize",
                "1 month ago",
                AppTheme.primaryColor,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildParticipationItem(
    String event,
    String status,
    String time,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingS),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppTheme.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.primaryTextColor,
                  ),
                ),
                Text(
                  "$status • $time",
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

  Widget _buildUpcomingEvents() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Upcoming Events",
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryTextColor,
          ),
        ),
        const SizedBox(height: AppTheme.spacingM),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('events')
              .where('startDate', isGreaterThan: Timestamp.now())
              .where('isActive', isEqualTo: true)
              .orderBy('startDate')
              .limit(5)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const LoadingWidget(message: "Loading events...");
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const EmptyStateWidget(
                title: "No upcoming events",
                subtitle: "Stay tuned for exciting events",
                icon: Icons.event,
              );
            }

            return Column(
              children: snapshot.data!.docs.map((doc) {
                final event = EventModel.fromMap(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                );
                return _buildUpcomingEventItem(event);
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildUpcomingEventItem(EventModel event) {
    return CustomCard(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingS),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.event,
              color: AppTheme.accentColor,
              size: 16,
            ),
          ),
          const SizedBox(width: AppTheme.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryTextColor,
                  ),
                ),
                Text(
                  DateFormat('MMM dd, yyyy • hh:mm a').format(event.startDate),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppTheme.secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios,
            size: 12,
            color: AppTheme.lightTextColor,
          ),
        ],
      ),
    );
  }

  Widget _buildExtracurricularActivities(StudentModel child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Extracurricular Activities",
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryTextColor,
          ),
        ),
        const SizedBox(height: AppTheme.spacingM),
        CustomCard(
          child: Column(
            children: [
              _buildActivityItem(
                "Debate Club",
                "Active Member",
                Icons.record_voice_over,
                AppTheme.primaryColor,
              ),
              _buildActivityItem(
                "Science Club",
                "Secretary",
                Icons.science,
                AppTheme.successColor,
              ),
              _buildActivityItem(
                "Basketball Team",
                "Team Player",
                Icons.sports_basketball,
                AppTheme.warningColor,
              ),
              _buildActivityItem(
                "Art & Craft",
                "Participant",
                Icons.palette,
                AppTheme.accentColor,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getAttendanceColor(double attendance) {
    if (attendance >= 85) return AppTheme.successColor;
    if (attendance >= 75) return AppTheme.warningColor;
    return AppTheme.errorColor;
  }

  Color _getGradeColor(double grade) {
    if (grade >= 3.5) return AppTheme.successColor;
    if (grade >= 2.5) return AppTheme.warningColor;
    return AppTheme.errorColor;
  }

  String _getGradeLetter(double grade) {
    if (grade >= 3.5) return 'A';
    if (grade >= 3.0) return 'B';
    if (grade >= 2.5) return 'C';
    if (grade >= 2.0) return 'D';
    return 'F';
  }
}
