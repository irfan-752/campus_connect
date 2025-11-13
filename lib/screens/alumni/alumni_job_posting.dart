import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/app_theme.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/custom_button.dart';

class AlumniJobPostingScreen extends StatefulWidget {
  const AlumniJobPostingScreen({super.key});

  @override
  State<AlumniJobPostingScreen> createState() => _AlumniJobPostingScreenState();
}

class _AlumniJobPostingScreenState extends State<AlumniJobPostingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _companyController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _requirementsController = TextEditingController();
  final _salaryMinController = TextEditingController();
  final _salaryMaxController = TextEditingController();
  final _applicationLinkController = TextEditingController();

  String _jobType = 'full-time';
  DateTime? _deadline;
  List<String> _selectedDepartments = [];
  bool _loading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _companyController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _requirementsController.dispose();
    _salaryMinController.dispose();
    _salaryMaxController.dispose();
    _applicationLinkController.dispose();
    super.dispose();
  }

  Future<void> _postJob() async {
    if (!_formKey.currentState!.validate()) return;
    if (_deadline == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select application deadline')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _loading = true);
    try {
      final jobData = {
        'title': _titleController.text.trim(),
        'company': _companyController.text.trim(),
        'location': _locationController.text.trim(),
        'jobType': _jobType,
        'description': _descriptionController.text.trim(),
        'requirements': _requirementsController.text
            .trim()
            .split('\n')
            .where((r) => r.isNotEmpty)
            .toList(),
        'skills': <String>[],
        'applicationDeadline': _deadline!.millisecondsSinceEpoch,
        'applicationLink': _applicationLinkController.text.trim().isEmpty
            ? null
            : _applicationLinkController.text.trim(),
        'departments': _selectedDepartments,
        'isActive': true,
        'postedBy': user.uid,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      };

      if (_salaryMinController.text.isNotEmpty) {
        final min = double.tryParse(_salaryMinController.text);
        if (min != null) jobData['salaryMin'] = min;
      }
      if (_salaryMaxController.text.isNotEmpty) {
        final max = double.tryParse(_salaryMaxController.text);
        if (max != null) jobData['salaryMax'] = max;
      }

      await FirebaseFirestore.instance
          .collection('job_postings')
          .add(jobData);

      // Clear form
      _formKey.currentState!.reset();
      _titleController.clear();
      _companyController.clear();
      _locationController.clear();
      _descriptionController.clear();
      _requirementsController.clear();
      _salaryMinController.clear();
      _salaryMaxController.clear();
      _applicationLinkController.clear();
      _deadline = null;
      _selectedDepartments = [];

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Job posted successfully'),
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
      appBar: const CustomAppBar(title: 'Post Job'),
      body: SingleChildScrollView(
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
                      'Job Details',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingM),
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(labelText: 'Job Title *'),
                      validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                    ),
                    const SizedBox(height: AppTheme.spacingM),
                    TextFormField(
                      controller: _companyController,
                      decoration: const InputDecoration(labelText: 'Company Name *'),
                      validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                    ),
                    const SizedBox(height: AppTheme.spacingM),
                    TextFormField(
                      controller: _locationController,
                      decoration: const InputDecoration(labelText: 'Location *'),
                      validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                    ),
                    const SizedBox(height: AppTheme.spacingM),
                    DropdownButtonFormField<String>(
                      value: _jobType,
                      decoration: const InputDecoration(labelText: 'Job Type'),
                      items: ['full-time', 'part-time', 'internship', 'contract']
                          .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _jobType = v);
                      },
                    ),
                    const SizedBox(height: AppTheme.spacingM),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(labelText: 'Job Description'),
                      maxLines: 5,
                    ),
                    const SizedBox(height: AppTheme.spacingM),
                    TextFormField(
                      controller: _requirementsController,
                      decoration: const InputDecoration(
                        labelText: 'Requirements (one per line)',
                      ),
                      maxLines: 5,
                    ),
                    const SizedBox(height: AppTheme.spacingM),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _salaryMinController,
                            decoration: const InputDecoration(labelText: 'Min Salary'),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacingM),
                        Expanded(
                          child: TextFormField(
                            controller: _salaryMaxController,
                            decoration: const InputDecoration(labelText: 'Max Salary'),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacingM),
                    TextFormField(
                      controller: _applicationLinkController,
                      decoration: const InputDecoration(labelText: 'Application Link'),
                      keyboardType: TextInputType.url,
                    ),
                    const SizedBox(height: AppTheme.spacingM),
                    ListTile(
                      title: Text(_deadline == null
                          ? 'Select Application Deadline *'
                          : 'Deadline: ${_deadline!.day}/${_deadline!.month}/${_deadline!.year}'),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().add(const Duration(days: 30)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (date != null) {
                          setState(() => _deadline = date);
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spacingM),
              CustomButton(
                text: _loading ? 'Posting...' : 'Post Job',
                onPressed: _loading ? null : _postJob,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

