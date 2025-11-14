import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/app_theme.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/responsive_wrapper.dart';

class PlacementDashboard extends StatelessWidget {
  const PlacementDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: const CustomAppBar(title: 'Placement Dashboard'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        child: ResponsiveWrapper(
          centerContent: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatsSection(context),
              const SizedBox(height: AppTheme.spacingL),
              _buildUpcomingDrives(context),
              const SizedBox(height: AppTheme.spacingL),
              _buildRecentApplications(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsSection(BuildContext context) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Placement Statistics',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('job_postings')
                .where('isActive', isEqualTo: true)
                .snapshots(),
            builder: (context, snapshot) {
              final totalJobs = snapshot.data?.docs.length ?? 0;
              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('job_applications')
                    .snapshots(),
                builder: (context, appSnapshot) {
                  final totalApplications = appSnapshot.data?.docs.length ?? 0;
                  final accepted = appSnapshot.data?.docs
                          .where((doc) =>
                              (doc.data() as Map)['status'] == 'accepted')
                          .length ??
                      0;

                  return Row(
                    children: [
                      Expanded(
                        child: _buildStatItem('Active Jobs', totalJobs.toString(), Icons.work),
                      ),
                      Expanded(
                        child: _buildStatItem('Applications', totalApplications.toString(), Icons.assignment),
                      ),
                      Expanded(
                        child: _buildStatItem('Placed', accepted.toString(), Icons.check_circle),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primaryColor, size: 32),
        const SizedBox(height: AppTheme.spacingXS),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: AppTheme.secondaryTextColor,
          ),
        ),
      ],
    );
  }

  Widget _buildUpcomingDrives(BuildContext context) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Upcoming Drives',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('job_postings')
                .where('isActive', isEqualTo: true)
                .where('applicationDeadline',
                    isGreaterThan: Timestamp.fromDate(DateTime.now()))
                .orderBy('applicationDeadline')
                .limit(5)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppTheme.spacingL),
                    child: Text('No upcoming drives'),
                  ),
                );
              }

              return Column(
                children: snapshot.data!.docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return ListTile(
                    title: Text(data['title'] ?? ''),
                    subtitle: Text('${data['company'] ?? ''} • ${data['location'] ?? ''}'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRecentApplications(BuildContext context) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Applications',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('job_applications')
                .orderBy('appliedAt', descending: true)
                .limit(5)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppTheme.spacingL),
                    child: Text('No applications yet'),
                  ),
                );
              }

              return Column(
                children: snapshot.data!.docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return ListTile(
                    title: Text('Application #${doc.id.substring(0, 8)}'),
                    subtitle: Text('Status: ${data['status'] ?? 'pending'}'),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(data['status'] ?? 'pending')
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        (data['status'] ?? 'pending').toUpperCase(),
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: _getStatusColor(data['status'] ?? 'pending'),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
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
}

