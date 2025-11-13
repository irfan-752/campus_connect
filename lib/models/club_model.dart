class ClubModel {
  final String id;
  final String name;
  final String description;
  final String? logoUrl;
  final String category; // 'academic', 'cultural', 'sports', 'technical', 'social'
  final String presidentId;
  final String presidentName;
  final List<String> memberIds;
  final List<String> adminIds;
  final int maxMembers;
  final List<String> tags;
  final String? meetingSchedule;
  final String? contactEmail;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  ClubModel({
    required this.id,
    required this.name,
    required this.description,
    this.logoUrl,
    required this.category,
    required this.presidentId,
    required this.presidentName,
    this.memberIds = const [],
    this.adminIds = const [],
    this.maxMembers = 50,
    this.tags = const [],
    this.meetingSchedule,
    this.contactEmail,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ClubModel.fromMap(Map<String, dynamic> map, String id) {
    return ClubModel(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      logoUrl: map['logoUrl'],
      category: map['category'] ?? 'social',
      presidentId: map['presidentId'] ?? '',
      presidentName: map['presidentName'] ?? '',
      memberIds: List<String>.from(map['memberIds'] ?? []),
      adminIds: List<String>.from(map['adminIds'] ?? []),
      maxMembers: map['maxMembers'] ?? 50,
      tags: List<String>.from(map['tags'] ?? []),
      meetingSchedule: map['meetingSchedule'],
      contactEmail: map['contactEmail'],
      isActive: map['isActive'] ?? true,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] ?? 0),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'logoUrl': logoUrl,
      'category': category,
      'presidentId': presidentId,
      'presidentName': presidentName,
      'memberIds': memberIds,
      'adminIds': adminIds,
      'maxMembers': maxMembers,
      'tags': tags,
      'meetingSchedule': meetingSchedule,
      'contactEmail': contactEmail,
      'isActive': isActive,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }
}

class ClubEventModel {
  final String id;
  final String clubId;
  final String title;
  final String description;
  final DateTime eventDate;
  final String? location;
  final String? imageUrl;
  final List<String> registeredMembers;
  final int maxParticipants;
  final String status; // 'upcoming', 'ongoing', 'completed', 'cancelled'
  final DateTime createdAt;
  final DateTime updatedAt;

  ClubEventModel({
    required this.id,
    required this.clubId,
    required this.title,
    required this.description,
    required this.eventDate,
    this.location,
    this.imageUrl,
    this.registeredMembers = const [],
    this.maxParticipants = 100,
    this.status = 'upcoming',
    required this.createdAt,
    required this.updatedAt,
  });

  factory ClubEventModel.fromMap(Map<String, dynamic> map, String id) {
    return ClubEventModel(
      id: id,
      clubId: map['clubId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      eventDate: DateTime.fromMillisecondsSinceEpoch(map['eventDate'] ?? 0),
      location: map['location'],
      imageUrl: map['imageUrl'],
      registeredMembers: List<String>.from(map['registeredMembers'] ?? []),
      maxParticipants: map['maxParticipants'] ?? 100,
      status: map['status'] ?? 'upcoming',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] ?? 0),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'clubId': clubId,
      'title': title,
      'description': description,
      'eventDate': eventDate.millisecondsSinceEpoch,
      'location': location,
      'imageUrl': imageUrl,
      'registeredMembers': registeredMembers,
      'maxParticipants': maxParticipants,
      'status': status,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }
}

