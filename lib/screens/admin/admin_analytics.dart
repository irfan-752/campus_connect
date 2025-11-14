import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/app_theme.dart';
import '../../utils/responsive_helper.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/responsive_wrapper.dart';
import '../../models/user_model.dart';
import '../../models/event_model.dart';
import '../../models/notice_model.dart';

class AdminAnalytics extends StatefulWidget {
  const AdminAnalytics({super.key});

  @override
  State<AdminAnalytics> createState() => _AdminAnalyticsState();
}

class _AdminAnalyticsState extends State<AdminAnalytics>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedPeriod = 'This Month';

  final List<String> _periods = [
    'This Week',
    'This Month',
    'Last 3 Months',
    'This Year',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Column(
        children: [
          _buildPeriodSelector(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildUserAnalytics(),
                _buildEventAnalytics(),
                _buildEngagementAnalytics(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: EdgeInsets.all(
        ResponsiveHelper.responsiveValue(
          context,
          mobile: AppTheme.spacingM,
          tablet: AppTheme.spacingL,
          desktop: AppTheme.spacingXL,
        ),
      ),
      color: Colors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _periods.map((period) {
            final isSelected = _selectedPeriod == period;
            return Padding(
              padding: const EdgeInsets.only(right: AppTheme.spacingS),
              child: FilterChip(
                label: Text(
                  period,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: isSelected ? Colors.white : AppTheme.primaryColor,
                  ),
                ),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedPeriod = period;
                  });
                },
                backgroundColor: Colors.white,
                selectedColor: AppTheme.primaryColor,
                checkmarkColor: Colors.white,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: AppTheme.primaryColor,
        unselectedLabelColor: AppTheme.secondaryTextColor,
        labelStyle: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.normal,
        ),
        indicatorColor: AppTheme.primaryColor,
        isScrollable: true,
        tabs: const [
          Tab(text: 'Overview'),
          Tab(text: 'Users'),
          Tab(text: 'Events'),
          Tab(text: 'Engagement'),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return ResponsiveWrapper(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(
          ResponsiveHelper.responsiveValue(
            context,
            mobile: AppTheme.spacingM,
            tablet: AppTheme.spacingL,
            desktop: AppTheme.spacingXL,
          ),
        ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSystemOverview(),
          const SizedBox(height: AppTheme.spacingL),
          _buildActivityTrends(),
          const SizedBox(height: AppTheme.spacingL),
          _buildQuickStats(),
          const SizedBox(height: AppTheme.spacingL),
          _buildRecentActivity(),
        ],
      ),
      ),
    );
  }

  Widget _buildUserAnalytics() {
    return ResponsiveWrapper(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(
          ResponsiveHelper.responsiveValue(
            context,
            mobile: AppTheme.spacingM,
            tablet: AppTheme.spacingL,
            desktop: AppTheme.spacingXL,
          ),
        ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildUserGrowth(),
          const SizedBox(height: AppTheme.spacingL),
          _buildUserDistribution(),
          const SizedBox(height: AppTheme.spacingL),
          _buildActiveUsers(),
          const SizedBox(height: AppTheme.spacingL),
          _buildUserEngagement(),
        ],
      ),
      ),
    );
  }

  Widget _buildEventAnalytics() {
    return ResponsiveWrapper(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(
          ResponsiveHelper.responsiveValue(
            context,
            mobile: AppTheme.spacingM,
            tablet: AppTheme.spacingL,
            desktop: AppTheme.spacingXL,
          ),
        ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildEventStats(),
          const SizedBox(height: AppTheme.spacingL),
          _buildEventParticipation(),
          const SizedBox(height: AppTheme.spacingL),
          _buildPopularEventCategories(),
          const SizedBox(height: AppTheme.spacingL),
          _buildEventTrends(),
        ],
      ),
      ),
    );
  }

  Widget _buildEngagementAnalytics() {
    return ResponsiveWrapper(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(
          ResponsiveHelper.responsiveValue(
            context,
            mobile: AppTheme.spacingM,
            tablet: AppTheme.spacingL,
            desktop: AppTheme.spacingXL,
          ),
        ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildNoticeEngagement(),
          const SizedBox(height: AppTheme.spacingL),
          _buildCommunicationStats(),
          const SizedBox(height: AppTheme.spacingL),
          _buildFeedbackAnalysis(),
          const SizedBox(height: AppTheme.spacingL),
          _buildPlatformUsage(),
        ],
      ),
      ),
    );
  }

  Widget _buildSystemOverview() {
    return StreamBuilder<List<QuerySnapshot>>(
      stream: _getCombinedSystemData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingWidget(message: "Loading system overview...");
        }

        if (!snapshot.hasData || snapshot.data!.length < 3) {
          return const Center(child: Text("Unable to load system data"));
        }

        final users = snapshot.data![0].docs;
        final events = snapshot.data![1].docs;
        final notices = snapshot.data![2].docs;

        final totalUsers = users.length;
        final activeEvents = events.where((e) {
          final data = e.data() as Map<String, dynamic>;
          return data['isActive'] == true;
        }).length;
        final activeNotices = notices.where((n) {
          final data = n.data() as Map<String, dynamic>;
          return data['isActive'] == true;
        }).length;

        return CustomCard(
          child: Column(
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
              const SizedBox(height: AppTheme.spacingL),
              Row(
                children: [
                  Expanded(
                    child: _buildOverviewCard(
                      "Total Users",
                      "$totalUsers",
                      Icons.group,
                      AppTheme.primaryColor,
                      "+12% this month",
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingS),
                  Expanded(
                    child: _buildOverviewCard(
                      "Active Events",
                      "$activeEvents",
                      Icons.event,
                      AppTheme.successColor,
                      "+5 this week",
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingS),
              Row(
                children: [
                  Expanded(
                    child: _buildOverviewCard(
                      "Active Notices",
                      "$activeNotices",
                      Icons.campaign,
                      AppTheme.warningColor,
                      "+8 this week",
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingS),
                  Expanded(
                    child: _buildOverviewCard(
                      "System Health",
                      "98.5%",
                      Icons.health_and_safety,
                      AppTheme.accentColor,
                      "Excellent",
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOverviewCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String subtitle,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const Spacer(),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingS),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppTheme.primaryTextColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            subtitle,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: AppTheme.secondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityTrends() {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Activity Trends",
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryTextColor,
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.trending_up,
                    size: 48,
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(height: AppTheme.spacingS),
                  Text(
                    "Activity Chart",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    "Chart implementation would go here",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppTheme.secondaryTextColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            "Daily Active Users",
            "1,234",
            Icons.people,
            AppTheme.primaryColor,
          ),
        ),
        const SizedBox(width: AppTheme.spacingS),
        Expanded(
          child: _buildStatCard(
            "Event Registrations",
            "456",
            Icons.app_registration,
            AppTheme.successColor,
          ),
        ),
        const SizedBox(width: AppTheme.spacingS),
        Expanded(
          child: _buildStatCard(
            "Notice Views",
            "2,345",
            Icons.visibility,
            AppTheme.warningColor,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return CustomCard(
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: AppTheme.spacingS),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryTextColor,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: AppTheme.secondaryTextColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Recent Activity",
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryTextColor,
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          _buildActivityItem(
            "New user registration",
            "John Doe joined as Student",
            "2 minutes ago",
            Icons.person_add,
            AppTheme.successColor,
          ),
          _buildActivityItem(
            "Event created",
            "Tech Fest 2024 was created",
            "15 minutes ago",
            Icons.event,
            AppTheme.primaryColor,
          ),
          _buildActivityItem(
            "Notice published",
            "Holiday announcement posted",
            "1 hour ago",
            Icons.campaign,
            AppTheme.warningColor,
          ),
          _buildActivityItem(
            "System backup",
            "Daily backup completed successfully",
            "2 hours ago",
            Icons.backup,
            AppTheme.accentColor,
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(
    String title,
    String description,
    String time,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingM),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
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
                Text(
                  description,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppTheme.secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: AppTheme.lightTextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserGrowth() {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "User Growth",
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryTextColor,
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          Container(
            height: 150,
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
            ),
            child: Center(
              child: Text(
                "User Growth Chart\n(Implementation pending)",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(color: AppTheme.secondaryTextColor),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserDistribution() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingWidget();
        }

        if (!snapshot.hasData) {
          return const SizedBox();
        }

        final users = snapshot.data!.docs.map((doc) {
          return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        }).toList();

        final studentCount = users.where((u) => u.role == 'Student').length;
        final teacherCount = users.where((u) => u.role == 'Teacher').length;
        final parentCount = users.where((u) => u.role == 'Parent').length;

        return CustomCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "User Distribution",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryTextColor,
                ),
              ),
              const SizedBox(height: AppTheme.spacingM),
              _buildDistributionItem(
                "Students",
                studentCount,
                AppTheme.primaryColor,
              ),
              _buildDistributionItem(
                "Teachers",
                teacherCount,
                AppTheme.successColor,
              ),
              _buildDistributionItem(
                "Parents",
                parentCount,
                AppTheme.warningColor,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDistributionItem(String label, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingS),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: AppTheme.spacingS),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppTheme.primaryTextColor,
              ),
            ),
          ),
          Text(
            "$count",
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryTextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveUsers() {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Active Users (Last 7 Days)",
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryTextColor,
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          Row(
            children: [
              Expanded(child: _buildActiveUserCard("Daily", "234", "+12%")),
              const SizedBox(width: AppTheme.spacingS),
              Expanded(child: _buildActiveUserCard("Weekly", "1,456", "+8%")),
              const SizedBox(width: AppTheme.spacingS),
              Expanded(child: _buildActiveUserCard("Monthly", "4,789", "+15%")),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActiveUserCard(String period, String count, String change) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
      ),
      child: Column(
        children: [
          Text(
            count,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          Text(
            period,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppTheme.primaryTextColor,
            ),
          ),
          Text(
            change,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: AppTheme.successColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserEngagement() {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "User Engagement Metrics",
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryTextColor,
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          _buildEngagementMetric("Average Session Duration", "12m 34s"),
          _buildEngagementMetric("Pages per Session", "4.7"),
          _buildEngagementMetric("Bounce Rate", "23.4%"),
          _buildEngagementMetric("Return User Rate", "68.2%"),
        ],
      ),
    );
  }

  Widget _buildEngagementMetric(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingS),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppTheme.primaryTextColor,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventStats() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('events').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingWidget();
        }

        if (!snapshot.hasData) {
          return const SizedBox();
        }

        final events = snapshot.data!.docs.map((doc) {
          return EventModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        }).toList();

        final totalEvents = events.length;
        final upcomingEvents = events
            .where((e) => e.startDate.isAfter(DateTime.now()))
            .length;
        final completedEvents = events
            .where((e) => e.endDate.isBefore(DateTime.now()))
            .length;

        return CustomCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Event Statistics",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryTextColor,
                ),
              ),
              const SizedBox(height: AppTheme.spacingM),
              Row(
                children: [
                  Expanded(
                    child: _buildEventStatCard(
                      "Total Events",
                      "$totalEvents",
                      Icons.event,
                      AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingS),
                  Expanded(
                    child: _buildEventStatCard(
                      "Upcoming",
                      "$upcomingEvents",
                      Icons.schedule,
                      AppTheme.warningColor,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingS),
                  Expanded(
                    child: _buildEventStatCard(
                      "Completed",
                      "$completedEvents",
                      Icons.check_circle,
                      AppTheme.successColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEventStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: AppTheme.spacingS),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: AppTheme.primaryTextColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEventParticipation() {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Event Participation Trends",
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryTextColor,
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          Container(
            height: 150,
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
            ),
            child: Center(
              child: Text(
                "Participation Trends Chart\n(Implementation pending)",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(color: AppTheme.secondaryTextColor),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPopularEventCategories() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('events').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingWidget();
        }

        if (!snapshot.hasData) {
          return const SizedBox();
        }

        final events = snapshot.data!.docs.map((doc) {
          return EventModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        }).toList();

        final categories = [
          'Academic',
          'Cultural',
          'Sports',
          'Technical',
          'Social',
        ];
        final colors = [
          AppTheme.primaryColor,
          AppTheme.accentColor,
          AppTheme.successColor,
          AppTheme.warningColor,
          AppTheme.errorColor,
        ];

        return CustomCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Popular Event Categories",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryTextColor,
                ),
              ),
              const SizedBox(height: AppTheme.spacingM),
              ...categories.asMap().entries.map((entry) {
                final index = entry.key;
                final category = entry.value;
                final count = events
                    .where((e) => e.category == category)
                    .length;
                final registrations = events
                    .where((e) => e.category == category)
                    .map((e) => e.registeredStudents.length)
                    .fold(0, (a, b) => a + b);

                return Padding(
                  padding: const EdgeInsets.only(bottom: AppTheme.spacingS),
                  child: Row(
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: colors[index],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingS),
                      Expanded(
                        child: Text(
                          category,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: AppTheme.primaryTextColor,
                          ),
                        ),
                      ),
                      Text(
                        "$count events • $registrations registrations",
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryTextColor,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEventTrends() {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Event Creation Trends",
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryTextColor,
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          Container(
            height: 150,
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
            ),
            child: Center(
              child: Text(
                "Event Trends Chart\n(Implementation pending)",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(color: AppTheme.secondaryTextColor),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoticeEngagement() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('notices').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingWidget();
        }

        if (!snapshot.hasData) {
          return const SizedBox();
        }

        final notices = snapshot.data!.docs.map((doc) {
          return NoticeModel.fromMap(
            doc.data() as Map<String, dynamic>,
            doc.id,
          );
        }).toList();

        final totalNotices = notices.length;
        final totalReads = notices
            .map((n) => n.readBy.length)
            .fold(0, (a, b) => a + b);
        final avgReadsPerNotice = totalNotices > 0
            ? (totalReads / totalNotices).round()
            : 0;

        return CustomCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Notice Engagement",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryTextColor,
                ),
              ),
              const SizedBox(height: AppTheme.spacingM),
              Row(
                children: [
                  Expanded(
                    child: _buildEngagementCard(
                      "Total Reads",
                      "$totalReads",
                      Icons.visibility,
                      AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingS),
                  Expanded(
                    child: _buildEngagementCard(
                      "Avg per Notice",
                      "$avgReadsPerNotice",
                      Icons.trending_up,
                      AppTheme.successColor,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingS),
                  Expanded(
                    child: _buildEngagementCard(
                      "Read Rate",
                      "73.2%",
                      Icons.percent,
                      AppTheme.warningColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEngagementCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: AppTheme.spacingS),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: AppTheme.primaryTextColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCommunicationStats() {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Communication Statistics",
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryTextColor,
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          _buildCommunicationItem("Total Messages Sent", "12,345"),
          _buildCommunicationItem("Active Chat Rooms", "89"),
          _buildCommunicationItem("Average Response Time", "2m 34s"),
          _buildCommunicationItem("User Satisfaction", "4.7/5.0"),
        ],
      ),
    );
  }

  Widget _buildCommunicationItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingS),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppTheme.primaryTextColor,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackAnalysis() {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Feedback Analysis",
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryTextColor,
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          Row(
            children: [
              Expanded(
                child: _buildFeedbackCard(
                  "Positive",
                  "78%",
                  AppTheme.successColor,
                ),
              ),
              const SizedBox(width: AppTheme.spacingS),
              Expanded(
                child: _buildFeedbackCard(
                  "Neutral",
                  "15%",
                  AppTheme.warningColor,
                ),
              ),
              const SizedBox(width: AppTheme.spacingS),
              Expanded(
                child: _buildFeedbackCard(
                  "Negative",
                  "7%",
                  AppTheme.errorColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackCard(String label, String percentage, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
      ),
      child: Column(
        children: [
          Text(
            percentage,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppTheme.primaryTextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlatformUsage() {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Platform Usage",
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryTextColor,
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          _buildUsageItem("Mobile App", "68%", AppTheme.primaryColor),
          _buildUsageItem("Web Browser", "32%", AppTheme.accentColor),
          const SizedBox(height: AppTheme.spacingM),
          Text(
            "Peak Usage Hours",
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryTextColor,
            ),
          ),
          const SizedBox(height: AppTheme.spacingS),
          _buildUsageItem("Morning (9-12)", "35%", AppTheme.successColor),
          _buildUsageItem("Afternoon (12-17)", "45%", AppTheme.warningColor),
          _buildUsageItem("Evening (17-21)", "20%", AppTheme.errorColor),
        ],
      ),
    );
  }

  Widget _buildUsageItem(String label, String percentage, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingS),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: AppTheme.spacingS),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppTheme.primaryTextColor,
              ),
            ),
          ),
          Text(
            percentage,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Stream<List<QuerySnapshot>> _getCombinedSystemData() async* {
    await for (final users
        in FirebaseFirestore.instance.collection('users').snapshots()) {
      await for (final events
          in FirebaseFirestore.instance.collection('events').snapshots()) {
        await for (final notices
            in FirebaseFirestore.instance.collection('notices').snapshots()) {
          yield [users, events, notices];
        }
      }
    }
  }
}
