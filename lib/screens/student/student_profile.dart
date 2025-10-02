import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../services/cloudinary_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/loading_widget.dart';
import '../../models/student_model.dart';
import '../../login.dart';

class StudentProfileScreen extends StatefulWidget {
  const StudentProfileScreen({super.key});

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _rollNumberController = TextEditingController();
  final _departmentController = TextEditingController();
  final _semesterController = TextEditingController();
  final _parentEmailController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _addressController = TextEditingController();
  final _emergencyContactController = TextEditingController();
  final _bloodGroupController = TextEditingController();

  bool _isEditing = false;
  // Loading flag reserved for future async UI
  // ignore: unused_field
  bool _isLoading = false;
  File? _selectedImage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _rollNumberController.dispose();
    _departmentController.dispose();
    _semesterController.dispose();
    _parentEmailController.dispose();
    _phoneNumberController.dispose();
    _addressController.dispose();
    _emergencyContactController.dispose();
    _bloodGroupController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: CustomAppBar(
        title: "Profile",
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            )
          else
            TextButton(
              onPressed: _saveProfile,
              child: Text(
                "Save",
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('students')
            .doc(user?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingWidget(message: "Loading profile...");
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
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

          _populateFields(student);

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.spacingM),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildProfileHeader(student),
                    const SizedBox(height: AppTheme.spacingL),
                    _buildPersonalInfo(student),
                    const SizedBox(height: AppTheme.spacingL),
                    _buildAcademicInfo(student),
                    const SizedBox(height: AppTheme.spacingL),
                    _buildStatistics(student),
                    const SizedBox(height: AppTheme.spacingL),
                    _buildActions(),
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
    );
  }

