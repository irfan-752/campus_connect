import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:campus_connect/utils/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  late String currentUserId;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    currentUserId = _auth.currentUser?.uid ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isPortrait = size.height > size.width;
    final isMobile = size.width < 600;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Campus Connect',
          style: GoogleFonts.poppins(
            fontSize: isMobile ? 18 : 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.notifications), onPressed: () {}),
          IconButton(icon: const Icon(Icons.menu), onPressed: () {}),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore
            .collection('students')
            .doc(currentUserId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final student = snapshot.data?.data() as Map<String, dynamic>? ?? {};
          final name = student['name'] ?? 'Student';
          final avatarUrl = student['avatarUrl'];
          final attendance = (student['attendance'] ?? 0).toStringAsFixed(1);
          final gpa = (student['gpa'] ?? 0).toStringAsFixed(2);
          final events = student['eventsParticipated'] ?? 0;
          final coursesCount = (student['courses'] as List?)?.length ?? 0;

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 16 : 24,
              vertical: isMobile ? 12 : 16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Header
                _buildProfileHeader(size, isMobile, name, avatarUrl),
                SizedBox(height: isMobile ? 20 : 28),

                // Stats Cards
                _buildStatsSection(
                  size,
                  isMobile,
                  attendance,
                  gpa,
                  events,
                  coursesCount,
                ),
                SizedBox(height: isMobile ? 20 : 28),

                // Today's Schedule
                _buildSectionTitle(isMobile, "Today's Schedule"),
                _buildScheduleSection(size, isMobile),
                SizedBox(height: isMobile ? 20 : 28),

                // Recent Notices
                _buildSectionTitle(isMobile, "Recent Notices"),
                _buildNoticesSection(size, isMobile),
                SizedBox(height: isMobile ? 20 : 28),

                // Course Progress
                _buildSectionTitle(isMobile, "Course Progress"),
                _buildCourseProgressSection(size, isMobile, student),
                SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(
    Size size,
    bool isMobile,
    String name,
    String? avatarUrl,
  ) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: isMobile ? 32 : 40,
            backgroundImage: avatarUrl != null
                ? NetworkImage(avatarUrl)
                : AssetImage('assets/images/student_avatar.png')
                      as ImageProvider,
            child: avatarUrl == null
                ? Icon(
                    Icons.person,
                    size: isMobile ? 32 : 40,
                    color: AppTheme.primaryColor,
                  )
                : null,
          ),
          SizedBox(width: isMobile ? 12 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back,',
                  style: GoogleFonts.poppins(
                    fontSize: isMobile ? 12 : 14,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  name,
                  style: GoogleFonts.poppins(
                    fontSize: isMobile ? 18 : 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryTextColor,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(
    Size size,
    bool isMobile,
    String attendance,
    String gpa,
    int events,
    int coursesCount,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = isMobile ? 2 : 4;
        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: isMobile ? 12 : 16,
          crossAxisSpacing: isMobile ? 12 : 16,
          childAspectRatio: 1.1,
          children: [
            _buildStatCard(
              isMobile,
              Icons.check_circle,
              'Attendance',
              '$attendance%',
              Colors.blue,
            ),
            _buildStatCard(isMobile, Icons.grade, 'GPA', gpa, Colors.orange),
            _buildStatCard(
              isMobile,
              Icons.event,
              'Events',
              '$events',
              Colors.purple,
            ),
            _buildStatCard(
              isMobile,
              Icons.book,
              'Courses',
              '$coursesCount',
              Colors.green,
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(
    bool isMobile,
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 10 : 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: isMobile ? 28 : 32),
          SizedBox(height: isMobile ? 6 : 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: isMobile ? 16 : 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: isMobile ? 2 : 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: isMobile ? 10 : 12,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(bool isMobile, String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: isMobile ? 8 : 12),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: isMobile ? 14 : 16,
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryTextColor,
        ),
      ),
    );
  }

  Widget _buildScheduleSection(Size size, bool isMobile) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('schedule')
          .where('studentId', isEqualTo: currentUserId)
          .orderBy('time')
          .limit(3)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return SizedBox(
            height: 150,
            child: Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            ),
          );
        }

        final schedules = snapshot.data!.docs;
        if (schedules.isEmpty) {
          return Container(
            padding: EdgeInsets.all(isMobile ? 12 : 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'No classes scheduled for today',
              style: GoogleFonts.poppins(color: Colors.grey),
            ),
          );
        }

        return Column(
          children: schedules.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return _buildScheduleCard(isMobile, data);
          }).toList(),
        );
      },
    );
  }

  Widget _buildScheduleCard(bool isMobile, Map<String, dynamic> data) {
    return Container(
      margin: EdgeInsets.only(bottom: isMobile ? 8 : 12),
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryColor, width: 4),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isMobile ? 8 : 12),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.schedule,
              color: AppTheme.primaryColor,
              size: isMobile ? 20 : 24,
            ),
          ),
          SizedBox(width: isMobile ? 12 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['subject'] ?? 'Class',
                  style: GoogleFonts.poppins(
                    fontSize: isMobile ? 14 : 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '${data['time'] ?? ''} • ${data['location'] ?? 'TBA'}',
                  style: GoogleFonts.poppins(
                    fontSize: isMobile ? 12 : 13,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoticesSection(Size size, bool isMobile) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('notices')
          .orderBy('date', descending: true)
          .limit(3)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return SizedBox(
            height: 150,
            child: Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            ),
          );
        }

        final notices = snapshot.data!.docs;
        if (notices.isEmpty) {
          return Container(
            padding: EdgeInsets.all(isMobile ? 12 : 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'No notices yet',
              style: GoogleFonts.poppins(color: Colors.grey),
            ),
          );
        }

        return Column(
          children: notices.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return _buildNoticeCard(isMobile, data);
          }).toList(),
        );
      },
    );
  }

  Widget _buildNoticeCard(bool isMobile, Map<String, dynamic> data) {
    return Container(
      margin: EdgeInsets.only(bottom: isMobile ? 8 : 12),
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isMobile ? 8 : 12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.campaign,
              color: Colors.blue,
              size: isMobile ? 20 : 24,
            ),
          ),
          SizedBox(width: isMobile ? 12 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['title'] ?? 'Notice',
                  style: GoogleFonts.poppins(
                    fontSize: isMobile ? 14 : 16,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4),
                Text(
                  data['description'] ?? '',
                  style: GoogleFonts.poppins(
                    fontSize: isMobile ? 12 : 13,
                    color: Colors.grey,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseProgressSection(
    Size size,
    bool isMobile,
    Map<String, dynamic> student,
  ) {
    final courses = student['courses'] as List? ?? [];
    if (courses.isEmpty) {
      return Container(
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'No courses enrolled',
          style: GoogleFonts.poppins(color: Colors.grey),
        ),
      );
    }

    return Column(
      children: List.generate(
        courses.length.clamp(0, 3),
        (index) => _buildCourseProgressCard(
          isMobile,
          courses[index] as Map<String, dynamic>? ?? {},
        ),
      ),
    );
  }

  Widget _buildCourseProgressCard(bool isMobile, Map<String, dynamic> course) {
    final progress = ((course['progress'] ?? 0) as num).toDouble();
    final courseName = course['name'] ?? 'Course ${course['id'] ?? ''}';

    return Container(
      margin: EdgeInsets.only(bottom: isMobile ? 12 : 16),
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  courseName,
                  style: GoogleFonts.poppins(
                    fontSize: isMobile ? 14 : 16,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${progress.toStringAsFixed(0)}%',
                style: GoogleFonts.poppins(
                  fontSize: isMobile ? 12 : 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 8 : 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress / 100,
              minHeight: isMobile ? 6 : 8,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            ),
          ),
        ],
      ),
    );
  }
}

extension BorderSideExt on Border {
  static Border l({required Color color, required double width}) {
    return Border(
      left: BorderSide(color: color, width: width),
    );
  }
}
