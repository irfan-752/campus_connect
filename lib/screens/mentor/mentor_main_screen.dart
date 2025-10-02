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
import 'mentor_attendance_marking.dart';
import '../../services/cloudinary_service.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class MentorHomeScreen extends StatefulWidget {
  const MentorHomeScreen({super.key});

  @override
  State<MentorHomeScreen> createState() => _MentorHomeScreenState();
}

class _MentorHomeScreenState extends State<MentorHomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
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
          ],
        ),
      ),
    );
  }
}

class _MentorDashboardTab extends StatelessWidget {
  const _MentorDashboardTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      children: const [
        CustomCard(child: SizedBox(height: 120)),
        SizedBox(height: AppTheme.spacingM),
        CustomCard(child: SizedBox(height: 240)),
      ],
    );
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
                .where('authorId', isEqualTo: user.uid)
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const LoadingWidget(message: 'Loading notices...');
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const EmptyStateWidget(
                  title: 'No notices yet',
                  subtitle: 'Create your first notice',
                  icon: Icons.campaign,
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(AppTheme.spacingM),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final doc = snapshot.data!.docs[index];
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
    String priority = 'Medium';
    String category = 'General';
    List<String> audience = ['Student'];
    File? attachment;

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
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          attachment == null
                              ? 'No attachment'
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
                            setState(() => attachment = File(picked.path));
                          }
                        },
                        icon: const Icon(Icons.attach_file),
                        label: const Text('Attach'),
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
                  final now = DateTime.now();
                  String? attachmentUrl;
                  if (attachment != null) {
                    attachmentUrl = await CloudinaryService.uploadImageFile(
                      attachment!,
                      folder: 'notice_attachments',
                    );
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
                        : ['Student'],
                    attachmentUrl: attachmentUrl,
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
                .orderBy('scheduledDate')
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

class _MentorStudentsTab extends StatelessWidget {
  const _MentorStudentsTab();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('Not authenticated'));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('students')
          .where('mentorId', isEqualTo: user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingWidget(message: 'Loading students...');
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const EmptyStateWidget(
            title: 'No assigned students',
            subtitle: 'You will see assigned mentees here',
            icon: Icons.people,
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(AppTheme.spacingM),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final data =
                snapshot.data!.docs[index].data() as Map<String, dynamic>;
            return CustomCard(
              child: ListTile(
                leading: const Icon(Icons.person, color: AppTheme.primaryColor),
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
                trailing: const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: AppTheme.lightTextColor,
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
        );
      },
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
        subtitle: Text(
          notice.description,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.poppins(fontSize: 12),
        ),
        trailing: Text(
          notice.priority,
          style: GoogleFonts.poppins(fontSize: 12),
        ),
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

  String? _avatarUrl;
  bool _isAvailable = true;
  bool _isLoading = false;
  bool _isEditing = false;
  File? _selectedImage;

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
          _avatarUrl = data['avatarUrl'];
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

      final mentorData = {
        'name': _nameController.text.trim(),
        'department': _departmentController.text.trim(),
        'designation': _designationController.text.trim(),
        'specialization': _specializationController.text.trim(),
        'experience': _experienceController.text.trim(),
        'qualification': _qualificationController.text.trim(),
        'avatarUrl': newAvatarUrl,
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
          _selectedImage = null;
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

class _MentorAttendanceTab extends StatelessWidget {
  const _MentorAttendanceTab();

  @override
  Widget build(BuildContext context) {
    return const MentorAttendanceMarkingScreen();
  }
}
