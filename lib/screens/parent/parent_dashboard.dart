import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../utils/app_theme.dart';
import '../../utils/responsive_helper.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/responsive_wrapper.dart';
import '../../models/student_model.dart';
import '../../models/notice_model.dart';
import '../../models/event_model.dart';

class ParentDashboard extends StatelessWidget {
  const ParentDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: ResponsiveWrapper(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(
              ResponsiveHelper.responsiveValue(
                context,
                mobile: AppTheme.spacingM,
                tablet: AppTheme.spacingL,
                desktop: AppTheme.spacingXL,
              ),
            ),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeHeader(user),
              const SizedBox(height: AppTheme.spacingL),
              _buildChildrenOverview(user?.uid ?? ''),
              const SizedBox(height: AppTheme.spacingL),
              _buildQuickActions(context),
              const SizedBox(height: AppTheme.spacingL),
              _buildRecentNotices(),
              const SizedBox(height: AppTheme.spacingL),
              _buildUpcomingEvents(),
              const SizedBox(height: AppTheme.spacingL),
              _buildChildEventParticipation(user?.uid ?? ''),
              const SizedBox(height: AppTheme.spacingL),
              _buildMentorInteractions(user?.uid ?? ''),
              const SizedBox(height: AppTheme.spacingL),
              _buildAttendanceAlert(),
              // Add bottom padding to prevent overflow
              SizedBox(
                height:
                    MediaQuery.of(context).padding.bottom + AppTheme.spacingXL,
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader(User? user) {
    return CustomCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.family_restroom,
              color: AppTheme.primaryColor,
              size: 32,
            ),
          ),
          const SizedBox(width: AppTheme.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Welcome, Parent",
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryTextColor,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingXS),
                Text(
                  "Monitor your child's academic progress",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppTheme.secondaryTextColor,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingS),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.successColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    DateFormat('EEEE, MMM dd, yyyy').format(DateTime.now()),
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppTheme.successColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.notifications_outlined,
            color: AppTheme.primaryColor,
            size: 24,
          ),
        ],
      ),
    );
  }

  Widget _buildChildrenOverview(String parentId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('students')
          .where('parentId', isEqualTo: parentId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingWidget(message: "Loading children data...");
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return CustomCard(
            child: Column(
              children: [
                const Icon(
                  Icons.family_restroom,
                  size: 64,
                  color: AppTheme.lightTextColor,
                ),
                const SizedBox(height: AppTheme.spacingM),
                Text(
                  "No Children Found",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryTextColor,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingS),
                Text(
                  "Please contact the administration to link your child's account.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppTheme.secondaryTextColor,
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "My Children",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryTextColor,
              ),
            ),
            const SizedBox(height: AppTheme.spacingM),
            ...snapshot.data!.docs.map((doc) {
              final student = StudentModel.fromMap(
                doc.data() as Map<String, dynamic>,
                doc.id,
              );
              return _buildChildCard(student);
            }).toList(),
          ],
        );
      },
    );
  }

  Widget _buildChildCard(StudentModel student) {
    return CustomCard(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundImage: student.avatarUrl != null
                ? NetworkImage(student.avatarUrl!)
                : null,
            backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
            child: student.avatarUrl == null
                ? Text(
                    student.name.isNotEmpty
                        ? student.name[0].toUpperCase()
                        : 'S',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
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
                  student.name,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryTextColor,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingXS),
                Text(
                  "${student.department} • ${student.semester}",
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppTheme.secondaryTextColor,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingS),
                Row(
                  children: [
                    _buildQuickStat(
                      "Attendance",
                      "${student.attendance.toStringAsFixed(1)}%",
                      student.attendance >= 75
                          ? AppTheme.successColor
                          : AppTheme.errorColor,
                    ),
                    const SizedBox(width: AppTheme.spacingM),
                    _buildQuickStat(
                      "GPA",
                      student.gpa.toStringAsFixed(2),
                      AppTheme.primaryColor,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: AppTheme.lightTextColor,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
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
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                "View Attendance",
                Icons.check_circle,
                AppTheme.successColor,
                () {
                  // Navigate to attendance reports
                },
              ),
            ),
            const SizedBox(width: AppTheme.spacingS),
            Expanded(
              child: _buildActionCard(
                "Academic Reports",
                Icons.assessment,
                AppTheme.primaryColor,
                () {
                  // Navigate to academic reports
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingS),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                "Contact Teacher",
                Icons.message,
                AppTheme.warningColor,
                () {
                  // Navigate to communication
                },
              ),
            ),
            const SizedBox(width: AppTheme.spacingS),
            Expanded(
              child: _buildActionCard(
                "Event Calendar",
                Icons.event,
                AppTheme.accentColor,
                () {
                  // Navigate to events
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return CustomCard(
      onTap: onTap,
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

  Widget _buildRecentNotices() {
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
                  fontSize: 12,
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
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const LoadingWidget(message: "Loading notices...");
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              print('DEBUG PARENT: No notices found in Firestore');
              return const EmptyStateWidget(
                title: "No recent notices",
                subtitle: "Check back later for updates",
                icon: Icons.campaign,
              );
            }

            print(
              'DEBUG PARENT: Found ${snapshot.data!.docs.length} notices in Firestore',
            );

            // Filter notices by target audience and limit to 3
            final filteredNotices = snapshot.data!.docs
                .where((doc) {
                  final notice = NoticeModel.fromMap(
                    doc.data() as Map<String, dynamic>,
                    doc.id,
                  );

                  // Debug logging
                  print(
                    'DEBUG PARENT: Notice - Title: ${notice.title}, Author: ${notice.authorName}, Target: ${notice.targetAudience}',
                  );

                  // Show notices that are either for 'All' or specifically for 'Parent'
                  final shouldShow =
                      notice.targetAudience.isEmpty ||
                      notice.targetAudience.contains('All') ||
                      notice.targetAudience.contains('Parent');

                  print(
                    'DEBUG PARENT: Should show notice "${notice.title}": $shouldShow',
                  );
                  return shouldShow;
                })
                .take(3)
                .toList();

            print(
              'DEBUG PARENT: After filtering, ${filteredNotices.length} notices remain',
            );

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
                return _buildNoticeItem(notice);
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildNoticeItem(NoticeModel notice) {
    return CustomCard(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingS),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getPriorityColor(notice.priority).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.campaign,
              color: _getPriorityColor(notice.priority),
              size: 16,
            ),
          ),
          const SizedBox(width: AppTheme.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notice.title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryTextColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppTheme.spacingXS),
                Text(
                  notice.description,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppTheme.secondaryTextColor,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppTheme.spacingXS),
                Text(
                  DateFormat('MMM dd, yyyy').format(notice.createdAt),
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: AppTheme.lightTextColor,
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
                  fontSize: 12,
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
              .where('startDate', isGreaterThan: Timestamp.now())
              .where('isActive', isEqualTo: true)
              .orderBy('startDate')
              .limit(3)
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
                return _buildEventItem(event);
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildChildEventParticipation(String parentId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('students')
          .where('parentId', isEqualTo: parentId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingWidget(message: "Loading participation...");
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }

        final childIds = snapshot.data!.docs.map((d) => d.id).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Event Participation",
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryTextColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingM),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('events')
                  .where('registeredStudents', arrayContainsAny: childIds)
                  .orderBy('startDate', descending: true)
                  .limit(5)
                  .snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const LoadingWidget();
                }
                if (!snap.hasData || snap.data!.docs.isEmpty) {
                  return const EmptyStateWidget(
                    title: "No participation yet",
                    subtitle:
                        "Your child’s event participation will appear here",
                    icon: Icons.event_available,
                  );
                }
                return Column(
                  children: snap.data!.docs.map((d) {
                    final event = EventModel.fromMap(
                      d.data() as Map<String, dynamic>,
                      d.id,
                    );
                    return _buildEventItem(event);
                  }).toList(),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildMentorInteractions(String parentId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('students')
          .where('parentId', isEqualTo: parentId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingWidget(message: "Loading mentor interactions...");
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }
        final childIds = snapshot.data!.docs.map((d) => d.id).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Mentor Interactions",
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryTextColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingM),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('mentor_sessions')
                  .where(
                    'studentId',
                    whereIn: childIds.length > 10
                        ? childIds.sublist(0, 10)
                        : childIds,
                  )
                  .orderBy('scheduledDate', descending: true)
                  .limit(5)
                  .snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const LoadingWidget();
                }
                if (!snap.hasData || snap.data!.docs.isEmpty) {
                  return const EmptyStateWidget(
                    title: "No interactions yet",
                    subtitle: "Mentoring sessions will appear here",
                    icon: Icons.forum,
                  );
                }
                return Column(
                  children: snap.data!.docs.map((d) {
                    final data = d.data() as Map<String, dynamic>;
                    return CustomCard(
                      margin: const EdgeInsets.only(bottom: AppTheme.spacingS),
                      child: ListTile(
                        leading: const Icon(
                          Icons.event_note,
                          color: AppTheme.primaryColor,
                        ),
                        title: Text(
                          data['title'] ?? 'Mentor Session',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          DateFormat('MMM dd, yyyy • hh:mm a').format(
                            DateTime.fromMillisecondsSinceEpoch(
                              (data['scheduledDate'] ?? 0) as int,
                            ),
                          ),
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppTheme.secondaryTextColor,
                          ),
                        ),
                        trailing: Text(
                          data['status'] ?? 'Scheduled',
                          style: GoogleFonts.poppins(fontSize: 12),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildEventItem(EventModel event) {
    return CustomCard(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingS),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.event,
              color: AppTheme.primaryColor,
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppTheme.spacingXS),
                Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 12,
                      color: AppTheme.secondaryTextColor,
                    ),
                    const SizedBox(width: AppTheme.spacingXS),
                    Text(
                      DateFormat('MMM dd, yyyy').format(event.startDate),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppTheme.secondaryTextColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingXS),
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 12,
                      color: AppTheme.secondaryTextColor,
                    ),
                    const SizedBox(width: AppTheme.spacingXS),
                    Expanded(
                      child: Text(
                        event.location,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppTheme.secondaryTextColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceAlert() {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.warningColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.warning,
                  color: AppTheme.warningColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Attendance Alert",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryTextColor,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingXS),
                    Text(
                      "Monitor your child's attendance regularly to ensure academic success.",
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
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // Navigate to attendance reports
                  },
                  icon: const Icon(Icons.assessment, size: 16),
                  label: Text(
                    "View Reports",
                    style: GoogleFonts.poppins(fontSize: 12),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                    side: const BorderSide(color: AppTheme.primaryColor),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.spacingS),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Navigate to communication
                  },
                  icon: const Icon(Icons.message, size: 16),
                  label: Text(
                    "Contact Teacher",
                    style: GoogleFonts.poppins(fontSize: 12),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'High':
        return AppTheme.errorColor;
      case 'Medium':
        return AppTheme.warningColor;
      case 'Low':
        return AppTheme.successColor;
      default:
        return AppTheme.secondaryTextColor;
    }
  }
}
