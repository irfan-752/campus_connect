import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/app_theme.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/responsive_wrapper.dart';
import '../../utils/responsive_helper.dart';
import '../../models/student_model.dart';
import '../../models/event_model.dart';
import '../../models/notice_model.dart';

class StudentDashboard extends StatelessWidget {
  const StudentDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('students')
              .doc(user?.uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const LoadingWidget(message: "Loading dashboard...");
            }
            if (!snapshot.hasData || !snapshot.data!.exists) {
              // Auto-create a minimal student profile document and show loading
              if (user != null) {
                final now = DateTime.now().millisecondsSinceEpoch;
                FirebaseFirestore.instance
                    .collection('students')
                    .doc(user.uid)
                    .set({
                      'userId': user.uid,
                      'name': user.displayName ?? 'Student',
                      'email': user.email ?? '',
                      'rollNumber': '',
                      'department': '',
                      'semester': '',
                      'avatarUrl': null,
                      'attendance': 0.0,
                      'gpa': 0.0,
                      'eventsParticipated': 0,
                      'courses': <String>[],
                      'mentorId': null,
                      'parentEmail': null,
                      'createdAt': now,
                      'updatedAt': now,
                    }, SetOptions(merge: true));
              }
              return const LoadingWidget(message: "Preparing your profile...");
            }

            final studentData = snapshot.data!.data() as Map<String, dynamic>;
            final student = StudentModel.fromMap(studentData, user!.uid);

            return SafeArea(
              child: SingleChildScrollView(
                child: ResponsiveWrapper(
                  centerContent: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(context, student),
                      const SizedBox(height: AppTheme.spacingL),
                      _buildQuickStats(context, student),
                      const SizedBox(height: AppTheme.spacingL),
                      ResponsiveHelper.isTabletOrDesktop(context)
                          ? _buildTabletDesktopLayout(
                              context,
                              student,
                              user.uid,
                            )
                          : _buildMobileLayout(context, student, user.uid),
                      // Add bottom padding to prevent overflow
                      SizedBox(
                        height:
                            MediaQuery.of(context).padding.bottom +
                            AppTheme.spacingXL,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, StudentModel student) {
    return Row(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundImage: student.avatarUrl != null
              ? NetworkImage(student.avatarUrl!)
              : null,
          child: student.avatarUrl == null
              ? Text(
                  student.name.isNotEmpty ? student.name[0].toUpperCase() : 'S',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
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
                "Welcome back,",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppTheme.secondaryTextColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                student.name,
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryTextColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                "${student.department} • ${student.semester}",
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppTheme.secondaryTextColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () {
            // Navigate to notifications
          },
        ),
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () {
            // Navigate to search
          },
        ),
      ],
    );
  }

  Widget _buildQuickStats(BuildContext context, StudentModel student) {
    final stats = [
      StatCard(
        title: "Attendance",
        value: "${student.attendance.toStringAsFixed(1)}%",
        icon: Icons.check_circle,
        iconColor: student.attendance >= 75
            ? AppTheme.successColor
            : AppTheme.errorColor,
      ),
      StatCard(
        title: "GPA",
        value: student.gpa.toStringAsFixed(2),
        icon: Icons.grade,
        iconColor: AppTheme.warningColor,
      ),
      StatCard(
        title: "Events",
        value: "${student.eventsParticipated}",
        icon: Icons.event,
        iconColor: AppTheme.primaryColor,
      ),
      StatCard(
        title: "Courses",
        value: "${student.courses.length}",
        icon: Icons.book,
        iconColor: AppTheme.successColor,
      ),
    ];

    if (ResponsiveHelper.isMobile(context)) {
      return ResponsiveGrid(
        mobileColumns: 2,
        tabletColumns: 4,
        desktopColumns: 4,
        childAspectRatio: 1.5,
        children: stats,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - 3 * AppTheme.spacingS) / 4;
        return Row(
          children: stats
              .expand(
                (stat) => [
                  SizedBox(width: itemWidth, child: stat),
                  if (stat != stats.last)
                    const SizedBox(width: AppTheme.spacingS),
                ],
              )
              .toList(),
        );
      },
    );
  }

