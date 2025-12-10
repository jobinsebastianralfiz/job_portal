import 'package:cloud_firestore/cloud_firestore.dart';

class JobModel {
  final String jobId;
  final String title;
  final String description;
  final String companyId;
  final String companyName;
  final String? companyLogo;
  final String providerId;
  final String category;
  final String employmentType;
  final String experienceLevel;
  final List<String> skills;
  final List<String> requirements;
  final String salaryType;
  final double? salaryMin;
  final double? salaryMax;
  final String currency;
  final int? hoursPerWeek;
  final JobSchedule? schedule;
  final String workLocation;
  final JobLocation? location;
  final String status;
  final bool isFeatured;
  final bool isUrgent;
  final DateTime? expiresAt;
  final int views;
  final int applications;
  final int saves;
  final List<ScreeningQuestion>? screeningQuestions;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? publishedAt;

  JobModel({
    required this.jobId,
    required this.title,
    required this.description,
    required this.companyId,
    required this.companyName,
    this.companyLogo,
    required this.providerId,
    required this.category,
    required this.employmentType,
    required this.experienceLevel,
    required this.skills,
    required this.requirements,
    required this.salaryType,
    this.salaryMin,
    this.salaryMax,
    required this.currency,
    this.hoursPerWeek,
    this.schedule,
    required this.workLocation,
    this.location,
    required this.status,
    this.isFeatured = false,
    this.isUrgent = false,
    this.expiresAt,
    this.views = 0,
    this.applications = 0,
    this.saves = 0,
    this.screeningQuestions,
    required this.createdAt,
    required this.updatedAt,
    this.publishedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'jobId': jobId,
      'title': title,
      'description': description,
      'companyId': companyId,
      'companyName': companyName,
      'companyLogo': companyLogo,
      'providerId': providerId,
      'category': category,
      'employmentType': employmentType,
      'experienceLevel': experienceLevel,
      'skills': skills,
      'requirements': requirements,
      'salaryType': salaryType,
      'salaryMin': salaryMin,
      'salaryMax': salaryMax,
      'currency': currency,
      'hoursPerWeek': hoursPerWeek,
      'schedule': schedule?.toJson(),
      'workLocation': workLocation,
      'location': location?.toJson(),
      'status': status,
      'isFeatured': isFeatured,
      'isUrgent': isUrgent,
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
      'views': views,
      'applications': applications,
      'saves': saves,
      'screeningQuestions': screeningQuestions?.map((q) => q.toJson()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'publishedAt': publishedAt != null ? Timestamp.fromDate(publishedAt!) : null,
    };
  }

  factory JobModel.fromJson(Map<String, dynamic> json) {
    return JobModel(
      jobId: json['jobId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      companyId: json['companyId'] as String? ?? '',
      companyName: json['companyName'] as String? ?? '',
      companyLogo: json['companyLogo'] as String?,
      providerId: json['providerId'] as String? ?? '',
      category: json['category'] as String? ?? '',
      employmentType: json['employmentType'] as String? ?? '',
      experienceLevel: json['experienceLevel'] as String? ?? '',
      skills: (json['skills'] as List<dynamic>?)?.cast<String>() ?? [],
      requirements: (json['requirements'] as List<dynamic>?)?.cast<String>() ?? [],
      salaryType: json['salaryType'] as String? ?? 'negotiable',
      salaryMin: (json['salaryMin'] as num?)?.toDouble(),
      salaryMax: (json['salaryMax'] as num?)?.toDouble(),
      currency: json['currency'] as String? ?? 'USD',
      hoursPerWeek: json['hoursPerWeek'] as int?,
      schedule: json['schedule'] != null
          ? JobSchedule.fromJson(json['schedule'] as Map<String, dynamic>)
          : null,
      workLocation: json['workLocation'] as String? ?? 'on-site',
      location: json['location'] != null
          ? JobLocation.fromJson(json['location'] as Map<String, dynamic>)
          : null,
      status: json['status'] as String? ?? 'draft',
      isFeatured: json['isFeatured'] as bool? ?? false,
      isUrgent: json['isUrgent'] as bool? ?? false,
      expiresAt: json['expiresAt'] != null
          ? (json['expiresAt'] as Timestamp).toDate()
          : null,
      views: json['views'] as int? ?? 0,
      applications: json['applications'] as int? ?? 0,
      saves: json['saves'] as int? ?? 0,
      screeningQuestions: (json['screeningQuestions'] as List<dynamic>?)
          ?.map((q) => ScreeningQuestion.fromJson(q as Map<String, dynamic>))
          .toList(),
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? (json['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
      publishedAt: json['publishedAt'] != null
          ? (json['publishedAt'] as Timestamp).toDate()
          : null,
    );
  }

  JobModel copyWith({
    String? jobId,
    String? title,
    String? description,
    String? companyId,
    String? companyName,
    String? companyLogo,
    String? providerId,
    String? category,
    String? employmentType,
    String? experienceLevel,
    List<String>? skills,
    List<String>? requirements,
    String? salaryType,
    double? salaryMin,
    double? salaryMax,
    String? currency,
    int? hoursPerWeek,
    JobSchedule? schedule,
    String? workLocation,
    JobLocation? location,
    String? status,
    bool? isFeatured,
    bool? isUrgent,
    DateTime? expiresAt,
    int? views,
    int? applications,
    int? saves,
    List<ScreeningQuestion>? screeningQuestions,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? publishedAt,
  }) {
    return JobModel(
      jobId: jobId ?? this.jobId,
      title: title ?? this.title,
      description: description ?? this.description,
      companyId: companyId ?? this.companyId,
      companyName: companyName ?? this.companyName,
      companyLogo: companyLogo ?? this.companyLogo,
      providerId: providerId ?? this.providerId,
      category: category ?? this.category,
      employmentType: employmentType ?? this.employmentType,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      skills: skills ?? this.skills,
      requirements: requirements ?? this.requirements,
      salaryType: salaryType ?? this.salaryType,
      salaryMin: salaryMin ?? this.salaryMin,
      salaryMax: salaryMax ?? this.salaryMax,
      currency: currency ?? this.currency,
      hoursPerWeek: hoursPerWeek ?? this.hoursPerWeek,
      schedule: schedule ?? this.schedule,
      workLocation: workLocation ?? this.workLocation,
      location: location ?? this.location,
      status: status ?? this.status,
      isFeatured: isFeatured ?? this.isFeatured,
      isUrgent: isUrgent ?? this.isUrgent,
      expiresAt: expiresAt ?? this.expiresAt,
      views: views ?? this.views,
      applications: applications ?? this.applications,
      saves: saves ?? this.saves,
      screeningQuestions: screeningQuestions ?? this.screeningQuestions,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      publishedAt: publishedAt ?? this.publishedAt,
    );
  }

  bool get isActive => status == 'active';
  bool get isDraft => status == 'draft';
  bool get isClosed => status == 'closed';
  bool get isExpired => expiresAt != null && expiresAt!.isBefore(DateTime.now());

  // Alias for companyName for compatibility
  String get company => companyName;

  // For admin moderation
  String? reportReason;

  String get salaryDisplay {
    if (salaryType == 'negotiable') return 'Negotiable';
    if (salaryMin == null && salaryMax == null) return 'Not specified';

    String suffix = '';
    switch (salaryType.toLowerCase()) {
      case 'hourly':
        suffix = '/hr';
        break;
      case 'daily':
        suffix = '/day';
        break;
      case 'weekly':
        suffix = '/week';
        break;
      case 'monthly':
        suffix = '/month';
        break;
    }

    if (salaryMin != null && salaryMax != null) {
      return '$currency ${salaryMin!.toInt()} - ${salaryMax!.toInt()}$suffix';
    } else if (salaryMin != null) {
      return 'From $currency ${salaryMin!.toInt()}$suffix';
    } else {
      return 'Up to $currency ${salaryMax!.toInt()}$suffix';
    }
  }
}

class JobSchedule {
  final String flexibility;
  final List<String>? preferredDays;
  final String? preferredTimes;

  JobSchedule({
    required this.flexibility,
    this.preferredDays,
    this.preferredTimes,
  });

  Map<String, dynamic> toJson() {
    return {
      'flexibility': flexibility,
      'preferredDays': preferredDays,
      'preferredTimes': preferredTimes,
    };
  }

  factory JobSchedule.fromJson(Map<String, dynamic> json) {
    return JobSchedule(
      flexibility: json['flexibility'] as String? ?? 'flexible',
      preferredDays: (json['preferredDays'] as List<dynamic>?)?.cast<String>(),
      preferredTimes: json['preferredTimes'] as String?,
    );
  }
}

class JobLocation {
  final String? address;
  final String city;
  final String state;
  final String country;
  final GeoPoint? coordinates;

  JobLocation({
    this.address,
    required this.city,
    required this.state,
    required this.country,
    this.coordinates,
  });

  Map<String, dynamic> toJson() {
    return {
      'address': address,
      'city': city,
      'state': state,
      'country': country,
      'coordinates': coordinates,
    };
  }

  factory JobLocation.fromJson(Map<String, dynamic> json) {
    return JobLocation(
      address: json['address'] as String?,
      city: json['city'] as String? ?? '',
      state: json['state'] as String? ?? '',
      country: json['country'] as String? ?? '',
      coordinates: json['coordinates'] as GeoPoint?,
    );
  }

  String get shortLocation => '$city, $state';
  String get fullLocation => address != null ? '$address, $city, $state, $country' : '$city, $state, $country';
}

class ScreeningQuestion {
  final String id;
  final String question;
  final String type;
  final bool isRequired;
  final List<String>? options;

  ScreeningQuestion({
    required this.id,
    required this.question,
    required this.type,
    this.isRequired = true,
    this.options,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'type': type,
      'isRequired': isRequired,
      'options': options,
    };
  }

  factory ScreeningQuestion.fromJson(Map<String, dynamic> json) {
    return ScreeningQuestion(
      id: json['id'] as String? ?? '',
      question: json['question'] as String? ?? '',
      type: json['type'] as String? ?? 'text',
      isRequired: json['isRequired'] as bool? ?? true,
      options: (json['options'] as List<dynamic>?)?.cast<String>(),
    );
  }
}
