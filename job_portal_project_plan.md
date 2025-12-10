# Job Management System - Project Plan

## Project Overview
**Technology Stack:**
- Frontend: Flutter (iOS, Android, Web)
- Backend: Firebase (Auth, Firestore, Storage, Functions)
- Architecture: MVC Pattern
- State Management: Provider
- Maps: Google Maps API
- Payments: Stripe/Razorpay
- Video Calls: Agora.io

---

## 1. Project Structure

```
job_portal/
├── lib/
│   ├── main.dart
│   ├── app.dart
│   │
│   ├── core/
│   │   ├── constants/
│   │   │   ├── app_constants.dart
│   │   │   ├── firebase_constants.dart
│   │   │   ├── route_constants.dart
│   │   │   └── api_constants.dart
│   │   ├── theme/
│   │   │   ├── app_theme.dart
│   │   │   ├── dark_theme.dart
│   │   │   └── light_theme.dart
│   │   ├── utils/
│   │   │   ├── validators.dart
│   │   │   ├── formatters.dart
│   │   │   ├── date_utils.dart
│   │   │   └── permission_handler.dart
│   │   └── errors/
│   │       ├── failures.dart
│   │       └── exceptions.dart
│   │
│   ├── models/
│   │   ├── user_model.dart
│   │   ├── job_model.dart
│   │   ├── application_model.dart
│   │   ├── message_model.dart
│   │   ├── company_model.dart
│   │   ├── subscription_model.dart
│   │   └── notification_model.dart
│   │
│   ├── views/
│   │   ├── auth/
│   │   │   ├── login_view.dart
│   │   │   ├── register_view.dart
│   │   │   ├── forgot_password_view.dart
│   │   │   └── role_selection_view.dart
│   │   ├── job_seeker/
│   │   │   ├── home_view.dart
│   │   │   ├── job_search_view.dart
│   │   │   ├── job_details_view.dart
│   │   │   ├── applications_view.dart
│   │   │   ├── profile_view.dart
│   │   │   └── saved_jobs_view.dart
│   │   ├── job_provider/
│   │   │   ├── provider_home_view.dart
│   │   │   ├── post_job_view.dart
│   │   │   ├── manage_jobs_view.dart
│   │   │   ├── applications_received_view.dart
│   │   │   ├── company_profile_view.dart
│   │   │   └── analytics_view.dart
│   │   ├── admin/
│   │   │   ├── admin_dashboard_view.dart
│   │   │   ├── user_management_view.dart
│   │   │   ├── job_moderation_view.dart
│   │   │   ├── reports_view.dart
│   │   │   └── system_settings_view.dart
│   │   ├── common/
│   │   │   ├── chat_view.dart
│   │   │   ├── notifications_view.dart
│   │   │   ├── settings_view.dart
│   │   │   └── splash_view.dart
│   │   └── widgets/
│   │       ├── custom_button.dart
│   │       ├── custom_text_field.dart
│   │       ├── job_card.dart
│   │       ├── application_card.dart
│   │       ├── loading_indicator.dart
│   │       └── error_widget.dart
│   │
│   ├── controllers/
│   │   ├── auth_controller.dart
│   │   ├── user_controller.dart
│   │   ├── job_controller.dart
│   │   ├── application_controller.dart
│   │   ├── chat_controller.dart
│   │   ├── payment_controller.dart
│   │   ├── notification_controller.dart
│   │   └── admin_controller.dart
│   │
│   ├── services/
│   │   ├── firebase/
│   │   │   ├── firebase_auth_service.dart
│   │   │   ├── firestore_service.dart
│   │   │   ├── storage_service.dart
│   │   │   └── cloud_functions_service.dart
│   │   ├── api/
│   │   │   ├── payment_service.dart
│   │   │   ├── maps_service.dart
│   │   │   └── video_call_service.dart
│   │   ├── local/
│   │   │   ├── shared_preferences_service.dart
│   │   │   └── secure_storage_service.dart
│   │   └── notification_service.dart
│   │
│   ├── providers/
│   │   ├── auth_provider.dart
│   │   ├── user_provider.dart
│   │   ├── job_provider.dart
│   │   ├── application_provider.dart
│   │   ├── chat_provider.dart
│   │   ├── theme_provider.dart
│   │   └── notification_provider.dart
│   │
│   └── routes/
│       ├── app_router.dart
│       └── route_generator.dart
│
├── assets/
│   ├── images/
│   ├── icons/
│   └── fonts/
│
├── test/
│   ├── unit/
│   ├── widget/
│   └── integration/
│
├── android/
├── ios/
├── web/
├── pubspec.yaml
└── README.md
```

---

## 2. Firebase Configuration

### 2.1 Firebase Services Setup

**Required Firebase Services:**
1. **Firebase Authentication**
   - Email/Password
   - Google Sign-In
   - Phone Authentication (optional)

2. **Cloud Firestore**
   - Database structure (see section 3)
   - Security rules
   - Indexes for complex queries

3. **Firebase Storage**
   - User profile images
   - Company logos
   - Resume/document uploads
   - Job images

4. **Cloud Functions**
   - Send notifications
   - Process payments
   - Generate analytics
   - Email triggers
   - Scheduled jobs

5. **Firebase Cloud Messaging (FCM)**
   - Push notifications
   - In-app notifications

6. **Firebase Analytics**
   - User behavior tracking
   - Feature usage analytics

### 2.2 Firebase Security Rules

