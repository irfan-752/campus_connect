import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/student/student_main_screen.dart';

class StudentHomeScreen extends StatelessWidget {
  const StudentHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const StudentMainScreen();
  }
}

class OldStudentHomeScreen extends StatelessWidget {
  const OldStudentHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('students')
              .doc(user?.uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final student =
                snapshot.data!.data() as Map<String, dynamic>? ?? {};
            final name = student['name'] ?? 'Student';
            final avatarUrl = student['avatarUrl'];
            final attendance = student['attendance'] ?? 'N/A';
            final gpa = student['gpa'] ?? 'N/A';
            final events = student['events'] ?? 0;
            final coursesCount = student['coursesCount'] ?? 0;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Bar
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundImage: avatarUrl != null
                            ? NetworkImage(avatarUrl)
                            : const AssetImage(
                                    'assets/images/student_avatar.png',
                                  )
                                  as ImageProvider,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Campus Connect",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            Text(
                              name,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: const Icon(Icons.notifications),
                        onPressed: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Quick Stats
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _StatCard(
                        "Attendance",
                        "$attendance%",
                        Icons.check_circle,
                        Colors.blue,
                      ),
                      _StatCard("GPA", "$gpa", Icons.grade, Colors.orange),
                      _StatCard(
                        "Events",
                        "$events",
                        Icons.event,
                        Colors.purple,
                      ),
                      _StatCard(
                        "Courses",
                        "$coursesCount",
                        Icons.book,
                        Colors.green,
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Today's Schedule
                  _SectionTitle("Today's Schedule"),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('schedule')
                        .where('studentId', isEqualTo: user?.uid)
                        .orderBy('time')
                        .snapshots(),
                    builder: (context, scheduleSnap) {
                      if (!scheduleSnap.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final schedule = scheduleSnap.data!.docs;
                      return Column(
                        children: schedule.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            child: ListTile(
                              leading: Text(
                                data['time'] ?? '',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              title: Text(data['subject'] ?? ''),
                              subtitle: Text(data['location'] ?? ''),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 18),

                  // Recent Notices
                  _SectionTitle("Recent Notice"),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('notices')
                        .orderBy('date', descending: true)
                        .limit(3)
                        .snapshots(),
                    builder: (context, noticeSnap) {
                      if (!noticeSnap.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final notices = noticeSnap.data!.docs;
                      return Column(
                        children: notices.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: ListTile(
                              leading: const Icon(
                                Icons.campaign,
                                color: Colors.blue,
                              ),
                              title: Text(data['title'] ?? ''),
                              subtitle: Text(data['description'] ?? ''),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 18),

                  // Course Progress
                  _SectionTitle("Course progress"),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('courses')
                        .where('studentId', isEqualTo: user?.uid)
                        .snapshots(),
                    builder: (context, courseSnap) {
                      if (!courseSnap.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final courses = courseSnap.data!.docs;
                      return Column(
                        children: courses.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final progress = (data['progress'] ?? 0).toDouble();
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data['name'] ?? '',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                LinearProgressIndicator(
                                  value: progress / 100,
                                  minHeight: 8,
                                  backgroundColor: Colors.grey[300],
                                  color: Colors.blue,
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }
}
