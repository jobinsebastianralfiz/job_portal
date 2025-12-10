import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/firebase_constants.dart';
import '../../models/user_model.dart';

class UserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _users => _db.collection(FirebaseConstants.usersCollection);

  // Create User
  Future<void> createUser(UserModel user) async {
    await _users.doc(user.userId).set(user.toJson());
  }

  // Update User
  Future<void> updateUser(UserModel user) async {
    final updatedUser = user.copyWith(updatedAt: DateTime.now());
    await _users.doc(user.userId).update(updatedUser.toJson());
  }

  // Get User by ID
  Future<UserModel?> getUser(String userId) async {
    final doc = await _users.doc(userId).get();
    if (!doc.exists) return null;
    return UserModel.fromJson(doc.data() as Map<String, dynamic>);
  }

  // Stream User
  Stream<UserModel?> streamUser(String userId) {
    return _users.doc(userId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromJson(doc.data() as Map<String, dynamic>);
    });
  }

  // Delete User
  Future<void> deleteUser(String userId) async {
    await _users.doc(userId).delete();
  }

  // Update User Profile
  Future<void> updateProfile({
    required String userId,
    String? firstName,
    String? lastName,
    String? phone,
    String? profileImage,
    String? bio,
    Map<String, dynamic>? location,
  }) async {
    final updates = <String, dynamic>{
      FirebaseConstants.fieldUpdatedAt: FieldValue.serverTimestamp(),
    };

    if (firstName != null) updates['firstName'] = firstName;
    if (lastName != null) updates['lastName'] = lastName;
    if (phone != null) updates['phoneNumber'] = phone;
    if (profileImage != null) updates['profileImage'] = profileImage;
    if (bio != null) updates['bio'] = bio;
    if (location != null) updates['location'] = location;

    await _users.doc(userId).update(updates);
  }

  // Update Job Seeker Profile
  Future<void> updateJobSeekerProfile({
    required String userId,
    List<String>? skills,
    String? experience,
    String? education,
    String? summary,
    String? resume,
    String? availability,
    double? expectedSalary,
    String? currentJobTitle,
    String? linkedinUrl,
    String? portfolioUrl,
  }) async {
    final updates = <String, dynamic>{
      FirebaseConstants.fieldUpdatedAt: FieldValue.serverTimestamp(),
    };

    if (skills != null) updates['skills'] = skills;
    if (experience != null) updates['experience'] = experience;
    if (education != null) updates['education'] = education;
    if (summary != null) updates['summary'] = summary;
    if (resume != null) updates['resume'] = resume;
    if (availability != null) updates['availability'] = availability;
    if (expectedSalary != null) updates['expectedSalary'] = expectedSalary;
    if (currentJobTitle != null) updates['currentJobTitle'] = currentJobTitle;
    if (linkedinUrl != null) updates['linkedinUrl'] = linkedinUrl;
    if (portfolioUrl != null) updates['portfolioUrl'] = portfolioUrl;

    await _users.doc(userId).update(updates);
  }

  // Save Job
  Future<void> saveJob(String userId, String jobId) async {
    await _users.doc(userId).update({
      'savedJobs': FieldValue.arrayUnion([jobId]),
      FirebaseConstants.fieldUpdatedAt: FieldValue.serverTimestamp(),
    });
  }

  // Unsave Job
  Future<void> unsaveJob(String userId, String jobId) async {
    await _users.doc(userId).update({
      'savedJobs': FieldValue.arrayRemove([jobId]),
      FirebaseConstants.fieldUpdatedAt: FieldValue.serverTimestamp(),
    });
  }

  // Check if Job is Saved
  Future<bool> isJobSaved(String userId, String jobId) async {
    final user = await getUser(userId);
    return user?.savedJobs?.contains(jobId) ?? false;
  }

  // Get Saved Jobs
  Future<List<String>> getSavedJobs(String userId) async {
    final user = await getUser(userId);
    return user?.savedJobs ?? [];
  }

  // Update FCM Token
  Future<void> updateFcmToken(String userId, String token) async {
    await _users.doc(userId).update({
      'fcmToken': token,
      'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Update Last Login
  Future<void> updateLastLogin(String userId) async {
    await _users.doc(userId).update({
      'lastLoginAt': FieldValue.serverTimestamp(),
    });
  }

  // Update Resume with AI Parse Data
  Future<void> updateResumeWithAIData({
    required String userId,
    required String resumeUrl,
    required Map<String, dynamic> parsedData,
    required double confidenceScore,
  }) async {
    await _users.doc(userId).update({
      'resume': resumeUrl,
      'skills': parsedData['skills'] ?? [],
      'experience': parsedData['experience'],
      'education': parsedData['education'],
      'currentJobTitle': parsedData['currentJobTitle'],
      'profileSource': 'ai_parsed',
      'resumeParseDate': FieldValue.serverTimestamp(),
      'aiConfidenceScore': confidenceScore,
      FirebaseConstants.fieldUpdatedAt: FieldValue.serverTimestamp(),
    });
  }

  // Get All Users (Admin)
  Future<List<UserModel>> getAllUsers({
    int limit = 50,
    String? role,
    DocumentSnapshot? startAfter,
  }) async {
    Query query = _users.orderBy(FirebaseConstants.fieldCreatedAt, descending: true);

    if (role != null && role.isNotEmpty) {
      query = query.where(FirebaseConstants.fieldRole, isEqualTo: role);
    }

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    query = query.limit(limit);

    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => UserModel.fromJson(doc.data() as Map<String, dynamic>))
        .toList();
  }

  // Stream All Users (Admin)
  Stream<List<UserModel>> streamAllUsers({int limit = 100}) {
    return _users
        .orderBy(FirebaseConstants.fieldCreatedAt, descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserModel.fromJson(doc.data() as Map<String, dynamic>))
            .toList());
  }

  // Search Users
  Future<List<UserModel>> searchUsers(String query, {int limit = 20}) async {
    final queryLower = query.toLowerCase();

    final snapshot = await _users.limit(100).get();

    return snapshot.docs
        .map((doc) => UserModel.fromJson(doc.data() as Map<String, dynamic>))
        .where((user) =>
            user.fullName.toLowerCase().contains(queryLower) ||
            user.email.toLowerCase().contains(queryLower) ||
            (user.skills?.any((skill) => skill.toLowerCase().contains(queryLower)) ?? false))
        .take(limit)
        .toList();
  }

  // Get Users by Role
  Future<List<UserModel>> getUsersByRole(String role, {int limit = 50}) async {
    final snapshot = await _users
        .where(FirebaseConstants.fieldRole, isEqualTo: role)
        .orderBy(FirebaseConstants.fieldCreatedAt, descending: true)
        .limit(limit)
        .get();

    return snapshot.docs
        .map((doc) => UserModel.fromJson(doc.data() as Map<String, dynamic>))
        .toList();
  }

  // Update User Status (Admin)
  Future<void> updateUserStatus(String userId, String status) async {
    await _users.doc(userId).update({
      FirebaseConstants.fieldStatus: status,
      FirebaseConstants.fieldUpdatedAt: FieldValue.serverTimestamp(),
    });
  }

  // Suspend User (Admin)
  Future<void> suspendUser(String userId, {String? reason}) async {
    await _users.doc(userId).update({
      FirebaseConstants.fieldStatus: 'suspended',
      'suspensionReason': reason,
      'suspendedAt': FieldValue.serverTimestamp(),
      FirebaseConstants.fieldUpdatedAt: FieldValue.serverTimestamp(),
    });
  }

  // Unsuspend User (Admin)
  Future<void> unsuspendUser(String userId) async {
    await _users.doc(userId).update({
      FirebaseConstants.fieldStatus: 'active',
      'suspensionReason': null,
      'suspendedAt': null,
      FirebaseConstants.fieldUpdatedAt: FieldValue.serverTimestamp(),
    });
  }

  // Verify User (Admin)
  Future<void> verifyUser(String userId) async {
    await _users.doc(userId).update({
      FirebaseConstants.fieldIsVerified: true,
      'verifiedAt': FieldValue.serverTimestamp(),
      FirebaseConstants.fieldUpdatedAt: FieldValue.serverTimestamp(),
    });
  }

  // Get User Stats (Admin)
  Future<Map<String, int>> getUserStats() async {
    final snapshot = await _users.get();

    int jobSeekers = 0;
    int jobProviders = 0;
    int admins = 0;
    int active = 0;
    int suspended = 0;
    int verified = 0;

    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final role = data[FirebaseConstants.fieldRole] as String?;
      final status = data[FirebaseConstants.fieldStatus] as String?;
      final isVerified = data[FirebaseConstants.fieldIsVerified] as bool?;

      switch (role) {
        case 'job_seeker':
          jobSeekers++;
          break;
        case 'job_provider':
          jobProviders++;
          break;
        case 'admin':
          admins++;
          break;
      }

      if (status == 'active') active++;
      if (status == 'suspended') suspended++;
      if (isVerified == true) verified++;
    }

    return {
      'total': snapshot.docs.length,
      'jobSeekers': jobSeekers,
      'jobProviders': jobProviders,
      'admins': admins,
      'active': active,
      'suspended': suspended,
      'verified': verified,
    };
  }

  // Get Job Seekers by Skills
  Future<List<UserModel>> getJobSeekersBySkills(
    List<String> skills, {
    int limit = 20,
  }) async {
    // Firestore doesn't support array-contains-any with multiple values efficiently
    // So we'll fetch and filter client-side
    final snapshot = await _users
        .where(FirebaseConstants.fieldRole, isEqualTo: 'job_seeker')
        .limit(100)
        .get();

    final skillsLower = skills.map((s) => s.toLowerCase()).toList();

    return snapshot.docs
        .map((doc) => UserModel.fromJson(doc.data() as Map<String, dynamic>))
        .where((user) => user.skills?.any(
            (skill) => skillsLower.contains(skill.toLowerCase())) ?? false)
        .take(limit)
        .toList();
  }

  // Update Subscription
  Future<void> updateSubscription({
    required String userId,
    required String tier,
    required DateTime expiresAt,
  }) async {
    await _users.doc(userId).update({
      'subscriptionTier': tier,
      'subscriptionExpiresAt': Timestamp.fromDate(expiresAt),
      FirebaseConstants.fieldUpdatedAt: FieldValue.serverTimestamp(),
    });
  }

  // Check if Email Exists
  Future<bool> emailExists(String email) async {
    final snapshot = await _users
        .where(FirebaseConstants.fieldEmail, isEqualTo: email)
        .limit(1)
        .get();

    return snapshot.docs.isNotEmpty;
  }

  // Get Recently Active Users
  Future<List<UserModel>> getRecentlyActiveUsers({int limit = 20}) async {
    final snapshot = await _users
        .orderBy('lastLoginAt', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs
        .map((doc) => UserModel.fromJson(doc.data() as Map<String, dynamic>))
        .toList();
  }
}