**Firestore Security Rules:**
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Helper functions
    function isAuthenticated() {
      return request.auth != null;
    }
    
    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }
    
    function isAdmin() {
      return isAuthenticated() && 
             get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
    
    function isJobProvider() {
      return isAuthenticated() && 
             get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'job_provider';
    }
    
    // Users collection
    match /users/{userId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated() && request.auth.uid == userId;
      allow update: if isOwner(userId);
      allow delete: if isOwner(userId) || isAdmin();
    }
    
    // Jobs collection
    match /jobs/{jobId} {
      allow read: if isAuthenticated();
      allow create: if isJobProvider();
      allow update: if isJobProvider() && 
                      get(/databases/$(database)/documents/jobs/$(jobId)).data.providerId == request.auth.uid;
      allow delete: if isAdmin() || 
                      (isJobProvider() && resource.data.providerId == request.auth.uid);
    }
    
    // Applications collection
    match /applications/{applicationId} {
      allow read: if isAuthenticated() && 
                    (resource.data.applicantId == request.auth.uid || 
                     resource.data.providerId == request.auth.uid ||
                     isAdmin());
      allow create: if isAuthenticated();
      allow update: if isAuthenticated() && 
                      (resource.data.applicantId == request.auth.uid || 
                       resource.data.providerId == request.auth.uid);
      allow delete: if isAdmin();
    }
    
    // Messages collection
    match /chats/{chatId}/messages/{messageId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated();
    }
    
    // Admin only collections
    match /analytics/{document=**} {
      allow read, write: if isAdmin();
    }
  }
}
```

**Storage Security Rules:**
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    
    // User profile images
    match /users/{userId}/profile/{filename} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Company logos
    match /companies/{companyId}/logo/{filename} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
    
    // Resumes
    match /resumes/{userId}/{filename} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Job images
    match /jobs/{jobId}/{filename} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
  }
}
```

---

## 3. Database Schema (Firestore)

### 3.1 Users Collection
```dart
users/{userId}
{
  "userId": String,
  "email": String,
  "phoneNumber": String?,
  "role": String, // "job_seeker", "job_provider", "admin"
  "firstName": String,
  "lastName": String,
  "profileImage": String?,
  "isVerified": bool,
  "isActive": bool,
  "createdAt": Timestamp,
  "updatedAt": Timestamp,
  
  // Job Seeker specific
  "skills": List<String>?,
  "experience": String?,
  "education": String?,
  "resume": String?, // Storage URL
  "availability": Map<String, dynamic>?,
  "savedJobs": List<String>?,
  "preferences": Map<String, dynamic>?,
  
  // Job Provider specific
  "companyId": String?,
  "subscriptionTier": String?, // "free", "basic", "premium"
  "subscriptionExpiresAt": Timestamp?,
  
  // Location
  "location": {
    "address": String,
    "city": String,
    "state": String,
    "country": String,
    "zipCode": String,
    "coordinates": GeoPoint
  }
}
```

### 3.2 Companies Collection
```dart
companies/{companyId}
{
  "companyId": String,
  "name": String,
  "description": String,
  "logo": String?, // Storage URL
  "industry": String,
  "size": String, // "1-10", "11-50", "51-200", "201-500", "501+"
  "website": String?,
  "email": String,
  "phone": String?,
  "isVerified": bool,
  "rating": double,
  "totalReviews": int,
  "location": {
    "address": String,
    "city": String,
    "state": String,
    "country": String,
    "zipCode": String,
    "coordinates": GeoPoint
  },
  "socialLinks": {
    "linkedin": String?,
    "facebook": String?,
    "twitter": String?
  },
  "createdAt": Timestamp,
  "updatedAt": Timestamp,
  "ownerId": String // User ID
}
```

### 3.3 Jobs Collection
```dart
jobs/{jobId}
{
  "jobId": String,
  "title": String,
  "description": String,
  "companyId": String,
  "providerId": String, // User ID
  "category": String,
  "employmentType": String, // "part-time", "freelance", "contract"
  "experience": String, // "entry", "intermediate", "expert"
  "
": List<String>,
  "requirements": List<String>,
  
  // Compensation
  "salaryType": String, // "hourly", "fixed", "negotiable"
  "salaryMin": double?,
  "salaryMax": double?,
  "currency": String,
  
  // Schedule
  "hoursPerWeek": int?,
  "schedule": {
    "flexibility": String, // "flexible", "fixed"
    "preferredDays": List<String>?,
    "preferredTimes": String?
  },
  
  // Location
  "workLocation": String, // "on-site", "remote", "hybrid"
  "location": {
    "address": String?,
    "city": String,
    "state": String,
    "country": String,
    "coordinates": GeoPoint?
  },
  
  // Status and visibility
  "status": String, // "draft", "active", "closed", "expired"
  "isFeatured": bool,
  "isUrgent": bool,
  "expiresAt": Timestamp?,
  
  // Engagement metrics
  "views": int,
  "applications": int,
  "saves": int,
  
  // Screening
  "screeningQuestions": List<Map<String, dynamic>>?,
  
  "createdAt": Timestamp,
  "updatedAt": Timestamp,
  "publishedAt": Timestamp?
}
```

### 3.4 Applications Collection
```dart
applications/{applicationId}
{
  "applicationId": String,
  "jobId": String,
  "applicantId": String, // User ID
  "providerId": String, // User ID
  "companyId": String,
  
  // Application details
  "coverLetter": String?,
  "resume": String?, // Storage URL
  "documents": List<String>?, // Additional documents
  "answers": List<Map<String, dynamic>>?, // Screening question answers
  
  // Status tracking
  "status": String, // "pending", "reviewed", "shortlisted", "interview", "offered", "accepted", "rejected", "withdrawn"
  "statusHistory": List<Map<String, dynamic>>,
  
  // Interview details
  "interview": {
    "scheduledAt": Timestamp?,
    "type": String?, // "phone", "video", "in-person"
    "meetingLink": String?,
    "notes": String?
  }?,
  
  // Provider notes
  "providerNotes": String?,
  "rating": int?, // 1-5 stars
  
  "appliedAt": Timestamp,
  "updatedAt": Timestamp
}
```

### 3.5 Chats Collection
```dart
chats/{chatId}
{
  "chatId": String,
  "participants": List<String>, // User IDs
  "participantsData": Map<String, Map<String, dynamic>>,
  "lastMessage": {
    "text": String,
    "senderId": String,
    "timestamp": Timestamp
  },
  "unreadCount": Map<String, int>, // userId: count
  "createdAt": Timestamp,
  "updatedAt": Timestamp,
  "relatedJobId": String?,
  "relatedApplicationId": String?
}

// Subcollection
chats/{chatId}/messages/{messageId}
{
  "messageId": String,
  "senderId": String,
  "text": String?,
  "type": String, // "text", "image", "file", "system"
  "fileUrl": String?,
  "fileName": String?,
  "isRead": bool,
  "readBy": List<String>,
  "createdAt": Timestamp
}
```

