import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/app_theme.dart';
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

      if (_editingJobId != null) {
        await FirebaseFirestore.instance
            .collection('job_postings')
            .doc(_editingJobId)
            .update(jobData);
      } else {
        await FirebaseFirestore.instance
            .collection('job_postings')
            .add(jobData);
      }

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
      _editingJobId = null;

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
  void initState() {
    super.initState();
    _loadMyJobs();
  }

  Future<void> _loadMyJobs() async {
    // This will be used when editing
  }

  Future<void> _deleteJob(String jobId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Job'),
        content: const Text('Are you sure you want to delete this job posting?'),
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
      await FirebaseFirestore.instance.collection('job_postings').doc(jobId).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Job deleted successfully'),
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

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          title: Text(
            _editingJobId == null ? 'Post Job' : 'Edit Job',
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
              Tab(text: 'My Jobs'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildJobForm(),
            _buildMyJobsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildMyJobsList() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Center(child: Text('Not authenticated'));

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('job_postings')
          .where('postedBy', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text('No jobs posted yet'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppTheme.spacingM),
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
                      onPressed: () => _editJob(doc.id, data),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: AppTheme.errorColor),
                      onPressed: () => _deleteJob(doc.id),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _editJob(String jobId, Map<String, dynamic> data) async {
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
    });
  }

  Widget _buildJobForm() {
    return SingleChildScrollView(
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
    );
  }
}

