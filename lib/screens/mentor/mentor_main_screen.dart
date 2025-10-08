import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/app_theme.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/responsive_wrapper.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/empty_state_widget.dart';
import '../../models/notice_model.dart';
import '../../models/mentor_model.dart';
import 'mentor_student_attendance.dart';
import 'mentor_chat.dart';
import '../../services/cloudinary_service.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

class MentorHomeScreen extends StatefulWidget {
  const MentorHomeScreen({super.key});

  @override
  State<MentorHomeScreen> createState() => _MentorHomeScreenState();
}

class _MentorHomeScreenState extends State<MentorHomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  TabController get tabController => _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _logout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Logout',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _showProfileDialog(BuildContext context) {
    showDialog(context: context, builder: (context) => _MentorProfileDialog());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Mentor Panel',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.primaryTextColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => _showProfileDialog(context),
            tooltip: 'Profile',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
            tooltip: 'Logout',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.secondaryTextColor,
          tabs: const [
            Tab(text: 'Dashboard'),
            Tab(text: 'Notices'),
            Tab(text: 'Sessions'),
            Tab(text: 'Students'),
            Tab(text: 'Attendance'),
            Tab(text: 'Chat'),
          ],
        ),
      ),
      body: ResponsiveWrapper(
        child: TabBarView(
          controller: _tabController,
          children: const [
            _MentorDashboardTab(),
            _MentorNoticesTab(),
            _MentorSessionsTab(),
            _MentorStudentsTab(),
            _MentorAttendanceTab(),
            MentorChatScreen(),
          ],
        ),
      ),
    );
  }
}

class _MentorDashboardTab extends StatefulWidget {
  const _MentorDashboardTab();

  @override
  State<_MentorDashboardTab> createState() => _MentorDashboardTabState();
}

class _MentorDashboardTabState extends State<_MentorDashboardTab> {
  String? _teacherName;
  String? _department;
  String? _semester;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTeacherProfile();
  }

  Future<void> _loadTeacherProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('mentors')
          .where('userId', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (doc.docs.isNotEmpty) {
        final data = doc.docs.first.data();
        setState(() {
          _teacherName = data['name'] ?? 'Teacher';
          _department = data['department'] ?? '';
          _semester = data['semester'] ?? '';
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      children: [
        // Welcome Card
        CustomCard(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                      child: Icon(
                        Icons.person,
                        size: 30,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingM),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome back,',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: AppTheme.secondaryTextColor,
                            ),
                          ),
                          Text(
                            _teacherName ?? 'Teacher',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryTextColor,
                            ),
                          ),
                          if (_department != null && _semester != null)
                            Text(
                              '$_department • Semester $_semester',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: AppTheme.secondaryTextColor,
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => _showProfileDialog(context),
                      icon: const Icon(Icons.settings),
                      tooltip: 'Profile Settings',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: AppTheme.spacingM),

        // Quick Actions
        Text(
          'Quick Actions',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryTextColor,
          ),
        ),
        const SizedBox(height: AppTheme.spacingM),

        // Action Cards
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                context,
                'Profile Settings',
                Icons.person,
                AppTheme.primaryColor,
                () => _showProfileDialog(context),
              ),
            ),
            const SizedBox(width: AppTheme.spacingM),
            Expanded(
              child: _buildActionCard(
                context,
                'My Students',
                Icons.people,
                AppTheme.successColor,
                () => _navigateToStudents(),
              ),
            ),
          ],
        ),

        const SizedBox(height: AppTheme.spacingM),

        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                context,
                'Mark Attendance',
                Icons.check_circle,
                AppTheme.warningColor,
                () => _navigateToAttendance(),
              ),
            ),
            const SizedBox(width: AppTheme.spacingM),
            Expanded(
              child: _buildActionCard(
                context,
                'Chat with Students',
                Icons.chat,
                AppTheme.accentColor,
                () => _navigateToChat(),
              ),
            ),
          ],
        ),

        const SizedBox(height: AppTheme.spacingL),

        // Recent Activity
        Text(
          'Recent Activity',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryTextColor,
          ),
        ),
        const SizedBox(height: AppTheme.spacingM),

        CustomCard(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            child: Column(
              children: [
                ListTile(
                  leading: Icon(
                    Icons.notifications,
                    color: AppTheme.primaryColor,
                  ),
                  title: Text(
                    'Profile Setup',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    'Complete your profile to get started',
                    style: GoogleFonts.poppins(fontSize: 12),
                  ),
                  trailing: TextButton(
                    onPressed: () => _showProfileDialog(context),
                    child: const Text('Setup'),
                  ),
                ),
              ],
            ),
          ),
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
    return GestureDetector(
      onTap: onTap,
      child: CustomCard(
        child: Padding(
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
        ),
      ),
    );
  }

  void _showProfileDialog(BuildContext context) {
    showDialog(context: context, builder: (context) => _MentorProfileDialog());
  }

  void _navigateToStudents() {
    // Navigate to students tab
    final mentorHomeScreen = context
        .findAncestorStateOfType<_MentorHomeScreenState>();
    mentorHomeScreen?.tabController.animateTo(3);
  }

  void _navigateToAttendance() {
    // Navigate to attendance tab
    final mentorHomeScreen = context
        .findAncestorStateOfType<_MentorHomeScreenState>();
    mentorHomeScreen?.tabController.animateTo(4);
  }

  void _navigateToChat() {
    // Navigate to chat tab
    final mentorHomeScreen = context
        .findAncestorStateOfType<_MentorHomeScreenState>();
    mentorHomeScreen?.tabController.animateTo(5);
  }
}

