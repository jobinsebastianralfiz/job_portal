import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../models/user_model.dart';
import '../../models/job_model.dart';
import '../../models/company_model.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==================== Dashboard Stats ====================

  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final usersSnapshot = await _firestore.collection('users').get();
      final jobsSnapshot = await _firestore.collection('jobs').get();
      final applicationsSnapshot = await _firestore.collection('applications').get();
      final companiesSnapshot = await _firestore.collection('companies').get();

      final users = usersSnapshot.docs;
      final seekers = users.where((u) => u.data()['role'] == 'job_seeker').length;
      final providers = users.where((u) => u.data()['role'] == 'job_provider').length;

      final jobs = jobsSnapshot.docs;
      final activeJobs = jobs.where((j) => j.data()['status'] == 'active').length;
      final pendingJobs = jobs.where((j) => j.data()['status'] == 'pending').length;

      final applications = applicationsSnapshot.docs;
      final pendingApps = applications.where((a) => a.data()['status'] == 'pending').length;

      final verifiedCompanies = companiesSnapshot.docs
          .where((c) => c.data()['isVerified'] == true).length;

      return {
        'totalUsers': users.length,
        'jobSeekers': seekers,
        'jobProviders': providers,
        'totalJobs': jobs.length,
        'activeJobs': activeJobs,
        'pendingJobs': pendingJobs,
        'totalApplications': applications.length,
        'pendingApplications': pendingApps,
        'totalCompanies': companiesSnapshot.docs.length,
        'verifiedCompanies': verifiedCompanies,
      };
    } catch (e) {
      print('Error getting dashboard stats: $e');
      return {};
    }
  }

  Future<Map<String, List<int>>> getWeeklyStats() async {
    try {
      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 7));

      // Get all data and filter client-side to avoid index issues
      final usersSnapshot = await _firestore.collection('users').get();
      final jobsSnapshot = await _firestore.collection('jobs').get();
      final applicationsSnapshot = await _firestore.collection('applications').get();

      // Group by day
      final Map<int, int> usersByDay = {};
      final Map<int, int> jobsByDay = {};
      final Map<int, int> applicationsByDay = {};

      for (int i = 0; i < 7; i++) {
        usersByDay[i] = 0;
        jobsByDay[i] = 0;
        applicationsByDay[i] = 0;
      }

      for (final doc in usersSnapshot.docs) {
        final data = doc.data();
        DateTime? createdAt;

        // Handle both Timestamp and String formats
        if (data['createdAt'] is Timestamp) {
          createdAt = (data['createdAt'] as Timestamp).toDate();
        } else if (data['createdAt'] is String) {
          createdAt = DateTime.tryParse(data['createdAt']);
        }

        if (createdAt != null && createdAt.isAfter(weekAgo)) {
          final daysDiff = now.difference(createdAt).inDays;
          if (daysDiff < 7 && daysDiff >= 0) {
            usersByDay[6 - daysDiff] = (usersByDay[6 - daysDiff] ?? 0) + 1;
          }
        }
      }

      for (final doc in jobsSnapshot.docs) {
        final data = doc.data();
        DateTime? createdAt;

        if (data['createdAt'] is Timestamp) {
          createdAt = (data['createdAt'] as Timestamp).toDate();
        } else if (data['createdAt'] is String) {
          createdAt = DateTime.tryParse(data['createdAt']);
        }

        if (createdAt != null && createdAt.isAfter(weekAgo)) {
          final daysDiff = now.difference(createdAt).inDays;
          if (daysDiff < 7 && daysDiff >= 0) {
            jobsByDay[6 - daysDiff] = (jobsByDay[6 - daysDiff] ?? 0) + 1;
          }
        }
      }

      for (final doc in applicationsSnapshot.docs) {
        final data = doc.data();
        DateTime? appliedAt;

        if (data['appliedAt'] is Timestamp) {
          appliedAt = (data['appliedAt'] as Timestamp).toDate();
        } else if (data['appliedAt'] is String) {
          appliedAt = DateTime.tryParse(data['appliedAt']);
        }

        if (appliedAt != null && appliedAt.isAfter(weekAgo)) {
          final daysDiff = now.difference(appliedAt).inDays;
          if (daysDiff < 7 && daysDiff >= 0) {
            applicationsByDay[6 - daysDiff] = (applicationsByDay[6 - daysDiff] ?? 0) + 1;
          }
        }
      }

      return {
        'users': List.generate(7, (i) => usersByDay[i] ?? 0),
        'jobs': List.generate(7, (i) => jobsByDay[i] ?? 0),
        'applications': List.generate(7, (i) => applicationsByDay[i] ?? 0),
      };
    } catch (e) {
      print('Error getting weekly stats: $e');
      return {
        'users': List.filled(7, 0),
        'jobs': List.filled(7, 0),
        'applications': List.filled(7, 0),
      };
    }
  }

  // ==================== User Management ====================

  Future<List<UserModel>> getAllUsers({
    String? role,
    String? status,
    String? searchQuery,
    int limit = 100,
    DocumentSnapshot? lastDoc,
  }) async {
    try {
      debugPrint('========================================');
      debugPrint('AdminService.getAllUsers() STARTING');
      debugPrint('Parameters - role: $role, status: $status, search: $searchQuery');
      debugPrint('========================================');

      // Simple query - just get all users
      final snapshot = await _firestore.collection('users').get();

      debugPrint('Firestore returned ${snapshot.docs.length} documents');

      if (snapshot.docs.isEmpty) {
        debugPrint('WARNING: No users found in Firestore users collection!');
        return [];
      }

      // Log first few documents for debugging
      for (int i = 0; i < snapshot.docs.length && i < 3; i++) {
        final doc = snapshot.docs[i];
        debugPrint('User ${i + 1}: id=${doc.id}, data=${doc.data()}');
      }

      List<UserModel> users = [];
      int suspendedCount = 0;
      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();
          // Check for suspended users in raw data
          if (data['status'] == 'suspended' || data['isActive'] == false) {
            debugPrint('FOUND SUSPENDED/INACTIVE USER: ${doc.id}, status=${data['status']}, isActive=${data['isActive']}');
            suspendedCount++;
          }
          final userWithId = {...data, 'userId': doc.id};
          users.add(UserModel.fromJson(userWithId));
        } catch (parseError) {
          debugPrint('ERROR parsing user ${doc.id}: $parseError');
        }
      }

      debugPrint('Successfully parsed ${users.length} users (found $suspendedCount suspended/inactive in raw data)');

      // Filter by role client-side
      if (role != null && role != 'all') {
        users = users.where((user) => user.role == role).toList();
        debugPrint('After role filter ($role): ${users.length} users');
      }

      // Filter by status client-side
      if (status != null && status != 'all') {
        users = users.where((user) => user.status == status).toList();
        debugPrint('After status filter ($status): ${users.length} users');
      }

      // Exclude deleted users unless specifically filtering for them
      if (status != 'deleted') {
        final beforeCount = users.length;
        users = users.where((user) => user.status != 'deleted').toList();
        debugPrint('After excluding deleted: ${users.length} users (removed ${beforeCount - users.length})');
      }

      // Filter by search query if provided
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final lowerQuery = searchQuery.toLowerCase();
        users = users.where((user) {
          return user.email.toLowerCase().contains(lowerQuery) ||
              user.firstName.toLowerCase().contains(lowerQuery) ||
              user.lastName.toLowerCase().contains(lowerQuery);
        }).toList();
        debugPrint('After search filter: ${users.length} users');
      }

      // Sort by createdAt descending (client-side)
      users.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      debugPrint('========================================');
      debugPrint('FINAL: Returning ${users.length} users');
      debugPrint('========================================');
      return users;
    } catch (e, stackTrace) {
      debugPrint('========================================');
      debugPrint('ERROR in getAllUsers: $e');
      debugPrint('Stack trace: $stackTrace');
      debugPrint('========================================');
      return [];
    }
  }

  Future<bool> updateUserStatus(String userId, String status) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'status': status,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      print('Error updating user status: $e');
      return false;
    }
  }

  Future<bool> suspendUser(String userId, String reason) async {
    try {
      print('Suspending user: $userId');
      await _firestore.collection('users').doc(userId).update({
        'status': 'suspended',
        'isActive': false,
        'suspendedAt': DateTime.now().toIso8601String(),
        'suspensionReason': reason,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      print('User $userId suspended successfully');
      return true;
    } catch (e) {
      print('Error suspending user: $e');
      return false;
    }
  }

  Future<bool> activateUser(String userId) async {
    try {
      print('Activating user: $userId');
      await _firestore.collection('users').doc(userId).update({
        'status': 'active',
        'isActive': true,
        'suspendedAt': FieldValue.delete(),
        'suspensionReason': FieldValue.delete(),
        'updatedAt': DateTime.now().toIso8601String(),
      });
      print('User $userId activated successfully');
      return true;
    } catch (e) {
      print('Error activating user: $e');
      return false;
    }
  }

  Future<bool> deleteUser(String userId) async {
    // Safety check - don't delete if userId is empty
    if (userId.isEmpty) {
      print('Error: Cannot delete user - userId is empty');
      return false;
    }

    try {
      print('Soft-deleting user with ID: $userId');
      // Soft delete - just mark as deleted (only affects this specific user)
      await _firestore.collection('users').doc(userId).update({
        'status': 'deleted',
        'deletedAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      });
      print('User $userId marked as deleted successfully');
      return true;
    } catch (e) {
      print('Error deleting user $userId: $e');
      return false;
    }
  }

  // ==================== Job Moderation ====================

  Future<List<JobModel>> getAllJobs({
    String? status,
    String? searchQuery,
    int limit = 20,
    DocumentSnapshot? lastDoc,
  }) async {
    try {
      Query query = _firestore.collection('jobs');

      if (status != null && status != 'all') {
        query = query.where('status', isEqualTo: status);
      }

      query = query.orderBy('createdAt', descending: true);

      if (lastDoc != null) {
        query = query.startAfterDocument(lastDoc);
      }

      query = query.limit(limit);

      final snapshot = await query.get();

      List<JobModel> jobs = snapshot.docs
          .map((doc) => JobModel.fromJson({...doc.data() as Map<String, dynamic>, 'jobId': doc.id}))
          .toList();

      // Filter by search query if provided
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final lowerQuery = searchQuery.toLowerCase();
        jobs = jobs.where((job) {
          return job.title.toLowerCase().contains(lowerQuery) ||
              job.companyName.toLowerCase().contains(lowerQuery);
        }).toList();
      }

      return jobs;
    } catch (e) {
      print('Error getting jobs: $e');
      return [];
    }
  }

  Future<List<JobModel>> getPendingJobs() async {
    try {
      final snapshot = await _firestore
          .collection('jobs')
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => JobModel.fromJson({...doc.data(), 'jobId': doc.id}))
          .toList();
    } catch (e) {
      print('Error getting pending jobs: $e');
      return [];
    }
  }

  Future<List<JobModel>> getReportedJobs() async {
    try {
      final snapshot = await _firestore
          .collection('jobs')
          .where('isReported', isEqualTo: true)
          .orderBy('reportedAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => JobModel.fromJson({...doc.data(), 'jobId': doc.id}))
          .toList();
    } catch (e) {
      print('Error getting reported jobs: $e');
      return [];
    }
  }

  Future<bool> approveJob(String jobId) async {
    try {
      await _firestore.collection('jobs').doc(jobId).update({
        'status': 'active',
        'approvedAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      print('Error approving job: $e');
      return false;
    }
  }

  Future<bool> rejectJob(String jobId, String reason) async {
    try {
      await _firestore.collection('jobs').doc(jobId).update({
        'status': 'rejected',
        'rejectedAt': DateTime.now().toIso8601String(),
        'rejectionReason': reason,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      print('Error rejecting job: $e');
      return false;
    }
  }

  Future<bool> flagJob(String jobId, String reason) async {
    try {
      await _firestore.collection('jobs').doc(jobId).update({
        'isFlagged': true,
        'flaggedAt': DateTime.now().toIso8601String(),
        'flagReason': reason,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      print('Error flagging job: $e');
      return false;
    }
  }

  Future<bool> removeJob(String jobId) async {
    try {
      await _firestore.collection('jobs').doc(jobId).update({
        'status': 'removed',
        'removedAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      print('Error removing job: $e');
      return false;
    }
  }

  Future<bool> clearJobReport(String jobId) async {
    try {
      await _firestore.collection('jobs').doc(jobId).update({
        'isReported': false,
        'reports': [],
        'reportedAt': FieldValue.delete(),
        'updatedAt': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      print('Error clearing job report: $e');
      return false;
    }
  }

  // ==================== Company Verification ====================

  Future<List<CompanyModel>> getPendingCompanyVerifications() async {
    try {
      final snapshot = await _firestore
          .collection('companies')
          .where('isVerified', isEqualTo: false)
          .where('verificationStatus', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => CompanyModel.fromJson({...doc.data(), 'companyId': doc.id}))
          .toList();
    } catch (e) {
      print('Error getting pending company verifications: $e');
      return [];
    }
  }

  Future<bool> verifyCompany(String companyId) async {
    try {
      await _firestore.collection('companies').doc(companyId).update({
        'isVerified': true,
        'verificationStatus': 'verified',
        'verifiedAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      print('Error verifying company: $e');
      return false;
    }
  }

  Future<bool> rejectCompanyVerification(String companyId, String reason) async {
    try {
      await _firestore.collection('companies').doc(companyId).update({
        'verificationStatus': 'rejected',
        'verificationRejectedAt': DateTime.now().toIso8601String(),
        'verificationRejectionReason': reason,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      print('Error rejecting company verification: $e');
      return false;
    }
  }

  // ==================== Recent Activity ====================

  Future<List<Map<String, dynamic>>> getRecentActivity({int limit = 20}) async {
    try {
      final activities = <Map<String, dynamic>>[];

      // Recent users
      final usersSnapshot = await _firestore
          .collection('users')
          .orderBy('createdAt', descending: true)
          .limit(5)
          .get();

      for (final doc in usersSnapshot.docs) {
        activities.add({
          'type': 'user_registered',
          'data': doc.data(),
          'timestamp': doc.data()['createdAt'],
        });
      }

      // Recent jobs
      final jobsSnapshot = await _firestore
          .collection('jobs')
          .orderBy('createdAt', descending: true)
          .limit(5)
          .get();

      for (final doc in jobsSnapshot.docs) {
        activities.add({
          'type': 'job_posted',
          'data': doc.data(),
          'timestamp': doc.data()['createdAt'],
        });
      }

      // Recent applications
      final applicationsSnapshot = await _firestore
          .collection('applications')
          .orderBy('appliedAt', descending: true)
          .limit(5)
          .get();

      for (final doc in applicationsSnapshot.docs) {
        activities.add({
          'type': 'application_submitted',
          'data': doc.data(),
          'timestamp': doc.data()['appliedAt'],
        });
      }

      // Sort by timestamp
      activities.sort((a, b) {
        final aTime = DateTime.parse(a['timestamp']);
        final bTime = DateTime.parse(b['timestamp']);
        return bTime.compareTo(aTime);
      });

      return activities.take(limit).toList();
    } catch (e) {
      print('Error getting recent activity: $e');
      return [];
    }
  }

  // ==================== System Settings ====================

  Future<Map<String, dynamic>?> getSystemSettings() async {
    try {
      final doc = await _firestore.collection('settings').doc('system').get();
      return doc.data();
    } catch (e) {
      print('Error getting system settings: $e');
      return null;
    }
  }

  Future<bool> updateSystemSettings(Map<String, dynamic> settings) async {
    try {
      await _firestore.collection('settings').doc('system').set(
        {
          ...settings,
          'updatedAt': DateTime.now().toIso8601String(),
        },
        SetOptions(merge: true),
      );
      return true;
    } catch (e) {
      print('Error updating system settings: $e');
      return false;
    }
  }
}