  Widget _buildTodaySchedule(BuildContext context, String studentId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Today's Schedule",
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryTextColor,
          ),
        ),
        const SizedBox(height: AppTheme.spacingM),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('schedule')
              .where('studentId', isEqualTo: studentId)
              .where(
                'date',
                isEqualTo: DateTime.now().toIso8601String().split('T')[0],
              )
              .orderBy('startTime')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const LoadingWidget(message: "Loading schedule...");
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const EmptyStateWidget(
                title: "No classes today",
                subtitle: "Enjoy your free day!",
                icon: Icons.free_breakfast,
              );
            }

            return Column(
              children: snapshot.data!.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppTheme.spacingS),
                  child: InfoCard(
                    title: data['subject'] ?? 'Subject',
                    subtitle:
                        "${data['startTime']} - ${data['endTime']} • ${data['room']}",
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.schedule,
                        color: AppTheme.primaryColor,
                        size: 20,
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRecentNotices(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Recent Notices",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryTextColor,
              ),
            ),
            TextButton(
              onPressed: () {
                // Navigate to all notices
              },
              child: Text(
                "View All",
                style: GoogleFonts.poppins(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingM),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('notices')
              .where('isActive', isEqualTo: true)
              .orderBy('createdAt', descending: true)
              .limit(10) // Get more to filter properly
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const LoadingWidget();
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const EmptyStateWidget(
                title: "No recent notices",
                subtitle: "Check back later for updates",
                icon: Icons.campaign,
              );
            }

            // Filter notices by target audience and limit to 3
            final filteredNotices = snapshot.data!.docs
                .where((doc) {
                  final notice = NoticeModel.fromMap(
                    doc.data() as Map<String, dynamic>,
                    doc.id,
                  );
                  // Show notices that are either for 'All' or specifically for 'Student'
                  return notice.targetAudience.contains('All') ||
                      notice.targetAudience.contains('Student');
                })
                .take(3)
                .toList();

            if (filteredNotices.isEmpty) {
              return const EmptyStateWidget(
                title: "No recent notices",
                subtitle: "Check back later for updates",
                icon: Icons.campaign,
              );
            }

            return Column(
              children: filteredNotices.map((doc) {
                final notice = NoticeModel.fromMap(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                );
                return InfoCard(
                  title: notice.title,
                  subtitle: notice.description,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getPriorityColor(
                        notice.priority,
                      ).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.campaign,
                      color: _getPriorityColor(notice.priority),
                      size: 20,
                    ),
                  ),
                  trailing:
                      !notice.isReadBy(FirebaseAuth.instance.currentUser!.uid)
                      ? Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppTheme.primaryColor,
                            shape: BoxShape.circle,
                          ),
                        )
                      : null,
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildUpcomingEvents(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Upcoming Events",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryTextColor,
              ),
            ),
            TextButton(
              onPressed: () {
                // Navigate to all events
              },
              child: Text(
                "View All",
                style: GoogleFonts.poppins(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingM),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('events')
              .where('isActive', isEqualTo: true)
              .where('startDate', isGreaterThan: DateTime.now())
              .orderBy('startDate')
              .limit(3)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const LoadingWidget();
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const EmptyStateWidget(
                title: "No upcoming events",
                subtitle: "Stay tuned for exciting events!",
                icon: Icons.event,
              );
            }

            return Column(
              children: snapshot.data!.docs.map((doc) {
                final event = EventModel.fromMap(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                );
                return InfoCard(
                  title: event.title,
                  subtitle:
                      "${event.location} • ${_formatDate(event.startDate)}",
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.event,
                      color: AppTheme.primaryColor,
                      size: 20,
                    ),
                  ),
                  trailing:
                      event.registeredStudents.contains(
                        FirebaseAuth.instance.currentUser!.uid,
                      )
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.successColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            "Registered",
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        )
                      : null,
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Quick Actions",
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryTextColor,
          ),
        ),
        const SizedBox(height: AppTheme.spacingM),
        ResponsiveGrid(
          mobileColumns: 2,
          tabletColumns: 2,
          desktopColumns: 4,
          childAspectRatio: ResponsiveHelper.responsiveValue(
            context,
            mobile: 1.2,
            tablet: 1.3,
            desktop: 1.0,
          ),
          children: [
            _buildActionCard(
              context,
              "Find Mentor",
              Icons.person_search,
              AppTheme.primaryColor,
              () {
                // Navigate to mentor search
              },
            ),
            _buildActionCard(
              context,
              "Submit Feedback",
              Icons.feedback,
              AppTheme.warningColor,
              () {
                // Navigate to feedback
              },
            ),
            _buildActionCard(
              context,
              "Join Discussion",
              Icons.forum,
              AppTheme.successColor,
              () {
                // Navigate to discussions
              },
            ),
            _buildActionCard(
              context,
              "Calculate CGPA",
              Icons.calculate,
              AppTheme.accentColor,
              () {
                // Navigate to CGPA calculator
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return CustomCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppTheme.spacingM),
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
          const SizedBox(height: AppTheme.spacingS),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppTheme.primaryTextColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return AppTheme.errorColor;
      case 'medium':
        return AppTheme.warningColor;
      case 'low':
        return AppTheme.successColor;
      default:
        return AppTheme.primaryColor;
    }
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }

  Widget _buildMobileLayout(
    BuildContext context,
    StudentModel student,
    String userId,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTodaySchedule(context, userId),
        const SizedBox(height: AppTheme.spacingL),
        _buildRecentNotices(context),
        const SizedBox(height: AppTheme.spacingL),
        _buildUpcomingEvents(context),
        const SizedBox(height: AppTheme.spacingL),
        _buildQuickActions(context),
      ],
    );
  }

  Widget _buildTabletDesktopLayout(
    BuildContext context,
    StudentModel student,
    String userId,
  ) {
    return ResponsiveRow(
      wrapOnMobile: false,
      children: [
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTodaySchedule(context, userId),
              const SizedBox(height: AppTheme.spacingL),
              _buildQuickActions(context),
            ],
          ),
        ),
        const SizedBox(width: AppTheme.spacingL),
        Expanded(
          flex: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildRecentNotices(context),
              const SizedBox(height: AppTheme.spacingL),
              _buildUpcomingEvents(context),
            ],
          ),
        ),
      ],
    );
  }
}
