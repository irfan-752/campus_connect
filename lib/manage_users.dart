import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageUsersScreen extends StatelessWidget {
  const ManageUsersScreen({super.key});

  Future<void> _approveUser(String userId) async {
    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'approved': true,
    });
  }

  Future<void> _rejectUser(String userId) async {
    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'approved': false,
    });
  }

  Future<void> _deleteUser(String userId) async {
    await FirebaseFirestore.instance.collection('users').doc(userId).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Users'),
        backgroundColor: const Color(0xFF0096FF),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final users = snapshot.data!.docs;
          if (users.isEmpty) {
            return const Center(child: Text('No users found.'));
          }
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index].data() as Map<String, dynamic>;
              final userId = users[index].id;
              final name = user['name'] ?? '';
              final email = user['email'] ?? '';
              final role = user['role'] ?? '';
              final approved = user['approved'] == true;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(name.isNotEmpty ? name[0] : '?'),
                  ),
                  title: Text(name),
                  subtitle: Text('$email\nRole: $role'),
                  isThreeLine: true,
                  trailing: role == 'Parent'
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              tooltip: 'Delete',
                              onPressed: () async {
                                await _deleteUser(userId);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Parent deleted'),
                                  ),
                                );
                              },
                            ),
                          ],
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.check_circle,
                                color: approved ? Colors.green : Colors.grey,
                              ),
                              tooltip: 'Approve',
                              onPressed: approved
                                  ? null
                                  : () async {
                                      await _approveUser(userId);
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text('$role approved'),
                                        ),
                                      );
                                    },
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.cancel,
                                color: !approved ? Colors.red : Colors.grey,
                              ),
                              tooltip: 'Reject',
                              onPressed: !approved
                                  ? null
                                  : () async {
                                      await _rejectUser(userId);
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text('$role rejected'),
                                        ),
                                      );
                                    },
                            ),
                          ],
                        ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
