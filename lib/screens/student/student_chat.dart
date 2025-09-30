import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../utils/app_theme.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/empty_state_widget.dart';
import '../../models/chat_model.dart';

class StudentChatScreen extends StatefulWidget {
  const StudentChatScreen({super.key});

  @override
  State<StudentChatScreen> createState() => _StudentChatScreenState();
}

class _StudentChatScreenState extends State<StudentChatScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _groupDescController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _groupNameController.dispose();
    _groupDescController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: const CustomAppBar(title: "Chats & Discussions"),
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildChatRooms(),
                _buildMentorChats(),
                _buildGroupDiscussions(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateChatOptions,
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showCreateGroupDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Create Study Group',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _groupNameController,
                decoration: const InputDecoration(hintText: 'Group name'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _groupDescController,
                decoration: const InputDecoration(
                  hintText: 'Description (optional)',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _createGroup,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _createGroup() async {
    final user = FirebaseAuth.instance.currentUser!;
    final now = DateTime.now();
    final room = ChatRoom(
      id: '',
      name: _groupNameController.text.trim(),
      description: _groupDescController.text.trim(),
      type: 'Group',
      participants: [user.uid],
      avatarUrl: null,
      createdBy: user.uid,
      createdAt: now,
      lastMessageAt: now,
      lastMessage: null,
      isActive: true,
    );
    await FirebaseFirestore.instance.collection('chat_rooms').add(room.toMap());
    Navigator.pop(context);
  }

  void _showStartMentorChatDialog() {
    final idController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Start Mentor Chat',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: TextField(
          controller: idController,
          decoration: const InputDecoration(
            hintText: 'Enter mentor (teacher) user ID',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final user = FirebaseAuth.instance.currentUser!;
              final mentorId = idController.text.trim();
              if (mentorId.isEmpty) return;
              final now = DateTime.now();
              final room = ChatRoom(
                id: '',
                name: 'Mentor Chat',
                description: 'Direct',
                type: 'Direct',
                participants: [user.uid, mentorId],
                avatarUrl: null,
                createdBy: user.uid,
                createdAt: now,
                lastMessageAt: now,
                lastMessage: null,
                isActive: true,
              );
              await FirebaseFirestore.instance
                  .collection('chat_rooms')
                  .add(room.toMap());
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Start'),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppTheme.dividerColor)),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: AppTheme.primaryColor,
        unselectedLabelColor: AppTheme.secondaryTextColor,
        labelStyle: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.normal,
        ),
        indicatorColor: AppTheme.primaryColor,
        tabs: const [
          Tab(text: "All Chats"),
          Tab(text: "Mentors"),
          Tab(text: "Groups"),
        ],
      ),
    );
  }

  Widget _buildChatRooms() {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chat_rooms')
          .where('participants', arrayContains: userId)
          .where('isActive', isEqualTo: true)
          .orderBy('lastMessageAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingWidget(message: "Loading chats...");
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const EmptyStateWidget(
            title: "No chats yet",
            subtitle:
                "Start a conversation with your mentors or join group discussions",
            icon: Icons.chat,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppTheme.spacingM),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final chatRoom = ChatRoom.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            );
            return _buildChatRoomCard(chatRoom);
          },
        );
      },
    );
  }

  Widget _buildMentorChats() {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chat_rooms')
          .where('participants', arrayContains: userId)
          .where('type', isEqualTo: 'Direct')
          .where('isActive', isEqualTo: true)
          .orderBy('lastMessageAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingWidget(message: "Loading mentor chats...");
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const EmptyStateWidget(
            title: "No mentor chats",
            subtitle: "Connect with your mentors to start conversations",
            icon: Icons.person,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppTheme.spacingM),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final chatRoom = ChatRoom.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            );
            return _buildChatRoomCard(chatRoom, isMentor: true);
          },
        );
      },
    );
  }

  Widget _buildGroupDiscussions() {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chat_rooms')
          .where('participants', arrayContains: userId)
          .where('type', whereIn: ['Group', 'Class', 'Event'])
          .where('isActive', isEqualTo: true)
          .orderBy('lastMessageAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingWidget(message: "Loading group discussions...");
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const EmptyStateWidget(
            title: "No group discussions",
            subtitle: "Join class groups or event discussions to collaborate",
            icon: Icons.group,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppTheme.spacingM),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final chatRoom = ChatRoom.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            );
            return _buildChatRoomCard(chatRoom, isGroup: true);
          },
        );
      },
    );
  }

  Widget _buildChatRoomCard(
    ChatRoom chatRoom, {
    bool isMentor = false,
    bool isGroup = false,
  }) {
    return CustomCard(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingS),
      onTap: () => _openChatRoom(chatRoom),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundImage: chatRoom.avatarUrl != null
                ? NetworkImage(chatRoom.avatarUrl!)
                : null,
            backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
            child: chatRoom.avatarUrl == null
                ? Icon(
                    _getChatIcon(chatRoom.type),
                    color: AppTheme.primaryColor,
                    size: 24,
                  )
                : null,
          ),
          const SizedBox(width: AppTheme.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        chatRoom.name,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryTextColor,
                        ),
                      ),
                    ),
                    if (chatRoom.lastMessageAt != null)
                      Text(
                        _formatTime(chatRoom.lastMessageAt),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppTheme.secondaryTextColor,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingXS),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _getTypeColor(chatRoom.type).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        chatRoom.type,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: _getTypeColor(chatRoom.type),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingS),
                    Text(
                      "${chatRoom.participants.length} participants",
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: AppTheme.secondaryTextColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingXS),
                if (chatRoom.lastMessage != null)
                  Text(
                    chatRoom.lastMessage!,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppTheme.secondaryTextColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppTheme.spacingS),
          Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: AppTheme.lightTextColor,
          ),
        ],
      ),
    );
  }

  IconData _getChatIcon(String type) {
    switch (type.toLowerCase()) {
      case 'direct':
        return Icons.person;
      case 'group':
        return Icons.group;
      case 'class':
        return Icons.school;
      case 'event':
        return Icons.event;
      default:
        return Icons.chat;
    }
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'direct':
        return AppTheme.primaryColor;
      case 'group':
        return AppTheme.successColor;
      case 'class':
        return AppTheme.warningColor;
      case 'event':
        return Colors.purple;
      default:
        return AppTheme.primaryColor;
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return DateFormat('MMM dd').format(dateTime);
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  void _openChatRoom(ChatRoom chatRoom) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatRoomScreen(chatRoom: chatRoom),
      ),
    );
  }

  void _showCreateChatOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppTheme.radiusL),
          ),
        ),
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.lightTextColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppTheme.spacingL),
            Text(
              "Start a Conversation",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryTextColor,
              ),
            ),
            const SizedBox(height: AppTheme.spacingL),
            _buildChatOption(
              "Find Mentor",
              "Connect with available mentors",
              Icons.person_search,
              AppTheme.primaryColor,
              () {
                Navigator.pop(context);
                // Navigate to mentor search
              },
            ),
            _buildChatOption(
              "Start Mentor Chat",
              "Enter mentor ID to start direct chat",
              Icons.person,
              AppTheme.primaryColor,
              () {
                Navigator.pop(context);
                _showStartMentorChatDialog();
              },
            ),
            _buildChatOption(
              "Join Class Group",
              "Join your class discussion group",
              Icons.school,
              AppTheme.warningColor,
              () {
                Navigator.pop(context);
                // Navigate to class groups
              },
            ),
            _buildChatOption(
              "Create Study Group",
              "Start a study group with classmates",
              Icons.group_add,
              AppTheme.successColor,
              () {
                Navigator.pop(context);
                _showCreateGroupDialog();
              },
            ),
            const SizedBox(height: AppTheme.spacingL),
          ],
        ),
      ),
    );
  }

  Widget _buildChatOption(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return CustomCard(
      onTap: onTap,
      margin: const EdgeInsets.only(bottom: AppTheme.spacingS),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: AppTheme.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryTextColor,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingXS),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppTheme.secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: AppTheme.lightTextColor,
          ),
        ],
      ),
    );
  }
}

