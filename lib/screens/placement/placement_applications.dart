import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../utils/app_theme.dart';
import '../../utils/responsive_helper.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/responsive_wrapper.dart';
import '../../models/placement_model.dart';

class PlacementApplicationsScreen extends StatefulWidget {
  const PlacementApplicationsScreen({super.key});

  @override
  State<PlacementApplicationsScreen> createState() =>
      _PlacementApplicationsScreenState();
}

class _PlacementApplicationsScreenState
    extends State<PlacementApplicationsScreen> {
  String _selectedStatus = 'All';
  final List<String> _statuses = ['All', 'pending', 'reviewed', 'shortlisted', 'rejected', 'accepted'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Applications',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.primaryTextColor,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingM),
            child: Row(
              children: _statuses.map((status) {
                final isSelected = status == _selectedStatus;
                return Padding(
                  padding: const EdgeInsets.only(right: AppTheme.spacingS),
                  child: FilterChip(
                    label: Text(status),
                    selected: isSelected,
                    onSelected: (v) {
                      setState(() => _selectedStatus = status);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
      body: ResponsiveWrapper(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('job_applications')
              .orderBy('appliedAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const LoadingWidget();
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text('No applications'));
            }

            var applications = snapshot.data!.docs
                .map((doc) => JobApplicationModel.fromMap(
                      doc.data() as Map<String, dynamic>,
                      doc.id,
                    ))
                .toList();

            if (_selectedStatus != 'All') {
              applications = applications
                  .where((app) => app.status == _selectedStatus)
                  .toList();
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
            itemCount: applications.length,
            itemBuilder: (context, index) =>
                _buildApplicationCard(applications[index]),
          );
        },
        ),
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

        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('students')
              .doc(application.studentId)
              .snapshots(),
          builder: (context, studentSnapshot) {
            if (!studentSnapshot.hasData) {
              return const SizedBox.shrink();
            }

            final student = studentSnapshot.data!.data() as Map<String, dynamic>;

            return CustomCard(
              margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
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
                              '${student['name'] ?? 'Student'} • ${student['rollNumber'] ?? ''}',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: AppTheme.secondaryTextColor,
                              ),
                            ),
                          ],
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
                  const SizedBox(height: AppTheme.spacingM),
                  Text(
                    'Applied: ${DateFormat('MMM dd, yyyy').format(application.appliedAt)}',
                    style: GoogleFonts.poppins(fontSize: 12),
                  ),
                  if (application.reviewNotes != null) ...[
                    const SizedBox(height: AppTheme.spacingS),
                    Text(
                      'Notes: ${application.reviewNotes}',
                      style: GoogleFonts.poppins(fontSize: 12),
                    ),
                  ],
                  const SizedBox(height: AppTheme.spacingM),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _viewResume(application.resumeId),
                          child: const Text('View Resume'),
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingS),
                      Expanded(
                        child: CustomButton(
                          text: 'Update Status',
                          onPressed: () => _updateStatus(application),
                          size: ButtonSize.small,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
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

  Future<void> _viewResume(String resumeId) async {
    // Navigate to resume view
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Resume viewer coming soon')),
    );
  }

  Future<void> _updateStatus(JobApplicationModel application) async {
    String? newStatus;
    String? notes;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Update Application Status'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: application.status,
                decoration: const InputDecoration(labelText: 'Status'),
                items: ['pending', 'reviewed', 'shortlisted', 'rejected', 'accepted']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => setDialogState(() => newStatus = v),
              ),
              const SizedBox(height: AppTheme.spacingM),
              TextField(
                decoration: const InputDecoration(labelText: 'Notes (optional)'),
                maxLines: 3,
                onChanged: (v) => notes = v,
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
                if (newStatus != null) {
                  Navigator.pop(context);
                  _saveStatus(application, newStatus!, notes);
                }
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveStatus(
    JobApplicationModel application,
    String status,
    String? notes,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('job_applications')
          .doc(application.id)
          .update({
        'status': status,
        'reviewNotes': notes,
        'reviewedAt': DateTime.now().millisecondsSinceEpoch,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Status updated successfully'),
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

