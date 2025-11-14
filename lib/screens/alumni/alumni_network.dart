import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/app_theme.dart';
import '../../utils/responsive_helper.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/responsive_wrapper.dart';
import '../../models/alumni_model.dart';
import '../../models/student_model.dart';

class AlumniNetworkScreen extends StatefulWidget {
  const AlumniNetworkScreen({super.key});

  @override
  State<AlumniNetworkScreen> createState() => _AlumniNetworkScreenState();
}

class _AlumniNetworkScreenState extends State<AlumniNetworkScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'all'; // 'all', 'alumni', 'students'

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: const CustomAppBar(title: 'Network'),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildFilterTabs(),
          Expanded(child: ResponsiveWrapper(child: _buildNetworkList())),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: EdgeInsets.all(
        ResponsiveHelper.responsiveValue(
          context,
          mobile: AppTheme.spacingM,
          tablet: AppTheme.spacingL,
          desktop: AppTheme.spacingXL,
        ),
      ),
      color: Colors.white,
      child: TextField(
        controller: _searchController,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          hintText: 'Search by name, company, department, or position...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      color: Colors.white,
      child: Row(
        children: [
          _buildFilterTab('all', 'All'),
          _buildFilterTab('alumni', 'Alumni'),
          _buildFilterTab('students', 'Students'),
        ],
      ),
    );
  }

  Widget _buildFilterTab(String value, String label) {
    final isSelected = _selectedFilter == value;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedFilter = value;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingM),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? AppTheme.primaryColor : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected
                  ? AppTheme.primaryColor
                  : AppTheme.secondaryTextColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNetworkList() {
    final query = _searchController.text.toLowerCase();

    if (_selectedFilter == 'alumni' || _selectedFilter == 'all') {
      return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('alumni')
            .where('isVerified', isEqualTo: true)
            .snapshots(),
        builder: (context, alumniSnapshot) {
          if (_selectedFilter == 'students' || _selectedFilter == 'all') {
            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('students')
                  .snapshots(),
              builder: (context, studentsSnapshot) {
                if (alumniSnapshot.connectionState == ConnectionState.waiting ||
                    studentsSnapshot.connectionState ==
                        ConnectionState.waiting) {
                  return const LoadingWidget();
                }

                final alumni = _selectedFilter == 'all'
                    ? (alumniSnapshot.data?.docs
                              .map(
                                (doc) => AlumniModel.fromMap(
                                  doc.data() as Map<String, dynamic>,
                                  doc.id,
                                ),
                              )
                              .toList() ??
                          [])
                    : [];

                final students = _selectedFilter == 'all'
                    ? (studentsSnapshot.data?.docs
                              .map(
                                (doc) => StudentModel.fromMap(
                                  doc.data() as Map<String, dynamic>,
                                  doc.id,
                                ),
                              )
                              .toList() ??
                          [])
                    : [];

                final allItems = <_NetworkItem>[];
                for (var a in alumni) {
                  if (query.isEmpty ||
                      a.name.toLowerCase().contains(query) ||
                      a.department.toLowerCase().contains(query) ||
                      (a.currentCompany?.toLowerCase().contains(query) ??
                          false) ||
                      (a.currentPosition?.toLowerCase().contains(query) ??
                          false)) {
                    allItems.add(_NetworkItem(type: 'alumni', alumni: a));
                  }
                }
                for (var s in students) {
                  if (query.isEmpty ||
                      s.name.toLowerCase().contains(query) ||
                      s.department.toLowerCase().contains(query) ||
                      s.email.toLowerCase().contains(query)) {
                    allItems.add(_NetworkItem(type: 'student', student: s));
                  }
                }

                if (allItems.isEmpty) {
                  return const EmptyStateWidget(
                    title: 'No connections found',
                    subtitle: 'Try adjusting your search or filters',
                    icon: Icons.people_outline,
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.all(
                    ResponsiveHelper.responsiveValue(
                      context,
                      mobile: AppTheme.spacingM,
                      tablet: AppTheme.spacingL,
                      desktop: AppTheme.spacingXL,
                    ),
                  ),
                  itemCount: allItems.length,
                  itemBuilder: (context, index) {
                    final item = allItems[index];
                    if (item.type == 'alumni') {
                      return _buildAlumniCard(item.alumni!);
                    } else {
                      return _buildStudentCard(item.student!);
                    }
                  },
                );
              },
            );
          } else {
            if (alumniSnapshot.connectionState == ConnectionState.waiting) {
              return const LoadingWidget();
            }

            final alumni =
                alumniSnapshot.data?.docs
                    .map(
                      (doc) => AlumniModel.fromMap(
                        doc.data() as Map<String, dynamic>,
                        doc.id,
                      ),
                    )
                    .toList() ??
                [];

            final filtered = query.isEmpty
                ? alumni
                : alumni.where((a) {
                    return a.name.toLowerCase().contains(query) ||
                        a.department.toLowerCase().contains(query) ||
                        (a.currentCompany?.toLowerCase().contains(query) ??
                            false) ||
                        (a.currentPosition?.toLowerCase().contains(query) ??
                            false);
                  }).toList();

            if (filtered.isEmpty) {
              return const EmptyStateWidget(
                title: 'No alumni found',
                subtitle: 'Try adjusting your search',
                icon: Icons.people_outline,
              );
            }

            return ListView.builder(
              padding: EdgeInsets.all(
                ResponsiveHelper.responsiveValue(
                  context,
                  mobile: AppTheme.spacingM,
                  tablet: AppTheme.spacingL,
                  desktop: AppTheme.spacingXL,
                ),
              ),
              itemCount: filtered.length,
              itemBuilder: (context, index) =>
                  _buildAlumniCard(filtered[index]),
            );
          }
        },
      );
    } else {
      // Only students
      return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('students').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingWidget();
          }

          final students =
              snapshot.data?.docs
                  .map(
                    (doc) => StudentModel.fromMap(
                      doc.data() as Map<String, dynamic>,
                      doc.id,
                    ),
                  )
                  .toList() ??
              [];

          final filtered = query.isEmpty
              ? students
              : students.where((s) {
                  return s.name.toLowerCase().contains(query) ||
                      s.department.toLowerCase().contains(query) ||
                      s.email.toLowerCase().contains(query);
                }).toList();

          if (filtered.isEmpty) {
            return const EmptyStateWidget(
              title: 'No students found',
              subtitle: 'Try adjusting your search',
              icon: Icons.school_outlined,
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(
              ResponsiveHelper.responsiveValue(
                context,
                mobile: AppTheme.spacingM,
                tablet: AppTheme.spacingL,
                desktop: AppTheme.spacingXL,
              ),
            ),
            itemCount: filtered.length,
            itemBuilder: (context, index) => _buildStudentCard(filtered[index]),
          );
        },
      );
    }
  }

  Widget _buildAlumniCard(AlumniModel alumni) {
    final user = FirebaseAuth.instance.currentUser;
    final isCurrentUser = alumni.userId == user?.uid;

    return CustomCard(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundImage: alumni.avatarUrl != null
                    ? NetworkImage(alumni.avatarUrl!)
                    : null,
                child: alumni.avatarUrl == null
                    ? Text(
                        alumni.name[0].toUpperCase(),
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            alumni.name,
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (alumni.isVerified)
                          const Icon(
                            Icons.verified,
                            color: AppTheme.successColor,
                            size: 20,
                          ),
                      ],
                    ),
                    if (alumni.currentPosition != null) ...[
                      const SizedBox(height: AppTheme.spacingXS),
                      Text(
                        alumni.currentPosition!,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: AppTheme.primaryTextColor,
                        ),
                      ),
                    ],
                    if (alumni.currentCompany != null) ...[
                      const SizedBox(height: AppTheme.spacingXS),
                      Text(
                        alumni.currentCompany!,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppTheme.secondaryTextColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingM),
          Row(
            children: [
              Icon(Icons.school, size: 16, color: AppTheme.secondaryTextColor),
              const SizedBox(width: AppTheme.spacingXS),
              Text(
                '${alumni.department} • Class of ${alumni.graduationYear}',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppTheme.secondaryTextColor,
                ),
              ),
            ],
          ),
          if (alumni.skills.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spacingM),
            Wrap(
              spacing: AppTheme.spacingXS,
              runSpacing: AppTheme.spacingXS,
              children: alumni.skills.take(5).map((skill) {
                return Chip(
                  label: Text(skill),
                  labelStyle: GoogleFonts.poppins(fontSize: 10),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                );
              }).toList(),
            ),
          ],
          if (!isCurrentUser) ...[
            const SizedBox(height: AppTheme.spacingM),
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'Connect',
                    onPressed: () => _connectUser(alumni.userId, 'alumni'),
                    size: ButtonSize.small,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingS),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _viewAlumniProfile(alumni),
                    child: const Text('View Profile'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStudentCard(StudentModel student) {
    final user = FirebaseAuth.instance.currentUser;
    final isCurrentUser = student.userId == user?.uid;

    return CustomCard(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundImage: student.avatarUrl != null
                    ? NetworkImage(student.avatarUrl!)
                    : null,
                child: student.avatarUrl == null
                    ? Text(
                        student.name[0].toUpperCase(),
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
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
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingXS),
                    Text(
                      'Student',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: AppTheme.primaryTextColor,
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
              Icon(Icons.school, size: 16, color: AppTheme.secondaryTextColor),
              const SizedBox(width: AppTheme.spacingXS),
              Text(
                '${student.department} • Semester ${student.semester}',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppTheme.secondaryTextColor,
                ),
              ),
            ],
          ),
          if (!isCurrentUser) ...[
            const SizedBox(height: AppTheme.spacingM),
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'Connect',
                    onPressed: () => _connectUser(student.userId, 'student'),
                    size: ButtonSize.small,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingS),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _viewStudentProfile(student),
                    child: const Text('View Profile'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _connectUser(String userId, String userType) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Check if connection already exists
      final existing = await FirebaseFirestore.instance
          .collection('connections')
          .where('fromUserId', isEqualTo: user.uid)
          .where('toUserId', isEqualTo: userId)
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Already connected')));
        return;
      }

      // Check reverse connection
      final reverse = await FirebaseFirestore.instance
          .collection('connections')
          .where('fromUserId', isEqualTo: userId)
          .where('toUserId', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (reverse.docs.isNotEmpty) {
        // Accept existing reverse connection
        await FirebaseFirestore.instance
            .collection('connections')
            .doc(reverse.docs.first.id)
            .update({'status': 'accepted'});
      } else {
        // Create new connection
        await FirebaseFirestore.instance.collection('connections').add({
          'fromUserId': user.uid,
          'toUserId': userId,
          'userType': userType,
          'status': 'pending',
          'createdAt': DateTime.now().millisecondsSinceEpoch,
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Connection request sent'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _viewAlumniProfile(AlumniModel alumni) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(alumni.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (alumni.currentPosition != null)
                Text('Position: ${alumni.currentPosition}'),
              if (alumni.currentCompany != null)
                Text('Company: ${alumni.currentCompany}'),
              Text('Department: ${alumni.department}'),
              Text('Graduation Year: ${alumni.graduationYear}'),
              if (alumni.bio != null) ...[
                const SizedBox(height: AppTheme.spacingM),
                Text('Bio: ${alumni.bio}'),
              ],
              if (alumni.skills.isNotEmpty) ...[
                const SizedBox(height: AppTheme.spacingM),
                Text('Skills: ${alumni.skills.join(", ")}'),
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

  void _viewStudentProfile(StudentModel student) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(student.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Email: ${student.email}'),
              Text('Department: ${student.department}'),
              Text('Semester: ${student.semester}'),
              Text('Roll Number: ${student.rollNumber}'),
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
}

class _NetworkItem {
  final String type;
  final AlumniModel? alumni;
  final StudentModel? student;

  _NetworkItem({required this.type, this.alumni, this.student});
}