// Chat Room Screen for individual conversations
class ChatRoomScreen extends StatefulWidget {
  final ChatRoom chatRoom;

  const ChatRoomScreen({super.key, required this.chatRoom});

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      appBar: CustomAppBar(
        title: widget.chatRoom.name,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              // Show chat info
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: _buildMessagesList()),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chat_messages')
          .where('chatRoomId', isEqualTo: widget.chatRoom.id)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingWidget(message: "Loading messages...");
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const EmptyStateWidget(
            title: "No messages yet",
            subtitle: "Start the conversation!",
            icon: Icons.chat,
          );
        }

        return ListView.builder(
          controller: _scrollController,
          reverse: true,
          padding: const EdgeInsets.all(AppTheme.spacingM),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final message = ChatMessage.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            );
            return _buildMessageBubble(message);
          },
        );
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isMe = message.senderId == FirebaseAuth.instance.currentUser!.uid;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppTheme.spacingS),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment: isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Padding(
                padding: const EdgeInsets.only(left: 12, bottom: 4),
                child: Text(
                  message.senderName,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppTheme.secondaryTextColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingM,
                vertical: AppTheme.spacingS,
              ),
              decoration: BoxDecoration(
                color: isMe ? AppTheme.primaryColor : Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                message.message,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: isMe ? Colors.white : AppTheme.primaryTextColor,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                DateFormat('hh:mm a').format(message.timestamp),
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: AppTheme.lightTextColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppTheme.dividerColor)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              style: GoogleFonts.poppins(),
              decoration: InputDecoration(
                hintText: "Type a message...",
                hintStyle: GoogleFonts.poppins(
                  color: AppTheme.secondaryTextColor,
                ),
                filled: true,
                fillColor: AppTheme.surfaceColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingM,
                  vertical: AppTheme.spacingS,
                ),
              ),
              maxLines: null,
            ),
          ),
          const SizedBox(width: AppTheme.spacingS),
          Container(
            decoration: const BoxDecoration(
              color: AppTheme.primaryColor,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage() {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser!;
    final message = ChatMessage(
      id: '',
      chatRoomId: widget.chatRoom.id,
      senderId: user.uid,
      senderName: user.displayName ?? 'Student',
      message: messageText,
      timestamp: DateTime.now(),
    );

    // Add message to Firestore
    FirebaseFirestore.instance.collection('chat_messages').add(message.toMap());

    // Update last message in chat room
    FirebaseFirestore.instance
        .collection('chat_rooms')
        .doc(widget.chatRoom.id)
        .update({
          'lastMessage': messageText,
          'lastMessageAt': DateTime.now().millisecondsSinceEpoch,
        });

    _messageController.clear();
  }
}
