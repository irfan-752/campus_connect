import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/app_theme.dart';
import '../../widgets/custom_app_bar.dart';
import '../../login.dart';
import 'admin_dashboard.dart';
import 'admin_user_management.dart';
import 'admin_event_management.dart';
import 'admin_notice_management.dart';
import 'admin_analytics.dart';
import 'admin_attendance_reporting.dart';
import 'admin_course_assignments.dart';
import 'admin_marketplace_monitoring.dart';
import 'admin_club_monitoring.dart';
import 'admin_communication_monitoring.dart';
import 'admin_system_settings.dart';
import 'admin_audit_logs.dart';
import 'admin_roles_permissions.dart';

class AdminMainScreen extends StatefulWidget {
  const AdminMainScreen({super.key});

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const AdminDashboard(),
    const AdminUserManagement(),
    const AdminEventManagement(),
    const AdminNoticeManagement(),
    const AdminAttendanceReporting(),
    const AdminCourseAssignmentsScreen(),
    const AdminAnalytics(),
    const AdminMarketplaceMonitoring(),
    const AdminClubMonitoring(),
    const AdminCommunicationMonitoring(),
    const AdminSystemSettings(),
    const AdminAuditLogs(),
    const AdminRolesPermissions(),
  ];

  final List<Map<String, dynamic>> _menuItems = [
    {'title': 'Dashboard', 'icon': Icons.dashboard, 'index': 0},
    {'title': 'User Management', 'icon': Icons.group, 'index': 1},
    {'title': 'Event Management', 'icon': Icons.event, 'index': 2},
    {'title': 'Notice Management', 'icon': Icons.campaign, 'index': 3},
    {'title': 'Attendance Reporting', 'icon': Icons.fact_check, 'index': 4},
    {'title': 'Course Assignments', 'icon': Icons.school, 'index': 5},
    {'title': 'Analytics & Reports', 'icon': Icons.analytics, 'index': 6},
    {'title': 'Marketplace Monitoring', 'icon': Icons.store, 'index': 7},
    {'title': 'Club Monitoring', 'icon': Icons.group_work, 'index': 8},
    {'title': 'Communication Monitoring', 'icon': Icons.forum, 'index': 9},
    {'title': 'System Settings', 'icon': Icons.settings, 'index': 10},
    {'title': 'Audit Logs', 'icon': Icons.history, 'index': 11},
    {'title': 'Roles & Permissions', 'icon': Icons.admin_panel_settings, 'index': 12},
  ];

  final List<String> _screenTitles = [
    'Admin Dashboard',
    'User Management',
    'Event Management',
    'Notice Management',
    'Attendance Reporting',
    'Course Assignments',
    'Analytics & Reports',
    'Marketplace Monitoring',
    'Club Monitoring',
    'Communication Monitoring',
    'System Settings',
    'Audit Logs',
    'Roles & Permissions',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: _screenTitles[_currentIndex],
        actions: [
          IconButton(
            icon: const Icon(Icons.backup),
            tooltip: 'Backup Data',
            onPressed: _showBackupDialog,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              setState(() => _currentIndex = 10); // System Settings
            },
          ),
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      drawer: _buildDrawer(),
      body: IndexedStack(index: _currentIndex, children: _screens),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.admin_panel_settings,
                  color: Colors.white,
                  size: 48,
                ),
                const SizedBox(height: AppTheme.spacingM),
                Text(
                  'Admin Panel',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Campus Connect',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          _buildDrawerSection('Core Management', [
            _menuItems[0], // Dashboard
            _menuItems[1], // User Management
            _menuItems[2], // Event Management
            _menuItems[3], // Notice Management
            _menuItems[4], // Attendance Reporting
            _menuItems[5], // Course Assignments
          ]),
          const Divider(),
          _buildDrawerSection('Monitoring', [
            _menuItems[7], // Marketplace Monitoring
            _menuItems[8], // Club Monitoring
            _menuItems[9], // Communication Monitoring
          ]),
          const Divider(),
          _buildDrawerSection('System', [
            _menuItems[6], // Analytics
            _menuItems[10], // System Settings
            _menuItems[11], // Audit Logs
            _menuItems[12], // Roles & Permissions
          ]),
        ],
      ),
    );
  }

  Widget _buildDrawerSection(String title, List<Map<String, dynamic>> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(AppTheme.spacingM),
          child: Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.secondaryTextColor,
            ),
          ),
        ),
        ...items.map((item) {
          final isSelected = _currentIndex == item['index'];
          return ListTile(
            leading: Icon(
              item['icon'] as IconData,
              color: isSelected
                  ? AppTheme.primaryColor
                  : AppTheme.secondaryTextColor,
            ),
            title: Text(
              item['title'] as String,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected
                    ? AppTheme.primaryColor
                    : AppTheme.primaryTextColor,
              ),
            ),
            selected: isSelected,
            selectedTileColor: AppTheme.primaryColor.withOpacity(0.1),
            onTap: () {
              setState(() {
                _currentIndex = item['index'] as int;
              });
              Navigator.pop(context);
            },
          );
        }).toList(),
      ],
    );
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Logout',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _showBackupDialog() {
    final Map<String, bool> collections = {
      'users': true,
      'students': true,
      'events': true,
      'notices': true,
      'attendance': true,
      'mentor_sessions': true,
    };

    showDialog(
      context: context,
      builder: (context) {
        bool isBackingUp = false;
        return StatefulBuilder(
          builder: (ctx, setState) => AlertDialog(
            title: Text(
              'Backup Collections',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ...collections.entries.map(
                  (e) => CheckboxListTile(
                    value: e.value,
                    onChanged: (v) =>
                        setState(() => collections[e.key] = v ?? false),
                    title: Text(e.key),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Backups will be saved under backups/{timestamp}/{collection}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppTheme.secondaryTextColor,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isBackingUp ? null : () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isBackingUp
                    ? null
                    : () async {
                        setState(() => isBackingUp = true);
                        try {
                          await _runBackup(collections);
                          if (mounted) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Backup completed successfully'),
                              ),
                            );
                          }
                        } catch (e) {
                          setState(() => isBackingUp = false);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Backup failed: $e')),
                            );
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: isBackingUp
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Start Backup'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _runBackup(Map<String, bool> selected) async {
    final ts = DateTime.now().millisecondsSinceEpoch;
    for (final entry in selected.entries) {
      if (!entry.value) continue;
      final col = entry.key;
      final snapshot = await FirebaseFirestore.instance.collection(col).get();
      for (final doc in snapshot.docs) {
        final data = doc.data();
        await FirebaseFirestore.instance
            .collection('backups')
            .doc(ts.toString())
            .collection(col)
            .doc(doc.id)
            .set(data);
      }
    }
  }
}
