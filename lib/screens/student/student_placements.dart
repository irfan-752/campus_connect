import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../utils/app_theme.dart';
import '../../utils/responsive_helper.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/responsive_wrapper.dart';
import '../../models/placement_model.dart';

class StudentPlacementsScreen extends StatefulWidget {
  const StudentPlacementsScreen({super.key});

  @override
  State<StudentPlacementsScreen> createState() =>
      _StudentPlacementsScreenState();
}

class _StudentPlacementsScreenState extends State<StudentPlacementsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedJobType = 'All';
  final List<String> _jobTypes = ['All', 'full-time', 'part-time', 'internship', 'contract'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          title: Text(
            'Placements',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          backgroundColor: Colors.white,
          foregroundColor: AppTheme.primaryTextColor,
          elevation: 0,
          bottom: TabBar(
            labelColor: AppTheme.primaryColor,
            unselectedLabelColor: AppTheme.secondaryTextColor,
            tabs: const [
              Tab(text: 'Job Listings'),
              Tab(text: 'My Applications'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildJobListings(),
            _buildMyApplications(),
          ],
        ),
      ),
    );
  }

  Widget _buildJobListings() {
    return Column(
      children: [
        _buildSearchAndFilter(),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('job_postings')
                .where('isActive', isEqualTo: true)
                .where('applicationDeadline',
                    isGreaterThan: Timestamp.fromDate(DateTime.now()))
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const LoadingWidget();
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const EmptyStateWidget(
                  title: 'No job listings',
                  subtitle: 'Check back later for opportunities',
                  icon: Icons.work_outline,
                );
              }

              var jobs = snapshot.data!.docs
                  .map((doc) => JobPostingModel.fromMap(
                        doc.data() as Map<String, dynamic>,
                        doc.id,
                      ))
                  .toList();

              if (_selectedJobType != 'All') {
                jobs = jobs
                    .where((job) => job.jobType == _selectedJobType)
                    .toList();
              }

              final query = _searchController.text.toLowerCase();
              if (query.isNotEmpty) {
                jobs = jobs.where((job) {
                  return job.title.toLowerCase().contains(query) ||
                      job.company.toLowerCase().contains(query) ||
                      job.location.toLowerCase().contains(query);
                }).toList();
              }

              return ResponsiveWrapper(
                child: ListView.builder(
                  padding: EdgeInsets.all(
                    ResponsiveHelper.responsiveValue(
                      context,
                      mobile: AppTheme.spacingM,
                      tablet: AppTheme.spacingL,
                      desktop: AppTheme.spacingXL,
                    ),
                  ),
                  itemCount: jobs.length,
                  itemBuilder: (context, index) => _buildJobCard(jobs[index]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilter() {
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
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search jobs...',
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
          const SizedBox(height: AppTheme.spacingS),
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _jobTypes.length,
              itemBuilder: (context, index) {
                final type = _jobTypes[index];
                final isSelected = type == _selectedJobType;
                return Padding(
                  padding: const EdgeInsets.only(right: AppTheme.spacingS),
                  child: FilterChip(
                    label: Text(type),
                    selected: isSelected,
                    onSelected: (v) {
                      setState(() => _selectedJobType = type);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobCard(JobPostingModel job) {
    final isDeadlinePassed = job.applicationDeadline.isBefore(DateTime.now());

    return CustomCard(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (job.companyLogo != null)
                Image.network(job.companyLogo!, width: 50, height: 50)
              else
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.business),
                ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.title,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      job.company,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: AppTheme.secondaryTextColor,
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
              Icon(Icons.location_on, size: 16, color: AppTheme.secondaryTextColor),
              const SizedBox(width: 4),
              Text(job.location, style: GoogleFonts.poppins(fontSize: 12)),
              const SizedBox(width: AppTheme.spacingM),
              Icon(Icons.work, size: 16, color: AppTheme.secondaryTextColor),
              const SizedBox(width: 4),
              Text(job.jobType, style: GoogleFonts.poppins(fontSize: 12)),
            ],
          ),
          if (job.salaryMin != null || job.salaryMax != null) ...[
            const SizedBox(height: AppTheme.spacingS),
            Text(
              'Salary: ₹${job.salaryMin?.toStringAsFixed(0) ?? ''} - ₹${job.salaryMax?.toStringAsFixed(0) ?? ''}',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.primaryColor,
              ),
            ),
          ],
          if (job.description != null && job.description!.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spacingS),
            Text(
              job.description!,
              style: GoogleFonts.poppins(fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: AppTheme.spacingS),
          Text(
            'Deadline: ${DateFormat('MMM dd, yyyy').format(job.applicationDeadline)}',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: isDeadlinePassed ? AppTheme.errorColor : AppTheme.secondaryTextColor,
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _viewJobDetails(job),
                  child: const Text('View Details'),
                ),
              ),
              const SizedBox(width: AppTheme.spacingS),
              Expanded(
                child: CustomButton(
                  text: 'Apply',
                  onPressed: isDeadlinePassed ? null : () => _applyForJob(job),
                  size: ButtonSize.small,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMyApplications() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Center(child: Text('Not authenticated'));

    return ResponsiveWrapper(
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('job_applications')
            .where('studentId', isEqualTo: user.uid)
            .orderBy('appliedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingWidget();
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const EmptyStateWidget(
              title: 'No applications',
              subtitle: 'Apply for jobs to see them here',
              icon: Icons.work_outline,
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
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final application = JobApplicationModel.fromMap(
                doc.data() as Map<String, dynamic>,
                doc.id,
              );
              return _buildApplicationCard(application);
            },
          );
        },
      ),
    );
  }

  Widget _buildApplicationCard(JobApplicationModel application) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('job_postings')
          .doc(application.jobId)
          .snapshots(),
      builder: (context, jobSnapshot) {
        if (!jobSnapshot.hasData) {
          return const SizedBox.shrink();
        }

        final job = JobPostingModel.fromMap(
          jobSnapshot.data!.data() as Map<String, dynamic>,
          jobSnapshot.data!.id,
        );

        return CustomCard(
          margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      job.title,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(application.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      application.status.toUpperCase(),
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: _getStatusColor(application.status),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingXS),
              Text(
                '${job.company} • ${job.location}',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppTheme.secondaryTextColor,
                ),
              ),
              const SizedBox(height: AppTheme.spacingXS),
              Text(
                'Applied: ${DateFormat('MMM dd, yyyy').format(application.appliedAt)}',
                style: GoogleFonts.poppins(fontSize: 12),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'accepted':
        return AppTheme.successColor;
      case 'shortlisted':
        return AppTheme.primaryColor;
      case 'rejected':
        return AppTheme.errorColor;
      default:
        return AppTheme.warningColor;
    }
  }

  void _viewJobDetails(JobPostingModel job) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(job.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Company: ${job.company}'),
              Text('Location: ${job.location}'),
              Text('Job Type: ${job.jobType}'),
              if (job.salaryMin != null || job.salaryMax != null)
                Text(
                    'Salary: ₹${job.salaryMin?.toStringAsFixed(0) ?? ''} - ₹${job.salaryMax?.toStringAsFixed(0) ?? ''}'),
              Text(
                  'Deadline: ${DateFormat('MMM dd, yyyy').format(job.applicationDeadline)}'),
              if (job.description != null) ...[
                const SizedBox(height: AppTheme.spacingM),
                Text('Description:', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                Text(job.description!),
              ],
              if (job.requirements.isNotEmpty) ...[
                const SizedBox(height: AppTheme.spacingM),
                Text('Requirements:', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                ...job.requirements.map((req) => Text('• $req')),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _applyForJob(job);
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  Future<void> _applyForJob(JobPostingModel job) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Check if already applied
    final existing = await FirebaseFirestore.instance
        .collection('job_applications')
        .where('studentId', isEqualTo: user.uid)
        .where('jobId', isEqualTo: job.id)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Already applied for this job')),
      );
      return;
    }

    // Check if resume exists
    final resumeSnapshot = await FirebaseFirestore.instance
        .collection('resumes')
        .where('studentId', isEqualTo: user.uid)
        .limit(1)
        .get();

    if (resumeSnapshot.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please create a resume first'),
          backgroundColor: AppTheme.warningColor,
        ),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('job_applications').add({
        'studentId': user.uid,
        'jobId': job.id,
        'resumeId': resumeSnapshot.docs.first.id,
        'status': 'pending',
        'appliedAt': DateTime.now().millisecondsSinceEpoch,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Application submitted successfully'),
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