### 3.6 Notifications Collection
```dart
notifications/{notificationId}
{
  "notificationId": String,
  "userId": String,
  "type": String, // "application", "message", "job_alert", "system"
  "title": String,
  "body": String,
  "data": Map<String, dynamic>?,
  "isRead": bool,
  "actionUrl": String?,
  "createdAt": Timestamp
}
```

### 3.7 Subscriptions Collection
```dart
subscriptions/{subscriptionId}
{
  "subscriptionId": String,
  "userId": String,
  "tier": String, // "free", "basic", "premium", "enterprise"
  "status": String, // "active", "cancelled", "expired"
  "startDate": Timestamp,
  "endDate": Timestamp,
  "features": {
    "jobPostsPerMonth": int,
    "featuredPosts": int,
    "applicantViews": bool,
    "analytics": bool,
    "prioritySupport": bool
  },
  "paymentDetails": {
    "amount": double,
    "currency": String,
    "paymentId": String?,
    "lastPaymentDate": Timestamp?
  },
  "autoRenew": bool,
  "createdAt": Timestamp,
  "updatedAt": Timestamp
}
```

### 3.8 Reviews Collection
```dart
reviews/{reviewId}
{
  "reviewId": String,
  "companyId": String,
  "reviewerId": String, // User ID
  "rating": int, // 1-5
  "title": String,
  "review": String,
  "pros": String?,
  "cons": String?,
  "isVerified": bool, // Only users who worked there
  "isVisible": bool,
  "helpfulCount": int,
  "createdAt": Timestamp,
  "updatedAt": Timestamp
}
```

---

## 4. MVC Architecture Implementation

### 4.1 Model Layer

**Base Model Pattern:**
```dart
// models/base_model.dart
abstract class BaseModel {
  Map<String, dynamic> toJson();
  
  factory BaseModel.fromJson(Map<String, dynamic> json);
  
  BaseModel copyWith();
}
```

**Example: User Model**
```dart
// models/user_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { jobSeeker, jobProvider, admin }

class UserModel {
  final String userId;
  final String email;
  final String? phoneNumber;
  final UserRole role;
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
  final Map<String, dynamic>? availability;
  final List<String>? savedJobs;
  
  // Job Provider specific
  final String? companyId;
  final String? subscriptionTier;
  final DateTime? subscriptionExpiresAt;
  
  // Location
  final LocationModel? location;

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
    this.availability,
    this.savedJobs,
    this.companyId,
    this.subscriptionTier,
    this.subscriptionExpiresAt,
    this.location,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'email': email,
      'phoneNumber': phoneNumber,
      'role': role.name,
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
      'availability': availability,
      'savedJobs': savedJobs,
      'companyId': companyId,
      'subscriptionTier': subscriptionTier,
      'subscriptionExpiresAt': subscriptionExpiresAt != null 
          ? Timestamp.fromDate(subscriptionExpiresAt!) 
          : null,
      'location': location?.toJson(),
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['userId'] as String,
      email: json['email'] as String,
      phoneNumber: json['phoneNumber'] as String?,
      role: UserRole.values.firstWhere(
        (e) => e.name == json['role'],
        orElse: () => UserRole.jobSeeker,
      ),
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      profileImage: json['profileImage'] as String?,
      isVerified: json['isVerified'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: (json['updatedAt'] as Timestamp).toDate(),
      skills: (json['skills'] as List<dynamic>?)?.cast<String>(),
      experience: json['experience'] as String?,
      education: json['education'] as String?,
      resume: json['resume'] as String?,
      availability: json['availability'] as Map<String, dynamic>?,
      savedJobs: (json['savedJobs'] as List<dynamic>?)?.cast<String>(),
      companyId: json['companyId'] as String?,
      subscriptionTier: json['subscriptionTier'] as String?,
      subscriptionExpiresAt: json['subscriptionExpiresAt'] != null
          ? (json['subscriptionExpiresAt'] as Timestamp).toDate()
          : null,
      location: json['location'] != null
          ? LocationModel.fromJson(json['location'] as Map<String, dynamic>)
          : null,
    );
  }

  UserModel copyWith({
    String? userId,
    String? email,
    String? phoneNumber,
    UserRole? role,
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
    Map<String, dynamic>? availability,
    List<String>? savedJobs,
    String? companyId,
    String? subscriptionTier,
    DateTime? subscriptionExpiresAt,
    LocationModel? location,
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
      availability: availability ?? this.availability,
      savedJobs: savedJobs ?? this.savedJobs,
      companyId: companyId ?? this.companyId,
      subscriptionTier: subscriptionTier ?? this.subscriptionTier,
      subscriptionExpiresAt: subscriptionExpiresAt ?? this.subscriptionExpiresAt,
      location: location ?? this.location,
    );
  }

  String get fullName => '$firstName $lastName';
  
  bool get isPremiumUser {
    if (subscriptionTier == null || subscriptionExpiresAt == null) return false;
    return subscriptionTier != 'free' && subscriptionExpiresAt!.isAfter(DateTime.now());
  }
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
      address: json['address'] as String,
      city: json['city'] as String,
      state: json['state'] as String,
      country: json['country'] as String,
      zipCode: json['zipCode'] as String,
      coordinates: json['coordinates'] as GeoPoint?,
    );
  }
}
```

### 4.2 View Layer

**Base View Structure:**
```dart
// views/base_view.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

abstract class BaseView<T extends ChangeNotifier> extends StatefulWidget {
  const BaseView({Key? key}) : super(key: key);
}

abstract class BaseViewState<T extends ChangeNotifier, V extends BaseView<T>>
    extends State<V> {
  T get provider => Provider.of<T>(context, listen: false);
  
  @override
  void initState() {
    super.initState();
    onModelReady();
  }
  
  void onModelReady() {}
  
  @override
  Widget build(BuildContext context);
}
```

