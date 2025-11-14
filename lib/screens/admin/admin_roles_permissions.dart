import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/app_theme.dart';
import '../../utils/responsive_helper.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/responsive_wrapper.dart';
import '../../models/user_model.dart';

class AdminRolesPermissions extends StatefulWidget {
  const AdminRolesPermissions({super.key});

  @override
  State<AdminRolesPermissions> createState() => _AdminRolesPermissionsState();
}

class _AdminRolesPermissionsState extends State<AdminRolesPermissions> {
  String _selectedRole = 'Student';
  final List<String> _roles = ['Student', 'Teacher', 'Admin'];

  final Map<String, Map<String, bool>> _permissions = {
    'Student': {
      'viewAttendance': true,
      'viewEvents': true,
      'viewNotices': true,
      'createMarketplace': true,
      'joinClubs': true,
      'applyPlacements': true,
    },
    'Teacher': {
      'markAttendance': true,
      'postNotices': true,
      'createEvents': true,
      'viewStudents': true,
      'chatWithStudents': true,
    },
    'Admin': {
      'manageUsers': true,
      'manageEvents': true,
      'manageNotices': true,
      'viewAnalytics': true,
      'systemSettings': true,
    },
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: ResponsiveWrapper(
        child: Column(
          children: [
            _buildRoleSelector(),
            Expanded(
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
                    _buildPermissionsCard(),
                    const SizedBox(height: AppTheme.spacingL),
                    _buildUsersWithRole(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleSelector() {
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
          children: _roles.map((role) {
            final isSelected = _selectedRole == role;
            return Padding(
              padding: const EdgeInsets.only(right: AppTheme.spacingS),
              child: FilterChip(
                label: Text(role),
                selected: isSelected,
                onSelected: (v) {
                  setState(() => _selectedRole = role);
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildPermissionsCard() {
    final rolePermissions = _permissions[_selectedRole] ?? {};

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Permissions for $_selectedRole',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          ...rolePermissions.entries.map((entry) {
            return SwitchListTile(
              title: Text(_formatPermissionName(entry.key)),
              value: entry.value,
              onChanged: (v) {
                setState(() {
                  _permissions[_selectedRole]![entry.key] = v;
                });
                _savePermissions();
              },
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildUsersWithRole() {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Users with $_selectedRole Role',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .where('role', isEqualTo: _selectedRole)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const LoadingWidget();
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('No users found'));
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final doc = snapshot.data!.docs[index];
                  final user = UserModel.fromMap(
                    doc.data() as Map<String, dynamic>,
                    doc.id,
                  );
                  return ListTile(
                    leading: CircleAvatar(
                      child: Text(user.name.isNotEmpty
                          ? user.name[0].toUpperCase()
                          : 'U'),
                    ),
                    title: Text(user.name),
                    subtitle: Text(user.email),
                    trailing: user.approved
                        ? const Icon(Icons.check_circle, color: AppTheme.successColor)
                        : const Icon(Icons.pending, color: AppTheme.warningColor),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  String _formatPermissionName(String permission) {
    return permission
        .replaceAllMapped(
          RegExp(r'([A-Z])'),
          (match) => ' ${match.group(0)}',
        )
        .trim()
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  Future<void> _savePermissions() async {
    try {
      await FirebaseFirestore.instance
          .collection('role_permissions')
          .doc(_selectedRole.toLowerCase())
          .set({
        'role': _selectedRole,
        'permissions': _permissions[_selectedRole],
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      }, SetOptions(merge: true));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving permissions: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }
}

