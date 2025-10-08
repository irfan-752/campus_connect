import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../utils/app_theme.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/empty_state_widget.dart';
import '../../models/attendance_model.dart';

class StudentAttendanceScreen extends StatefulWidget {
  const StudentAttendanceScreen({super.key});

  @override
  State<StudentAttendanceScreen> createState() =>
      _StudentAttendanceScreenState();
}

class _StudentAttendanceScreenState extends State<StudentAttendanceScreen> {
  DateTime _selectedDate = DateTime.now();
  List<AttendanceModel> _attendanceRecords = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAttendance();
  }

  Future<void> _loadAttendance() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final snapshot = await FirebaseFirestore.instance
          .collection('attendance')
          .where('studentId', isEqualTo: user.uid)
          .where('date', isEqualTo: dateStr)
          .get();

      setState(() {
        _attendanceRecords = snapshot.docs.map((doc) {
          return AttendanceModel.fromMap(doc.data(), doc.id);
        }).toList();
      });
    } catch (e) {
      print('Error loading attendance: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'My Attendance',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.primaryTextColor,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Date selector
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: AppTheme.dividerColor)),
            ),
            child: Row(
              children: [
                Text(
                  'Attendance for ${DateFormat('MMM dd, yyyy').format(_selectedDate)}',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: _selectDate,
                  icon: const Icon(Icons.calendar_today),
                  tooltip: 'Select Date',
                ),
              ],
            ),
          ),

          // Attendance records
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _attendanceRecords.isEmpty
                ? const Center(
                    child: EmptyStateWidget(
                      title: 'No attendance record',
                      subtitle: 'No attendance marked for this date',
                      icon: Icons.event_busy,
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(AppTheme.spacingM),
                    itemCount: _attendanceRecords.length,
                    itemBuilder: (context, index) {
                      final record = _attendanceRecords[index];
                      return _buildAttendanceCard(record);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceCard(AttendanceModel record) {
    Color statusColor;
    IconData statusIcon;

    switch (record.status) {
      case 'Present':
        statusColor = AppTheme.successColor;
        statusIcon = Icons.check_circle;
        break;
      case 'Late':
        statusColor = AppTheme.warningColor;
        statusIcon = Icons.schedule;
        break;
      default:
        statusColor = AppTheme.errorColor;
        statusIcon = Icons.cancel;
    }

    return CustomCard(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(statusIcon, color: statusColor, size: 20),
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Status: ${record.status}',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryTextColor,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingXS),
                    Text(
                      'Marked by: ${record.teacherId}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppTheme.secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  record.status,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),

          if (record.remarks != null && record.remarks!.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spacingM),
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingM),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Remarks:',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.secondaryTextColor,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingXS),
                  Text(
                    record.remarks!,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppTheme.primaryTextColor,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: AppTheme.spacingM),
          Row(
            children: [
              Icon(
                Icons.access_time,
                size: 16,
                color: AppTheme.secondaryTextColor,
              ),
              const SizedBox(width: AppTheme.spacingXS),
              Text(
                'Updated: ${DateFormat('MMM dd, yyyy • hh:mm a').format(record.updatedAt)}',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppTheme.secondaryTextColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadAttendance();
    }
  }
}
