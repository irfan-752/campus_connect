class JobPostingModel {
  final String id;
  final String title;
  final String company;
  final String? companyLogo;
  final String location;
  final String jobType; // 'full-time', 'part-time', 'internship', 'contract'
  final String? description;
  final List<String> requirements;
  final List<String> skills;
  final double? salaryMin;
  final double? salaryMax;
  final String? salaryCurrency;
  final DateTime applicationDeadline;
  final String? applicationLink;
  final List<String> departments; // Eligible departments
  final bool isActive;
  final String postedBy; // Admin/HR ID
  final DateTime createdAt;
  final DateTime updatedAt;

  JobPostingModel({
    required this.id,
    required this.title,
    required this.company,
    this.companyLogo,
    required this.location,
    required this.jobType,
    this.description,
    this.requirements = const [],
    this.skills = const [],
    this.salaryMin,
    this.salaryMax,
    this.salaryCurrency,
    required this.applicationDeadline,
    this.applicationLink,
    this.departments = const [],
    this.isActive = true,
    required this.postedBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory JobPostingModel.fromMap(Map<String, dynamic> map, String id) {
    return JobPostingModel(
      id: id,
      title: map['title'] ?? '',
      company: map['company'] ?? '',
      companyLogo: map['companyLogo'],
      location: map['location'] ?? '',
      jobType: map['jobType'] ?? 'full-time',
      description: map['description'],
      requirements: List<String>.from(map['requirements'] ?? []),
      skills: List<String>.from(map['skills'] ?? []),
      salaryMin: map['salaryMin']?.toDouble(),
      salaryMax: map['salaryMax']?.toDouble(),
      salaryCurrency: map['salaryCurrency'] ?? 'USD',
      applicationDeadline:
          DateTime.fromMillisecondsSinceEpoch(map['applicationDeadline'] ?? 0),
      applicationLink: map['applicationLink'],
      departments: List<String>.from(map['departments'] ?? []),
      isActive: map['isActive'] ?? true,
      postedBy: map['postedBy'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] ?? 0),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'company': company,
      'companyLogo': companyLogo,
      'location': location,
      'jobType': jobType,
      'description': description,
      'requirements': requirements,
      'skills': skills,
      'salaryMin': salaryMin,
      'salaryMax': salaryMax,
      'salaryCurrency': salaryCurrency,
      'applicationDeadline': applicationDeadline.millisecondsSinceEpoch,
      'applicationLink': applicationLink,
      'departments': departments,
      'isActive': isActive,
      'postedBy': postedBy,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }
}

class JobApplicationModel {
  final String id;
  final String studentId;
  final String jobId;
  final String resumeId;
  final String status; // 'pending', 'reviewed', 'shortlisted', 'rejected', 'accepted'
  final String? coverLetter;
  final DateTime appliedAt;
  final DateTime? reviewedAt;
  final String? reviewNotes;
  final DateTime createdAt;
  final DateTime updatedAt;

  JobApplicationModel({
    required this.id,
    required this.studentId,
    required this.jobId,
    required this.resumeId,
    required this.status,
    this.coverLetter,
    required this.appliedAt,
    this.reviewedAt,
    this.reviewNotes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory JobApplicationModel.fromMap(Map<String, dynamic> map, String id) {
    return JobApplicationModel(
      id: id,
      studentId: map['studentId'] ?? '',
      jobId: map['jobId'] ?? '',
      resumeId: map['resumeId'] ?? '',
      status: map['status'] ?? 'pending',
      coverLetter: map['coverLetter'],
      appliedAt: DateTime.fromMillisecondsSinceEpoch(map['appliedAt'] ?? 0),
      reviewedAt: map['reviewedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['reviewedAt'])
          : null,
      reviewNotes: map['reviewNotes'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] ?? 0),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'jobId': jobId,
      'resumeId': resumeId,
      'status': status,
      'coverLetter': coverLetter,
      'appliedAt': appliedAt.millisecondsSinceEpoch,
      'reviewedAt': reviewedAt?.millisecondsSinceEpoch,
      'reviewNotes': reviewNotes,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }
}

