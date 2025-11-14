import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/app_theme.dart';
import 'alumni_dashboard.dart';
import 'alumni_job_posting.dart';
import 'alumni_network.dart';
import 'alumni_profile.dart';
import '../placement/placement_drive_management.dart';
import '../placement/placement_applications.dart';
import '../placement/placement_analytics.dart';

class AlumniMainScreen extends StatefulWidget {
  const AlumniMainScreen({super.key});

  @override
  State<AlumniMainScreen> createState() => _AlumniMainScreenState();
}

class _AlumniMainScreenState extends State<AlumniMainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const AlumniDashboard(),
    const AlumniNetworkScreen(),
    const AlumniJobPostingScreen(),
    const PlacementDriveManagementScreen(),
    const PlacementApplicationsScreen(),
    const PlacementAnalyticsScreen(),
    const AlumniProfileScreen(),
  ];

  final List<BottomNavigationBarItem> _bottomNavItems = [
    const BottomNavigationBarItem(
      icon: Icon(Icons.dashboard),
      label: 'Dashboard',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.people),
      label: 'Network',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.work),
      label: 'Jobs',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.event),
      label: 'Drives',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.assignment),
      label: 'Applications',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.analytics),
      label: 'Analytics',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.person),
      label: 'Profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.normal,
        ),
        elevation: 8,
        selectedIconTheme: const IconThemeData(size: 24),
        unselectedIconTheme: const IconThemeData(size: 22),
      ),
    );
  }
}

