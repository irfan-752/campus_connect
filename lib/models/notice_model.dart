class NoticeModel {
  final String id;
  final String title;
  final String description;
  final String authorId;
  final String authorName;
  final String priority; // High, Medium, Low
  final String category;
  final List<String> targetAudience; // Student, Teacher, Parent, All
  final String? attachmentUrl;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> readBy;

  NoticeModel({
    required this.id,
    required this.title,
    required this.description,
    required this.authorId,
    required this.authorName,
    this.priority = 'Medium',
    this.category = 'General',
    this.targetAudience = const ['All'],
    this.attachmentUrl,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.readBy = const [],
  });

  factory NoticeModel.fromMap(Map<String, dynamic> map, String id) {
    return NoticeModel(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      authorId: map['authorId'] ?? '',
      authorName: map['authorName'] ?? '',
      priority: map['priority'] ?? 'Medium',
      category: map['category'] ?? 'General',
      targetAudience: List<String>.from(map['targetAudience'] ?? ['All']),
      attachmentUrl: map['attachmentUrl'],
      isActive: map['isActive'] ?? true,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] ?? 0),
      readBy: List<String>.from(map['readBy'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'authorId': authorId,
      'authorName': authorName,
      'priority': priority,
      'category': category,
      'targetAudience': targetAudience,
      'attachmentUrl': attachmentUrl,
      'isActive': isActive,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'readBy': readBy,
    };
  }

  bool isReadBy(String userId) => readBy.contains(userId);
}
