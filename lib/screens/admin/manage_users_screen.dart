import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:campus_connect/utils/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _selectedFilter = 'All';

  Future<void> _approveUser(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'approved': true,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User approved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _rejectUser(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'approved': false,
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('User rejected')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _deleteUser(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Manage Users',
          style: GoogleFonts.poppins(
            fontSize: isMobile ? 18 : 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Filter Section
          Container(
            padding: EdgeInsets.all(isMobile ? 12 : 16),
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children:
                    [
                          'All',
                          'Student',
                          'Teacher',
                          'Parent',
                          'Approved',
                          'Pending',
                        ]
                        .map(
                          (filter) => Padding(
                            padding: EdgeInsets.only(right: isMobile ? 8 : 12),
                            child: FilterChip(
                              label: Text(
                                filter,
                                style: GoogleFonts.poppins(
                                  fontSize: isMobile ? 12 : 14,
                                ),
                              ),
                              selected: _selectedFilter == filter,
                              onSelected: (selected) {
                                setState(() => _selectedFilter = filter);
                              },
                              backgroundColor: Colors.grey[200],
                              selectedColor: AppTheme.primaryColor,
                              labelStyle: GoogleFonts.poppins(
                                color: _selectedFilter == filter
                                    ? Colors.white
                                    : Colors.black,
                              ),
                            ),
                          ),
                        )
                        .toList(),
              ),
            ),
          ),
          // Users List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryColor,
                    ),
                  );
                }

                var users = snapshot.data!.docs;

                // Apply filters
                users = users.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final role = data['role'] ?? '';
                  final approved = data['approved'] ?? false;

                  if (_selectedFilter == 'All') return true;
                  if (_selectedFilter == role) return true;
                  if (_selectedFilter == 'Approved' && approved) return true;
                  if (_selectedFilter == 'Pending' &&
                      !approved &&
                      role != 'Admin')
                    return true;
                  return false;
                }).toList();

                if (users.isEmpty) {
                  return Center(
                    child: Text(
                      'No users found',
                      style: GoogleFonts.poppins(color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.all(isMobile ? 8 : 12),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index].data() as Map<String, dynamic>;
                    final userId = users[index].id;
                    final name = user['name'] ?? 'Unknown';
                    final email = user['email'] ?? '';
                    final role = user['role'] ?? '';
                    final approved = user['approved'] ?? false;
                    final avatarUrl = user['avatarUrl'];

                    return _buildUserCard(
                      context,
                      isMobile,
                      userId,
                      name,
                      email,
                      role,
                      approved,
                      avatarUrl,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(
    BuildContext context,
    bool isMobile,
    String userId,
    String name,
    String email,
    String role,
    bool approved,
    String? avatarUrl,
  ) {
    final isParent = role == 'Parent';

    return Container(
      margin: EdgeInsets.symmetric(vertical: isMobile ? 6 : 8, horizontal: 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        child: Column(
          children: [
            // User Info Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                CircleAvatar(
                  radius: isMobile ? 24 : 32,
                  backgroundImage: avatarUrl != null
                      ? NetworkImage(avatarUrl)
                      : AssetImage('assets/images/user_avatar.png')
                            as ImageProvider,
                  child: avatarUrl == null
                      ? Icon(Icons.person, size: isMobile ? 24 : 32)
                      : null,
                ),
                SizedBox(width: isMobile ? 12 : 16),
                // User Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.poppins(
                          fontSize: isMobile ? 14 : 16,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      Text(
                        email,
                        style: GoogleFonts.poppins(
                          fontSize: isMobile ? 11 : 12,
                          color: Colors.grey,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 6),
                      // Role and Status Badges
                      Wrap(
                        spacing: 8,
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isMobile ? 8 : 10,
                              vertical: isMobile ? 4 : 6,
                            ),
                            decoration: BoxDecoration(
                              color: _getRoleColor(role).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              role,
                              style: GoogleFonts.poppins(
                                fontSize: isMobile ? 10 : 12,
                                fontWeight: FontWeight.w600,
                                color: _getRoleColor(role),
                              ),
                            ),
                          ),
                          if (!isParent)
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isMobile ? 8 : 10,
                                vertical: isMobile ? 4 : 6,
                              ),
                              decoration: BoxDecoration(
                                color: approved
                                    ? Colors.green.withOpacity(0.2)
                                    : Colors.orange.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                approved ? 'Approved' : 'Pending',
                                style: GoogleFonts.poppins(
                                  fontSize: isMobile ? 10 : 12,
                                  fontWeight: FontWeight.w600,
                                  color: approved
                                      ? Colors.green
                                      : Colors.orange,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: isMobile ? 12 : 16),
            // Action Buttons
            if (isParent)
              _buildParentActions(context, isMobile, userId)
            else
              _buildApprovalActions(context, isMobile, userId, approved),
          ],
        ),
      ),
    );
  }

  Widget _buildParentActions(
    BuildContext context,
    bool isMobile,
    String userId,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        ElevatedButton.icon(
          onPressed: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Delete Parent'),
                content: const Text(
                  'Are you sure you want to delete this parent account?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text(
                      'Delete',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            );
            if (confirm == true) {
              await _deleteUser(userId);
            }
          },
          icon: const Icon(Icons.delete, size: 18),
          label: Text(isMobile ? 'Delete' : 'Delete Parent'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 12 : 16,
              vertical: isMobile ? 8 : 10,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildApprovalActions(
    BuildContext context,
    bool isMobile,
    String userId,
    bool approved,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (!approved)
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _approveUser(userId),
              icon: const Icon(Icons.check_circle, size: 18),
              label: Text(
                isMobile ? 'Approve' : 'Approve User',
                style: GoogleFonts.poppins(fontSize: isMobile ? 12 : 14),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: isMobile ? 8 : 10),
              ),
            ),
          ),
        if (!approved) SizedBox(width: isMobile ? 8 : 12),
        if (approved)
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _rejectUser(userId),
              icon: const Icon(Icons.cancel, size: 18),
              label: Text(
                isMobile ? 'Reject' : 'Reject User',
                style: GoogleFonts.poppins(fontSize: isMobile ? 12 : 14),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: isMobile ? 8 : 10),
              ),
            ),
          ),
      ],
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'Student':
        return Colors.blue;
      case 'Teacher':
        return Colors.purple;
      case 'Parent':
        return Colors.green;
      case 'Admin':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
