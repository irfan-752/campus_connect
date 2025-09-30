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
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.secondaryTextColor,
          tabs: const [
            Tab(text: 'Dashboard'),
            Tab(text: 'Notices'),
            Tab(text: 'Sessions'),
            Tab(text: 'Students'),
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
