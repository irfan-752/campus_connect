import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/app_theme.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/loading_widget.dart';

class AdminAttendanceReporting extends StatefulWidget {
  const AdminAttendanceReporting({super.key});

  @override
  State<AdminAttendanceReporting> createState() =>
      _AdminAttendanceReportingState();
}

class _AdminAttendanceReportingState extends State<AdminAttendanceReporting> {
  String _selectedDepartment = 'All';
  String _selectedSemester = 'All';
  String _selectedSubject = 'All';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Column(
        children: [
          _buildFilters(),
          Expanded(child: _buildSummaryAndList()),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      color: Colors.white,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildDropdown(
                  'Department',
                  _selectedDepartment,
                  ['All', 'CS', 'IT', 'Math', 'Physics'],
                  (v) {
                    setState(() => _selectedDepartment = v);
                  },
                ),
              ),
              const SizedBox(width: AppTheme.spacingS),
              Expanded(
                child: _buildDropdown(
                  'Semester',
                  _selectedSemester,
                  ['All', 'S1', 'S2', 'S3', 'S4', 'S5', 'S6'],
                  (v) {
                    setState(() => _selectedSemester = v);
                  },
                ),
              ),
              const SizedBox(width: AppTheme.spacingS),
              Expanded(
                child: _buildDropdown('Subject', _selectedSubject, ['All'], (
                  v,
                ) {
                  setState(() => _selectedSubject = v);
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    String value,
    List<String> items,
    Function(String) onChanged,
  ) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items
          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
          .toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: AppTheme.surfaceColor,
      ),
    );
  }

  Widget _buildSummaryAndList() {
    Query query = FirebaseFirestore.instance.collection('attendance');
    if (_selectedDepartment != 'All') {
      query = query.where('department', isEqualTo: _selectedDepartment);
    }
    if (_selectedSemester != 'All') {
      query = query.where('semester', isEqualTo: _selectedSemester);
    }
    if (_selectedSubject != 'All') {
      query = query.where('subjectName', isEqualTo: _selectedSubject);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.limit(500).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingWidget(message: 'Loading attendance...');
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Text(
              'No attendance records',
              style: GoogleFonts.poppins(color: AppTheme.secondaryTextColor),
            ),
          );
        }

        int total = docs.length;
        int present = 0;
        final Map<String, Map<String, int>> subjectAgg = {};
        for (final d in docs) {
          final data = d.data() as Map<String, dynamic>;
          final isPresent = (data['isPresent'] ?? false) as bool;
          if (isPresent) present++;
          final subject = (data['subjectName'] ?? 'Unknown') as String;
          subjectAgg.putIfAbsent(subject, () => {'total': 0, 'present': 0});
          subjectAgg[subject]!['total'] =
              (subjectAgg[subject]!['total'] ?? 0) + 1;
          if (isPresent)
            subjectAgg[subject]!['present'] =
                (subjectAgg[subject]!['present'] ?? 0) + 1;
        }
        final overallPct = total > 0 ? (present / total * 100) : 0.0;

        return ListView(
          padding: const EdgeInsets.all(AppTheme.spacingM),
          children: [
            _buildOverallCard(overallPct, total, present),
            const SizedBox(height: AppTheme.spacingM),
            _buildSubjectSummary(subjectAgg),
          ],
        );
      },
    );
  }

  Widget _buildOverallCard(double pct, int total, int present) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Overall Attendance',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: (pct / 100).clamp(0, 1),
            backgroundColor: AppTheme.surfaceColor,
            valueColor: AlwaysStoppedAnimation(_colorForPct(pct)),
            minHeight: 8,
          ),
          const SizedBox(height: 6),
          Text(
            '${pct.toStringAsFixed(1)}% • $present/$total classes',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppTheme.secondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectSummary(Map<String, Map<String, int>> agg) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'By Subject',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          ...agg.entries.map((e) {
            final total = e.value['total'] ?? 0;
            final present = e.value['present'] ?? 0;
            final pct = total > 0 ? present / total * 100 : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.spacingS),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      e.key,
                      style: GoogleFonts.poppins(fontSize: 14),
                    ),
                  ),
                  SizedBox(
                    width: 120,
                    child: LinearProgressIndicator(
                      value: (pct / 100).clamp(0, 1),
                      backgroundColor: AppTheme.surfaceColor,
                      valueColor: AlwaysStoppedAnimation(_colorForPct(pct)),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${pct.toStringAsFixed(0)}%',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppTheme.secondaryTextColor,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Color _colorForPct(double p) {
    if (p >= 85) return AppTheme.successColor;
    if (p >= 75) return AppTheme.warningColor;
    return AppTheme.errorColor;
  }
}
