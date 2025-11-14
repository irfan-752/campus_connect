import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/app_theme.dart';
import '../../utils/animations.dart';
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
                  child: AppAnimations.fadeIn(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppAnimations.slideInFromBottom(
                          child: _buildHeader(context, student),
                        ),
                        const SizedBox(height: AppTheme.spacingL),
                        AppAnimations.slideInFromBottom(
                          offset: 30,
                          child: _buildQuickStats(context, student),
                        ),
                        const SizedBox(height: AppTheme.spacingL),
                        AppAnimations.slideInFromBottom(
                          offset: 40,
                          child: ResponsiveHelper.isTabletOrDesktop(context)
                              ? _buildTabletDesktopLayout(
                                  context,
                                  student,
                                  user.uid,
                                )
                              : _buildMobileLayout(context, student, user.uid),
                        ),
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

    return ResponsiveGrid(
      mobileColumns: 2,
      tabletColumns: 4,
      desktopColumns: 4,
      childAspectRatio: ResponsiveHelper.responsiveValue(
        context,
        mobile: 1.3,
        tablet: 1.5,
        desktop: 1.6,
      ),
      crossAxisSpacing: ResponsiveHelper.responsiveValue(
        context,
        mobile: AppTheme.spacingS,
        tablet: AppTheme.spacingM,
        desktop: AppTheme.spacingM,
      ),
      mainAxisSpacing: ResponsiveHelper.responsiveValue(
        context,
        mobile: AppTheme.spacingS,
        tablet: AppTheme.spacingM,
        desktop: AppTheme.spacingM,
      ),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: stats,
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
                Navigator.pushNamed(context, '/student/notices');
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
                  // Also show notices with no target audience specified (backward compatibility)
                  return notice.targetAudience.isEmpty ||
                      notice.targetAudience.contains('All') ||
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
                Navigator.pushNamed(context, '/student/events');
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
          tabletColumns: 4,
          desktopColumns: 4,
          childAspectRatio: ResponsiveHelper.responsiveValue(
            context,
            mobile: 1.2,
            tablet: 1.3,
            desktop: 1.0,
          ),
          crossAxisSpacing: ResponsiveHelper.responsiveValue(
            context,
            mobile: AppTheme.spacingS,
            tablet: AppTheme.spacingM,
            desktop: AppTheme.spacingM,
          ),
          mainAxisSpacing: ResponsiveHelper.responsiveValue(
            context,
            mobile: AppTheme.spacingS,
            tablet: AppTheme.spacingM,
            desktop: AppTheme.spacingM,
          ),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildActionCard(
              context,
              "Resume Builder",
              Icons.description,
              AppTheme.primaryColor,
              () {
                Navigator.pushNamed(context, '/student/resume-builder');
              },
              0,
            ),
            _buildActionCard(
              context,
              "Library",
              Icons.library_books,
              AppTheme.accentColor,
              () {
                Navigator.pushNamed(context, '/student/library');
              },
              50,
            ),
            _buildActionCard(
              context,
              "Placements",
              Icons.work,
              AppTheme.successColor,
              () {
                Navigator.pushNamed(context, '/student/placements');
              },
              100,
            ),
            _buildActionCard(
              context,
              "Marketplace",
              Icons.store,
              AppTheme.warningColor,
              () {
                Navigator.pushNamed(context, '/student/marketplace');
              },
              150,
            ),
            _buildActionCard(
              context,
              "Clubs",
              Icons.group,
              AppTheme.primaryColor,
              () {
                Navigator.pushNamed(context, '/student/clubs');
              },
              200,
            ),
            _buildActionCard(
              context,
              "Alumni",
              Icons.school,
              AppTheme.accentColor,
              () {
                Navigator.pushNamed(context, '/student/alumni');
              },
              250,
            ),
            _buildActionCard(
              context,
              "Career Guide",
              Icons.trending_up,
              AppTheme.successColor,
              () {
                Navigator.pushNamed(context, '/student/career-guidance');
              },
              300,
            ),
            _buildActionCard(
              context,
              "Peer Groups",
              Icons.people,
              AppTheme.warningColor,
              () {
                Navigator.pushNamed(context, '/student/peer-groups');
              },
              350,
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
    int animationDelay,
  ) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: AppAnimations.normalDuration + Duration(milliseconds: animationDelay),
      curve: AppAnimations.defaultCurve,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - value)),
            child: Transform.scale(
              scale: 0.9 + (0.1 * value),
              child: child,
            ),
          ),
        );
      },
      child: CustomCard(
        onTap: onTap,
        padding: const EdgeInsets.all(AppTheme.spacingM),
        child: Column(
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: AppAnimations.slowDuration + Duration(milliseconds: animationDelay),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Transform.rotate(
                    angle: (1 - value) * 0.5,
                    child: child,
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      color.withOpacity(0.2),
                      color.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, color: color, size: 28),
              ),
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