**Example: Job Search View**
```dart
// views/job_seeker/job_search_view.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class JobSearchView extends StatefulWidget {
  const JobSearchView({Key? key}) : super(key: key);

  @override
  State<JobSearchView> createState() => _JobSearchViewState();
}

class _JobSearchViewState extends State<JobSearchView> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<JobProvider>().loadJobs();
    });
    
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels == 
        _scrollController.position.maxScrollExtent) {
      context.read<JobProvider>().loadMoreJobs();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Jobs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildFilterChips(),
          Expanded(child: _buildJobList()),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search jobs, companies, keywords...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    context.read<JobProvider>().searchJobs('');
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onChanged: (value) {
          context.read<JobProvider>().searchJobs(value);
        },
      ),
    );
  }

  Widget _buildFilterChips() {
    return Consumer<JobProvider>(
      builder: (context, jobProvider, child) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _buildChip('All', jobProvider.selectedCategory == null, () {
                jobProvider.filterByCategory(null);
              }),
              ...jobProvider.categories.map((category) {
                return _buildChip(
                  category,
                  jobProvider.selectedCategory == category,
                  () => jobProvider.filterByCategory(category),
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChip(String label, bool isSelected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onTap(),
      ),
    );
  }

  Widget _buildJobList() {
    return Consumer<JobProvider>(
      builder: (context, jobProvider, child) {
        if (jobProvider.isLoading && jobProvider.jobs.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (jobProvider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(jobProvider.error!),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => jobProvider.loadJobs(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (jobProvider.jobs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.work_off, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text('No jobs found'),
              ],
            ),
          );
        }

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          itemCount: jobProvider.jobs.length + (jobProvider.hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == jobProvider.jobs.length) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            final job = jobProvider.jobs[index];
            return JobCard(
              job: job,
              onTap: () => _navigateToJobDetails(job),
            );
          },
        );
      },
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const JobFilterSheet(),
    );
  }

  void _navigateToJobDetails(JobModel job) {
    Navigator.pushNamed(
      context,
      '/job-details',
      arguments: job,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
```

### 4.3 Controller Layer

**Base Controller Pattern:**
```dart
// controllers/base_controller.dart
import 'package:flutter/foundation.dart';

abstract class BaseController extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
```

**Example: Job Controller**
```dart
// controllers/job_controller.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/job_model.dart';
import '../services/firebase/firestore_service.dart';
import 'base_controller.dart';

class JobController extends BaseController {
  final FirestoreService _firestoreService;
  
  List<JobModel> _jobs = [];
  JobModel? _selectedJob;
  
  // Filters
  String? _searchQuery;
  String? _selectedCategory;
  Map<String, dynamic>? _filters;
  
  // Pagination
  DocumentSnapshot? _lastDocument;
  bool _hasMore = true;
  final int _pageSize = 20;

  JobController(this._firestoreService);

  List<JobModel> get jobs => _jobs;
  JobModel? get selectedJob => _selectedJob;
  String? get searchQuery => _searchQuery;
  String? get selectedCategory => _selectedCategory;
  bool get hasMore => _hasMore;

  // Load jobs with optional filters
  Future<void> loadJobs({bool refresh = false}) async {
    if (refresh) {
      _jobs.clear();
      _lastDocument = null;
      _hasMore = true;
    }

    if (!_hasMore || isLoading) return;

    try {
      setLoading(true);
      clearError();

      Query query = _firestoreService.collection('jobs')
          .where('status', isEqualTo: 'active')
          .orderBy('createdAt', descending: true)
          .limit(_pageSize);

      // Apply filters
      if (_selectedCategory != null) {
        query = query.where('category', isEqualTo: _selectedCategory);
      }

      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      final querySnapshot = await query.get();
      
      if (querySnapshot.docs.isEmpty) {
        _hasMore = false;
      } else {
        _lastDocument = querySnapshot.docs.last;
        
        final newJobs = querySnapshot.docs
            .map((doc) => JobModel.fromJson(doc.data() as Map<String, dynamic>))
            .toList();
        
        _jobs.addAll(newJobs);
        _hasMore = newJobs.length == _pageSize;
      }

      notifyListeners();
    } catch (e) {
      setError('Failed to load jobs: ${e.toString()}');
    } finally {
      setLoading(false);
    }
  }

  // Load more jobs (pagination)
  Future<void> loadMoreJobs() async {
    if (!_hasMore || isLoading) return;
    await loadJobs();
  }

  // Search jobs
  Future<void> searchJobs(String query) async {
    _searchQuery = query.toLowerCase();
    _jobs.clear();
    _lastDocument = null;
    _hasMore = true;

    if (query.isEmpty) {
      await loadJobs();
      return;
    }

    try {
      setLoading(true);
      clearError();

      // Note: For production, use Algolia or ElasticSearch for better search
      final querySnapshot = await _firestoreService
          .collection('jobs')
          .where('status', isEqualTo: 'active')
          .get();

      _jobs = querySnapshot.docs
          .map((doc) => JobModel.fromJson(doc.data()))
          .where((job) =>
              job.title.toLowerCase().contains(query) ||
              job.description.toLowerCase().contains(query) ||
              job.skills.any((skill) => skill.toLowerCase().contains(query)))
          .toList();

      _hasMore = false;
      notifyListeners();
    } catch (e) {
      setError('Search failed: ${e.toString()}');
    } finally {
      setLoading(false);
    }
  }

  // Filter by category
  Future<void> filterByCategory(String? category) async {
    _selectedCategory = category;
    _jobs.clear();
    _lastDocument = null;
    _hasMore = true;
    await loadJobs();
  }

  // Apply advanced filters
  Future<void> applyFilters(Map<String, dynamic> filters) async {
    _filters = filters;
    _jobs.clear();
    _lastDocument = null;
    _hasMore = true;

    try {
      setLoading(true);
      clearError();

      Query query = _firestoreService.collection('jobs')
          .where('status', isEqualTo: 'active');

      // Apply various filters
      if (filters['category'] != null) {
        query = query.where('category', isEqualTo: filters['category']);
      }

      if (filters['employmentType'] != null) {
        query = query.where('employmentType', isEqualTo: filters['employmentType']);
      }

      if (filters['workLocation'] != null) {
        query = query.where('workLocation', isEqualTo: filters['workLocation']);
      }

      if (filters['salaryMin'] != null) {
        query = query.where('salaryMin', isGreaterThanOrEqualTo: filters['salaryMin']);
      }

      query = query.orderBy('createdAt', descending: true).limit(_pageSize);

      final querySnapshot = await query.get();
      
      _jobs = querySnapshot.docs
          .map((doc) => JobModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();

      if (querySnapshot.docs.isNotEmpty) {
        _lastDocument = querySnapshot.docs.last;
        _hasMore = querySnapshot.docs.length == _pageSize;
      }

      notifyListeners();
    } catch (e) {
      setError('Failed to apply filters: ${e.toString()}');
    } finally {
      setLoading(false);
    }
  }

  // Get job by ID
  Future<JobModel?> getJobById(String jobId) async {
    try {
      setLoading(true);
      clearError();

      final doc = await _firestoreService.collection('jobs').doc(jobId).get();
      
      if (doc.exists) {
        _selectedJob = JobModel.fromJson(doc.data()!);
        notifyListeners();
        return _selectedJob;
      }
      
      return null;
    } catch (e) {
      setError('Failed to load job: ${e.toString()}');
      return null;
    } finally {
      setLoading(false);
    }
  }

  // Create new job (for providers)
  Future<bool> createJob(JobModel job) async {
    try {
      setLoading(true);
      clearError();

      await _firestoreService.collection('jobs').doc(job.jobId).set(job.toJson());
      
      notifyListeners();
      return true;
    } catch (e) {
      setError('Failed to create job: ${e.toString()}');
      return false;
    } finally {
      setLoading(false);
    }
  }

  // Update job
  Future<bool> updateJob(String jobId, Map<String, dynamic> updates) async {
    try {
      setLoading(true);
      clearError();

      updates['updatedAt'] = Timestamp.now();
      await _firestoreService.collection('jobs').doc(jobId).update(updates);
      
      // Update local job if it's the selected one
      if (_selectedJob?.jobId == jobId) {
        _selectedJob = _selectedJob!.copyWith(
          // Apply updates...
        );
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      setError('Failed to update job: ${e.toString()}');
      return false;
    } finally {
      setLoading(false);
    }
  }

  // Delete job
  Future<bool> deleteJob(String jobId) async {
    try {
      setLoading(true);
      clearError();

      await _firestoreService.collection('jobs').doc(jobId).delete();
      _jobs.removeWhere((job) => job.jobId == jobId);
      
      if (_selectedJob?.jobId == jobId) {
        _selectedJob = null;
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      setError('Failed to delete job: ${e.toString()}');
      return false;
    } finally {
      setLoading(false);
    }
  }

  // Increment job views
  Future<void> incrementJobViews(String jobId) async {
    try {
      await _firestoreService.collection('jobs').doc(jobId).update({
        'views': FieldValue.increment(1),
      });
    } catch (e) {
      // Silent fail for view tracking
      debugPrint('Failed to increment views: $e');
    }
  }

  // Save job for later
  Future<bool> toggleSaveJob(String jobId, String userId) async {
    try {
      final userRef = _firestoreService.collection('users').doc(userId);
      final userDoc = await userRef.get();
      
      final savedJobs = List<String>.from(userDoc.data()?['savedJobs'] ?? []);
      
      if (savedJobs.contains(jobId)) {
        savedJobs.remove(jobId);
        await _firestoreService.collection('jobs').doc(jobId).update({
          'saves': FieldValue.increment(-1),
        });
      } else {
        savedJobs.add(jobId);
        await _firestoreService.collection('jobs').doc(jobId).update({
          'saves': FieldValue.increment(1),
        });
      }
      
      await userRef.update({'savedJobs': savedJobs});
      
      notifyListeners();
      return true;
    } catch (e) {
      setError('Failed to save job: ${e.toString()}');
      return false;
    }
  }

  void clearFilters() {
    _selectedCategory = null;
    _filters = null;
    _searchQuery = null;
    _jobs.clear();
    _lastDocument = null;
    _hasMore = true;
    loadJobs();
  }
}
```

