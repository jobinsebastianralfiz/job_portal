import 'package:cloud_firestore/cloud_firestore.dart';

class CompanyModel {
  final String companyId;
  final String name;
  final String description;
  final String? logo;
  final String industry;
  final String size;
  final String? website;
  final String email;
  final String? phone;
  final bool isVerified;
  final double rating;
  final int totalReviews;
  final CompanyLocation? location;
  final SocialLinks? socialLinks;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String ownerId;
  final List<String>? teamMembers;
  final int activeJobs;
  final int totalHires;

  CompanyModel({
    required this.companyId,
    required this.name,
    required this.description,
    this.logo,
    required this.industry,
    required this.size,
    this.website,
    required this.email,
    this.phone,
    this.isVerified = false,
    this.rating = 0.0,
    this.totalReviews = 0,
    this.location,
    this.socialLinks,
    required this.createdAt,
    required this.updatedAt,
    required this.ownerId,
    this.teamMembers,
    this.activeJobs = 0,
    this.totalHires = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'companyId': companyId,
      'name': name,
      'description': description,
      'logo': logo,
      'industry': industry,
      'size': size,
      'website': website,
      'email': email,
      'phone': phone,
      'isVerified': isVerified,
      'rating': rating,
      'totalReviews': totalReviews,
      'location': location?.toJson(),
      'socialLinks': socialLinks?.toJson(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'ownerId': ownerId,
      'teamMembers': teamMembers,
      'activeJobs': activeJobs,
      'totalHires': totalHires,
    };
  }

  factory CompanyModel.fromJson(Map<String, dynamic> json) {
    return CompanyModel(
      companyId: json['companyId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      logo: json['logo'] as String?,
      industry: json['industry'] as String? ?? '',
      size: json['size'] as String? ?? '1-10',
      website: json['website'] as String?,
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String?,
      isVerified: json['isVerified'] as bool? ?? false,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      totalReviews: json['totalReviews'] as int? ?? 0,
      location: json['location'] != null
          ? CompanyLocation.fromJson(json['location'] as Map<String, dynamic>)
          : null,
      socialLinks: json['socialLinks'] != null
          ? SocialLinks.fromJson(json['socialLinks'] as Map<String, dynamic>)
          : null,
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? (json['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
      ownerId: json['ownerId'] as String? ?? '',
      teamMembers: (json['teamMembers'] as List<dynamic>?)?.cast<String>(),
      activeJobs: json['activeJobs'] as int? ?? 0,
      totalHires: json['totalHires'] as int? ?? 0,
    );
  }

  CompanyModel copyWith({
    String? companyId,
    String? name,
    String? description,
    String? logo,
    String? industry,
    String? size,
    String? website,
    String? email,
    String? phone,
    bool? isVerified,
    double? rating,
    int? totalReviews,
    CompanyLocation? location,
    SocialLinks? socialLinks,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? ownerId,
    List<String>? teamMembers,
    int? activeJobs,
    int? totalHires,
  }) {
    return CompanyModel(
      companyId: companyId ?? this.companyId,
      name: name ?? this.name,
      description: description ?? this.description,
      logo: logo ?? this.logo,
      industry: industry ?? this.industry,
      size: size ?? this.size,
      website: website ?? this.website,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      isVerified: isVerified ?? this.isVerified,
      rating: rating ?? this.rating,
      totalReviews: totalReviews ?? this.totalReviews,
      location: location ?? this.location,
      socialLinks: socialLinks ?? this.socialLinks,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      ownerId: ownerId ?? this.ownerId,
      teamMembers: teamMembers ?? this.teamMembers,
      activeJobs: activeJobs ?? this.activeJobs,
      totalHires: totalHires ?? this.totalHires,
    );
  }

  String get initials {
    final words = name.split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '';
  }

  // Compatibility getters for company_profile_view
  int get totalJobs => activeJobs;
  String? get founded => null; // Not tracked in current model
  String? get type => industry;
  String? get headquarters => location?.fullAddress;
  String? get linkedin => socialLinks?.linkedin;
  String? get twitter => socialLinks?.twitter;
  List<String> get benefits => []; // Not tracked in current model
  List<String> get gallery => []; // Not tracked in current model
}

class CompanyLocation {
  final String address;
  final String city;
  final String state;
  final String country;
  final String zipCode;
  final GeoPoint? coordinates;

  CompanyLocation({
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

  factory CompanyLocation.fromJson(Map<String, dynamic> json) {
    return CompanyLocation(
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

class SocialLinks {
  final String? linkedin;
  final String? facebook;
  final String? twitter;
  final String? instagram;

  SocialLinks({
    this.linkedin,
    this.facebook,
    this.twitter,
    this.instagram,
  });

  Map<String, dynamic> toJson() {
    return {
      'linkedin': linkedin,
      'facebook': facebook,
      'twitter': twitter,
      'instagram': instagram,
    };
  }

  factory SocialLinks.fromJson(Map<String, dynamic> json) {
    return SocialLinks(
      linkedin: json['linkedin'] as String?,
      facebook: json['facebook'] as String?,
      twitter: json['twitter'] as String?,
      instagram: json['instagram'] as String?,
    );
  }
}