class _MentorNoticesTab extends StatelessWidget {
  const _MentorNoticesTab();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('Not authenticated'));
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppTheme.spacingM),
          child: Row(
            children: [
              Text(
                'My Notices',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _showCreateNoticeDialog(context),
                icon: const Icon(Icons.add),
                label: const Text('New Notice'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('notices')
                .where('isActive', isEqualTo: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const LoadingWidget(message: 'Loading notices...');
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                print('DEBUG TEACHER: No notices found in Firestore');
                return const EmptyStateWidget(
                  title: 'No notices yet',
                  subtitle: 'Create your first notice',
                  icon: Icons.campaign,
                );
              }

              print(
                'DEBUG TEACHER: Found ${snapshot.data!.docs.length} notices in Firestore',
              );

              // Filter notices by target audience
              final filteredNotices = snapshot.data!.docs.where((doc) {
                final notice = NoticeModel.fromMap(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                );

                // Debug logging
                print(
                  'DEBUG: Notice - Title: ${notice.title}, Author: ${notice.authorName}, Target: ${notice.targetAudience}',
                );

                // Show notices that are either for 'All' or specifically for 'Teacher'
                final shouldShow =
                    notice.targetAudience.isEmpty ||
                    notice.targetAudience.contains('All') ||
                    notice.targetAudience.contains('Teacher');

                print(
                  'DEBUG: Should show notice "${notice.title}": $shouldShow',
                );
                return shouldShow;
              }).toList();

              print(
                'DEBUG TEACHER: After filtering, ${filteredNotices.length} notices remain',
              );

              if (filteredNotices.isEmpty) {
                return const EmptyStateWidget(
                  title: 'No notices yet',
                  subtitle: 'Create your first notice',
                  icon: Icons.campaign,
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(AppTheme.spacingM),
                itemCount: filteredNotices.length,
                itemBuilder: (context, index) {
                  final doc = filteredNotices[index];
                  final notice = NoticeModel.fromMap(
                    doc.data() as Map<String, dynamic>,
                    doc.id,
                  );
                  return _NoticeItem(notice: notice);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _showCreateNoticeDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final linkController = TextEditingController();
    String priority = 'Medium';
    String category = 'General';
    List<String> audience = ['Teacher'];
    File? attachment;
    String attachmentType = 'none'; // 'none', 'image', 'pdf', 'link'
    String? attachmentName;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) => AlertDialog(
            title: Text(
              'Create Notice',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(hintText: 'Title'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: descriptionController,
                    maxLines: 4,
                    decoration: const InputDecoration(hintText: 'Description'),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: priority,
                          items: const [
                            DropdownMenuItem(
                              value: 'High',
                              child: Text('High'),
                            ),
                            DropdownMenuItem(
                              value: 'Medium',
                              child: Text('Medium'),
                            ),
                            DropdownMenuItem(value: 'Low', child: Text('Low')),
                          ],
                          onChanged: (v) =>
                              setState(() => priority = v ?? 'Medium'),
                          decoration: const InputDecoration(
                            labelText: 'Priority',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: category,
                          items: const [
                            DropdownMenuItem(
                              value: 'General',
                              child: Text('General'),
                            ),
                            DropdownMenuItem(
                              value: 'Academic',
                              child: Text('Academic'),
                            ),
                            DropdownMenuItem(
                              value: 'Event',
                              child: Text('Event'),
                            ),
                            DropdownMenuItem(
                              value: 'Administrative',
                              child: Text('Administrative'),
                            ),
                          ],
                          onChanged: (v) =>
                              setState(() => category = v ?? 'General'),
                          decoration: const InputDecoration(
                            labelText: 'Category',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      spacing: 8,
                      children: [
                        FilterChip(
                          label: const Text('Student'),
                          selected: audience.contains('Student'),
                          onSelected: (s) {
                            setState(() {
                              if (s) {
                                audience.add('Student');
                              } else {
                                audience.remove('Student');
                              }
                            });
                          },
                        ),
                        FilterChip(
                          label: const Text('Parent'),
                          selected: audience.contains('Parent'),
                          onSelected: (s) {
                            setState(() {
                              if (s) {
                                audience.add('Parent');
                              } else {
                                audience.remove('Parent');
                              }
                            });
                          },
                        ),
                        FilterChip(
                          label: const Text('Mentor'),
                          selected: audience.contains('Teacher'),
                          onSelected: (s) {
                            setState(() {
                              if (s) {
                                audience.add('Teacher');
                              } else {
                                audience.remove('Teacher');
                              }
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Attachment Type Selection
                  DropdownButtonFormField<String>(
                    value: attachmentType,
                    decoration: const InputDecoration(
                      labelText: 'Attachment Type',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'none',
                        child: Text('No Attachment'),
                      ),
                      DropdownMenuItem(value: 'image', child: Text('Image')),
                      DropdownMenuItem(
                        value: 'pdf',
                        child: Text('PDF Document'),
                      ),
                      DropdownMenuItem(
                        value: 'link',
                        child: Text('External Link'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        attachmentType = value ?? 'none';
                        attachment = null;
                        attachmentName = null;
                        linkController.clear();
                      });
                    },
                  ),

                  // Attachment Content based on type
                  if (attachmentType == 'image') ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            attachment == null
                                ? 'No image selected'
                                : attachment!.path.split('/').last,
                            style: GoogleFonts.poppins(fontSize: 12),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () async {
                            final picker = ImagePicker();
                            final picked = await picker.pickImage(
                              source: ImageSource.gallery,
                            );
                            if (picked != null) {
                              setState(() {
                                attachment = File(picked.path);
                                attachmentName = picked.path.split('/').last;
                              });
                            }
                          },
                          icon: const Icon(Icons.image),
                          label: const Text('Select Image'),
                        ),
                      ],
                    ),
                  ],

                  if (attachmentType == 'pdf') ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            attachment == null
                                ? 'No PDF selected'
                                : attachment!.path.split('/').last,
                            style: GoogleFonts.poppins(fontSize: 12),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () async {
                            final picker = ImagePicker();
                            final picked = await picker.pickImage(
                              source: ImageSource.gallery,
                            );
                            if (picked != null) {
                              setState(() {
                                attachment = File(picked.path);
                                attachmentName = picked.path.split('/').last;
                              });
                            }
                          },
                          icon: const Icon(Icons.picture_as_pdf),
                          label: const Text('Select PDF'),
                        ),
                      ],
                    ),
                  ],

                  if (attachmentType == 'link') ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: linkController,
                      decoration: const InputDecoration(
                        labelText: 'External Link',
                        hintText: 'https://example.com',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.url,
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final user = FirebaseAuth.instance.currentUser!;
                  final now = DateTime.now();
                  String? attachmentUrl;
                  String? finalAttachmentType;
                  String? finalAttachmentName;

                  if (attachmentType != 'none') {
                    if (attachmentType == 'link') {
                      attachmentUrl = linkController.text.trim();
                      finalAttachmentType = 'link';
                      finalAttachmentName = 'External Link';
                    } else if (attachment != null) {
                      attachmentUrl = await CloudinaryService.uploadImageFile(
                        attachment!,
                        folder: 'notice_attachments',
                      );
                      finalAttachmentType = attachmentType;
                      finalAttachmentName = attachmentName;
                    }
                  }

                  final notice = NoticeModel(
                    id: '',
                    title: titleController.text.trim(),
                    description: descriptionController.text.trim(),
                    authorId: user.uid,
                    authorName: user.displayName ?? 'Mentor',
                    priority: priority,
                    category: category,
                    targetAudience: audience.isNotEmpty
                        ? audience
                        : ['Teacher'],
                    attachmentUrl: attachmentUrl,
                    attachmentType: finalAttachmentType,
                    attachmentName: finalAttachmentName,
                    isActive: true,
                    createdAt: now,
                    updatedAt: now,
                    readBy: const [],
                  );
                  await FirebaseFirestore.instance
                      .collection('notices')
                      .add(notice.toMap());
                  // ignore: use_build_context_synchronously
                  Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Publish'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MentorSessionsTab extends StatelessWidget {
  const _MentorSessionsTab();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('Not authenticated'));
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppTheme.spacingM),
          child: Row(
            children: [
              Text(
                'Mentor Sessions',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _showCreateSessionDialog(context),
                icon: const Icon(Icons.add),
                label: const Text('New Session'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('mentor_sessions')
                .where('mentorId', isEqualTo: user.uid)
                .orderBy('scheduledDate', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const LoadingWidget(message: 'Loading sessions...');
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const EmptyStateWidget(
                  title: 'No sessions scheduled',
                  subtitle: 'Create your first mentoring session',
                  icon: Icons.schedule,
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(AppTheme.spacingM),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final data =
                      snapshot.data!.docs[index].data() as Map<String, dynamic>;
                  final session = MentorSession.fromMap(
                    data,
                    snapshot.data!.docs[index].id,
                  );
                  return CustomCard(
                    child: ListTile(
                      leading: const Icon(
                        Icons.event_available,
                        color: AppTheme.primaryColor,
                      ),
                      title: Text(
                        session.title,
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        '${DateTime.fromMillisecondsSinceEpoch(data['scheduledDate']).toLocal()} • ${session.durationMinutes} mins',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppTheme.secondaryTextColor,
                        ),
                      ),
                      trailing: Text(
                        session.status,
                        style: GoogleFonts.poppins(fontSize: 12),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _showCreateSessionDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    DateTime scheduled = DateTime.now().add(const Duration(days: 1));
    int duration = 60;
    String studentId = '';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Schedule Session',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(hintText: 'Title'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(hintText: 'Description'),
              ),
              const SizedBox(height: 8),
              TextField(
                decoration: const InputDecoration(hintText: 'Student ID'),
                onChanged: (v) => studentId = v,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: scheduled,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                        );
                        if (picked != null) {
                          final time = await showTimePicker(
                            context: ctx,
                            initialTime: TimeOfDay.fromDateTime(scheduled),
                          );
                          if (time != null) {
                            scheduled = DateTime(
                              picked.year,
                              picked.month,
                              picked.day,
                              time.hour,
                              time.minute,
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.calendar_month),
                      label: const Text('Pick Date & Time'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 100,
                    child: TextFormField(
                      initialValue: '$duration',
                      decoration: const InputDecoration(labelText: 'Mins'),
                      keyboardType: TextInputType.number,
                      onChanged: (v) => duration = int.tryParse(v) ?? 60,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final user = FirebaseAuth.instance.currentUser!;
              final session = MentorSession(
                id: '',
                mentorId: user.uid,
                studentId: studentId,
                title: titleController.text.trim(),
                description: descriptionController.text.trim(),
                scheduledDate: scheduled,
                durationMinutes: duration,
                status: 'Scheduled',
                createdAt: DateTime.now(),
              );
              await FirebaseFirestore.instance
                  .collection('mentor_sessions')
                  .add(session.toMap());
              // ignore: use_build_context_synchronously
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _MentorStudentsTab extends StatefulWidget {
  const _MentorStudentsTab();

  @override
  State<_MentorStudentsTab> createState() => _MentorStudentsTabState();
}

class _MentorStudentsTabState extends State<_MentorStudentsTab> {
  String? _teacherDepartment;
  String? _teacherSemester;

  @override
  void initState() {
    super.initState();
    _loadTeacherProfile();
  }

  Future<void> _loadTeacherProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('mentors')
          .where('userId', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (doc.docs.isNotEmpty) {
        final data = doc.docs.first.data();
        setState(() {
          _teacherDepartment = data['department'];
          _teacherSemester = data['semester'];
        });
      }
    } catch (e) {
      print('Error loading teacher profile: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('Not authenticated'));
    }

    if (_teacherDepartment == null || _teacherSemester == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading teacher profile...'),
          ],
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('students')
          .where('department', isEqualTo: _teacherDepartment)
          .where('semester', isEqualTo: _teacherSemester)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingWidget(message: 'Loading students...');
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppTheme.spacingM),
                child: Row(
                  children: [
                    Text(
                      'My Students',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
              ),
              const Expanded(
                child: EmptyStateWidget(
                  title: 'No students found',
                  subtitle: 'No students in your department and semester',
                  icon: Icons.people,
                ),
              ),
            ],
          );
        }
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacingM),
              child: Row(
                children: [
                  Text(
                    'Students in $_teacherDepartment - Semester $_teacherSemester',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(AppTheme.spacingM),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final data =
                      snapshot.data!.docs[index].data() as Map<String, dynamic>;
                  return CustomCard(
                    child: ListTile(
                      leading: const Icon(
                        Icons.person,
                        color: AppTheme.primaryColor,
                      ),
                      title: Text(
                        data['name'] ?? 'Student',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        '${data['department'] ?? ''} • ${data['semester'] ?? ''}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppTheme.secondaryTextColor,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chat),
                            onPressed: () => _startChatWithStudent(
                              context,
                              snapshot.data!.docs[index].id,
                              data['name'] ?? 'Student',
                            ),
                            tooltip: 'Chat',
                          ),
                          const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: AppTheme.lightTextColor,
                          ),
                        ],
                      ),
                      onTap: () {
                        final id = snapshot.data!.docs[index].id;
                        final name = data['name'] ?? 'Student';
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MentorStudentAttendanceScreen(
                              studentId: id,
                              studentName: name,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  void _startChatWithStudent(
    BuildContext context,
    String studentId,
    String studentName,
  ) {
    // Navigate to chat with student
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            _MentorChatScreen(studentId: studentId, studentName: studentName),
      ),
    );
  }
}

class _NoticeItem extends StatelessWidget {
  final NoticeModel notice;
  const _NoticeItem({required this.notice});

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingS),
      child: ListTile(
        leading: Icon(Icons.campaign, color: _colorByPriority(notice.priority)),
        title: Text(
          notice.title,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notice.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(fontSize: 12),
            ),
            if (notice.attachmentUrl != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    _getAttachmentIcon(notice.attachmentType),
                    size: 16,
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    notice.attachmentName ?? 'Attachment',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        trailing: Text(
          notice.priority,
          style: GoogleFonts.poppins(fontSize: 12),
        ),
        onTap: () => _showNoticeDetails(context, notice),
      ),
    );
  }

  Color _colorByPriority(String p) {
    switch (p.toLowerCase()) {
      case 'high':
        return AppTheme.errorColor;
      case 'low':
        return AppTheme.successColor;
      default:
        return AppTheme.warningColor;
    }
  }

  IconData _getAttachmentIcon(String? attachmentType) {
    switch (attachmentType) {
      case 'image':
        return Icons.image;
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'link':
        return Icons.link;
      default:
        return Icons.attach_file;
    }
  }

  void _showNoticeDetails(BuildContext context, NoticeModel notice) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          notice.title,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                notice.description,
                style: GoogleFonts.poppins(fontSize: 14),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _colorByPriority(notice.priority).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      notice.priority,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: _colorByPriority(notice.priority),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
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
                      notice.category,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'By: ${notice.authorName}',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppTheme.secondaryTextColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Created: ${DateFormat('MMM dd, yyyy • hh:mm a').format(notice.createdAt)}',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppTheme.secondaryTextColor,
                ),
              ),
              if (notice.attachmentUrl != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.primaryColor),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _getAttachmentIcon(notice.attachmentType),
                        color: AppTheme.primaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              notice.attachmentName ?? 'Attachment',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryTextColor,
                              ),
                            ),
                            Text(
                              notice.attachmentType == 'link'
                                  ? 'External Link'
                                  : 'Tap to view',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: AppTheme.secondaryTextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.open_in_new,
                          color: AppTheme.primaryColor,
                        ),
                        onPressed: () => _openAttachment(notice.attachmentUrl!),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _openAttachment(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      // Handle error silently or show a snackbar
      print('Failed to open attachment: $e');
    }
  }
}

class _MentorProfileDialog extends StatefulWidget {
  @override
  _MentorProfileDialogState createState() => _MentorProfileDialogState();
}

class _MentorProfileDialogState extends State<_MentorProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _departmentController = TextEditingController();
  final _designationController = TextEditingController();
  final _specializationController = TextEditingController();
  final _experienceController = TextEditingController();
  final _qualificationController = TextEditingController();
  final _semesterController = TextEditingController();

  String? _avatarUrl;
  String? _idCardUrl;
  bool _isAvailable = true;
  bool _isLoading = false;
  bool _isEditing = false;
  File? _selectedImage;
  File? _selectedIdCard;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _departmentController.dispose();
    _designationController.dispose();
    _specializationController.dispose();
    _experienceController.dispose();
    _qualificationController.dispose();
    _semesterController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('mentors')
          .where('userId', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (doc.docs.isNotEmpty) {
        final data = doc.docs.first.data();
        setState(() {
          _nameController.text = data['name'] ?? '';
          _emailController.text = data['email'] ?? '';
          _departmentController.text = data['department'] ?? '';
          _designationController.text = data['designation'] ?? '';
          _specializationController.text = data['specialization'] ?? '';
          _experienceController.text = data['experience'] ?? '';
          _qualificationController.text = data['qualification'] ?? '';
          _semesterController.text = data['semester'] ?? '';
          _avatarUrl = data['avatarUrl'];
          _idCardUrl = data['idCardUrl'];
          _isAvailable = data['isAvailable'] ?? true;
        });
      }
    } catch (e) {
      print('Error loading profile: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.person, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Mentor Profile',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildProfileImage(),
                      const SizedBox(height: 20),
                      _buildTextField(
                        controller: _nameController,
                        label: 'Full Name',
                        hint: 'Enter your full name',
                        enabled: _isEditing,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _emailController,
                        label: 'Email',
                        hint: 'Enter your email',
                        enabled: false, // Email cannot be changed
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _departmentController,
                        label: 'Department',
                        hint: 'Enter your department',
                        enabled: _isEditing,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your department';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _designationController,
                        label: 'Designation',
                        hint: 'Enter your designation',
                        enabled: _isEditing,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your designation';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _specializationController,
                        label: 'Specialization',
                        hint: 'Enter your specialization',
                        enabled: _isEditing,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your specialization';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _experienceController,
                        label: 'Years of Experience',
                        hint: 'Enter years of experience',
                        enabled: _isEditing,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your experience';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _qualificationController,
                        label: 'Qualification',
                        hint: 'Enter your qualifications',
                        enabled: _isEditing,
                        maxLines: 2,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your qualifications';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _semesterController,
                        label: 'Semester',
                        hint: 'Enter semester (e.g., 1, 2, 3, 4)',
                        enabled: _isEditing,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your semester';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildIdCardSection(),
                      const SizedBox(height: 16),
                      _buildAvailabilityToggle(),
                      const SizedBox(height: 24),
                      _buildActionButtons(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileImage() {
    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
            backgroundImage: _selectedImage != null
                ? FileImage(_selectedImage!)
                : (_avatarUrl != null ? NetworkImage(_avatarUrl!) : null)
                      as ImageProvider?,
            child: _selectedImage == null && _avatarUrl == null
                ? Icon(Icons.person, size: 50, color: AppTheme.primaryColor)
                : null,
          ),
          if (_isEditing)
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: _pickImage,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool enabled = true,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.primaryTextColor,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          enabled: enabled,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          style: GoogleFonts.poppins(
            color: enabled
                ? AppTheme.primaryTextColor
                : AppTheme.secondaryTextColor,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(color: AppTheme.secondaryTextColor),
            filled: true,
            fillColor: enabled
                ? AppTheme.surfaceColor
                : AppTheme.surfaceColor.withOpacity(0.5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIdCardSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ID Card',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.primaryTextColor,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.dividerColor),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.credit_card, color: AppTheme.primaryColor, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedIdCard != null
                          ? _selectedIdCard!.path.split('/').last
                          : _idCardUrl != null
                          ? 'ID Card uploaded'
                          : 'No ID card uploaded',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.primaryTextColor,
                      ),
                    ),
                    if (_idCardUrl != null && _selectedIdCard == null)
                      Text(
                        'Tap to view current ID card',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: AppTheme.secondaryTextColor,
                        ),
                      ),
                  ],
                ),
              ),
              if (_isEditing)
                TextButton.icon(
                  onPressed: _pickIdCard,
                  icon: const Icon(Icons.upload, size: 16),
                  label: Text(
                    _selectedIdCard != null ? 'Change' : 'Upload',
                    style: GoogleFonts.poppins(fontSize: 12),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAvailabilityToggle() {
    return Row(
      children: [
        Text(
          'Available for Mentoring',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.primaryTextColor,
          ),
        ),
        const Spacer(),
        Switch(
          value: _isAvailable,
          onChanged: _isEditing
              ? (value) {
                  setState(() {
                    _isAvailable = value;
                  });
                }
              : null,
          activeColor: AppTheme.primaryColor,
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        if (_isEditing) ...[
          Expanded(
            child: TextButton(
              onPressed: _isLoading
                  ? null
                  : () {
                      setState(() {
                        _isEditing = false;
                      });
                      _loadProfileData(); // Reset to original data
                    },
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _isLoading ? null : _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Save Profile',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                    ),
            ),
          ),
        ] else ...[
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Edit Profile',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: () => _showChangePasswordDialog(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Change Password',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _pickIdCard() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedIdCard = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      String? newAvatarUrl = _avatarUrl;
      if (_selectedImage != null) {
        newAvatarUrl = await CloudinaryService.uploadImageFile(
          _selectedImage!,
          folder: 'mentor_avatars',
        );
      }

      String? newIdCardUrl = _idCardUrl;
      if (_selectedIdCard != null) {
        newIdCardUrl = await CloudinaryService.uploadImageFile(
          _selectedIdCard!,
          folder: 'mentor_id_cards',
        );
      }

      final mentorData = {
        'name': _nameController.text.trim(),
        'department': _departmentController.text.trim(),
        'designation': _designationController.text.trim(),
        'specialization': _specializationController.text.trim(),
        'experience': _experienceController.text.trim(),
        'qualification': _qualificationController.text.trim(),
        'semester': _semesterController.text.trim(),
        'avatarUrl': newAvatarUrl,
        'idCardUrl': newIdCardUrl,
        'isAvailable': _isAvailable,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      };

      await FirebaseFirestore.instance
          .collection('mentors')
          .where('userId', isEqualTo: user.uid)
          .limit(1)
          .get()
          .then((querySnapshot) {
            if (querySnapshot.docs.isNotEmpty) {
              querySnapshot.docs.first.reference.update(mentorData);
            }
          });

      if (mounted) {
        setState(() {
          _isEditing = false;
          _avatarUrl = newAvatarUrl;
          _idCardUrl = newIdCardUrl;
          _selectedImage = null;
          _selectedIdCard = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Change Password',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Current Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'New Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Confirm New Password',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (newPasswordController.text !=
                  confirmPasswordController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('New passwords do not match'),
                    backgroundColor: AppTheme.errorColor,
                  ),
                );
                return;
              }

              try {
                final user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  await user.updatePassword(newPasswordController.text);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Password updated successfully'),
                      backgroundColor: AppTheme.successColor,
                    ),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to update password: $e'),
                    backgroundColor: AppTheme.errorColor,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: const Text('Update Password'),
          ),
        ],
      ),
    );
  }
}

class _MentorAttendanceTab extends StatefulWidget {
  const _MentorAttendanceTab();

  @override
  State<_MentorAttendanceTab> createState() => _MentorAttendanceTabState();
}

class _MentorAttendanceTabState extends State<_MentorAttendanceTab> {
  DateTime _selectedDate = DateTime.now();
  String? _teacherDepartment;
  String? _teacherSemester;
  List<Map<String, dynamic>> _students = [];
  Map<String, String> _attendanceStatus = {}; // studentId -> status
  Map<String, String> _attendanceRemarks = {}; // studentId -> remarks
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadTeacherProfile();
  }

  Future<void> _loadTeacherProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('mentors')
          .where('userId', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (doc.docs.isNotEmpty) {
        final data = doc.docs.first.data();
        setState(() {
          _teacherDepartment = data['department'];
          _teacherSemester = data['semester'];
        });
        _loadStudents();
      }
    } catch (e) {
      print('Error loading teacher profile: $e');
    }
  }

  Future<void> _loadStudents() async {
    if (_teacherDepartment == null || _teacherSemester == null) return;

    setState(() => _isLoading = true);
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('students')
          .where('department', isEqualTo: _teacherDepartment)
          .where('semester', isEqualTo: _teacherSemester)
          .get();

      setState(() {
        _students = snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'name': data['name'] ?? 'Student',
            'department': data['department'] ?? '',
            'semester': data['semester'] ?? '',
          };
        }).toList();
      });

      _loadExistingAttendance();
    } catch (e) {
      print('Error loading students: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadExistingAttendance() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final snapshot = await FirebaseFirestore.instance
          .collection('attendance')
          .where('teacherId', isEqualTo: user.uid)
          .where('date', isEqualTo: dateStr)
          .get();

      setState(() {
        _attendanceStatus = {};
        _attendanceRemarks = {};

        for (var doc in snapshot.docs) {
          final data = doc.data();
          _attendanceStatus[data['studentId']] = data['status'] ?? 'Absent';
          _attendanceRemarks[data['studentId']] = data['remarks'] ?? '';
        }
      });
    } catch (e) {
      print('Error loading attendance: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_teacherDepartment == null || _teacherSemester == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading teacher profile...'),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Date selector and header
        Container(
          padding: const EdgeInsets.all(AppTheme.spacingM),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: AppTheme.dividerColor)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Text(
                    'Attendance for ${DateFormat('MMM dd, yyyy').format(_selectedDate)}',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: _selectDate,
                    icon: const Icon(Icons.calendar_today),
                    tooltip: 'Select Date',
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingS),
              Text(
                '$_teacherDepartment - Semester $_teacherSemester',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppTheme.secondaryTextColor,
                ),
              ),
            ],
          ),
        ),

        // Students list
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _students.isEmpty
              ? const Center(
                  child: Text(
                    'No students found in your department and semester',
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(AppTheme.spacingM),
                  itemCount: _students.length,
                  itemBuilder: (context, index) {
                    final student = _students[index];
                    final studentId = student['id'];
                    final currentStatus =
                        _attendanceStatus[studentId] ?? 'Absent';

                    return CustomCard(
                      margin: const EdgeInsets.only(bottom: AppTheme.spacingS),
                      child: Column(
                        children: [
                          ListTile(
                            leading: CircleAvatar(
                              child: Text(
                                student['name'][0].toUpperCase(),
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              student['name'],
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              '${student['department']} • ${student['semester']}',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: AppTheme.secondaryTextColor,
                              ),
                            ),
                            trailing: _buildStatusChip(currentStatus),
                          ),

                          // Status buttons
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppTheme.spacingM,
                              vertical: AppTheme.spacingS,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _buildStatusButton(
                                    'Present',
                                    currentStatus == 'Present',
                                    AppTheme.successColor,
                                    () =>
                                        _updateAttendance(studentId, 'Present'),
                                  ),
                                ),
                                const SizedBox(width: AppTheme.spacingS),
                                Expanded(
                                  child: _buildStatusButton(
                                    'Absent',
                                    currentStatus == 'Absent',
                                    AppTheme.errorColor,
                                    () =>
                                        _updateAttendance(studentId, 'Absent'),
                                  ),
                                ),
                                const SizedBox(width: AppTheme.spacingS),
                                Expanded(
                                  child: _buildStatusButton(
                                    'Late',
                                    currentStatus == 'Late',
                                    AppTheme.warningColor,
                                    () => _updateAttendance(studentId, 'Late'),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Remarks field
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppTheme.spacingM,
                              vertical: AppTheme.spacingS,
                            ),
                            child: TextField(
                              controller: TextEditingController(
                                text: _attendanceRemarks[studentId] ?? '',
                              ),
                              decoration: const InputDecoration(
                                hintText: 'Remarks (optional)',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                              onChanged: (value) {
                                _attendanceRemarks[studentId] = value;
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),

        // Save button
        Container(
          padding: const EdgeInsets.all(AppTheme.spacingM),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: AppTheme.dividerColor)),
          ),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saveAttendance,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(
                'Save Attendance',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status) {
      case 'Present':
        color = AppTheme.successColor;
        break;
      case 'Late':
        color = AppTheme.warningColor;
        break;
      default:
        color = AppTheme.errorColor;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  Widget _buildStatusButton(
    String status,
    bool isSelected,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color),
        ),
        child: Text(
          status,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : color,
          ),
        ),
      ),
    );
  }

  void _updateAttendance(String studentId, String status) {
    setState(() {
      _attendanceStatus[studentId] = status;
    });
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadExistingAttendance();
    }
  }

  Future<void> _saveAttendance() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      final batch = FirebaseFirestore.instance.batch();
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

      for (final student in _students) {
        final studentId = student['id'];
        final status = _attendanceStatus[studentId] ?? 'Absent';
        final remarks = _attendanceRemarks[studentId] ?? '';

        final attendanceRef = FirebaseFirestore.instance
            .collection('attendance')
            .doc('${user.uid}_${studentId}_$dateStr');

        batch.set(attendanceRef, {
          'studentId': studentId,
          'studentName': student['name'],
          'teacherId': user.uid,
          'date': dateStr,
          'status': status,
          'remarks': remarks,
          'createdAt': DateTime.now().millisecondsSinceEpoch,
          'updatedAt': DateTime.now().millisecondsSinceEpoch,
        });
      }

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Attendance saved successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save attendance: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }
}

class _AssignStudentsDialog extends StatefulWidget {
  @override
  _AssignStudentsDialogState createState() => _AssignStudentsDialogState();
}

class _AssignStudentsDialogState extends State<_AssignStudentsDialog> {
  List<Map<String, dynamic>> _allStudents = [];
  List<String> _selectedStudentIds = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    setState(() => _isLoading = true);
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('students')
          .get();

      setState(() {
        _allStudents = snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'name': data['name'] ?? 'Student',
            'department': data['department'] ?? '',
            'semester': data['semester'] ?? '',
            'mentorId': data['mentorId'],
          };
        }).toList();
      });
    } catch (e) {
      print('Error loading students: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.people, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    'Assign Students',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: _allStudents.length,
                      itemBuilder: (context, index) {
                        final student = _allStudents[index];
                        final isSelected = _selectedStudentIds.contains(
                          student['id'],
                        );
                        final hasMentor =
                            student['mentorId'] != null &&
                            student['mentorId'].isNotEmpty;

                        return CheckboxListTile(
                          title: Text(student['name']),
                          subtitle: Text(
                            '${student['department']} • ${student['semester']}',
                          ),
                          value: isSelected,
                          onChanged: hasMentor
                              ? null
                              : (value) {
                                  setState(() {
                                    if (value == true) {
                                      _selectedStudentIds.add(student['id']);
                                    } else {
                                      _selectedStudentIds.remove(student['id']);
                                    }
                                  });
                                },
                          secondary: hasMentor
                              ? Icon(Icons.person, color: AppTheme.warningColor)
                              : Icon(Icons.person_outline),
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _selectedStudentIds.isEmpty
                          ? null
                          : _assignStudents,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Assign'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _assignStudents() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);
    try {
      final batch = FirebaseFirestore.instance.batch();

      for (final studentId in _selectedStudentIds) {
        final studentRef = FirebaseFirestore.instance
            .collection('students')
            .doc(studentId);
        batch.update(studentRef, {
          'mentorId': user.uid,
          'updatedAt': DateTime.now().millisecondsSinceEpoch,
        });
      }

      await batch.commit();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Students assigned successfully'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to assign students: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
}

class _MentorChatScreen extends StatelessWidget {
  final String studentId;
  final String studentName;

  const _MentorChatScreen({required this.studentId, required this.studentName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Chat with $studentName',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.primaryTextColor,
        elevation: 0,
      ),
      body: const Center(
        child: Text('Chat functionality will be implemented here'),
      ),
    );
  }
}