---

## 5. Provider State Management Setup

### 5.1 Provider Configuration

```dart
// main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'services/firebase/firebase_auth_service.dart';
import 'services/firebase/firestore_service.dart';
import 'services/firebase/storage_service.dart';
import 'providers/auth_provider.dart';
import 'providers/user_provider.dart';
import 'providers/job_provider.dart';
import 'providers/application_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/notification_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  runApp(
    MultiProvider(
      providers: [
        // Services
        Provider(create: (_) => FirebaseAuthService()),
        Provider(create: (_) => FirestoreService()),
        Provider(create: (_) => StorageService()),
        
        // Providers with dependencies
        ChangeNotifierProvider(
          create: (context) => AuthProvider(
            context.read<FirebaseAuthService>(),
            context.read<FirestoreService>(),
          ),
        ),
        
        ChangeNotifierProxyProvider<AuthProvider, UserProvider>(
          create: (context) => UserProvider(
            context.read<FirestoreService>(),
            context.read<StorageService>(),
          ),
          update: (context, auth, previous) => previous!..updateUser(auth.currentUser),
        ),
        
        ChangeNotifierProvider(
          create: (context) => JobProvider(
            context.read<FirestoreService>(),
          ),
        ),
        
        ChangeNotifierProxyProvider<AuthProvider, ApplicationProvider>(
          create: (context) => ApplicationProvider(
            context.read<FirestoreService>(),
          ),
          update: (context, auth, previous) => previous!..setCurrentUserId(auth.currentUser?.userId),
        ),
        
        ChangeNotifierProxyProvider<AuthProvider, ChatProvider>(
          create: (context) => ChatProvider(
            context.read<FirestoreService>(),
          ),
          update: (context, auth, previous) => previous!..setCurrentUserId(auth.currentUser?.userId),
        ),
        
        ChangeNotifierProvider(
          create: (_) => ThemeProvider(),
        ),
        
        ChangeNotifierProxyProvider<AuthProvider, NotificationProvider>(
          create: (context) => NotificationProvider(
            context.read<FirestoreService>(),
          ),
          update: (context, auth, previous) => previous!..setCurrentUserId(auth.currentUser?.userId),
        ),
      ],
      child: const MyApp(),
    ),
  );
}
```

### 5.2 Provider Implementation Examples

