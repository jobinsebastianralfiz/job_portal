import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String userId;
  final String email;
  final String? phoneNumber;
  final String role;
  final String firstName;
  final String lastName;
  final String? profileImage;
  final bool isVerified;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Job Seeker specific
  final List<String>? skills;
  final String? experience;
  final String? education;
  final String? resume;
  final String? summary;
  final Map<String, dynamic>? availability;
  final List<String>? savedJobs;
  final Map<String, dynamic>? preferences;

  // Job Provider specific
  final String? companyId;
  final String? subscriptionTier;
  final String? subscriptionId;
  final DateTime? subscriptionExpiresAt;
  final String? providerStatus; // pending_approval, approved, rejected, active, suspended
  final DateTime? approvedAt;
  final DateTime? rejectedAt;
  final String? rejectionReason;

  // Location
  final LocationModel? location;

  // AI Resume Parser
  final String? profileSource;
  final DateTime? resumeParseDate;
  final double? aiConfidenceScore;

  UserModel({
    required this.userId,
    required this.email,
    this.phoneNumber,
    required this.role,
    required this.firstName,
    required this.lastName,
    this.profileImage,
    required this.isVerified,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.skills,
    this.experience,
    this.education,
    this.resume,
    this.summary,
    this.availability,
    this.savedJobs,
    this.preferences,
    this.companyId,
    this.subscriptionTier,
    this.subscriptionId,
    this.subscriptionExpiresAt,
    this.providerStatus,
    this.approvedAt,
    this.rejectedAt,
    this.rejectionReason,
    this.location,
    this.profileSource,
    this.resumeParseDate,
    this.aiConfidenceScore,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'email': email,
      'phoneNumber': phoneNumber,
      'role': role,
      'firstName': firstName,
      'lastName': lastName,
      'profileImage': profileImage,
      'isVerified': isVerified,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'skills': skills,
      'experience': experience,
      'education': education,
      'resume': resume,
      'summary': summary,
      'availability': availability,
      'savedJobs': savedJobs,
      'preferences': preferences,
      'companyId': companyId,
      'subscriptionTier': subscriptionTier,
      'subscriptionId': subscriptionId,
      'subscriptionExpiresAt': subscriptionExpiresAt != null
          ? Timestamp.fromDate(subscriptionExpiresAt!)
          : null,
      'providerStatus': providerStatus,
      'approvedAt': approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
      'rejectedAt': rejectedAt != null ? Timestamp.fromDate(rejectedAt!) : null,
      'rejectionReason': rejectionReason,
      'location': location?.toJson(),
      'profileSource': profileSource,
      'resumeParseDate': resumeParseDate != null
          ? Timestamp.fromDate(resumeParseDate!)
          : null,
      'aiConfidenceScore': aiConfidenceScore,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['userId'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String?,
      role: json['role'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      profileImage: json['profileImage'] as String?,
      isVerified: json['isVerified'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? (json['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
      skills: (json['skills'] as List<dynamic>?)?.cast<String>(),
      experience: json['experience'] as String?,
      education: json['education'] as String?,
      resume: json['resume'] as String?,
      summary: json['summary'] as String?,
      availability: json['availability'] as Map<String, dynamic>?,
      savedJobs: (json['savedJobs'] as List<dynamic>?)?.cast<String>(),
      preferences: json['preferences'] as Map<String, dynamic>?,
      companyId: json['companyId'] as String?,
      subscriptionTier: json['subscriptionTier'] as String?,
      subscriptionId: json['subscriptionId'] as String?,
      subscriptionExpiresAt: json['subscriptionExpiresAt'] != null
          ? (json['subscriptionExpiresAt'] as Timestamp).toDate()
          : null,
      providerStatus: json['providerStatus'] as String?,
      approvedAt: json['approvedAt'] != null
          ? (json['approvedAt'] as Timestamp).toDate()
          : null,
      rejectedAt: json['rejectedAt'] != null
          ? (json['rejectedAt'] as Timestamp).toDate()
          : null,
      rejectionReason: json['rejectionReason'] as String?,
      location: json['location'] != null
          ? LocationModel.fromJson(json['location'] as Map<String, dynamic>)
          : null,
      profileSource: json['profileSource'] as String?,
      resumeParseDate: json['resumeParseDate'] != null
          ? (json['resumeParseDate'] as Timestamp).toDate()
          : null,
      aiConfidenceScore: (json['aiConfidenceScore'] as num?)?.toDouble(),
    );
  }

  UserModel copyWith({
    String? userId,
    String? email,
    String? phoneNumber,
    String? role,
    String? firstName,
    String? lastName,
    String? profileImage,
    bool? isVerified,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? skills,
    String? experience,
    String? education,
    String? resume,
    String? summary,
    Map<String, dynamic>? availability,
    List<String>? savedJobs,
    Map<String, dynamic>? preferences,
    String? companyId,
    String? subscriptionTier,
    String? subscriptionId,
    DateTime? subscriptionExpiresAt,
    String? providerStatus,
    DateTime? approvedAt,
    DateTime? rejectedAt,
    String? rejectionReason,
    LocationModel? location,
    String? profileSource,
    DateTime? resumeParseDate,
    double? aiConfidenceScore,
  }) {
    return UserModel(
      userId: userId ?? this.userId,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role ?? this.role,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      profileImage: profileImage ?? this.profileImage,
      isVerified: isVerified ?? this.isVerified,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      skills: skills ?? this.skills,
      experience: experience ?? this.experience,
      education: education ?? this.education,
      resume: resume ?? this.resume,
      summary: summary ?? this.summary,
      availability: availability ?? this.availability,
      savedJobs: savedJobs ?? this.savedJobs,
      preferences: preferences ?? this.preferences,
      companyId: companyId ?? this.companyId,
      subscriptionTier: subscriptionTier ?? this.subscriptionTier,
      subscriptionId: subscriptionId ?? this.subscriptionId,
      subscriptionExpiresAt: subscriptionExpiresAt ?? this.subscriptionExpiresAt,
      providerStatus: providerStatus ?? this.providerStatus,
      approvedAt: approvedAt ?? this.approvedAt,
      rejectedAt: rejectedAt ?? this.rejectedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      location: location ?? this.location,
      profileSource: profileSource ?? this.profileSource,
      resumeParseDate: resumeParseDate ?? this.resumeParseDate,
      aiConfidenceScore: aiConfidenceScore ?? this.aiConfidenceScore,
    );
  }

  // Helper getters for provider status
  bool get isPendingApproval => providerStatus == 'pending_approval';
  bool get isApproved => providerStatus == 'approved';
  bool get isRejected => providerStatus == 'rejected';
  bool get isProviderActive => providerStatus == 'active';
  bool get isSuspended => providerStatus == 'suspended';
  bool get canPostJobs => providerStatus == 'active';
  bool get canSelectPlan => providerStatus == 'approved' || providerStatus == 'active';

  // Check if subscription is valid
  bool get hasActiveSubscription {
    if (subscriptionExpiresAt == null) return false;
    return subscriptionExpiresAt!.isAfter(DateTime.now());
  }

  // Check if user has AI access
  bool get hasAIAccess {
    if (!hasActiveSubscription) return false;
    return subscriptionTier == 'pro' || subscriptionTier == 'enterprise';
  }

  String get fullName => '$firstName $lastName'.trim();

  String get initials {
    final first = firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
    final last = lastName.isNotEmpty ? lastName[0].toUpperCase() : '';
    return '$first$last';
  }

  bool get isPremiumUser {
    if (subscriptionTier == null || subscriptionExpiresAt == null) return false;
    return subscriptionTier != 'free' &&
        subscriptionExpiresAt!.isAfter(DateTime.now());
  }

  bool get hasCompletedProfile {
    if (role == 'job_seeker') {
      return firstName.isNotEmpty &&
          lastName.isNotEmpty &&
          (skills?.isNotEmpty ?? false);
    }
    return firstName.isNotEmpty && lastName.isNotEmpty;
  }

  // Compatibility getters for admin views
  String get status => isActive ? 'active' : 'inactive';
  String? get phone => phoneNumber;
  bool get isEmailVerified => isVerified;
  DateTime? get lastLoginAt => updatedAt; // Using updatedAt as proxy
  DateTime? get suspendedAt => null; // Not tracked in current model
  String? get suspensionReason => null; // Not tracked in current model
  int get applicationsCount => 0; // Would need to be fetched separately
  int get jobsPosted => 0; // Would need to be fetched separately
  int get totalHires => 0; // Would need to be fetched separately
}

class LocationModel {
  final String address;
  final String city;
  final String state;
  final String country;
  final String zipCode;
  final GeoPoint? coordinates;

  LocationModel({
    required this.address,
    required this.city,
    required this.state,
    required this.country,
    required this.zipCode,
    this.coordinates,
  });

  Map<String, dynamic> toJson() {
    return {
      'address': address,
      'city': city,
      'state': state,
      'country': country,
      'zipCode': zipCode,
      'coordinates': coordinates,
    };
  }

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      address: json['address'] as String? ?? '',
      city: json['city'] as String? ?? '',
      state: json['state'] as String? ?? '',
      country: json['country'] as String? ?? '',
      zipCode: json['zipCode'] as String? ?? '',
      coordinates: json['coordinates'] as GeoPoint?,
    );
  }

  String get fullAddress => '$address, $city, $state, $country $zipCode';

  String get shortAddress => '$city, $state';
}
