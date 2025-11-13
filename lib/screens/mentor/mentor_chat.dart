import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../utils/app_theme.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/empty_state_widget.dart';

class MentorChatScreen extends StatefulWidget {
  const MentorChatScreen({super.key});

  @override
  State<MentorChatScreen> createState() => _MentorChatScreenState();
}

class _MentorChatScreenState extends State<MentorChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _selectedStudentId;
  String? _selectedStudentName;
  List<Map<String, dynamic>> _students = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadStudents() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      // Get teacher's department and semester
      final teacherDoc = await FirebaseFirestore.instance
          .collection('mentors')
          .where('userId', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (teacherDoc.docs.isNotEmpty) {
        final teacherData = teacherDoc.docs.first.data();
        final department = teacherData['department'];
        final semester = teacherData['semester'];

        // Get students from same department and semester
        final studentsSnapshot = await FirebaseFirestore.instance
            .collection('students')
            .where('department', isEqualTo: department)
            .where('semester', isEqualTo: semester)
            .get();

        setState(() {
          _students = studentsSnapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              'name': data['name'] ?? 'Student',
              'department': data['department'] ?? '',
              'semester': data['semester'] ?? '',
            };
          }).toList();
        });
      }
    } catch (e) {
      print('Error loading students: $e');
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
          _selectedStudentName != null
              ? 'Chat with $_selectedStudentName'
              : 'Select Student',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.primaryTextColor,
        elevation: 0,
        actions: [
          if (_selectedStudentId != null)
            IconButton(
              onPressed: () {
                setState(() {
                  _selectedStudentId = null;
                  _selectedStudentName = null;
                });
              },
              icon: const Icon(Icons.close),
              tooltip: 'Back to student list',
            ),
        ],
      ),
      body: _selectedStudentId == null
          ? _buildStudentList()
          : _buildChatInterface(),
    );
  }

  Widget _buildStudentList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_students.isEmpty) {
      return const Center(
        child: EmptyStateWidget(
          title: 'No students available',
          subtitle: 'No students found in your department and semester',
          icon: Icons.person_off,
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      itemCount: _students.length,
      itemBuilder: (context, index) {
        final student = _students[index];
        return CustomCard(
          margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
          child: ListTile(
            leading: CircleAvatar(
              child: Text(
                student['name'][0].toUpperCase(),
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(
              student['name'],
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              '${student['department']} • ${student['semester']}',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppTheme.secondaryTextColor,
              ),
            ),
            trailing: const Icon(Icons.chat),
            onTap: () {
              setState(() {
                _selectedStudentId = student['id'];
                _selectedStudentName = student['name'];
              });
            },
          ),
        );
      },
    );
  }

  Widget _buildChatInterface() {
    return Column(
      children: [
        // Messages
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('chats')
                .where(
                  'participants',
                  arrayContains: FirebaseAuth.instance.currentUser!.uid,
                )
                .where('studentId', isEqualTo: _selectedStudentId)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: EmptyStateWidget(
                    title: 'No messages yet',
                    subtitle: 'Start a conversation with your student',
                    icon: Icons.chat_bubble_outline,
                  ),
                );
              }

              final messages = snapshot.data!.docs;

              // Auto-scroll to latest after frame paints
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (_scrollController.hasClients) {
                  _scrollController.animateTo(
                    0,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                  );
                }
              });
              return ListView.builder(
                controller: _scrollController,
                reverse: true,
                padding: const EdgeInsets.all(AppTheme.spacingM),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final message =
                      messages[index].data() as Map<String, dynamic>;
                  final isMe =
                      message['senderId'] ==
                      FirebaseAuth.instance.currentUser!.uid;

                  return _buildMessageBubble(message, isMe);
                },
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: AppTheme.dividerColor)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: const BoxDecoration(
                  color: AppTheme.primaryColor,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: _messageController.text.trim().isEmpty
                      ? null
                      : _sendMessage,
                  icon: const Icon(Icons.send, color: Colors.white, size: 20),
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message, bool isMe) {
    return Container(
      margin: EdgeInsets.only(
        bottom: AppTheme.spacingS,
        left: isMe ? 50 : 0,
        right: isMe ? 0 : 50,
      ),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
              child: Icon(Icons.person, size: 16, color: AppTheme.primaryColor),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? AppTheme.primaryColor : Colors.grey[200],
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isMe ? 20 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message['text'] ?? '',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: isMe ? Colors.white : AppTheme.primaryTextColor,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        DateFormat(
                          'hh:mm a',
                        ).format(_toDateTime(message['timestamp'])),
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: isMe
                              ? Colors.white70
                              : AppTheme.secondaryTextColor,
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        Icon(Icons.done_all, size: 14, color: Colors.white70),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.primaryColor,
              child: Icon(Icons.person, size: 16, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }

  DateTime _toDateTime(dynamic ts) {
    if (ts == null) return DateTime.now(); 
    if (ts is Timestamp) return ts.toDate();
    if (ts is int) return DateTime.fromMillisecondsSinceEpoch(ts);
    if (ts is String) {
      final parsed = int.tryParse(ts);
      if (parsed != null) return DateTime.fromMillisecondsSinceEpoch(parsed);
    }
    return DateTime.now();
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance.collection('chats').add({
        'senderId': user.uid,
        'senderName': user.displayName ?? 'Mentor',
        'studentId': _selectedStudentId,
        'text': _messageController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
        'participants': [user.uid, _selectedStudentId!],
        'createdAt': FieldValue.serverTimestamp(),
      });

      _messageController.clear();

      // Scroll to bottom
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send message: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }
}