**Auth Provider:**
```dart
// providers/auth_provider.dart
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../models/user_model.dart';
import '../services/firebase/firebase_auth_service.dart';
import '../services/firebase/firestore_service.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuthService _authService;
  final FirestoreService _firestoreService;

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;

  AuthProvider(this._authService, this._firestoreService) {
    _authService.authStateChanges.listen(_onAuthStateChanged);
  }

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;

  void _onAuthStateChanged(firebase_auth.User? firebaseUser) async {
    if (firebaseUser != null) {
      await _loadUserData(firebaseUser.uid);
    } else {
      _currentUser = null;
      notifyListeners();
    }
  }

  Future<void> _loadUserData(String userId) async {
    try {
      final doc = await _firestoreService.collection('users').doc(userId).get();
      if (doc.exists) {
        _currentUser = UserModel.fromJson(doc.data()!);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  Future<bool> signIn(String email, String password) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final user = await _authService.signInWithEmail(email, password);
      if (user != null) {
        await _loadUserData(user.uid);
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required UserRole role,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final firebaseUser = await _authService.signUpWithEmail(email, password);
      if (firebaseUser != null) {
        final newUser = UserModel(
          userId: firebaseUser.uid,
          email: email,
          firstName: firstName,
          lastName: lastName,
          role: role,
          isVerified: false,
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await _firestoreService.collection('users')
            .doc(firebaseUser.uid)
            .set(newUser.toJson());

        _currentUser = newUser;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _currentUser = null;
    notifyListeners();
  }

  Future<bool> resetPassword(String email) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _authService.resetPassword(email);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
```

**Job Provider:**
```dart
// providers/job_provider.dart
import 'package:flutter/foundation.dart';
import '../models/job_model.dart';
import '../controllers/job_controller.dart';

class JobProvider extends ChangeNotifier {
  final JobController _jobController;

  JobProvider(FirestoreService firestoreService)
      : _jobController = JobController(firestoreService);

  List<JobModel> get jobs => _jobController.jobs;
  JobModel? get selectedJob => _jobController.selectedJob;
  bool get isLoading => _jobController.isLoading;
  String? get error => _jobController.error;
  bool get hasMore => _jobController.hasMore;
  String? get selectedCategory => _jobController.selectedCategory;

  // Categories for filtering
  final List<String> categories = [
    'Technology',
    'Healthcare',
    'Education',
    'Retail',
    'Hospitality',
    'Finance',
    'Marketing',
    'Customer Service',
    'Other',
  ];

  Future<void> loadJobs({bool refresh = false}) async {
    await _jobController.loadJobs(refresh: refresh);
    notifyListeners();
  }

  Future<void> loadMoreJobs() async {
    await _jobController.loadMoreJobs();
    notifyListeners();
  }

  Future<void> searchJobs(String query) async {
    await _jobController.searchJobs(query);
    notifyListeners();
  }

  Future<void> filterByCategory(String? category) async {
    await _jobController.filterByCategory(category);
    notifyListeners();
  }

  Future<void> applyFilters(Map<String, dynamic> filters) async {
    await _jobController.applyFilters(filters);
    notifyListeners();
  }

  Future<JobModel?> getJobById(String jobId) async {
    final job = await _jobController.getJobById(jobId);
    notifyListeners();
    return job;
  }

  Future<bool> createJob(JobModel job) async {
    final success = await _jobController.createJob(job);
    notifyListeners();
    return success;
  }

  Future<bool> updateJob(String jobId, Map<String, dynamic> updates) async {
    final success = await _jobController.updateJob(jobId, updates);
    notifyListeners();
    return success;
  }

  Future<bool> deleteJob(String jobId) async {
    final success = await _jobController.deleteJob(jobId);
    notifyListeners();
    return success;
  }

  Future<void> incrementJobViews(String jobId) async {
    await _jobController.incrementJobViews(jobId);
  }

  Future<bool> toggleSaveJob(String jobId, String userId) async {
    final success = await _jobController.toggleSaveJob(jobId, userId);
    notifyListeners();
    return success;
  }

  void clearFilters() {
    _jobController.clearFilters();
    notifyListeners();
  }

  void clearError() {
    _jobController.clearError();
    notifyListeners();
  }
}
```

---

## 6. Development Phases & Timeline

### Phase 1: Foundation & Core Setup (Weeks 1-4)

**Week 1: Project Setup**
- Initialize Flutter project
- Set up Firebase project and integrate SDKs
- Configure development, staging, and production environments
- Set up project structure (MVC folders)
- Install and configure dependencies

**Dependencies:**
```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # State Management
  provider: ^6.1.1
  
  # Firebase
  firebase_core: ^2.24.2
  firebase_auth: ^4.15.3
  cloud_firestore: ^4.13.6
  firebase_storage: ^11.5.6
  firebase_messaging: ^14.7.10
  firebase_analytics: ^10.8.0
  
  # UI & Utilities
  google_fonts: ^6.1.0
  flutter_svg: ^2.0.9
  cached_network_image: ^3.3.1
  image_picker: ^1.0.7
  file_picker: ^6.1.1
  
  # Maps & Location
  google_maps_flutter: ^2.5.3
  geolocator: ^10.1.0
  geocoding: ^2.1.1
  
  # Networking
  dio: ^5.4.0
  
  # Local Storage
  shared_preferences: ^2.2.2
  flutter_secure_storage: ^9.0.0
  
  # Utils
  intl: ^0.18.1
  uuid: ^4.3.3
  timeago: ^3.6.0
  url_launcher: ^6.2.4
  
  # Payments
  flutter_stripe: ^10.1.1
  
  # Video Calling
  agora_rtc_engine: ^6.3.0
  
  # Notifications
  flutter_local_notifications: ^16.3.2

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.1
  build_runner: ^2.4.8
```

**Week 2: Authentication Module**
- Implement Firebase Authentication service
- Create login view and controller
- Create registration view with role selection
- Implement forgot password functionality
- Set up auth state management with Provider
- Create splash screen with auth check

**Week 3: User Profile Module**
- Design and implement user model
- Create profile views for all user roles
- Implement profile editing functionality
- Add image upload (profile pictures)
- Create company profile management (for providers)
- Set up Firestore user collection

