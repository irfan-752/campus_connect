import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:campus_connect/utils/app_theme.dart';
import 'package:campus_connect/screens/admin/manage_users_screen.dart';
import 'package:campus_connect/login.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  void _logout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Admin Dashboard',
          style: GoogleFonts.poppins(
            fontSize: isMobile ? 18 : 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () {
              // TODO: Navigate to system settings
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Settings coming soon')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            Container(
              padding: EdgeInsets.all(isMobile ? 14 : 18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome, Admin',
                    style: GoogleFonts.poppins(
                      fontSize: isMobile ? 16 : 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryTextColor,
                    ),
                  ),
                  SizedBox(height: isMobile ? 6 : 8),
                  Text(
                    'Manage your campus efficiently',
                    style: GoogleFonts.poppins(
                      fontSize: isMobile ? 11 : 13,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: isMobile ? 20 : 28),

            // User Management Section
            _buildSectionTitle(isMobile, 'User Management'),
            _buildFeatureCard(
              context,
              isMobile,
              Icons.group,
              'Manage Users',
              'Add, edit, or remove students, teachers, parents.',
              Colors.blue,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ManageUsersScreen(),
                  ),
                );
              },
            ),
            SizedBox(height: isMobile ? 16 : 20),

            // Events & Feedback
            _buildSectionTitle(isMobile, 'Events & Feedback'),
            _buildFeatureCard(
              context,
              isMobile,
              Icons.event,
              'Manage Events',
              'Create and manage campus events.',
              Colors.orange,
              () {
                _showComingSoon('Events Management');
              },
            ),
            SizedBox(height: isMobile ? 12 : 16),
            _buildFeatureCard(
              context,
              isMobile,
              Icons.feedback,
              'Feedback Reports',
              'View and respond to feedback.',
              Colors.green,
              () {
                _showComingSoon('Feedback Reports');
              },
            ),
            SizedBox(height: isMobile ? 16 : 20),

            // Notices
            _buildSectionTitle(isMobile, 'Notices'),
            _buildFeatureCard(
              context,
              isMobile,
              Icons.campaign,
              'Publish Notices',
              'Send institution-wide announcements.',
              Colors.red,
              () {
                _showComingSoon('Notice Publishing');
              },
            ),
            SizedBox(height: isMobile ? 16 : 20),

            // Attendance
            _buildSectionTitle(isMobile, 'Attendance'),
            _buildFeatureCard(
              context,
              isMobile,
              Icons.check_circle,
              'Attendance Management',
              'Track and report attendance.',
              Colors.purple,
              () {
                _showComingSoon('Attendance Management');
              },
            ),
            SizedBox(height: isMobile ? 16 : 20),

            // Communication
            _buildSectionTitle(isMobile, 'Communication'),
            _buildFeatureCard(
              context,
              isMobile,
              Icons.forum,
              'Monitor Threads',
              'Monitor campus communication threads.',
              Colors.teal,
              () {
                _showComingSoon('Communication Monitoring');
              },
            ),
            SizedBox(height: isMobile ? 16 : 20),

            // Analytics & Logs
            _buildSectionTitle(isMobile, 'Analytics & Logs'),
            _buildFeatureCard(
              context,
              isMobile,
              Icons.analytics,
              'Analytics & Usage Logs',
              'View analytics and system usage logs.',
              Colors.indigo,
              () {
                _showComingSoon('Analytics & Usage Logs');
              },
            ),
            SizedBox(height: isMobile ? 16 : 20),

            // Roles & Permissions
            _buildSectionTitle(isMobile, 'Roles & Permissions'),
            _buildFeatureCard(
              context,
              isMobile,
              Icons.admin_panel_settings,
              'Assign Roles & Permissions',
              'Manage user roles and permissions.',
              Colors.pink,
              () {
                _showComingSoon('Roles & Permissions');
              },
            ),
            SizedBox(height: isMobile ? 16 : 20),

            // Backup & Settings
            _buildSectionTitle(isMobile, 'Backup & Settings'),
            _buildFeatureCard(
              context,
              isMobile,
              Icons.backup,
              'Backup & System Settings',
              'Backup data and configure system settings.',
              Colors.cyan,
              () {
                _showComingSoon('Backup & System Settings');
              },
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(bool isMobile, String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: isMobile ? 10 : 12),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: isMobile ? 14 : 16,
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryTextColor,
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context,
    bool isMobile,
    IconData icon,
    String label,
    String description,
    Color color,
    VoidCallback onTap,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 12 : 16),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(isMobile ? 10 : 12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: isMobile ? 24 : 28),
                ),
                SizedBox(width: isMobile ? 12 : 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: GoogleFonts.poppins(
                          fontSize: isMobile ? 14 : 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryTextColor,
                        ),
                      ),
                      SizedBox(height: isMobile ? 4 : 6),
                      Text(
                        description,
                        style: GoogleFonts.poppins(
                          fontSize: isMobile ? 11 : 12,
                          color: Colors.grey,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: isMobile ? 16 : 18,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showComingSoon(String featureName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$featureName - Coming soon!'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }
}
