import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/app_theme.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/responsive_wrapper.dart';
import '../../services/attendance_analytics_service.dart';

class StudentAttendanceAnalyticsScreen extends StatefulWidget {
  const StudentAttendanceAnalyticsScreen({super.key});

  @override
  State<StudentAttendanceAnalyticsScreen> createState() =>
      _StudentAttendanceAnalyticsScreenState();
}

class _StudentAttendanceAnalyticsScreenState
    extends State<StudentAttendanceAnalyticsScreen> {
  final AttendanceAnalyticsService _analyticsService =
      AttendanceAnalyticsService();
  Map<String, dynamic>? _analytics;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _loading = true);
    try {
      final analytics = await _analyticsService.getStudentAttendanceAnalytics(
        user.uid,
      );
      setState(() => _analytics = analytics);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: const CustomAppBar(title: 'Attendance Analytics'),
      body: _loading
          ? const LoadingWidget(message: 'Analyzing attendance...')
          : _analytics == null
              ? const Center(child: Text('No data available'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(AppTheme.spacingM),
                  child: ResponsiveWrapper(
                    centerContent: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildOverviewCards(),
                        const SizedBox(height: AppTheme.spacingL),
                        _buildPredictionCard(),
                        const SizedBox(height: AppTheme.spacingL),
                        _buildRecommendationsCard(),
                        const SizedBox(height: AppTheme.spacingL),
                        _buildSubjectBreakdown(),
                        const SizedBox(height: AppTheme.spacingL),
                        _buildTrendChart(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildOverviewCards() {
    final overall = _analytics!['overallPercentage'] as double;
    final monthly = _analytics!['monthlyPercentage'] as double;
    final semester = _analytics!['semesterPercentage'] as double;
    final lastWeek = _analytics!['lastWeekPercentage'] as double;

    return ResponsiveGrid(
      mobileColumns: 2,
      tabletColumns: 4,
      desktopColumns: 4,
      children: [
        _buildStatCard('Overall', overall, Icons.trending_up),
        _buildStatCard('Monthly', monthly, Icons.calendar_month),
        _buildStatCard('Semester', semester, Icons.school),
        _buildStatCard('Last Week', lastWeek, Icons.access_time),
      ],
    );
  }

  Widget _buildStatCard(String title, double value, IconData icon) {
    final color = value >= 75
        ? AppTheme.successColor
        : value >= 60
            ? AppTheme.warningColor
            : AppTheme.errorColor;

    return CustomCard(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: AppTheme.spacingS),
          Text(
            '${value.toStringAsFixed(1)}%',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: AppTheme.spacingXS),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppTheme.secondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPredictionCard() {
    final predicted = _analytics!['predictedPercentage'] as double;
    final riskLevel = _analytics!['riskLevel'] as String;

    Color riskColor;
    String riskText;
    IconData riskIcon;

    switch (riskLevel) {
      case 'low':
        riskColor = AppTheme.successColor;
        riskText = 'Low Risk';
        riskIcon = Icons.check_circle;
        break;
      case 'medium':
        riskColor = AppTheme.warningColor;
        riskText = 'Medium Risk';
        riskIcon = Icons.warning;
        break;
      case 'high':
        riskColor = AppTheme.errorColor;
        riskText = 'High Risk';
        riskIcon = Icons.error;
        break;
      default:
        riskColor = AppTheme.errorColor;
        riskText = 'Critical Risk';
        riskIcon = Icons.dangerous;
    }

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: AppTheme.primaryColor),
              const SizedBox(width: AppTheme.spacingS),
              Text(
                'AI Prediction',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingM),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Predicted Attendance',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: AppTheme.secondaryTextColor,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingXS),
                    Text(
                      '${predicted.toStringAsFixed(1)}%',
                      style: GoogleFonts.poppins(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingM),
                decoration: BoxDecoration(
                  color: riskColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Icon(riskIcon, color: riskColor, size: 32),
                    const SizedBox(height: AppTheme.spacingXS),
                    Text(
                      riskText,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: riskColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsCard() {
    final recommendations =
        _analytics!['recommendations'] as List<dynamic>;

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb, color: AppTheme.warningColor),
              const SizedBox(width: AppTheme.spacingS),
              Text(
                'Recommendations',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingM),
          ...recommendations.map((rec) => Padding(
                padding: const EdgeInsets.only(bottom: AppTheme.spacingS),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle_outline,
                        color: AppTheme.successColor, size: 20),
                    const SizedBox(width: AppTheme.spacingS),
                    Expanded(
                      child: Text(
                        rec.toString(),
                        style: GoogleFonts.poppins(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildSubjectBreakdown() {
    final breakdown = _analytics!['subjectBreakdown'] as Map<String, dynamic>;

    if (breakdown.isEmpty) {
      return const SizedBox.shrink();
    }

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Subject-wise Breakdown',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          ...breakdown.entries.map((entry) => Padding(
                padding: const EdgeInsets.only(bottom: AppTheme.spacingM),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            entry.key,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Text(
                          '${entry.value.toStringAsFixed(1)}%',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: (entry.value as double) >= 75
                                ? AppTheme.successColor
                                : AppTheme.errorColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacingXS),
                    LinearProgressIndicator(
                      value: (entry.value as double) / 100,
                      backgroundColor: AppTheme.surfaceColor,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        (entry.value as double) >= 75
                            ? AppTheme.successColor
                            : AppTheme.errorColor,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildTrendChart() {
    final total = _analytics!['totalClasses'] as int;
    final present = _analytics!['presentClasses'] as int;
    final absent = _analytics!['absentClasses'] as int;

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Summary',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem('Total Classes', total, Icons.event),
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: _buildSummaryItem('Present', present, Icons.check_circle,
                    AppTheme.successColor),
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: _buildSummaryItem('Absent', absent, Icons.cancel,
                    AppTheme.errorColor),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, int value, IconData icon,
      [Color? color]) {
    return Column(
      children: [
        Icon(icon, color: color ?? AppTheme.primaryColor, size: 32),
        const SizedBox(height: AppTheme.spacingXS),
        Text(
          value.toString(),
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color ?? AppTheme.primaryColor,
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
}

