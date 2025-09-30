class FeedbackModel {
  final String id;
  final String eventId;
  final String eventTitle;
  final String studentId;
  final String studentName;
  final int rating; // 1-5 stars
  final String comments;
  final List<String> categories; // Organization, Content, Venue, etc.
  final Map<String, int> categoryRatings;
  final bool isAnonymous;
  final DateTime submittedAt;

  FeedbackModel({
    required this.id,
    required this.eventId,
    required this.eventTitle,
    required this.studentId,
    required this.studentName,
    required this.rating,
    required this.comments,
    this.categories = const [],
    this.categoryRatings = const {},
    this.isAnonymous = false,
    required this.submittedAt,
  });

  factory FeedbackModel.fromMap(Map<String, dynamic> map, String id) {
    return FeedbackModel(
      id: id,
      eventId: map['eventId'] ?? '',
      eventTitle: map['eventTitle'] ?? '',
      studentId: map['studentId'] ?? '',
      studentName: map['studentName'] ?? '',
      rating: map['rating'] ?? 1,
      comments: map['comments'] ?? '',
      categories: List<String>.from(map['categories'] ?? []),
      categoryRatings: Map<String, int>.from(map['categoryRatings'] ?? {}),
      isAnonymous: map['isAnonymous'] ?? false,
      submittedAt: DateTime.fromMillisecondsSinceEpoch(map['submittedAt'] ?? 0),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'eventId': eventId,
      'eventTitle': eventTitle,
      'studentId': studentId,
      'studentName': studentName,
      'rating': rating,
      'comments': comments,
      'categories': categories,
      'categoryRatings': categoryRatings,
      'isAnonymous': isAnonymous,
      'submittedAt': submittedAt.millisecondsSinceEpoch,
    };
  }
}

class EventFeedbackSummary {
  final String eventId;
  final String eventTitle;
  final int totalResponses;
  final double averageRating;
  final Map<int, int> ratingDistribution;
  final Map<String, double> categoryAverages;
  final List<String> topComments;

  EventFeedbackSummary({
    required this.eventId,
    required this.eventTitle,
    required this.totalResponses,
    required this.averageRating,
    required this.ratingDistribution,
    required this.categoryAverages,
    required this.topComments,
  });

  factory EventFeedbackSummary.fromMap(Map<String, dynamic> map) {
    return EventFeedbackSummary(
      eventId: map['eventId'] ?? '',
      eventTitle: map['eventTitle'] ?? '',
      totalResponses: map['totalResponses'] ?? 0,
      averageRating: (map['averageRating'] ?? 0.0).toDouble(),
      ratingDistribution: Map<int, int>.from(map['ratingDistribution'] ?? {}),
      categoryAverages: Map<String, double>.from(map['categoryAverages'] ?? {}),
      topComments: List<String>.from(map['topComments'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'eventId': eventId,
      'eventTitle': eventTitle,
      'totalResponses': totalResponses,
      'averageRating': averageRating,
      'ratingDistribution': ratingDistribution,
      'categoryAverages': categoryAverages,
      'topComments': topComments,
    };
  }
}