**Week 4: Core UI Components**
- Design app theme (light/dark modes)
- Create reusable widgets (buttons, text fields, cards)
- Implement navigation structure
- Create bottom navigation for each role
- Design and implement empty states
- Create loading and error widgets

### Phase 2: Job Management (Weeks 5-8)

**Week 5: Job Listing & Display**
- Implement job model
- Create job listing view for seekers
- Design job card widget
- Implement job details view
- Add image support for job postings
- Create job provider home dashboard

**Week 6: Job Posting (Provider Side)**
- Create job posting form
- Implement multi-step job creation
- Add rich text editor for descriptions
- Implement category and tag selection
- Add location picker with maps
- Create job preview functionality

**Week 7: Search & Filters**
- Implement basic search functionality
- Create filter bottom sheet
- Add category filters
- Implement location-based filtering
- Add salary range filter
- Create saved searches functionality

**Week 8: Job Management (Provider Side)**
- Create "My Jobs" view for providers
- Implement job editing
- Add job status management (active/closed/draft)
- Create job analytics view (views, applications)
- Implement job duplication feature
- Add bulk job operations

### Phase 3: Application System (Weeks 9-12)

**Week 9: Application Submission**
- Implement application model
- Create job application form
- Add document upload (resume, cover letter)
- Implement screening questions
- Create application preview
- Add application submission logic

**Week 10: Application Management (Seeker Side)**
- Create "My Applications" view
- Implement application status tracking
- Add application withdrawal feature
- Create application details view
- Implement document management
- Add application history

**Week 11: Application Management (Provider Side)**
- Create applications received view
- Implement application filtering and sorting
- Create applicant profile view
- Add candidate screening tools
- Implement bulk application operations
- Create interview scheduling interface

**Week 12: Application Status Flow**
- Implement status update functionality
- Create notification system for status changes
- Add interview management
- Implement offer sending/accepting
- Create feedback system
- Add application analytics

### Phase 4: Communication (Weeks 13-15)

**Week 13: In-App Messaging**
- Implement chat model and structure
- Create chat list view
- Design message bubble widgets
- Implement real-time messaging with Firestore
- Add message read receipts
- Create chat notifications

**Week 14: Enhanced Chat Features**
- Add file sharing in chats
- Implement image sharing
- Add typing indicators
- Create message search
- Implement chat archiving
- Add block/report functionality

**Week 15: Video Integration**
- Integrate Agora for video calls
- Create video call interface
- Implement call notifications
- Add call history
- Create scheduled interview calls
- Implement call recording (optional)

### Phase 5: Advanced Features (Weeks 16-19)

**Week 16: Notifications**
- Implement FCM setup
- Create notification model
- Add local notifications
- Implement push notifications
- Create notification preferences
- Add notification history view

**Week 17: Payment Integration**
- Set up Stripe/Razorpay
- Create subscription plans
- Implement payment processing
- Add subscription management
- Create billing history
- Implement refund processing

**Week 18: Analytics & Reporting**
- Implement Firebase Analytics events
- Create analytics dashboard (providers)
- Add job performance metrics
- Create application success tracking
- Implement custom report generation
- Add data export functionality

**Week 19: Reviews & Ratings**
- Implement review model
- Create company review system
- Add rating functionality
- Implement review moderation
- Create review display widgets
- Add helpful/report review features

### Phase 6: Admin Panel (Weeks 20-22)

**Week 20: User Management**
- Create admin dashboard
- Implement user list view
- Add user search and filtering
- Create user details view
- Implement user verification
- Add user ban/suspend functionality

**Week 21: Content Moderation**
- Create job moderation queue
- Implement job approval/rejection
- Add review moderation
- Create reported content view
- Implement automated content filtering
- Add moderation logs

**Week 22: System Management**
- Create system settings view
- Implement platform configuration
- Add analytics dashboard
- Create revenue reports
- Implement support ticket system
- Add system health monitoring

### Phase 7: Testing & Polish (Weeks 23-26)

**Week 23: Unit Testing**
- Write unit tests for models
- Test service layers
- Test controllers
- Test utility functions
- Achieve 70%+ code coverage

**Week 24: Widget Testing**
- Test critical UI components
- Test user flows
- Test form validations
- Test navigation
- Test state management

**Week 25: Integration Testing**
- Test end-to-end flows
- Test Firebase integration
- Test payment flows
- Test real-time features
- Perform performance testing

**Week 26: Bug Fixes & Polish**
- Fix identified bugs
- Optimize performance
- Improve UI/UX
- Add loading states
- Implement error handling
- Polish animations

### Phase 8: Deployment (Weeks 27-28)

**Week 27: Pre-Launch**
- Prepare app store assets
- Create privacy policy & terms
- Set up app store listings
- Configure production Firebase
- Perform security audit
- Create user documentation

**Week 28: Launch**
- Deploy to Play Store (Android)
- Deploy to App Store (iOS)
- Deploy web version
- Set up monitoring and analytics
- Prepare customer support
- Create marketing materials

---

## 7. Key Services Implementation

### 7.1 Firebase Auth Service

```dart
// services/firebase/firebase_auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  
  User? get currentUser => _auth.currentUser;

  Future<User?> signInWithEmail(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } catch (e) {
      rethrow;
    }
  }

  Future<User?> signUpWithEmail(String email, String password) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> sendEmailVerification() async {
    await _auth.currentUser?.sendEmailVerification();
  }
}
```

### 7.2 Firestore Service

```dart
// services/firebase/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference collection(String path) {
    return _db.collection(path);
  }

  DocumentReference doc(String path) {
    return _db.doc(path);
  }

  Future<void> setData(String path, Map<String, dynamic> data) async {
    await _db.doc(path).set(data);
  }

  Future<void> updateData(String path, Map<String, dynamic> data) async {
    await _db.doc(path).update(data);
  }

  Future<void> deleteData(String path) async {
    await _db.doc(path).delete();
  }

  Stream<DocumentSnapshot> streamDocument(String path) {
    return _db.doc(path).snapshots();
  }

  Stream<QuerySnapshot> streamCollection(String path) {
    return _db.collection(path).snapshots();
  }

  Future<QuerySnapshot> getCollection(String path) {
    return _db.collection(path).get();
  }

  Future<DocumentSnapshot> getDocument(String path) {
    return _db.doc(path).get();
  }
}
```

