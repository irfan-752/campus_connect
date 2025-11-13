import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/app_theme.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/loading_widget.dart';
import '../../models/alumni_model.dart';

class AlumniProfileScreen extends StatefulWidget {
  const AlumniProfileScreen({super.key});

  @override
  State<AlumniProfileScreen> createState() => _AlumniProfileScreenState();
}

class _AlumniProfileScreenState extends State<AlumniProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _companyController = TextEditingController();
  final _positionController = TextEditingController();
  final _linkedInController = TextEditingController();
  final _bioController = TextEditingController();
  final _skillsController = TextEditingController();

  String? _department;
  String? _graduationYear;
  bool _loading = false;
  bool _isNew = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _companyController.dispose();
    _positionController.dispose();
    _linkedInController.dispose();
    _bioController.dispose();
    _skillsController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _loading = true);
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('alumni')
          .where('userId', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final alumni = AlumniModel.fromMap(
          snapshot.docs.first.data(),
          snapshot.docs.first.id,
        );
        _nameController.text = alumni.name;
        _companyController.text = alumni.currentCompany ?? '';
        _positionController.text = alumni.currentPosition ?? '';
        _linkedInController.text = alumni.linkedInUrl ?? '';
        _bioController.text = alumni.bio ?? '';
        _skillsController.text = alumni.skills.join(', ');
        _department = alumni.department;
        _graduationYear = alumni.graduationYear;
        _isNew = false;
      } else {
        // Load from user
        final userData = user;
        _nameController.text = userData.displayName ?? '';
      }
    } catch (e) {
      print('Error loading profile: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (_department == null || _graduationYear == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _loading = true);
    try {
      final skills = _skillsController.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      final alumni = AlumniModel(
        id: '',
        userId: user.uid,
        name: _nameController.text.trim(),
        email: user.email ?? '',
        department: _department!,
        graduationYear: _graduationYear!,
        currentCompany: _companyController.text.trim().isEmpty
            ? null
            : _companyController.text.trim(),
        currentPosition: _positionController.text.trim().isEmpty
            ? null
            : _positionController.text.trim(),
        linkedInUrl: _linkedInController.text.trim().isEmpty
            ? null
            : _linkedInController.text.trim(),
        bio: _bioController.text.trim().isEmpty ? null : _bioController.text.trim(),
        skills: skills,
        isVerified: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (_isNew) {
        await FirebaseFirestore.instance
            .collection('alumni')
            .add(alumni.toMap());
      } else {
        final snapshot = await FirebaseFirestore.instance
            .collection('alumni')
            .where('userId', isEqualTo: user.uid)
            .limit(1)
            .get();
        if (snapshot.docs.isNotEmpty) {
          await FirebaseFirestore.instance
              .collection('alumni')
              .doc(snapshot.docs.first.id)
              .update(alumni.toMap());
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile saved successfully'),
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
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: const CustomAppBar(title: 'Alumni Profile'),
      body: _loading && _isNew
          ? const LoadingWidget()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.spacingM),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Personal Information',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacingM),
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(labelText: 'Name *'),
                            validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                          ),
                          const SizedBox(height: AppTheme.spacingM),
                          DropdownButtonFormField<String>(
                            value: _department,
                            decoration: const InputDecoration(labelText: 'Department *'),
                            items: ['CS', 'EE', 'ME', 'CE', 'Other']
                                .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                                .toList(),
                            onChanged: (v) => setState(() => _department = v),
                            validator: (v) => v == null ? 'Required' : null,
                          ),
                          const SizedBox(height: AppTheme.spacingM),
                          DropdownButtonFormField<String>(
                            value: _graduationYear,
                            decoration: const InputDecoration(labelText: 'Graduation Year *'),
                            items: List.generate(20, (i) {
                              final year = DateTime.now().year - i;
                              return DropdownMenuItem(
                                value: year.toString(),
                                child: Text(year.toString()),
                              );
                            }),
                            onChanged: (v) => setState(() => _graduationYear = v),
                            validator: (v) => v == null ? 'Required' : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingM),
                    CustomCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Professional Information',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacingM),
                          TextFormField(
                            controller: _companyController,
                            decoration: const InputDecoration(labelText: 'Current Company'),
                          ),
                          const SizedBox(height: AppTheme.spacingM),
                          TextFormField(
                            controller: _positionController,
                            decoration: const InputDecoration(labelText: 'Current Position'),
                          ),
                          const SizedBox(height: AppTheme.spacingM),
                          TextFormField(
                            controller: _linkedInController,
                            decoration: const InputDecoration(labelText: 'LinkedIn URL'),
                            keyboardType: TextInputType.url,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingM),
                    CustomCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Additional Information',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacingM),
                          TextFormField(
                            controller: _bioController,
                            decoration: const InputDecoration(labelText: 'Bio'),
                            maxLines: 5,
                          ),
                          const SizedBox(height: AppTheme.spacingM),
                          TextFormField(
                            controller: _skillsController,
                            decoration: const InputDecoration(
                              labelText: 'Skills (comma separated)',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingM),
                    CustomButton(
                      text: _loading ? 'Saving...' : 'Save Profile',
                      onPressed: _loading ? null : _saveProfile,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

