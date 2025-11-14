import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/app_theme.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/responsive_wrapper.dart';

class PlacementAnalyticsScreen extends StatelessWidget {
  const PlacementAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: const CustomAppBar(title: 'Placement Analytics'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        child: ResponsiveWrapper(
          centerContent: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildOverallStats(),
              const SizedBox(height: AppTheme.spacingL),
              _buildStatusBreakdown(),
              const SizedBox(height: AppTheme.spacingL),
              _buildDepartmentStats(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverallStats() {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Overall Statistics',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('job_applications')
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final total = snapshot.data!.docs.length;
              final accepted = snapshot.data!.docs
                  .where((doc) => (doc.data() as Map)['status'] == 'accepted')
                  .length;
              final shortlisted = snapshot.data!.docs
                  .where((doc) => (doc.data() as Map)['status'] == 'shortlisted')
                  .length;
              final rejected = snapshot.data!.docs
                  .where((doc) => (doc.data() as Map)['status'] == 'rejected')
                  .length;

              return Row(
                children: [
                  Expanded(
                    child: _buildStatItem('Total', total.toString(), Icons.assignment),
                  ),
                  Expanded(
                    child: _buildStatItem('Placed', accepted.toString(), Icons.check_circle),
                  ),
                  Expanded(
                    child: _buildStatItem('Shortlisted', shortlisted.toString(), Icons.star),
                  ),
                  Expanded(
                    child: _buildStatItem('Rejected', rejected.toString(), Icons.cancel),
                  ),
                ],
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

  Widget _buildStatusBreakdown() {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Status Breakdown',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('job_applications')
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final statusCounts = <String, int>{};
              for (final doc in snapshot.data!.docs) {
                final status = (doc.data() as Map)['status'] ?? 'pending';
                statusCounts[status] = (statusCounts[status] ?? 0) + 1;
              }

              return Column(
                children: statusCounts.entries.map((entry) {
                  final total = snapshot.data!.docs.length;
                  final percentage = total > 0 ? (entry.value / total) * 100 : 0.0;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppTheme.spacingM),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              entry.key.toUpperCase(),
                              style: GoogleFonts.poppins(fontSize: 14),
                            ),
                            Text(
                              '${entry.value} (${percentage.toStringAsFixed(1)}%)',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppTheme.spacingXS),
                        LinearProgressIndicator(
                          value: percentage / 100,
                          backgroundColor: AppTheme.surfaceColor,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _getStatusColor(entry.key),
                          ),
                        ),
                      ],
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

  Widget _buildDepartmentStats() {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Department-wise Statistics',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('job_applications')
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              // Department stats would require fetching student data
              // Simplified for now

              return const Center(child: Text('Department stats coming soon'));
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

