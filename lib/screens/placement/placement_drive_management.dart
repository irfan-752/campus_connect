import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/app_theme.dart';
import '../../utils/responsive_helper.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/responsive_wrapper.dart';

class PlacementDriveManagementScreen extends StatefulWidget {
  const PlacementDriveManagementScreen({super.key});

  @override
  State<PlacementDriveManagementScreen> createState() =>
      _PlacementDriveManagementScreenState();
}

class _PlacementDriveManagementScreenState
    extends State<PlacementDriveManagementScreen> {
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
  DateTime? _driveDate;
  List<String> _selectedDepartments = [];
  List<String> _eligibilityCriteria = [];
  bool _loading = false;
  String? _editingJobId;

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

  Future<void> _saveDrive() async {
    if (!_formKey.currentState!.validate()) return;
    if (_deadline == null || _driveDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select dates')),
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
        'driveDate': _driveDate!.millisecondsSinceEpoch,
        'applicationLink': _applicationLinkController.text.trim().isEmpty
            ? null
            : _applicationLinkController.text.trim(),
        'departments': _selectedDepartments,
        'eligibilityCriteria': _eligibilityCriteria,
        'isActive': true,
        'postedBy': user.uid,
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

      if (_editingJobId != null) {
        await FirebaseFirestore.instance
            .collection('job_postings')
            .doc(_editingJobId)
            .update(jobData);
      } else {
        jobData['createdAt'] = DateTime.now().millisecondsSinceEpoch;
        await FirebaseFirestore.instance
            .collection('job_postings')
            .add(jobData);
      }

      _clearForm();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Drive saved successfully'),
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

  void _clearForm() {
    _formKey.currentState?.reset();
    _titleController.clear();
    _companyController.clear();
    _locationController.clear();
    _descriptionController.clear();
    _requirementsController.clear();
    _salaryMinController.clear();
    _salaryMaxController.clear();
    _applicationLinkController.clear();
    _deadline = null;
    _driveDate = null;
    _selectedDepartments = [];
    _eligibilityCriteria = [];
    _editingJobId = null;
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          title: Text(
            'Drive Management',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          backgroundColor: Colors.white,
          foregroundColor: AppTheme.primaryTextColor,
          elevation: 0,
          bottom: TabBar(
            labelColor: AppTheme.primaryColor,
            unselectedLabelColor: AppTheme.secondaryTextColor,
            tabs: const [
              Tab(text: 'Create/Edit'),
              Tab(text: 'All Drives'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildDriveForm(),
            _buildAllDrives(),
          ],
        ),
      ),
    );
  }

  Widget _buildDriveForm() {
    return ResponsiveWrapper(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(
          ResponsiveHelper.responsiveValue(
            context,
            mobile: AppTheme.spacingM,
            tablet: AppTheme.spacingL,
            desktop: AppTheme.spacingXL,
          ),
        ),
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
                    'Drive Details',
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
                  ListTile(
                    title: Text(_driveDate == null
                        ? 'Select Drive Date *'
                        : 'Drive Date: ${_driveDate!.day}/${_driveDate!.month}/${_driveDate!.year}'),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now().add(const Duration(days: 30)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        setState(() => _driveDate = date);
                      }
                    },
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
              text: _loading ? 'Saving...' : 'Save Drive',
              onPressed: _loading ? null : _saveDrive,
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildAllDrives() {
    return ResponsiveWrapper(
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('job_postings')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingWidget();
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No drives created yet'));
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
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;
            return CustomCard(
              margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
              child: ListTile(
                title: Text(data['title'] ?? ''),
                subtitle: Text('${data['company'] ?? ''} • ${data['location'] ?? ''}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _editDrive(doc.id, data),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: AppTheme.errorColor),
                      onPressed: () => _deleteDrive(doc.id),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
      ),
    );
  }

  Future<void> _editDrive(String jobId, Map<String, dynamic> data) async {
    setState(() {
      _editingJobId = jobId;
      _titleController.text = data['title'] ?? '';
      _companyController.text = data['company'] ?? '';
      _locationController.text = data['location'] ?? '';
      _descriptionController.text = data['description'] ?? '';
      _requirementsController.text = (data['requirements'] as List?)?.join('\n') ?? '';
      _salaryMinController.text = data['salaryMin']?.toString() ?? '';
      _salaryMaxController.text = data['salaryMax']?.toString() ?? '';
      _applicationLinkController.text = data['applicationLink'] ?? '';
      _jobType = data['jobType'] ?? 'full-time';
      if (data['applicationDeadline'] != null) {
        _deadline = DateTime.fromMillisecondsSinceEpoch(data['applicationDeadline']);
      }
      if (data['driveDate'] != null) {
        _driveDate = DateTime.fromMillisecondsSinceEpoch(data['driveDate']);
      }
    });
  }

  Future<void> _deleteDrive(String jobId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Drive'),
        content: const Text('Are you sure you want to delete this drive?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: AppTheme.errorColor)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await FirebaseFirestore.instance.collection('job_postings').doc(jobId).update({
        'isActive': false,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Drive deactivated'),
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
}

