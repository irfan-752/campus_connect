import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../utils/app_theme.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/empty_state_widget.dart';
import '../../models/course_assignment_model.dart';
import '../../models/student_model.dart';
import '../../models/attendance_model.dart';

class MentorAttendanceMarkingScreen extends StatefulWidget {
  const MentorAttendanceMarkingScreen({super.key});

  @override
  State<MentorAttendanceMarkingScreen> createState() =>
      _MentorAttendanceMarkingScreenState();
}

class _MentorAttendanceMarkingScreenState
    extends State<MentorAttendanceMarkingScreen> {
  String? _selectedCourse;
  DateTime _selectedDate = DateTime.now();
  List<CourseAssignmentModel> _assignedCourses = [];
  List<StudentModel> _students = [];
  Map<String, bool> _attendanceStatus = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAssignedCourses();
  }

  Future<void> _loadAssignedCourses() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final assignments = await FirebaseFirestore.instance
          .collection('course_assignments')
          .where('teacherId', isEqualTo: user.uid)
          .where('isActive', isEqualTo: true)
          .get();

      setState(() {
        _assignedCourses = assignments.docs
            .map((doc) => CourseAssignmentModel.fromMap(doc.data(), doc.id))
            .toList();
      });

      if (_assignedCourses.isNotEmpty) {
        _selectedCourse = _assignedCourses.first.courseId;
        await _loadStudentsForCourse(_selectedCourse!);
      }
    } catch (e) {
      print('Error loading courses: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadStudentsForCourse(String courseId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final assignment = _assignedCourses.firstWhere(
        (course) => course.courseId == courseId,
      );

      if (assignment.studentIds.isEmpty) {
        setState(() {
          _students = [];
          _attendanceStatus = {};
        });
        return;
      }

      final students = await FirebaseFirestore.instance
          .collection('students')
          .where(FieldPath.documentId, whereIn: assignment.studentIds)
          .get();

      setState(() {
        _students = students.docs
            .map((doc) => StudentModel.fromMap(doc.data(), doc.id))
            .toList();
      });

      // Load existing attendance for the selected date
      await _loadExistingAttendance();
    } catch (e) {
      print('Error loading students: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadExistingAttendance() async {
    if (_selectedCourse == null) return;

    try {
      final attendance = await FirebaseFirestore.instance
          .collection('attendance')
          .where('subjectId', isEqualTo: _selectedCourse)
          .where('date', isEqualTo: Timestamp.fromDate(_selectedDate))
          .get();

      setState(() {
        _attendanceStatus = {};
        for (var doc in attendance.docs) {
          final data = doc.data();
          _attendanceStatus[data['studentId']] = data['isPresent'] ?? false;
        }
      });
    } catch (e) {
      print('Error loading existing attendance: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Mark Attendance',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.primaryTextColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveAttendance,
            tooltip: 'Save Attendance',
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingWidget(message: 'Loading...')
          : _assignedCourses.isEmpty
          ? const EmptyStateWidget(
              title: 'No Assigned Courses',
              subtitle: 'You have not been assigned to any courses yet',
              icon: Icons.school,
            )
          : Column(
              children: [
                _buildCourseSelector(),
                _buildDateSelector(),
                Expanded(child: _buildStudentList()),
              ],
            ),
    );
  }

  Widget _buildCourseSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Course',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryTextColor,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedCourse,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            items: _assignedCourses.map((course) {
              return DropdownMenuItem<String>(
                value: course.courseId,
                child: Text('${course.courseName} (${course.semester})'),
              );
            }).toList(),
            onChanged: (value) async {
              if (value != null) {
                setState(() {
                  _selectedCourse = value;
                });
                await _loadStudentsForCourse(value);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Date',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryTextColor,
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _selectDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.dividerColor),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          color: AppTheme.primaryColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('MMM dd, yyyy').format(_selectedDate),
                          style: GoogleFonts.poppins(),
                        ),
                      ],
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

  Widget _buildStudentList() {
    if (_students.isEmpty) {
      return const EmptyStateWidget(
        title: 'No Students',
        subtitle: 'No students are enrolled in this course',
        icon: Icons.people,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _students.length,
      itemBuilder: (context, index) {
        final student = _students[index];
        final isPresent = _attendanceStatus[student.id] ?? false;

        return CustomCard(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
              backgroundImage: student.avatarUrl != null
                  ? NetworkImage(student.avatarUrl!)
                  : null,
              child: student.avatarUrl == null
                  ? Text(
                      student.name.isNotEmpty
                          ? student.name[0].toUpperCase()
                          : 'S',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    )
                  : null,
            ),
            title: Text(
              student.name,
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              'Roll: ${student.rollNumber} • ${student.department}',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppTheme.secondaryTextColor,
              ),
            ),
            trailing: Switch(
              value: isPresent,
              onChanged: (value) {
                setState(() {
                  _attendanceStatus[student.id] = value;
                });
              },
              activeColor: AppTheme.successColor,
            ),
          ),
        );
      },
    );
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );

    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
      await _loadExistingAttendance();
    }
  }

  Future<void> _saveAttendance() async {
    if (_selectedCourse == null || _students.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final course = _assignedCourses.firstWhere(
        (c) => c.courseId == _selectedCourse,
      );

      final batch = FirebaseFirestore.instance.batch();

      for (final student in _students) {
        final attendanceRef = FirebaseFirestore.instance
            .collection('attendance')
            .doc(
              '${student.id}_${_selectedCourse}_${_selectedDate.millisecondsSinceEpoch}',
            );

        final attendance = AttendanceModel(
          id: attendanceRef.id,
          studentId: student.id,
          subjectId: _selectedCourse!,
          subjectName: course.courseName,
          date: _selectedDate,
          isPresent: _attendanceStatus[student.id] ?? false,
          teacherId: user.uid,
          createdAt: DateTime.now(),
        );

        batch.set(attendanceRef, attendance.toMap());
      }

      await batch.commit();

      // Update student attendance percentage
      await _updateStudentAttendancePercentage();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Attendance saved successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save attendance: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateStudentAttendancePercentage() async {
    for (final student in _students) {
      try {
        final attendanceRecords = await FirebaseFirestore.instance
            .collection('attendance')
            .where('studentId', isEqualTo: student.id)
            .where('subjectId', isEqualTo: _selectedCourse)
            .get();

        final totalClasses = attendanceRecords.docs.length;
        final attendedClasses = attendanceRecords.docs
            .where((doc) => doc.data()['isPresent'] == true)
            .length;

        final percentage = totalClasses > 0
            ? (attendedClasses / totalClasses) * 100
            : 0.0;

        await FirebaseFirestore.instance
            .collection('students')
            .doc(student.id)
            .update({
              'attendance': percentage,
              'updatedAt': DateTime.now().millisecondsSinceEpoch,
            });
      } catch (e) {
        print('Error updating attendance percentage for ${student.name}: $e');
      }
    }
  }
}