### 7.3 Storage Service

```dart
// services/firebase/storage_service.dart
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String?> uploadFile(File file, String path) async {
    try {
      final ref = _storage.ref().child(path);
      await ref.putFile(file);
      return await ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  Future<bool> deleteFile(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<String?> uploadProfileImage(File image, String userId) async {
    return uploadFile(image, 'users/$userId/profile/${DateTime.now().millisecondsSinceEpoch}.jpg');
  }

  Future<String?> uploadResume(File resume, String userId) async {
    return uploadFile(resume, 'resumes/$userId/${DateTime.now().millisecondsSinceEpoch}.pdf');
  }

  Future<String?> uploadCompanyLogo(File logo, String companyId) async {
    return uploadFile(logo, 'companies/$companyId/logo/${DateTime.now().millisecondsSinceEpoch}.jpg');
  }
}
```

---

## 8. Testing Strategy

### 8.1 Unit Tests

```dart
// test/models/user_model_test.dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UserModel', () {
    test('should create UserModel from JSON', () {
      // Arrange
      final json = {
        'userId': '123',
        'email': 'test@example.com',
        'role': 'job_seeker',
        'firstName': 'John',
        'lastName': 'Doe',
        // ... other fields
      };

      // Act
      final user = UserModel.fromJson(json);

      // Assert
      expect(user.userId, '123');
      expect(user.email, 'test@example.com');
      expect(user.role, UserRole.jobSeeker);
    });

    test('should convert UserModel to JSON', () {
      // Arrange
      final user = UserModel(/* ... */);

      // Act
      final json = user.toJson();

      // Assert
      expect(json['userId'], user.userId);
      expect(json['email'], user.email);
    });
  });
}
```

### 8.2 Widget Tests

```dart
// test/widgets/job_card_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('JobCard displays job information', (WidgetTester tester) async {
    // Arrange
    final job = JobModel(/* ... */);

    // Act
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: JobCard(job: job, onTap: () {}),
        ),
      ),
    );

    // Assert
    expect(find.text(job.title), findsOneWidget);
    expect(find.text(job.company), findsOneWidget);
  });
}
```

### 8.3 Integration Tests

```dart
// integration_test/app_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('end-to-end test', () {
    testWidgets('complete job application flow', (tester) async {
      // 1. Launch app
      // 2. Navigate to job listing
      // 3. Search for a job
      // 4. Open job details
      // 5. Apply for job
      // 6. Verify application submitted
    });
  });
}
```

---

## 9. Deployment Checklist

### 9.1 Pre-Launch

- [ ] Complete all feature development
- [ ] Fix all critical bugs
- [ ] Achieve minimum test coverage (70%)
- [ ] Perform security audit
- [ ] Optimize app performance
- [ ] Test on multiple devices
- [ ] Create privacy policy
- [ ] Create terms of service
- [ ] Set up crash reporting (Firebase Crashlytics)
- [ ] Set up analytics tracking
- [ ] Prepare app store assets
- [ ] Create app screenshots
- [ ] Write app descriptions
- [ ] Set up customer support system

### 9.2 Android Deployment

- [ ] Update app version in pubspec.yaml
- [ ] Configure release signing
- [ ] Generate release APK/App Bundle
- [ ] Test release build
- [ ] Create Play Store listing
- [ ] Upload to Play Console
- [ ] Submit for review

### 9.3 iOS Deployment

- [ ] Configure provisioning profiles
- [ ] Update version and build number
- [ ] Generate release IPA
- [ ] Test on physical devices
- [ ] Create App Store listing
- [ ] Upload to App Store Connect
- [ ] Submit for review

### 9.4 Web Deployment

- [ ] Build web release
- [ ] Test web build
- [ ] Set up hosting (Firebase Hosting)
- [ ] Configure domain
- [ ] Deploy to production

---

## 10. Post-Launch

### 10.1 Monitoring

- Monitor Firebase Analytics
- Track crash reports
- Monitor user feedback
- Track key metrics (DAU, MAU, retention)
- Monitor API performance
- Track payment transactions

### 10.2 Maintenance

- Regular bug fixes
- Performance optimization
- Security updates
- Feature enhancements
- User feedback implementation
- Regular Firebase SDK updates

---

## 11. Best Practices

### 11.1 Code Organization

- Follow MVC pattern strictly
- Keep controllers thin, move logic to services
- Use meaningful variable names
- Add comments for complex logic
- Follow Dart style guide

### 11.2 State Management

- Use Provider for global state
- Keep state as local as possible
- Avoid unnecessary rebuilds
- Use const constructors
- Dispose controllers properly

### 11.3 Firebase

- Implement offline persistence
- Use batch writes for multiple operations
- Optimize queries with indexes
- Implement proper security rules
- Use Cloud Functions for sensitive operations

### 11.4 Performance

- Use ListView.builder for long lists
- Implement pagination
- Cache images
- Lazy load data
- Minimize widget rebuilds
- Use const widgets

### 11.5 Security

- Never store sensitive data locally
- Use HTTPS for all API calls
- Implement proper authentication
- Validate all user inputs
- Use secure storage for tokens
- Implement rate limiting

---

## 12. Additional Recommendations

1. **CI/CD Pipeline**: Set up automated testing and deployment using Codemagic or GitHub Actions

2. **Error Tracking**: Implement Sentry or Firebase Crashlytics for better error tracking

3. **Feature Flags**: Use Firebase Remote Config for feature toggles

4. **A/B Testing**: Implement Firebase A/B Testing for experimenting with features

5. **Deep Linking**: Implement deep linking for better navigation

6. **Accessibility**: Ensure app is accessible (screen readers, color contrast)

7. **Localization**: Prepare app for multi-language support

8. **Documentation**: Maintain comprehensive documentation

9. **Code Reviews**: Implement peer code review process

10. **Version Control**: Use Git with proper branching strategy

---

This comprehensive project plan provides a solid foundation for building the Job Management System. Adjust timelines based on team size and expertise. Good luck with your project!
