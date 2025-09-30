class EventModel {
  final String id;
  final String title;
  final String description;
  final String organizer;
  final DateTime startDate;
  final DateTime endDate;
  final String location;
  final String category;
  final String? imageUrl;
  final List<String> registeredStudents;
  final int maxParticipants;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.organizer,
    required this.startDate,
    required this.endDate,
    required this.location,
    required this.category,
    this.imageUrl,
    this.registeredStudents = const [],
    this.maxParticipants = 100,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory EventModel.fromMap(Map<String, dynamic> map, String id) {
    return EventModel(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      organizer: map['organizer'] ?? '',
      startDate: DateTime.fromMillisecondsSinceEpoch(map['startDate'] ?? 0),
      endDate: DateTime.fromMillisecondsSinceEpoch(map['endDate'] ?? 0),
      location: map['location'] ?? '',
      category: map['category'] ?? '',
      imageUrl: map['imageUrl'],
      registeredStudents: List<String>.from(map['registeredStudents'] ?? []),
      maxParticipants: map['maxParticipants'] ?? 100,
      isActive: map['isActive'] ?? true,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] ?? 0),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'organizer': organizer,
      'startDate': startDate.millisecondsSinceEpoch,
      'endDate': endDate.millisecondsSinceEpoch,
      'location': location,
      'category': category,
      'imageUrl': imageUrl,
      'registeredStudents': registeredStudents,
      'maxParticipants': maxParticipants,
      'isActive': isActive,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  bool get isFull => registeredStudents.length >= maxParticipants;
  bool get hasStarted => DateTime.now().isAfter(startDate);
  bool get hasEnded => DateTime.now().isAfter(endDate);
}
