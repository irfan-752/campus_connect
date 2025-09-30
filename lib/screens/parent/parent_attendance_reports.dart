import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/app_theme.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/empty_state_widget.dart';
import '../../models/student_model.dart';

class ParentAttendanceReports extends StatefulWidget {
  const ParentAttendanceReports({super.key});

  @override
  State<ParentAttendanceReports> createState() =>
      _ParentAttendanceReportsState();
}

class _ParentAttendanceReportsState extends State<ParentAttendanceReports> {
  StudentModel? _selectedChild;
  List<StudentModel> _children = [];
  String _selectedPeriod = 'This Month';

  final List<String> _periods = [
    'This Week',
    'This Month',
    'Last 3 Months',
    'This Year',
  ];

  @override
  void initState() {
    super.initState();
    _loadChildren();
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
      appBar: const CustomAppBar(title: "Attendance Reports"),
      body: _children.isEmpty
          ? const Center(
              child: EmptyStateWidget(
                title: "No Children Found",
                subtitle: "Please contact administration",
                icon: Icons.family_restroom,
              ),
            )
          : Column(
              children: [
                _buildFilters(),
                Expanded(child: _buildReportsContent()),
              ],
            ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      color: Colors.white,
      child: Column(
        children: [
          if (_children.length > 1) ...[
            Row(
              children: [
                Text(
                  "Child:",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.primaryTextColor,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingS),
                Expanded(
                  child: DropdownButton<StudentModel>(
                    value: _selectedChild,
                    isExpanded: true,
                    items: _children.map((child) {
                      return DropdownMenuItem(
                        value: child,
                        child: Text(child.name),
                      );
                    }).toList(),
                    onChanged: (child) {
                      setState(() {
                        _selectedChild = child;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingM),
          ],
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _periods.map((period) {
                final isSelected = _selectedPeriod == period;
                return Padding(
                  padding: const EdgeInsets.only(right: AppTheme.spacingS),
                  child: FilterChip(
                    label: Text(
                      period,
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
                        _selectedPeriod = period;
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

  Widget _buildReportsContent() {
    if (_selectedChild == null) return const SizedBox();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAttendanceSummary(_selectedChild!),
          const SizedBox(height: AppTheme.spacingL),
          _buildSubjectWiseAttendance(_selectedChild!),
          const SizedBox(height: AppTheme.spacingL),
          _buildAttendanceTrend(_selectedChild!),
          const SizedBox(height: AppTheme.spacingL),
          _buildRecentAbsences(_selectedChild!),
        ],
      ),
    );
  }

  Widget _buildAttendanceSummary(StudentModel child) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Attendance Summary",
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
                child: _buildSummaryCard(
                  "Overall",
                  "${child.attendance.toStringAsFixed(1)}%",
                  Icons.check_circle,
                  child.attendance >= 75
                      ? AppTheme.successColor
                      : AppTheme.errorColor,
                ),
              ),
              const SizedBox(width: AppTheme.spacingS),
              Expanded(
                child: _buildSummaryCard(
                  "This Month",
                  "87.5%",
                  Icons.calendar_month,
                  AppTheme.warningColor,
                ),
              ),
              const SizedBox(width: AppTheme.spacingS),
              Expanded(
                child: _buildSummaryCard(
                  "This Week",
                  "100%",
                  Icons.date_range,
                  AppTheme.successColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: AppTheme.spacingS),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: AppTheme.primaryTextColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectWiseAttendance(StudentModel child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Subject-wise Attendance",
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryTextColor,
          ),
        ),
        const SizedBox(height: AppTheme.spacingM),
        ...child.courses.map((course) {
          final attendance = 75.0 + (course.hashCode % 25);
          return _buildSubjectAttendanceCard(course, attendance.toDouble());
        }).toList(),
      ],
    );
  }

  Widget _buildSubjectAttendanceCard(String subject, double attendance) {
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
                const SizedBox(height: AppTheme.spacingS),
                LinearProgressIndicator(
                  value: attendance / 100,
                  backgroundColor: AppTheme.surfaceColor,
                  valueColor: AlwaysStoppedAnimation(
                    _getAttendanceColor(attendance),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppTheme.spacingM),
          Text(
            "${attendance.toStringAsFixed(1)}%",
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: _getAttendanceColor(attendance),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceTrend(StudentModel child) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Attendance Trend",
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryTextColor,
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.trending_up,
                    size: 48,
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(height: AppTheme.spacingS),
                  Text(
                    "Attendance Trend Chart",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    "Chart implementation would go here",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppTheme.secondaryTextColor,
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

  Widget _buildRecentAbsences(StudentModel child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Recent Absences",
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
              _buildAbsenceItem(
                "March 10, 2024",
                "Mathematics",
                "Medical Leave",
              ),
              _buildAbsenceItem(
                "March 8, 2024",
                "Physics Lab",
                "Family Function",
              ),
              _buildAbsenceItem("March 5, 2024", "Chemistry", "Sick Leave"),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAbsenceItem(String date, String subject, String reason) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingM),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.errorColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.cancel,
              color: AppTheme.errorColor,
              size: 16,
            ),
          ),
          const SizedBox(width: AppTheme.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "$date - $subject",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryTextColor,
                  ),
                ),
                Text(
                  reason,
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

  Color _getAttendanceColor(double attendance) {
    if (attendance >= 85) return AppTheme.successColor;
    if (attendance >= 75) return AppTheme.warningColor;
    return AppTheme.errorColor;
  }
}
