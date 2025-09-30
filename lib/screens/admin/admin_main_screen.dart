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
    const AdminAnalytics(),
  ];

  final List<BottomNavigationBarItem> _bottomNavItems = [
    const BottomNavigationBarItem(
      icon: Icon(Icons.dashboard),
      label: 'Dashboard',
    ),
    const BottomNavigationBarItem(icon: Icon(Icons.group), label: 'Users'),
    const BottomNavigationBarItem(icon: Icon(Icons.event), label: 'Events'),
    const BottomNavigationBarItem(icon: Icon(Icons.campaign), label: 'Notices'),
    const BottomNavigationBarItem(
      icon: Icon(Icons.fact_check),
      label: 'Attendance',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.analytics),
      label: 'Analytics',
    ),
  ];

  final List<String> _screenTitles = [
    'Admin Dashboard',
    'User Management',
    'Event Management',
    'Notice Management',
    'Attendance Reporting',
    'Analytics & Reports',
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
              // Navigate to settings
            },
          ),
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: _bottomNavItems,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: AppTheme.secondaryTextColor,
        selectedLabelStyle: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.normal,
        ),
        elevation: 8,
      ),
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
