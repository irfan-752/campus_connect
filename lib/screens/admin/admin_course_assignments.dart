import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/app_theme.dart';
import '../../utils/responsive_helper.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/responsive_wrapper.dart';
import '../../models/course_assignment_model.dart';
import '../../models/mentor_model.dart';
import '../../models/student_model.dart';

class AdminCourseAssignmentsScreen extends StatefulWidget {
  const AdminCourseAssignmentsScreen({super.key});

  @override
  State<AdminCourseAssignmentsScreen> createState() =>
      _AdminCourseAssignmentsScreenState();
}

class _AdminCourseAssignmentsScreenState
    extends State<AdminCourseAssignmentsScreen> {
  bool _isLoading = false;
  List<CourseAssignmentModel> _assignments = [];
  List<MentorModel> _teachers = [];
  List<StudentModel> _students = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load assignments
      final assignments = await FirebaseFirestore.instance
          .collection('course_assignments')
          .get();

      setState(() {
        _assignments = assignments.docs
            .map((doc) => CourseAssignmentModel.fromMap(doc.data(), doc.id))
            .toList();
      });

      // Load teachers
      final teachers = await FirebaseFirestore.instance
          .collection('mentors')
          .get();

      setState(() {
        _teachers = teachers.docs
            .map((doc) => MentorModel.fromMap(doc.data(), doc.id))
            .toList();
      });

      // Load students
      final students = await FirebaseFirestore.instance
          .collection('students')
          .get();

      setState(() {
        _students = students.docs
            .map((doc) => StudentModel.fromMap(doc.data(), doc.id))
            .toList();
      });
    } catch (e) {
      print('Error loading data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Course Assignments',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.primaryTextColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showCreateAssignmentDialog,
            tooltip: 'Assign Teacher',
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingWidget(message: 'Loading assignments...')
          : _assignments.isEmpty
          ? const EmptyStateWidget(
              title: 'No Course Assignments',
              subtitle: 'Assign teachers to courses to get started',
              icon: Icons.school,
            )
          : ResponsiveWrapper(
              child: ListView.builder(
                padding: EdgeInsets.all(
                  ResponsiveHelper.responsiveValue(
                    context,
                    mobile: AppTheme.spacingM,
                    tablet: AppTheme.spacingL,
                    desktop: AppTheme.spacingXL,
                  ),
                ),
              itemCount: _assignments.length,
              itemBuilder: (context, index) {
                final assignment = _assignments[index];
                return _buildAssignmentCard(assignment);
              },
            ),
            ),
    );
  }

  Widget _buildAssignmentCard(CourseAssignmentModel assignment) {
    return CustomCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.school, color: AppTheme.primaryColor, size: 24),
        ),
        title: Text(
          assignment.courseName,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Teacher: ${assignment.teacherName}',
              style: GoogleFonts.poppins(fontSize: 12),
            ),
            Text(
              '${assignment.department} • Semester ${assignment.semester}',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppTheme.secondaryTextColor,
              ),
            ),
            Text(
              'Students: ${assignment.studentIds.length}',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppTheme.secondaryTextColor,
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'edit':
                _showEditAssignmentDialog(assignment);
                break;
              case 'students':
                _showStudentListDialog(assignment);
                break;
              case 'delete':
                _deleteAssignment(assignment);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 16),
                  SizedBox(width: 8),
                  Text('Edit'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'students',
              child: Row(
                children: [
                  Icon(Icons.people, size: 16),
                  SizedBox(width: 8),
                  Text('View Students'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red, size: 16),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateAssignmentDialog() {
    showDialog(
      context: context,
      builder: (context) => _CreateAssignmentDialog(
        teachers: _teachers,
        students: _students,
        onAssignmentCreated: _loadData,
      ),
    );
  }

  void _showEditAssignmentDialog(CourseAssignmentModel assignment) {
    showDialog(
      context: context,
      builder: (context) => _EditAssignmentDialog(
        assignment: assignment,
        teachers: _teachers,
        students: _students,
        onAssignmentUpdated: _loadData,
      ),
    );
  }

  void _showStudentListDialog(CourseAssignmentModel assignment) {
    final assignedStudents = _students
        .where((student) => assignment.studentIds.contains(student.id))
        .toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Students in ${assignment.courseName}',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: assignedStudents.length,
            itemBuilder: (context, index) {
              final student = assignedStudents[index];
              return ListTile(
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
                title: Text(student.name),
                subtitle: Text('Roll: ${student.rollNumber}'),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAssignment(CourseAssignmentModel assignment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Assignment',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to delete this course assignment?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance
            .collection('course_assignments')
            .doc(assignment.id)
            .delete();

        _loadData();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Assignment deleted successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete assignment: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }
}

class _CreateAssignmentDialog extends StatefulWidget {
  final List<MentorModel> teachers;
  final List<StudentModel> students;
  final VoidCallback onAssignmentCreated;

  const _CreateAssignmentDialog({
    required this.teachers,
    required this.students,
    required this.onAssignmentCreated,
  });

  @override
  State<_CreateAssignmentDialog> createState() =>
      _CreateAssignmentDialogState();
}

class _CreateAssignmentDialogState extends State<_CreateAssignmentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _courseNameController = TextEditingController();
  final _courseCodeController = TextEditingController();
  final _departmentController = TextEditingController();
  final _semesterController = TextEditingController();

  String? _selectedTeacherId;
  List<String> _selectedStudentIds = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _courseNameController.dispose();
    _courseCodeController.dispose();
    _departmentController.dispose();
    _semesterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.school, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Assign Teacher to Course',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTextField(
                        controller: _courseNameController,
                        label: 'Course Name',
                        hint: 'Enter course name',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter course name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _courseCodeController,
                        label: 'Course Code',
                        hint: 'Enter course code',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter course code';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _departmentController,
                        label: 'Department',
                        hint: 'Enter department',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter department';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _semesterController,
                        label: 'Semester',
                        hint: 'Enter semester',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter semester';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildTeacherDropdown(),
                      const SizedBox(height: 16),
                      _buildStudentSelection(),
                      const SizedBox(height: 24),
                      _buildActionButtons(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.primaryTextColor,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          style: GoogleFonts.poppins(),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(color: AppTheme.secondaryTextColor),
            filled: true,
            fillColor: AppTheme.surfaceColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTeacherDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Teacher',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.primaryTextColor,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedTeacherId,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppTheme.surfaceColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          items: widget.teachers.map((teacher) {
            return DropdownMenuItem<String>(
              value: teacher.id,
              child: Text('${teacher.name} (${teacher.department})'),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedTeacherId = value;
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select a teacher';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildStudentSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Students',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.primaryTextColor,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 200,
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.dividerColor),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListView.builder(
            itemCount: widget.students.length,
            itemBuilder: (context, index) {
              final student = widget.students[index];
              final isSelected = _selectedStudentIds.contains(student.id);

              return CheckboxListTile(
                title: Text(student.name),
                subtitle: Text(
                  'Roll: ${student.rollNumber} • ${student.department}',
                ),
                value: isSelected,
                onChanged: (value) {
                  setState(() {
                    if (value == true) {
                      _selectedStudentIds.add(student.id);
                    } else {
                      _selectedStudentIds.remove(student.id);
                    }
                  });
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: _isLoading ? null : () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _isLoading ? null : _createAssignment,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    'Create Assignment',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                  ),
          ),
        ),
      ],
    );
  }

  Future<void> _createAssignment() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTeacherId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final selectedTeacher = widget.teachers.firstWhere(
        (teacher) => teacher.id == _selectedTeacherId,
      );

      final assignment = CourseAssignmentModel(
        id: '',
        teacherId: _selectedTeacherId!,
        teacherName: selectedTeacher.name,
        courseId: _courseCodeController.text.trim(),
        courseName: _courseNameController.text.trim(),
        department: _departmentController.text.trim(),
        semester: _semesterController.text.trim(),
        studentIds: _selectedStudentIds,
        assignedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await FirebaseFirestore.instance
          .collection('course_assignments')
          .add(assignment.toMap());

      if (mounted) {
        Navigator.pop(context);
        widget.onAssignmentCreated();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Assignment created successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create assignment: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

class _EditAssignmentDialog extends StatefulWidget {
  final CourseAssignmentModel assignment;
  final List<MentorModel> teachers;
  final List<StudentModel> students;
  final VoidCallback onAssignmentUpdated;

  const _EditAssignmentDialog({
    required this.assignment,
    required this.teachers,
    required this.students,
    required this.onAssignmentUpdated,
  });

  @override
  State<_EditAssignmentDialog> createState() => _EditAssignmentDialogState();
}

class _EditAssignmentDialogState extends State<_EditAssignmentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _courseNameController = TextEditingController();
  final _courseCodeController = TextEditingController();
  final _departmentController = TextEditingController();
  final _semesterController = TextEditingController();

  String? _selectedTeacherId;
  List<String> _selectedStudentIds = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _courseNameController.text = widget.assignment.courseName;
    _courseCodeController.text = widget.assignment.courseId;
    _departmentController.text = widget.assignment.department;
    _semesterController.text = widget.assignment.semester;
    _selectedTeacherId = widget.assignment.teacherId;
    _selectedStudentIds = List.from(widget.assignment.studentIds);
  }

  @override
  void dispose() {
    _courseNameController.dispose();
    _courseCodeController.dispose();
    _departmentController.dispose();
    _semesterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.edit, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Edit Assignment',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTextField(
                        controller: _courseNameController,
                        label: 'Course Name',
                        hint: 'Enter course name',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter course name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _courseCodeController,
                        label: 'Course Code',
                        hint: 'Enter course code',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter course code';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _departmentController,
                        label: 'Department',
                        hint: 'Enter department',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter department';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _semesterController,
                        label: 'Semester',
                        hint: 'Enter semester',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter semester';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildTeacherDropdown(),
                      const SizedBox(height: 16),
                      _buildStudentSelection(),
                      const SizedBox(height: 24),
                      _buildActionButtons(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.primaryTextColor,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          style: GoogleFonts.poppins(),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(color: AppTheme.secondaryTextColor),
            filled: true,
            fillColor: AppTheme.surfaceColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTeacherDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Teacher',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.primaryTextColor,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedTeacherId,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppTheme.surfaceColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          items: widget.teachers.map((teacher) {
            return DropdownMenuItem<String>(
              value: teacher.id,
              child: Text('${teacher.name} (${teacher.department})'),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedTeacherId = value;
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select a teacher';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildStudentSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Students',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.primaryTextColor,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 200,
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.dividerColor),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListView.builder(
            itemCount: widget.students.length,
            itemBuilder: (context, index) {
              final student = widget.students[index];
              final isSelected = _selectedStudentIds.contains(student.id);

              return CheckboxListTile(
                title: Text(student.name),
                subtitle: Text(
                  'Roll: ${student.rollNumber} • ${student.department}',
                ),
                value: isSelected,
                onChanged: (value) {
                  setState(() {
                    if (value == true) {
                      _selectedStudentIds.add(student.id);
                    } else {
                      _selectedStudentIds.remove(student.id);
                    }
                  });
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: _isLoading ? null : () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _isLoading ? null : _updateAssignment,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    'Update Assignment',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                  ),
          ),
        ),
      ],
    );
  }

  Future<void> _updateAssignment() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTeacherId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final selectedTeacher = widget.teachers.firstWhere(
        (teacher) => teacher.id == _selectedTeacherId,
      );

      final updatedData = {
        'courseName': _courseNameController.text.trim(),
        'courseId': _courseCodeController.text.trim(),
        'department': _departmentController.text.trim(),
        'semester': _semesterController.text.trim(),
        'teacherId': _selectedTeacherId!,
        'teacherName': selectedTeacher.name,
        'studentIds': _selectedStudentIds,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      };

      await FirebaseFirestore.instance
          .collection('course_assignments')
          .doc(widget.assignment.id)
          .update(updatedData);

      if (mounted) {
        Navigator.pop(context);
        widget.onAssignmentUpdated();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Assignment updated successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update assignment: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
