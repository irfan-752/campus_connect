import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/app_theme.dart';
import 'placement_dashboard.dart';
import 'placement_drive_management.dart';
import 'placement_applications.dart';
import 'placement_analytics.dart';

class PlacementMainScreen extends StatefulWidget {
  const PlacementMainScreen({super.key});

  @override
  State<PlacementMainScreen> createState() => _PlacementMainScreenState();
}

class _PlacementMainScreenState extends State<PlacementMainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const PlacementDashboard(),
    const PlacementDriveManagementScreen(),
    const PlacementApplicationsScreen(),
    const PlacementAnalyticsScreen(),
  ];

  final List<BottomNavigationBarItem> _bottomNavItems = [
    const BottomNavigationBarItem(
      icon: Icon(Icons.dashboard),
      label: 'Dashboard',
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
}

