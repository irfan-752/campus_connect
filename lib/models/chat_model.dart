class ChatRoom {
  final String id;
  final String name;
  final String description;
  final String type; // Group, Direct, Class, Event
  final List<String> participants;
  final String? avatarUrl;
  final String createdBy;
  final DateTime createdAt;
  final DateTime lastMessageAt;
  final String? lastMessage;
  final bool isActive;

  ChatRoom({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.participants,
    this.avatarUrl,
    required this.createdBy,
    required this.createdAt,
    required this.lastMessageAt,
    this.lastMessage,
    this.isActive = true,
  });

  factory ChatRoom.fromMap(Map<String, dynamic> map, String id) {
    return ChatRoom(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      type: map['type'] ?? 'Group',
      participants: List<String>.from(map['participants'] ?? []),
      avatarUrl: map['avatarUrl'],
      createdBy: map['createdBy'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      lastMessageAt: DateTime.fromMillisecondsSinceEpoch(
        map['lastMessageAt'] ?? 0,
      ),
      lastMessage: map['lastMessage'],
      isActive: map['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'type': type,
      'participants': participants,
      'avatarUrl': avatarUrl,
      'createdBy': createdBy,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'lastMessageAt': lastMessageAt.millisecondsSinceEpoch,
      'lastMessage': lastMessage,
      'isActive': isActive,
    };
  }
}

class ChatMessage {
  final String id;
  final String chatRoomId;
  final String senderId;
  final String senderName;
  final String message;
  final String type; // Text, Image, File, Event
  final String? attachmentUrl;
  final DateTime timestamp;
  final List<String> readBy;
  final bool isEdited;
  final DateTime? editedAt;

  ChatMessage({
    required this.id,
    required this.chatRoomId,
    required this.senderId,
    required this.senderName,
    required this.message,
    this.type = 'Text',
    this.attachmentUrl,
    required this.timestamp,
    this.readBy = const [],
    this.isEdited = false,
    this.editedAt,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> map, String id) {
    return ChatMessage(
      id: id,
      chatRoomId: map['chatRoomId'] ?? '',
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      message: map['message'] ?? '',
      type: map['type'] ?? 'Text',
      attachmentUrl: map['attachmentUrl'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] ?? 0),
      readBy: List<String>.from(map['readBy'] ?? []),
      isEdited: map['isEdited'] ?? false,
      editedAt: map['editedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['editedAt'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'chatRoomId': chatRoomId,
      'senderId': senderId,
      'senderName': senderName,
      'message': message,
      'type': type,
      'attachmentUrl': attachmentUrl,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'readBy': readBy,
      'isEdited': isEdited,
      'editedAt': editedAt?.millisecondsSinceEpoch,
    };
  }

  bool isReadBy(String userId) => readBy.contains(userId);
}
