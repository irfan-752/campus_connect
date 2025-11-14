import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../utils/app_theme.dart';
import '../../utils/responsive_helper.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/responsive_wrapper.dart';
import '../../models/chat_model.dart';

class AdminCommunicationMonitoring extends StatefulWidget {
  const AdminCommunicationMonitoring({super.key});

  @override
  State<AdminCommunicationMonitoring> createState() =>
      _AdminCommunicationMonitoringState();
}

class _AdminCommunicationMonitoringState
    extends State<AdminCommunicationMonitoring> {
  String _selectedType = 'All';
  final List<String> _types = ['All', 'Direct', 'Group'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: ResponsiveWrapper(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('chat_rooms')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const LoadingWidget();
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No chat rooms'));
                  }

                  var rooms = snapshot.data!.docs
                      .map((doc) => ChatRoom.fromMap(
                            doc.data() as Map<String, dynamic>,
                            doc.id,
                          ))
                      .toList();

                  if (_selectedType != 'All') {
                    rooms = rooms
                        .where((room) => room.type == _selectedType)
                        .toList();
                  }

                  rooms.sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));

                  return ListView.builder(
                    padding: EdgeInsets.all(
                      ResponsiveHelper.responsiveValue(
                        context,
                        mobile: AppTheme.spacingM,
                        tablet: AppTheme.spacingL,
                        desktop: AppTheme.spacingXL,
                      ),
                    ),
                    itemCount: rooms.length,
                    itemBuilder: (context, index) => _buildChatRoomCard(rooms[index]),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
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
          children: _types.map((type) {
            final isSelected = _selectedType == type;
            return Padding(
              padding: const EdgeInsets.only(right: AppTheme.spacingS),
              child: FilterChip(
                label: Text(type),
                selected: isSelected,
                onSelected: (v) {
                  setState(() => _selectedType = type);
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildChatRoomCard(ChatRoom room) {
    return CustomCard(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundImage: room.avatarUrl != null
                    ? NetworkImage(room.avatarUrl!)
                    : null,
                backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                child: room.avatarUrl == null
                    ? Text(
                        room.name.isNotEmpty ? room.name[0].toUpperCase() : 'C',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      room.name,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingXS),
                    Text(
                      room.description,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppTheme.secondaryTextColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppTheme.spacingXS),
                    Text(
                      '${room.participants.length} participants • ${room.type}',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getTypeColor(room.type).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  room.type.toUpperCase(),
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: _getTypeColor(room.type),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (room.lastMessage != null) ...[
            const SizedBox(height: AppTheme.spacingM),
            const Divider(),
            const SizedBox(height: AppTheme.spacingM),
            Row(
              children: [
                Expanded(
                  child: Text(
                    room.lastMessage!,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppTheme.secondaryTextColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingS),
                Text(
                  DateFormat('MMM dd, hh:mm a').format(room.lastMessageAt),
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: AppTheme.lightTextColor,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppTheme.spacingM),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _viewMessages(room),
                  child: const Text('View Messages'),
                ),
              ),
              const SizedBox(width: AppTheme.spacingS),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _viewParticipants(room),
                  child: const Text('Participants'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'Direct':
        return AppTheme.primaryColor;
      case 'Group':
        return AppTheme.successColor;
      default:
        return AppTheme.secondaryTextColor;
    }
  }

  void _viewMessages(ChatRoom room) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Messages: ${room.name}'),
        content: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('chats')
              .where('roomId', isEqualTo: room.id)
              .orderBy('timestamp', descending: true)
              .limit(50)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const LoadingWidget();
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Text('No messages');
            }

            return SizedBox(
              width: double.maxFinite,
              height: 400,
              child: ListView.builder(
                reverse: true,
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final doc = snapshot.data!.docs[index];
                  final data = doc.data() as Map<String, dynamic>;
                  return ListTile(
                    title: Text(data['senderName'] ?? 'Unknown'),
                    subtitle: Text(data['message'] ?? ''),
                    trailing: Text(
                      DateFormat('hh:mm a').format(
                        DateTime.fromMillisecondsSinceEpoch(data['timestamp'] ?? 0),
                      ),
                      style: GoogleFonts.poppins(fontSize: 10),
                    ),
                  );
                },
              ),
            );
          },
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

  void _viewParticipants(ChatRoom room) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Participants: ${room.name}'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: room.participants.length,
            itemBuilder: (context, index) {
              final participantId = room.participants[index];
              return StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(participantId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return ListTile(
                      title: Text('User: $participantId'),
                    );
                  }

                  final data = snapshot.data!.data() as Map<String, dynamic>?;
                  return ListTile(
                    title: Text(data?['name'] ?? 'Unknown'),
                    subtitle: Text(data?['email'] ?? participantId),
                  );
                },
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
}

