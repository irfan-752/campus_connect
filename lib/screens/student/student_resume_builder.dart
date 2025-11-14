import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/app_theme.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/loading_widget.dart';
import '../../models/resume_model.dart';
import '../../widgets/responsive_wrapper.dart';

class StudentResumeBuilderScreen extends StatefulWidget {
  const StudentResumeBuilderScreen({super.key});

  @override
  State<StudentResumeBuilderScreen> createState() =>
      _StudentResumeBuilderScreenState();
}

class _StudentResumeBuilderScreenState
    extends State<StudentResumeBuilderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _linkedInController = TextEditingController();
  final _githubController = TextEditingController();
  final _portfolioController = TextEditingController();
  final _summaryController = TextEditingController();

  List<Education> _education = [];
  List<Experience> _experience = [];
  List<Skill> _skills = [];
  List<Project> _projects = [];
  List<String> _certifications = [];
  List<String> _languages = [];
  String _selectedTemplate = 'default';
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadResume();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _linkedInController.dispose();
    _githubController.dispose();
    _portfolioController.dispose();
    _summaryController.dispose();
    super.dispose();
  }

  Future<void> _loadResume() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _loading = true);
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('resumes')
          .where('studentId', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final resume = ResumeModel.fromMap(
          snapshot.docs.first.data(),
          snapshot.docs.first.id,
        );
        _nameController.text = resume.personalInfo.fullName;
        _emailController.text = resume.personalInfo.email;
        _phoneController.text = resume.personalInfo.phone ?? '';
        _addressController.text = resume.personalInfo.address ?? '';
        _linkedInController.text = resume.personalInfo.linkedIn ?? '';
        _githubController.text = resume.personalInfo.github ?? '';
        _portfolioController.text = resume.personalInfo.portfolio ?? '';
        _summaryController.text = resume.summary ?? '';
        _education = resume.education;
        _experience = resume.experience;
        _skills = resume.skills;
        _projects = resume.projects;
        _certifications = resume.certifications;
        _languages = resume.languages;
        _selectedTemplate = resume.templateId;
      } else {
        // Load from student profile
        final studentDoc = await FirebaseFirestore.instance
            .collection('students')
            .doc(user.uid)
            .get();
        if (studentDoc.exists) {
          final data = studentDoc.data()!;
          _nameController.text = data['name'] ?? '';
          _emailController.text = data['email'] ?? '';
        }
      }
    } catch (e) {
      print('Error loading resume: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveResume() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _loading = true);
    try {
      final personalInfo = PersonalInfo(
        fullName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        address: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
        linkedIn: _linkedInController.text.trim().isEmpty
            ? null
            : _linkedInController.text.trim(),
        github: _githubController.text.trim().isEmpty
            ? null
            : _githubController.text.trim(),
        portfolio: _portfolioController.text.trim().isEmpty
            ? null
            : _portfolioController.text.trim(),
      );

      final resume = ResumeModel(
        id: '',
        studentId: user.uid,
        personalInfo: personalInfo,
        education: _education,
        experience: _experience,
        skills: _skills,
        projects: _projects,
        certifications: _certifications,
        languages: _languages,
        summary: _summaryController.text.trim().isEmpty
            ? null
            : _summaryController.text.trim(),
        templateId: _selectedTemplate,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Check if resume exists
      final existing = await FirebaseFirestore.instance
          .collection('resumes')
          .where('studentId', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('resumes')
            .doc(existing.docs.first.id)
            .update(resume.toMap());
      } else {
        await FirebaseFirestore.instance
            .collection('resumes')
            .add(resume.toMap());
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Resume saved successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving resume: $e'),
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
      appBar: const CustomAppBar(title: 'Resume Builder'),
      body: _loading && _education.isEmpty
          ? const LoadingWidget(message: 'Loading resume...')
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.spacingM),
              child: ResponsiveWrapper(
                centerContent: true,
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPersonalInfoSection(),
                      const SizedBox(height: AppTheme.spacingL),
                      _buildEducationSection(),
                      const SizedBox(height: AppTheme.spacingL),
                      _buildExperienceSection(),
                      const SizedBox(height: AppTheme.spacingL),
                      _buildSkillsSection(),
                      const SizedBox(height: AppTheme.spacingL),
                      _buildProjectsSection(),
                      const SizedBox(height: AppTheme.spacingL),
                      _buildAdditionalSection(),
                      const SizedBox(height: AppTheme.spacingL),
                      _buildTemplateSection(),
                      const SizedBox(height: AppTheme.spacingL),
                      CustomButton(
                        text: 'Save Resume',
                        onPressed: _saveResume,
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildPersonalInfoSection() {
    return CustomCard(
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
            decoration: const InputDecoration(labelText: 'Full Name'),
            validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
          ),
          const SizedBox(height: AppTheme.spacingM),
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(labelText: 'Email'),
            keyboardType: TextInputType.emailAddress,
            validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
          ),
          const SizedBox(height: AppTheme.spacingM),
          TextFormField(
            controller: _phoneController,
            decoration: const InputDecoration(labelText: 'Phone'),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: AppTheme.spacingM),
          TextFormField(
            controller: _addressController,
            decoration: const InputDecoration(labelText: 'Address'),
            maxLines: 2,
          ),
          const SizedBox(height: AppTheme.spacingM),
          TextFormField(
            controller: _linkedInController,
            decoration: const InputDecoration(labelText: 'LinkedIn URL'),
          ),
          const SizedBox(height: AppTheme.spacingM),
          TextFormField(
            controller: _githubController,
            decoration: const InputDecoration(labelText: 'GitHub URL'),
          ),
          const SizedBox(height: AppTheme.spacingM),
          TextFormField(
            controller: _portfolioController,
            decoration: const InputDecoration(labelText: 'Portfolio URL'),
          ),
        ],
      ),
    );
  }

  Widget _buildEducationSection() {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Education',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => _showEducationDialog(),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingM),
          ..._education.asMap().entries.map((entry) {
            final edu = entry.value;
            return ListTile(
              title: Text(edu.degree),
              subtitle: Text('${edu.institution} • ${edu.field}'),
              trailing:               Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _showEducationDialog(edu, entry.key),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      setState(() => _education.removeAt(entry.key));
                    },
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildExperienceSection() {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Experience',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => _showExperienceDialog(),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingM),
          ..._experience.asMap().entries.map((entry) {
            final exp = entry.value;
            return ListTile(
              title: Text(exp.position),
              subtitle: Text('${exp.company} • ${exp.startDate ?? ''}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _showExperienceDialog(exp, entry.key),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      setState(() => _experience.removeAt(entry.key));
                    },
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSkillsSection() {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Skills',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => _showSkillDialog(),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingM),
          Wrap(
            spacing: AppTheme.spacingS,
            runSpacing: AppTheme.spacingS,
            children: _skills.map((skill) {
              return Chip(
                label: Text('${skill.name} (${skill.level})'),
                onDeleted: () {
                  setState(() => _skills.remove(skill));
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectsSection() {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Projects',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => _showProjectDialog(),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingM),
          ..._projects.asMap().entries.map((entry) {
            final proj = entry.value;
            return ListTile(
              title: Text(proj.name),
              subtitle: Text(proj.description ?? ''),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _showProjectDialog(proj, entry.key),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      setState(() => _projects.removeAt(entry.key));
                    },
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAdditionalSection() {
    return CustomCard(
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
            controller: _summaryController,
            decoration: const InputDecoration(labelText: 'Professional Summary'),
            maxLines: 5,
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateSection() {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resume Template',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          DropdownButtonFormField<String>(
            value: _selectedTemplate,
            decoration: const InputDecoration(labelText: 'Select Template'),
            items: ['default', 'modern', 'classic', 'creative']
                .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => _selectedTemplate = v);
            },
          ),
        ],
      ),
    );
  }

  void _showEducationDialog([Education? education, int? index]) {
    final institutionController = TextEditingController(text: education?.institution ?? '');
    final degreeController = TextEditingController(text: education?.degree ?? '');
    final fieldController = TextEditingController(text: education?.field ?? '');
    final startDateController = TextEditingController(text: education?.startDate ?? '');
    final endDateController = TextEditingController(text: education?.endDate ?? '');
    final gpaController = TextEditingController(text: education?.gpa?.toString() ?? '');
    final descriptionController = TextEditingController(text: education?.description ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(education == null ? 'Add Education' : 'Edit Education'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: institutionController, decoration: const InputDecoration(labelText: 'Institution *')),
              TextField(controller: degreeController, decoration: const InputDecoration(labelText: 'Degree *')),
              TextField(controller: fieldController, decoration: const InputDecoration(labelText: 'Field *')),
              TextField(controller: startDateController, decoration: const InputDecoration(labelText: 'Start Date')),
              TextField(controller: endDateController, decoration: const InputDecoration(labelText: 'End Date')),
              TextField(controller: gpaController, decoration: const InputDecoration(labelText: 'GPA'), keyboardType: TextInputType.number),
              TextField(controller: descriptionController, decoration: const InputDecoration(labelText: 'Description'), maxLines: 3),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (institutionController.text.isNotEmpty &&
                  degreeController.text.isNotEmpty &&
                  fieldController.text.isNotEmpty) {
                final edu = Education(
                  institution: institutionController.text.trim(),
                  degree: degreeController.text.trim(),
                  field: fieldController.text.trim(),
                  startDate: startDateController.text.trim().isEmpty ? null : startDateController.text.trim(),
                  endDate: endDateController.text.trim().isEmpty ? null : endDateController.text.trim(),
                  gpa: gpaController.text.trim().isEmpty ? null : double.tryParse(gpaController.text.trim()),
                  description: descriptionController.text.trim().isEmpty ? null : descriptionController.text.trim(),
                );
                setState(() {
                  if (index != null) {
                    _education[index] = edu;
                  } else {
                    _education.add(edu);
                  }
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showExperienceDialog([Experience? experience, int? index]) {
    final companyController = TextEditingController(text: experience?.company ?? '');
    final positionController = TextEditingController(text: experience?.position ?? '');
    final startDateController = TextEditingController(text: experience?.startDate ?? '');
    final endDateController = TextEditingController(text: experience?.endDate ?? '');
    final descriptionController = TextEditingController(text: experience?.description ?? '');
    bool isCurrent = experience?.isCurrent ?? false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(experience == null ? 'Add Experience' : 'Edit Experience'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: companyController, decoration: const InputDecoration(labelText: 'Company *')),
                TextField(controller: positionController, decoration: const InputDecoration(labelText: 'Position *')),
                TextField(controller: startDateController, decoration: const InputDecoration(labelText: 'Start Date')),
                CheckboxListTile(
                  title: const Text('Current Position'),
                  value: isCurrent,
                  onChanged: (v) => setDialogState(() => isCurrent = v ?? false),
                ),
                if (!isCurrent)
                  TextField(controller: endDateController, decoration: const InputDecoration(labelText: 'End Date')),
                TextField(controller: descriptionController, decoration: const InputDecoration(labelText: 'Description'), maxLines: 3),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (companyController.text.isNotEmpty && positionController.text.isNotEmpty) {
                  final exp = Experience(
                    company: companyController.text.trim(),
                    position: positionController.text.trim(),
                    startDate: startDateController.text.trim().isEmpty ? null : startDateController.text.trim(),
                    endDate: isCurrent ? null : (endDateController.text.trim().isEmpty ? null : endDateController.text.trim()),
                    isCurrent: isCurrent,
                    description: descriptionController.text.trim().isEmpty ? null : descriptionController.text.trim(),
                  );
                  setState(() {
                    if (index != null) {
                      _experience[index] = exp;
                    } else {
                      _experience.add(exp);
                    }
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSkillDialog() {
    final nameController = TextEditingController();
    String level = 'intermediate';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Skill'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Skill Name *')),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: level,
                decoration: const InputDecoration(labelText: 'Level'),
                items: ['beginner', 'intermediate', 'advanced', 'expert']
                    .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                    .toList(),
                onChanged: (v) => setDialogState(() => level = v ?? 'intermediate'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  setState(() {
                    _skills.add(Skill(name: nameController.text.trim(), level: level));
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showProjectDialog([Project? project, int? index]) {
    final nameController = TextEditingController(text: project?.name ?? '');
    final descriptionController = TextEditingController(text: project?.description ?? '');
    final technologiesController = TextEditingController(text: project?.technologies ?? '');
    final urlController = TextEditingController(text: project?.url ?? '');
    final startDateController = TextEditingController(text: project?.startDate ?? '');
    final endDateController = TextEditingController(text: project?.endDate ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(project == null ? 'Add Project' : 'Edit Project'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Project Name *')),
              TextField(controller: descriptionController, decoration: const InputDecoration(labelText: 'Description'), maxLines: 3),
              TextField(controller: technologiesController, decoration: const InputDecoration(labelText: 'Technologies')),
              TextField(controller: urlController, decoration: const InputDecoration(labelText: 'URL'), keyboardType: TextInputType.url),
              TextField(controller: startDateController, decoration: const InputDecoration(labelText: 'Start Date')),
              TextField(controller: endDateController, decoration: const InputDecoration(labelText: 'End Date')),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                final proj = Project(
                  name: nameController.text.trim(),
                  description: descriptionController.text.trim().isEmpty ? null : descriptionController.text.trim(),
                  technologies: technologiesController.text.trim().isEmpty ? null : technologiesController.text.trim(),
                  url: urlController.text.trim().isEmpty ? null : urlController.text.trim(),
                  startDate: startDateController.text.trim().isEmpty ? null : startDateController.text.trim(),
                  endDate: endDateController.text.trim().isEmpty ? null : endDateController.text.trim(),
                );
                setState(() {
                  if (index != null) {
                    _projects[index] = proj;
                  } else {
                    _projects.add(proj);
                  }
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

