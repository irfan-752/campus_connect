class CareerGuidanceModel {
  final String id;
  final String studentId;
  final String? careerPath;
  final List<String> recommendedSkills;
  final List<String> recommendedCourses;
  final List<String> jobSuggestions;
  final Map<String, dynamic>? personalityAssessment;
  final Map<String, dynamic>? skillGapAnalysis;
  final String? aiRecommendations;
  final DateTime createdAt;
  final DateTime updatedAt;

  CareerGuidanceModel({
    required this.id,
    required this.studentId,
    this.careerPath,
    this.recommendedSkills = const [],
    this.recommendedCourses = const [],
    this.jobSuggestions = const [],
    this.personalityAssessment,
    this.skillGapAnalysis,
    this.aiRecommendations,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CareerGuidanceModel.fromMap(Map<String, dynamic> map, String id) {
    return CareerGuidanceModel(
      id: id,
      studentId: map['studentId'] ?? '',
      careerPath: map['careerPath'],
      recommendedSkills: List<String>.from(map['recommendedSkills'] ?? []),
      recommendedCourses: List<String>.from(map['recommendedCourses'] ?? []),
      jobSuggestions: List<String>.from(map['jobSuggestions'] ?? []),
      personalityAssessment: map['personalityAssessment'],
      skillGapAnalysis: map['skillGapAnalysis'],
      aiRecommendations: map['aiRecommendations'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] ?? 0),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'careerPath': careerPath,
      'recommendedSkills': recommendedSkills,
      'recommendedCourses': recommendedCourses,
      'jobSuggestions': jobSuggestions,
      'personalityAssessment': personalityAssessment,
      'skillGapAnalysis': skillGapAnalysis,
      'aiRecommendations': aiRecommendations,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }
}

