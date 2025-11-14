import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/app_theme.dart';
import '../../utils/responsive_helper.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/responsive_wrapper.dart';

class StudentCareerGuidanceScreen extends StatefulWidget {
  const StudentCareerGuidanceScreen({super.key});

  @override
  State<StudentCareerGuidanceScreen> createState() =>
      _StudentCareerGuidanceScreenState();
}

class _StudentCareerGuidanceScreenState
    extends State<StudentCareerGuidanceScreen> {
  bool _loading = false;
  Map<String, dynamic>? _guidance;

  @override
  void initState() {
    super.initState();
    _loadCareerGuidance();
  }

  Future<void> _loadCareerGuidance() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _loading = true);
    try {
      // Get student profile
      final studentDoc = await FirebaseFirestore.instance
          .collection('students')
          .doc(user.uid)
          .get();

      if (studentDoc.exists) {
        final studentData = studentDoc.data()!;
        final department = studentData['department'] ?? '';
        final gpa = studentData['gpa'] ?? 0.0;
        final attendance = studentData['attendance'] ?? 0.0;

        // Get resume if exists
        final resumeSnapshot = await FirebaseFirestore.instance
            .collection('resumes')
            .where('studentId', isEqualTo: user.uid)
            .limit(1)
            .get();

        List<String> skills = [];
        if (resumeSnapshot.docs.isNotEmpty) {
          final resumeData = resumeSnapshot.docs.first.data();
          final resumeSkills = resumeData['skills'] as List?;
          if (resumeSkills != null) {
            skills = resumeSkills
                .map((s) => (s as Map)['name'] as String? ?? '')
                .where((s) => s.isNotEmpty)
                .toList();
          }
        }

        // Generate AI recommendations
        final recommendations = _generateRecommendations(
          department,
          gpa,
          attendance,
          skills,
        );

        setState(() {
          _guidance = {
            'careerPath': _suggestCareerPath(department, skills),
            'recommendedSkills': recommendations['skills'],
            'recommendedCourses': recommendations['courses'],
            'jobSuggestions': recommendations['jobs'],
            'aiRecommendations': recommendations['summary'],
          };
        });

        // Save to Firestore
        final existing = await FirebaseFirestore.instance
            .collection('career_guidance')
            .where('studentId', isEqualTo: user.uid)
            .limit(1)
            .get();

        final guidanceData = {
          'studentId': user.uid,
          'careerPath': _guidance!['careerPath'],
          'recommendedSkills': _guidance!['recommendedSkills'],
          'recommendedCourses': _guidance!['recommendedCourses'],
          'jobSuggestions': _guidance!['jobSuggestions'],
          'aiRecommendations': _guidance!['aiRecommendations'],
          'updatedAt': DateTime.now().millisecondsSinceEpoch,
        };

        if (existing.docs.isNotEmpty) {
          await FirebaseFirestore.instance
              .collection('career_guidance')
              .doc(existing.docs.first.id)
              .update(guidanceData);
        } else {
          await FirebaseFirestore.instance
              .collection('career_guidance')
              .add({
            ...guidanceData,
            'createdAt': DateTime.now().millisecondsSinceEpoch,
          });
        }
      }
    } catch (e) {
      print('Error loading career guidance: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _suggestCareerPath(String department, List<String> skills) {
    if (department.toLowerCase().contains('cs') ||
        department.toLowerCase().contains('computer')) {
      if (skills.any((s) => s.toLowerCase().contains('machine learning') ||
          s.toLowerCase().contains('ai'))) {
        return 'AI/ML Engineer';
      }
      if (skills.any((s) => s.toLowerCase().contains('web'))) {
        return 'Full Stack Developer';
      }
      return 'Software Engineer';
    }
    if (department.toLowerCase().contains('ee') ||
        department.toLowerCase().contains('electrical')) {
      return 'Electrical Engineer';
    }
    if (department.toLowerCase().contains('me') ||
        department.toLowerCase().contains('mechanical')) {
      return 'Mechanical Engineer';
    }
    return 'Professional in $department';
  }

  Map<String, dynamic> _generateRecommendations(
    String department,
    double gpa,
    double attendance,
    List<String> currentSkills,
  ) {
    final skills = <String>[];
    final courses = <String>[];
    final jobs = <String>[];

    // Skill recommendations based on department
    if (department.toLowerCase().contains('cs') ||
        department.toLowerCase().contains('computer')) {
      skills.addAll([
        'Data Structures & Algorithms',
        'System Design',
        'Cloud Computing',
        'DevOps',
      ]);
      courses.addAll([
        'Advanced Algorithms',
        'Cloud Architecture',
        'Microservices',
      ]);
      jobs.addAll([
        'Software Engineer',
        'Full Stack Developer',
        'DevOps Engineer',
      ]);
    } else {
      skills.addAll(['Project Management', 'Technical Writing', 'Communication']);
      courses.addAll(['Professional Development', 'Leadership Skills']);
    }

    // Attendance-based recommendations
    if (attendance < 75) {
      courses.insert(0, 'Focus on improving attendance');
    }

    // GPA-based recommendations
    if (gpa < 7.0) {
      courses.insert(0, 'Focus on core subjects');
    }

    String summary = 'Based on your profile:\n';
    summary += '• Department: $department\n';
    summary += '• Current GPA: ${gpa.toStringAsFixed(2)}\n';
    summary += '• Attendance: ${attendance.toStringAsFixed(1)}%\n\n';
    summary += 'Recommendations:\n';
    summary += '• Focus on building practical projects\n';
    summary += '• Participate in hackathons and coding competitions\n';
    summary += '• Build a strong portfolio\n';
    summary += '• Network with industry professionals';

    return {
      'skills': skills,
      'courses': courses,
      'jobs': jobs,
      'summary': summary,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: const CustomAppBar(title: 'Career Guidance'),
      body: _loading
          ? const LoadingWidget(message: 'Analyzing your profile...')
          : _guidance == null
              ? const Center(child: Text('No guidance available'))
              : ResponsiveWrapper(
                  centerContent: true,
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
                        _buildCareerPathCard(),
                        SizedBox(height: ResponsiveHelper.responsiveValue(
                          context,
                          mobile: AppTheme.spacingL,
                          tablet: AppTheme.spacingXL,
                          desktop: AppTheme.spacingXL,
                        )),
                        _buildRecommendationsCard(),
                        SizedBox(height: ResponsiveHelper.responsiveValue(
                          context,
                          mobile: AppTheme.spacingL,
                          tablet: AppTheme.spacingXL,
                          desktop: AppTheme.spacingXL,
                        )),
                        _buildSkillsCard(),
                        SizedBox(height: ResponsiveHelper.responsiveValue(
                          context,
                          mobile: AppTheme.spacingL,
                          tablet: AppTheme.spacingXL,
                          desktop: AppTheme.spacingXL,
                        )),
                        _buildCoursesCard(),
                        SizedBox(height: ResponsiveHelper.responsiveValue(
                          context,
                          mobile: AppTheme.spacingL,
                          tablet: AppTheme.spacingXL,
                          desktop: AppTheme.spacingXL,
                        )),
                        _buildJobSuggestionsCard(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildCareerPathCard() {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_up, color: AppTheme.primaryColor),
              const SizedBox(width: AppTheme.spacingS),
              Text(
                'Suggested Career Path',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingM),
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _guidance!['careerPath'] ?? 'Not determined',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsCard() {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb, color: AppTheme.warningColor),
              const SizedBox(width: AppTheme.spacingS),
              Text(
                'AI Recommendations',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingM),
          Text(
            _guidance!['aiRecommendations'] ?? '',
            style: GoogleFonts.poppins(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillsCard() {
    final skills = _guidance!['recommendedSkills'] as List<dynamic>? ?? [];

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recommended Skills',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          Wrap(
            spacing: AppTheme.spacingS,
            runSpacing: AppTheme.spacingS,
            children: skills.map((skill) {
              return Chip(
                label: Text(skill.toString()),
                backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCoursesCard() {
    final courses = _guidance!['recommendedCourses'] as List<dynamic>? ?? [];

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recommended Courses',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          ...courses.map((course) {
            return ListTile(
              leading: const Icon(Icons.school),
              title: Text(course.toString()),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildJobSuggestionsCard() {
    final jobs = _guidance!['jobSuggestions'] as List<dynamic>? ?? [];

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Job Suggestions',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          ...jobs.map((job) {
            return ListTile(
              leading: const Icon(Icons.work),
              title: Text(job.toString()),
              trailing: CustomButton(
                text: 'View Jobs',
                onPressed: () {
                  Navigator.pushNamed(context, '/student/placements');
                },
                size: ButtonSize.small,
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}

