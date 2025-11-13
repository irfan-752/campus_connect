import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/app_theme.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/responsive_wrapper.dart';
import '../../models/alumni_model.dart';

class AlumniDashboard extends StatelessWidget {
  const AlumniDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: const CustomAppBar(title: 'Alumni Dashboard'),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('alumni')
            .where('userId', isEqualTo: user?.uid)
            .limit(1)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingWidget();
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.person_add, size: 64, color: AppTheme.secondaryTextColor),
                  const SizedBox(height: AppTheme.spacingM),
                  Text(
                    'Complete your alumni profile',
                    style: GoogleFonts.poppins(fontSize: 18),
                  ),
                  const SizedBox(height: AppTheme.spacingM),
                  CustomButton(
                    text: 'Create Profile',
                    onPressed: () {
                      Navigator.pushNamed(context, '/alumni/profile');
                    },
                  ),
                ],
              ),
            );
          }

          final doc = snapshot.data!.docs.first;
          final alumni = AlumniModel.fromMap(
            doc.data() as Map<String, dynamic>,
            doc.id,
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            child: ResponsiveWrapper(
              centerContent: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWelcomeCard(context, alumni),
                  const SizedBox(height: AppTheme.spacingL),
                  _buildQuickActions(context),
                  const SizedBox(height: AppTheme.spacingL),
                  _buildStatsSection(context, alumni),
                  const SizedBox(height: AppTheme.spacingL),
                  _buildRecentActivity(context),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWelcomeCard(BuildContext context, AlumniModel alumni) {
    return CustomCard(
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundImage: alumni.avatarUrl != null
                ? NetworkImage(alumni.avatarUrl!)
                : null,
            child: alumni.avatarUrl == null
                ? Text(
                    alumni.name[0].toUpperCase(),
                    style: GoogleFonts.poppins(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: AppTheme.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back, ${alumni.name}',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingXS),
                if (alumni.currentPosition != null)
                  Text(
                    '${alumni.currentPosition} at ${alumni.currentCompany ?? "Company"}',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppTheme.secondaryTextColor,
                    ),
                  ),
                Text(
                  'Class of ${alumni.graduationYear}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppTheme.secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          Wrap(
            spacing: AppTheme.spacingM,
            runSpacing: AppTheme.spacingM,
            children: [
              _buildActionButton(
                context,
                'Post Job',
                Icons.work,
                AppTheme.primaryColor,
                () => Navigator.pushNamed(context, '/alumni/job-posting'),
              ),
              _buildActionButton(
                context,
                'Share Story',
                Icons.star,
                AppTheme.warningColor,
                () => _showShareStoryDialog(context),
              ),
              _buildActionButton(
                context,
                'Connect',
                Icons.people,
                AppTheme.successColor,
                () => Navigator.pushNamed(context, '/alumni/network'),
              ),
              _buildActionButton(
                context,
                'Sell Items',
                Icons.store,
                AppTheme.accentColor,
                () => Navigator.pushNamed(context, '/marketplace/create'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: AppTheme.spacingS),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection(BuildContext context, AlumniModel alumni) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Impact',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('job_postings')
                .where('postedBy', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                .snapshots(),
            builder: (context, snapshot) {
              final jobCount = snapshot.data?.docs.length ?? 0;
              return Row(
                children: [
                  Expanded(
                    child: _buildStatItem('Jobs Posted', jobCount.toString(), Icons.work),
                  ),
                  Expanded(
                    child: _buildStatItem('Connections', '0', Icons.people),
                  ),
                  Expanded(
                    child: _buildStatItem('Stories', '0', Icons.star),
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

  Widget _buildRecentActivity(BuildContext context) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Activity',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('job_postings')
                .where('postedBy', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                .orderBy('createdAt', descending: true)
                .limit(5)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppTheme.spacingL),
                    child: Text('No recent activity'),
                  ),
                );
              }

              return Column(
                children: snapshot.data!.docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return ListTile(
                    leading: const Icon(Icons.work),
                    title: Text(data['title'] ?? 'Job Posting'),
                    subtitle: Text('Posted ${_formatDate(data['createdAt'])}'),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Recently';
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showShareStoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Share Success Story'),
        content: const Text('Feature coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

