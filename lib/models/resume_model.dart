class ResumeModel {
  final String id;
  final String studentId;
  final PersonalInfo personalInfo;
  final List<Education> education;
  final List<Experience> experience;
  final List<Skill> skills;
  final List<Project> projects;
  final List<String> certifications;
  final List<String> languages;
  final String? summary;
  final String templateId;
  final DateTime createdAt;
  final DateTime updatedAt;

  ResumeModel({
    required this.id,
    required this.studentId,
    required this.personalInfo,
    this.education = const [],
    this.experience = const [],
    this.skills = const [],
    this.projects = const [],
    this.certifications = const [],
    this.languages = const [],
    this.summary,
    this.templateId = 'default',
    required this.createdAt,
    required this.updatedAt,
  });

  factory ResumeModel.fromMap(Map<String, dynamic> map, String id) {
    return ResumeModel(
      id: id,
      studentId: map['studentId'] ?? '',
      personalInfo: PersonalInfo.fromMap(map['personalInfo'] ?? {}),
      education: (map['education'] as List?)
              ?.map((e) => Education.fromMap(e))
              .toList() ??
          [],
      experience: (map['experience'] as List?)
              ?.map((e) => Experience.fromMap(e))
              .toList() ??
          [],
      skills: (map['skills'] as List?)
              ?.map((e) => Skill.fromMap(e))
              .toList() ??
          [],
      projects: (map['projects'] as List?)
              ?.map((e) => Project.fromMap(e))
              .toList() ??
          [],
      certifications: List<String>.from(map['certifications'] ?? []),
      languages: List<String>.from(map['languages'] ?? []),
      summary: map['summary'],
      templateId: map['templateId'] ?? 'default',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] ?? 0),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'personalInfo': personalInfo.toMap(),
      'education': education.map((e) => e.toMap()).toList(),
      'experience': experience.map((e) => e.toMap()).toList(),
      'skills': skills.map((e) => e.toMap()).toList(),
      'projects': projects.map((e) => e.toMap()).toList(),
      'certifications': certifications,
      'languages': languages,
      'summary': summary,
      'templateId': templateId,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }
}

class PersonalInfo {
  final String fullName;
  final String email;
  final String? phone;
  final String? address;
  final String? linkedIn;
  final String? github;
  final String? portfolio;

  PersonalInfo({
    required this.fullName,
    required this.email,
    this.phone,
    this.address,
    this.linkedIn,
    this.github,
    this.portfolio,
  });

  factory PersonalInfo.fromMap(Map<String, dynamic> map) {
    return PersonalInfo(
      fullName: map['fullName'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'],
      address: map['address'],
      linkedIn: map['linkedIn'],
      github: map['github'],
      portfolio: map['portfolio'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'address': address,
      'linkedIn': linkedIn,
      'github': github,
      'portfolio': portfolio,
    };
  }
}

class Education {
  final String institution;
  final String degree;
  final String field;
  final String? startDate;
  final String? endDate;
  final double? gpa;
  final String? description;

  Education({
    required this.institution,
    required this.degree,
    required this.field,
    this.startDate,
    this.endDate,
    this.gpa,
    this.description,
  });

  factory Education.fromMap(Map<String, dynamic> map) {
    return Education(
      institution: map['institution'] ?? '',
      degree: map['degree'] ?? '',
      field: map['field'] ?? '',
      startDate: map['startDate'],
      endDate: map['endDate'],
      gpa: map['gpa']?.toDouble(),
      description: map['description'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'institution': institution,
      'degree': degree,
      'field': field,
      'startDate': startDate,
      'endDate': endDate,
      'gpa': gpa,
      'description': description,
    };
  }
}

class Experience {
  final String company;
  final String position;
  final String? startDate;
  final String? endDate;
  final bool isCurrent;
  final String? description;
  final List<String> achievements;

  Experience({
    required this.company,
    required this.position,
    this.startDate,
    this.endDate,
    this.isCurrent = false,
    this.description,
    this.achievements = const [],
  });

  factory Experience.fromMap(Map<String, dynamic> map) {
    return Experience(
      company: map['company'] ?? '',
      position: map['position'] ?? '',
      startDate: map['startDate'],
      endDate: map['endDate'],
      isCurrent: map['isCurrent'] ?? false,
      description: map['description'],
      achievements: List<String>.from(map['achievements'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'company': company,
      'position': position,
      'startDate': startDate,
      'endDate': endDate,
      'isCurrent': isCurrent,
      'description': description,
      'achievements': achievements,
    };
  }
}

class Skill {
  final String name;
  final String level; // 'beginner', 'intermediate', 'advanced', 'expert'

  Skill({required this.name, required this.level});

  factory Skill.fromMap(Map<String, dynamic> map) {
    return Skill(
      name: map['name'] ?? '',
      level: map['level'] ?? 'intermediate',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'level': level,
    };
  }
}

class Project {
  final String name;
  final String? description;
  final String? technologies;
  final String? url;
  final String? startDate;
  final String? endDate;

  Project({
    required this.name,
    this.description,
    this.technologies,
    this.url,
    this.startDate,
    this.endDate,
  });

  factory Project.fromMap(Map<String, dynamic> map) {
    return Project(
      name: map['name'] ?? '',
      description: map['description'],
      technologies: map['technologies'],
      url: map['url'],
      startDate: map['startDate'],
      endDate: map['endDate'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'technologies': technologies,
      'url': url,
      'startDate': startDate,
      'endDate': endDate,
    };
  }
}

