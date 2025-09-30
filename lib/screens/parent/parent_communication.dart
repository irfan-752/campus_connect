import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../utils/app_theme.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/custom_button.dart';
import '../../models/chat_model.dart';

class ParentCommunication extends StatefulWidget {
  const ParentCommunication({super.key});

  @override
  State<ParentCommunication> createState() => _ParentCommunicationState();
}

class _ParentCommunicationState extends State<ParentCommunication>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: const CustomAppBar(title: "Communication"),
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTeacherChats(),
                _buildNotifications(),
                _buildMeetingRequests(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showContactOptions,
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
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
          Tab(text: 'Teacher Chats'),
          Tab(text: 'Notifications'),
          Tab(text: 'Meetings'),
        ],
      ),
    );
  }

  Widget _buildTeacherChats() {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chat_rooms')
          .where('participants', arrayContains: userId)
          .where('type', isEqualTo: 'parent_teacher')
          .orderBy('lastMessageAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingWidget(message: "Loading chats...");
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const EmptyStateWidget(
            title: "No conversations yet",
            subtitle: "Start a conversation with your child's teachers",
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

  Widget _buildChatRoomCard(ChatRoom chatRoom) {
    return CustomCard(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
      onTap: () => _openChatRoom(chatRoom),
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
            child: const Icon(Icons.person, color: AppTheme.primaryColor),
          ),
          const SizedBox(width: AppTheme.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  chatRoom.name,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryTextColor,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingXS),
                Text(
                  (chatRoom.lastMessage?.isNotEmpty == true)
                      ? chatRoom.lastMessage!
                      : "No messages yet",
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppTheme.secondaryTextColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppTheme.spacingXS),
                Text(
                  _formatTime(chatRoom.lastMessageAt),
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: AppTheme.lightTextColor,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: AppTheme.lightTextColor,
          ),
        ],
      ),
    );
  }

  Widget _buildNotifications() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Recent Notifications",
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryTextColor,
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          _buildNotificationItem(
            "Low Attendance Alert",
            "Your child's attendance has dropped below 75%",
            "2 hours ago",
            Icons.warning,
            AppTheme.errorColor,
          ),
          _buildNotificationItem(
            "Parent-Teacher Meeting",
            "Scheduled for March 20, 2024 at 2:00 PM",
            "1 day ago",
            Icons.event,
            AppTheme.primaryColor,
          ),
          _buildNotificationItem(
            "Assignment Due",
            "Mathematics assignment due tomorrow",
            "2 days ago",
            Icons.assignment,
            AppTheme.warningColor,
          ),
          _buildNotificationItem(
            "Excellent Performance",
            "Your child scored 95% in Science test",
            "3 days ago",
            Icons.star,
            AppTheme.successColor,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(
    String title,
    String description,
    String time,
    IconData icon,
    Color color,
  ) {
    return CustomCard(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: AppTheme.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryTextColor,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingXS),
                Text(
                  description,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppTheme.secondaryTextColor,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingXS),
                Text(
                  time,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: AppTheme.lightTextColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeetingRequests() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Meeting Requests",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryTextColor,
                ),
              ),
              CustomButton(
                text: "Request Meeting",
                onPressed: _showMeetingRequestDialog,
                size: ButtonSize.small,
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingM),
          _buildMeetingItem(
            "Math Teacher Meeting",
            "Mrs. Sarah Johnson",
            "March 20, 2024 • 2:00 PM",
            "Confirmed",
            AppTheme.successColor,
          ),
          _buildMeetingItem(
            "Class Teacher Discussion",
            "Mr. John Smith",
            "March 25, 2024 • 3:30 PM",
            "Pending",
            AppTheme.warningColor,
          ),
          _buildMeetingItem(
            "Principal Meeting",
            "Dr. Emily Davis",
            "March 28, 2024 • 10:00 AM",
            "Requested",
            AppTheme.primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildMeetingItem(
    String title,
    String teacher,
    String datetime,
    String status,
    Color statusColor,
  ) {
    return CustomCard(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryTextColor,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingS),
          Row(
            children: [
              Icon(Icons.person, size: 16, color: AppTheme.secondaryTextColor),
              const SizedBox(width: AppTheme.spacingXS),
              Text(
                teacher,
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
              Icon(
                Icons.schedule,
                size: 16,
                color: AppTheme.secondaryTextColor,
              ),
              const SizedBox(width: AppTheme.spacingXS),
              Text(
                datetime,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppTheme.secondaryTextColor,
                ),
              ),
            ],
          ),
          if (status == "Pending") ...[
            const SizedBox(height: AppTheme.spacingM),
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: "Reschedule",
                    onPressed: () {},
                    type: ButtonType.secondary,
                    size: ButtonSize.small,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingS),
                Expanded(
                  child: CustomButton(
                    text: "Cancel",
                    onPressed: () {},
                    type: ButtonType.secondary,
                    size: ButtonSize.small,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _showContactOptions() {
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
            Text(
              "Contact Options",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryTextColor,
              ),
            ),
            const SizedBox(height: AppTheme.spacingL),
            _buildContactOption(
              "Message Teacher",
              "Send a direct message to your child's teacher",
              Icons.message,
              AppTheme.primaryColor,
              () {
                Navigator.pop(context);
                _showTeacherSelectionDialog();
              },
            ),
            _buildContactOption(
              "Request Meeting",
              "Schedule a meeting with teacher or principal",
              Icons.event,
              AppTheme.warningColor,
              () {
                Navigator.pop(context);
                _showMeetingRequestDialog();
              },
            ),
            _buildContactOption(
              "Emergency Contact",
              "Contact school administration immediately",
              Icons.emergency,
              AppTheme.errorColor,
              () {
                Navigator.pop(context);
                // Handle emergency contact
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactOption(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return CustomCard(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
      onTap: onTap,
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
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryTextColor,
                  ),
                ),
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
          const Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: AppTheme.lightTextColor,
          ),
        ],
      ),
    );
  }

  void _showTeacherSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Select Teacher',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const CircleAvatar(child: Text('MJ')),
              title: const Text('Mrs. Sarah Johnson'),
              subtitle: const Text('Mathematics Teacher'),
              onTap: () {
                Navigator.pop(context);
                // Start chat with teacher
              },
            ),
            ListTile(
              leading: const CircleAvatar(child: Text('JS')),
              title: const Text('Mr. John Smith'),
              subtitle: const Text('Class Teacher'),
              onTap: () {
                Navigator.pop(context);
                // Start chat with teacher
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showMeetingRequestDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Request Meeting',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Meeting request functionality would be implemented here with date/time selection and reason input.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Meeting request sent successfully'),
                ),
              );
            },
            child: const Text('Send Request'),
          ),
        ],
      ),
    );
  }

  void _openChatRoom(ChatRoom chatRoom) {
    // Navigate to chat room screen
    // Implementation would be similar to student chat
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return "Just now";
    } else if (difference.inHours < 1) {
      return "${difference.inMinutes}m ago";
    } else if (difference.inDays < 1) {
      return "${difference.inHours}h ago";
    } else if (difference.inDays < 7) {
      return "${difference.inDays}d ago";
    } else {
      return DateFormat('MMM dd').format(dateTime);
    }
  }
}
