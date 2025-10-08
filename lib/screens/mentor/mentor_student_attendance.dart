import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/app_theme.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/empty_state_widget.dart';
import '../../models/attendance_model.dart';

class MentorStudentAttendanceScreen extends StatelessWidget {
  final String studentId;
  final String studentName;

  const MentorStudentAttendanceScreen({
    super.key,
    required this.studentId,
    required this.studentName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Attendance • $studentName',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.primaryTextColor,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('attendance')
            .where('studentId', isEqualTo: studentId)
            .orderBy('date', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingWidget(message: 'Loading attendance...');
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const EmptyStateWidget(
              title: 'No attendance data',
              subtitle: 'Records will appear here when available',
              icon: Icons.check_circle,
            );
          }

          final records = snapshot.data!.docs
              .map(
                (d) => AttendanceModel.fromMap(
                  d.data() as Map<String, dynamic>,
                  d.id,
                ),
              )
              .toList();
          final total = records.length;
          final attended = records.where((r) => r.isPresent).length;
          final percentage = total > 0 ? attended / total * 100 : 0.0;

          return ListView(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            children: [
              _buildHeaderStats(percentage, total, attended),
              const SizedBox(height: AppTheme.spacingM),
              ...records.map(_buildRecordTile),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeaderStats(double pct, int total, int attended) {
    return CustomCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Overall',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: (pct / 100).clamp(0, 1),
                  backgroundColor: AppTheme.surfaceColor,
                  valueColor: AlwaysStoppedAnimation(_colorForPct(pct)),
                  minHeight: 8,
                ),
                const SizedBox(height: 6),
                Text(
                  '${pct.toStringAsFixed(1)}% • $attended/$total classes',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppTheme.secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordTile(AttendanceModel r) {
    return CustomCard(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingS),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (r.isPresent ? AppTheme.successColor : AppTheme.errorColor)
                .withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            r.isPresent ? Icons.check : Icons.close,
            color: r.isPresent ? AppTheme.successColor : AppTheme.errorColor,
          ),
        ),
        title: Text(
          r.subjectName ?? 'Subject',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          DateTime.fromMillisecondsSinceEpoch(
            r.date.millisecondsSinceEpoch,
          ).toLocal().toString(),
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: AppTheme.secondaryTextColor,
          ),
        ),
        trailing: Text(
          r.isPresent ? 'Present' : 'Absent',
          style: GoogleFonts.poppins(fontSize: 12),
        ),
      ),
    );
  }

  Color _colorForPct(double p) {
    if (p >= 85) return AppTheme.successColor;
    if (p >= 75) return AppTheme.warningColor;
    return AppTheme.errorColor;
  }
}
