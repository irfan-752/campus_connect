import 'package:campus_connect/manage_users.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'login.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        backgroundColor: const Color(0xFF0096FF),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Logout",
            onPressed: () => _logout(context),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // TODO: Navigate to system settings
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(18.0),
        child: ListView(
          children: [
            _SectionTitle("User Management"),
            _FeatureCard(
              icon: Icons.group,
              label: "Manage Users",
              description: "Add, edit, or remove students, teachers, parents.",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ManageUsersScreen(),
                  ),
                );
              },
            ),
            _SectionTitle("Events & Feedback"),
            _FeatureCard(
              icon: Icons.event,
              label: "Manage Events",
              description: "Create and manage campus events.",
              onTap: () {
                // TODO: Navigate to events management
              },
            ),
            _FeatureCard(
              icon: Icons.feedback,
              label: "Feedback Reports",
              description: "View and respond to feedback.",
              onTap: () {
                // TODO: Navigate to feedback reports
              },
            ),
            _SectionTitle("Notices"),
            _FeatureCard(
              icon: Icons.campaign,
              label: "Publish Notices",
              description: "Send institution-wide announcements.",
              onTap: () {
                // TODO: Navigate to notice publishing
              },
            ),
            _SectionTitle("Attendance"),
            _FeatureCard(
              icon: Icons.check_circle,
              label: "Attendance Management",
              description: "Track and report attendance.",
              onTap: () {
                // TODO: Navigate to attendance management
              },
            ),
            _SectionTitle("Communication"),
            _FeatureCard(
              icon: Icons.forum,
              label: "Monitor Threads",
              description: "Monitor campus communication threads.",
              onTap: () {
                // TODO: Navigate to communication monitoring
              },
            ),
            _SectionTitle("Analytics & Logs"),
            _FeatureCard(
              icon: Icons.analytics,
              label: "Analytics & Usage Logs",
              description: "View analytics and system usage logs.",
              onTap: () {
                // TODO: Navigate to analytics/logs
              },
            ),
            _SectionTitle("Roles & Permissions"),
            _FeatureCard(
              icon: Icons.admin_panel_settings,
              label: "Assign Roles & Permissions",
              description: "Manage user roles and permissions.",
              onTap: () {
                // TODO: Navigate to roles/permissions
              },
            ),
            _SectionTitle("Backup & Settings"),
            _FeatureCard(
              icon: Icons.backup,
              label: "Backup & System Settings",
              description: "Backup data and configure system settings.",
              onTap: () {
                // TODO: Navigate to backup/settings
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.icon,
    required this.label,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: Color(0xFF0096FF), size: 32),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(description),
        trailing: const Icon(Icons.arrow_forward_ios, size: 18),
        onTap: onTap,
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 6),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }
}