  Widget _buildProfileHeader(StudentModel student) {
    return CustomCard(
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 60,
                backgroundImage: _selectedImage != null
                    ? FileImage(_selectedImage!)
                    : (student.avatarUrl != null
                          ? NetworkImage(student.avatarUrl!) as ImageProvider
                          : null),
                backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                child: _selectedImage == null && student.avatarUrl == null
                    ? Text(
                        student.name.isNotEmpty
                            ? student.name[0].toUpperCase()
                            : 'S',
                        style: GoogleFonts.poppins(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      )
                    : null,
              ),
              if (_isEditing)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: _pickImage,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingM),
          Text(
            student.name,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryTextColor,
            ),
          ),
          const SizedBox(height: AppTheme.spacingXS),
          Text(
            student.rollNumber,
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: AppTheme.secondaryTextColor,
            ),
          ),
          const SizedBox(height: AppTheme.spacingXS),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              "${student.department} • ${student.semester}",
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfo(StudentModel student) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Personal Information",
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryTextColor,
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          _buildInfoField(
            "Full Name",
            _nameController,
            Icons.person,
            enabled: _isEditing,
          ),
          const SizedBox(height: AppTheme.spacingM),
          _buildInfoField(
            "Email",
            _emailController,
            Icons.email,
            enabled: false, // Email shouldn't be editable
          ),
          const SizedBox(height: AppTheme.spacingM),
          _buildInfoField(
            "Parent Email",
            _parentEmailController,
            Icons.family_restroom,
            enabled: _isEditing,
          ),
          const SizedBox(height: AppTheme.spacingM),
          _buildInfoField(
            "Phone Number",
            _phoneNumberController,
            Icons.phone,
            enabled: _isEditing,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: AppTheme.spacingM),
          _buildInfoField(
            "Address",
            _addressController,
            Icons.location_on,
            enabled: _isEditing,
            maxLines: 2,
          ),
          const SizedBox(height: AppTheme.spacingM),
          _buildInfoField(
            "Emergency Contact",
            _emergencyContactController,
            Icons.emergency,
            enabled: _isEditing,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: AppTheme.spacingM),
          _buildInfoField(
            "Blood Group",
            _bloodGroupController,
            Icons.bloodtype,
            enabled: _isEditing,
          ),
        ],
      ),
    );
  }

  Widget _buildAcademicInfo(StudentModel student) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Academic Information",
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryTextColor,
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          _buildInfoField(
            "Roll Number",
            _rollNumberController,
            Icons.badge,
            enabled: _isEditing,
          ),
          const SizedBox(height: AppTheme.spacingM),
          _buildInfoField(
            "Department",
            _departmentController,
            Icons.school,
            enabled: _isEditing,
          ),
          const SizedBox(height: AppTheme.spacingM),
          _buildInfoField(
            "Semester",
            _semesterController,
            Icons.class_,
            enabled: _isEditing,
          ),
          const SizedBox(height: AppTheme.spacingM),
          Text(
            "Courses",
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.primaryTextColor,
            ),
          ),
          const SizedBox(height: AppTheme.spacingS),
          Wrap(
            spacing: AppTheme.spacingS,
            runSpacing: AppTheme.spacingS,
            children: student.courses.map((course) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.dividerColor),
                ),
                child: Text(
                  course,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppTheme.primaryTextColor,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatistics(StudentModel student) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Academic Statistics",
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryTextColor,
            ),
          ),
          const SizedBox(height: AppTheme.spacingL),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  "Attendance",
                  "${student.attendance.toStringAsFixed(1)}%",
                  Icons.check_circle,
                  student.attendance >= 75
                      ? AppTheme.successColor
                      : AppTheme.errorColor,
                ),
              ),
              const SizedBox(width: AppTheme.spacingS),
              Expanded(
                child: _buildStatCard(
                  "GPA",
                  student.gpa.toStringAsFixed(2),
                  Icons.grade,
                  AppTheme.warningColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingS),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  "Events",
                  "${student.eventsParticipated}",
                  Icons.event,
                  AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: AppTheme.spacingS),
              Expanded(
                child: _buildStatCard(
                  "Courses",
                  "${student.courses.length}",
                  Icons.book,
                  AppTheme.successColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
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
          Icon(icon, color: color, size: 32),
          const SizedBox(height: AppTheme.spacingS),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppTheme.secondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Account Actions",
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryTextColor,
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          _buildActionItem(
            "Change Password",
            "Update your account password",
            Icons.lock,
            AppTheme.primaryColor,
            _showChangePasswordDialog,
          ),
          _buildActionItem(
            "Privacy Settings",
            "Manage your privacy preferences",
            Icons.privacy_tip,
            AppTheme.warningColor,
            () {
              // Navigate to privacy settings
            },
          ),
          _buildActionItem(
            "Help & Support",
            "Get help or contact support",
            Icons.help,
            AppTheme.successColor,
            () {
              // Navigate to help
            },
          ),
          _buildActionItem(
            "Logout",
            "Sign out of your account",
            Icons.logout,
            AppTheme.errorColor,
            _logout,
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusM),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingS),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: AppTheme.spacingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.primaryTextColor,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppTheme.secondaryTextColor,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppTheme.lightTextColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoField(
    String label,
    TextEditingController controller,
    IconData icon, {
    bool enabled = true,
    TextInputType? keyboardType,
    int maxLines = 1,
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
        const SizedBox(height: AppTheme.spacingXS),
        TextFormField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: GoogleFonts.poppins(
            color: enabled
                ? AppTheme.primaryTextColor
                : AppTheme.secondaryTextColor,
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(
              icon,
              color: enabled ? AppTheme.primaryColor : AppTheme.lightTextColor,
            ),
            filled: true,
            fillColor: enabled
                ? AppTheme.surfaceColor
                : AppTheme.surfaceColor.withOpacity(0.5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
              borderSide: BorderSide.none,
            ),
          ),
          validator: (value) {
            if (enabled && (value == null || value.isEmpty)) {
              return 'Please enter $label';
            }
            return null;
          },
        ),
      ],
    );
  }

  void _populateFields(StudentModel student) {
    if (_nameController.text.isEmpty) {
      _nameController.text = student.name;
      _emailController.text = student.email;
      _rollNumberController.text = student.rollNumber;
      _departmentController.text = student.department;
      _semesterController.text = student.semester;
      _parentEmailController.text = student.parentEmail ?? '';
      _phoneNumberController.text = student.phoneNumber ?? '';
      _addressController.text = student.address ?? '';
      _emergencyContactController.text = student.emergencyContact ?? '';
      _bloodGroupController.text = student.bloodGroup ?? '';
    }
  }

  void _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  void _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser!;

      // Update student data
      await FirebaseFirestore.instance
          .collection('students')
          .doc(user.uid)
          .update({
            'name': _nameController.text.trim(),
            'rollNumber': _rollNumberController.text.trim(),
            'department': _departmentController.text.trim(),
            'semester': _semesterController.text.trim(),
            'parentEmail': _parentEmailController.text.trim(),
            'phoneNumber': _phoneNumberController.text.trim(),
            'address': _addressController.text.trim(),
            'emergencyContact': _emergencyContactController.text.trim(),
            'bloodGroup': _bloodGroupController.text.trim(),
            'updatedAt': DateTime.now().millisecondsSinceEpoch,
          });

      // Upload image if selected
      if (_selectedImage != null) {
        final url = await CloudinaryService.uploadImageFile(_selectedImage!);
        await FirebaseFirestore.instance
            .collection('students')
            .doc(user.uid)
            .update({
              'avatarUrl': url,
              'updatedAt': DateTime.now().millisecondsSinceEpoch,
            });
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'avatarUrl': url,
          'updatedAt': DateTime.now().millisecondsSinceEpoch,
        }, SetOptions(merge: true));
      }

      setState(() {
        _isEditing = false;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _logout() async {
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
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
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
                prefixIcon: Icon(Icons.lock),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'New Password',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Confirm New Password',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock_outline),
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

              if (newPasswordController.text.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Password must be at least 6 characters'),
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
