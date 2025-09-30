import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../utils/app_theme.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/responsive_wrapper.dart';
import '../../utils/responsive_helper.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: ResponsiveWrapper(
            centerContent: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWelcomeCard(),
                const SizedBox(height: AppTheme.spacingL),
                _buildStatsOverview(context),
                const SizedBox(height: AppTheme.spacingL),
                ResponsiveHelper.isTabletOrDesktop(context)
                    ? _buildTabletDesktopLayout(context)
                    : _buildMobileLayout(context),
                // Add bottom padding to prevent overflow
                SizedBox(
                  height:
                      MediaQuery.of(context).padding.bottom +
                      AppTheme.spacingXL,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.admin_panel_settings,
                  color: AppTheme.primaryColor,
                  size: 32,
                ),
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Welcome, Administrator",
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryTextColor,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingXS),
                    Text(
                      "Campus Connect Admin Panel",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: AppTheme.secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingM),
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: AppTheme.spacingS),
                Expanded(
                  child: Text(
                    "Manage users, events, notices, and monitor campus activities from this central dashboard.",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsOverview(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "System Overview",
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryTextColor,
          ),
        ),
        const SizedBox(height: AppTheme.spacingM),
        _buildStatsGrid(context),
      ],
    );
  }

  Widget _buildStatsGrid(BuildContext context) {
    final stats = [
      _buildStatCard(
        "Total Students",
        "students",
        Icons.school,
        AppTheme.primaryColor,
      ),
      _buildStatCard(
        "Total Teachers",
        "users",
        Icons.person,
        AppTheme.successColor,
        additionalQuery: {'role': 'Teacher'},
      ),
      _buildStatCard(
        "Active Events",
        "events",
        Icons.event,
        AppTheme.warningColor,
        additionalQuery: {'isActive': true},
      ),
      _buildStatCard(
        "Recent Notices",
        "notices",
        Icons.campaign,
        AppTheme.accentColor,
        additionalQuery: {'isActive': true},
      ),
    ];

    if (ResponsiveHelper.isMobile(context)) {
      // Mobile: 2x2 grid
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: stats[0]),
              const SizedBox(width: AppTheme.spacingS),
              Expanded(child: stats[1]),
            ],
          ),
          const SizedBox(height: AppTheme.spacingS),
          Row(
            children: [
              Expanded(child: stats[2]),
              const SizedBox(width: AppTheme.spacingS),
              Expanded(child: stats[3]),
            ],
          ),
        ],
      );
    } else if (ResponsiveHelper.isTablet(context)) {
      // Tablet: 2x2 grid
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: stats[0]),
              const SizedBox(width: AppTheme.spacingS),
              Expanded(child: stats[1]),
            ],
          ),
          const SizedBox(height: AppTheme.spacingS),
          Row(
            children: [
              Expanded(child: stats[2]),
              const SizedBox(width: AppTheme.spacingS),
              Expanded(child: stats[3]),
            ],
          ),
        ],
      );
    } else {
      // Desktop: 1x4 row
      return Row(
        children: [
          Expanded(child: stats[0]),
          const SizedBox(width: AppTheme.spacingS),
          Expanded(child: stats[1]),
          const SizedBox(width: AppTheme.spacingS),
          Expanded(child: stats[2]),
          const SizedBox(width: AppTheme.spacingS),
          Expanded(child: stats[3]),
        ],
      );
    }
  }

  Widget _buildStatCard(
    String title,
    String collection,
    IconData icon,
    Color color, {
    Map<String, dynamic>? additionalQuery,
  }) {
    return StreamBuilder<QuerySnapshot>(
      stream: _buildQuery(collection, additionalQuery).snapshots(),
      builder: (context, snapshot) {
        int count = 0;
        if (snapshot.hasData) {
          count = snapshot.data!.docs.length;
        }

        return CustomCard(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(height: AppTheme.spacingS),
              Text(
                "$count",
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppTheme.secondaryTextColor,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }

  Query _buildQuery(String collection, Map<String, dynamic>? additionalQuery) {
    Query query = FirebaseFirestore.instance.collection(collection);

    if (additionalQuery != null) {
      additionalQuery.forEach((key, value) {
        query = query.where(key, isEqualTo: value);
      });
    }

    return query;
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Quick Actions",
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryTextColor,
          ),
        ),
        const SizedBox(height: AppTheme.spacingM),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                "Add User",
                Icons.person_add,
                AppTheme.primaryColor,
                () {
                  // Navigate to add user
                },
              ),
            ),
            const SizedBox(width: AppTheme.spacingS),
            Expanded(
              child: _buildActionCard(
                "Create Event",
                Icons.event,
                AppTheme.successColor,
                () {
                  // Navigate to create event
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingS),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                "Post Notice",
                Icons.campaign,
                AppTheme.warningColor,
                () {
                  // Navigate to post notice
                },
              ),
            ),
            const SizedBox(width: AppTheme.spacingS),
            Expanded(
              child: _buildActionCard(
                "View Reports",
                Icons.analytics,
                AppTheme.accentColor,
                () {
                  // Navigate to reports
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return CustomCard(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(height: AppTheme.spacingS),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.primaryTextColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivities() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Recent Activities",
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryTextColor,
          ),
        ),
        const SizedBox(height: AppTheme.spacingM),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('activity_logs')
              .orderBy('timestamp', descending: true)
              .limit(5)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const LoadingWidget();
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return CustomCard(
                child: Column(
                  children: [
                    Icon(
                      Icons.history,
                      size: 48,
                      color: AppTheme.lightTextColor,
                    ),
                    const SizedBox(height: AppTheme.spacingS),
                    Text(
                      "No recent activities",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: AppTheme.secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: snapshot.data!.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return _buildActivityItem(
                  data['action'] ?? 'Unknown action',
                  data['description'] ?? '',
                  DateTime.fromMillisecondsSinceEpoch(data['timestamp'] ?? 0),
                  _getActivityIcon(data['type'] ?? ''),
                  _getActivityColor(data['type'] ?? ''),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildActivityItem(
    String title,
    String description,
    DateTime timestamp,
    IconData icon,
    Color color,
  ) {
    return CustomCard(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingS),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: AppTheme.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryTextColor,
                  ),
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: AppTheme.spacingXS),
                  Text(
                    description,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppTheme.secondaryTextColor,
                    ),
                  ),
                ],
                const SizedBox(height: AppTheme.spacingXS),
                Text(
                  DateFormat('MMM dd, hh:mm a').format(timestamp),
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: AppTheme.lightTextColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemStatus() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "System Status",
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryTextColor,
          ),
        ),
        const SizedBox(height: AppTheme.spacingM),
        CustomCard(
          child: Column(
            children: [
              _buildStatusItem(
                "Database",
                "Connected",
                Icons.storage,
                AppTheme.successColor,
                true,
              ),
              const Divider(),
              _buildStatusItem(
                "Authentication",
                "Active",
                Icons.security,
                AppTheme.successColor,
                true,
              ),
              const Divider(),
              _buildStatusItem(
                "File Storage",
                "Available",
                Icons.cloud,
                AppTheme.successColor,
                true,
              ),
              const Divider(),
              _buildStatusItem(
                "Notifications",
                "Enabled",
                Icons.notifications,
                AppTheme.successColor,
                true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusItem(
    String service,
    String status,
    IconData icon,
    Color color,
    bool isHealthy,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingS),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: AppTheme.spacingM),
          Expanded(
            child: Text(
              service,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.primaryTextColor,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  status,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getActivityIcon(String type) {
    switch (type.toLowerCase()) {
      case 'user':
        return Icons.person;
      case 'event':
        return Icons.event;
      case 'notice':
        return Icons.campaign;
      case 'system':
        return Icons.settings;
      default:
        return Icons.info;
    }
  }

  Color _getActivityColor(String type) {
    switch (type.toLowerCase()) {
      case 'user':
        return AppTheme.primaryColor;
      case 'event':
        return AppTheme.successColor;
      case 'notice':
        return AppTheme.warningColor;
      case 'system':
        return AppTheme.accentColor;
      default:
        return AppTheme.secondaryTextColor;
    }
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildQuickActions(context),
        const SizedBox(height: AppTheme.spacingL),
        _buildRecentActivities(),
        const SizedBox(height: AppTheme.spacingL),
        _buildSystemStatus(),
      ],
    );
  }

  Widget _buildTabletDesktopLayout(BuildContext context) {
    return Column(
      children: [
        _buildQuickActions(context),
        const SizedBox(height: AppTheme.spacingL),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 2, child: _buildRecentActivities()),
            const SizedBox(width: AppTheme.spacingL),
            Expanded(flex: 1, child: _buildSystemStatus()),
          ],
        ),
      ],
    );
  }
}
