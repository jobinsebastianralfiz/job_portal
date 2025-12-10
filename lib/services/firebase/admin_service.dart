import 'package:cloud_firestore/cloud_firestore.dart';
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
    int limit = 20,
    DocumentSnapshot? lastDoc,
  }) async {
    try {
      Query query = _firestore.collection('users');

      if (role != null && role != 'all') {
        query = query.where('role', isEqualTo: role);
      }

      if (status != null && status != 'all') {
        query = query.where('status', isEqualTo: status);
      }

      query = query.orderBy('createdAt', descending: true);

      if (lastDoc != null) {
        query = query.startAfterDocument(lastDoc);
      }

      query = query.limit(limit);

      final snapshot = await query.get();

      List<UserModel> users = snapshot.docs
          .map((doc) => UserModel.fromJson({...doc.data() as Map<String, dynamic>, 'userId': doc.id}))
          .toList();

      // Filter by search query if provided
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final lowerQuery = searchQuery.toLowerCase();
        users = users.where((user) {
          return user.email.toLowerCase().contains(lowerQuery) ||
              (user.firstName?.toLowerCase().contains(lowerQuery) ?? false) ||
              (user.lastName?.toLowerCase().contains(lowerQuery) ?? false);
        }).toList();
      }

      return users;
    } catch (e) {
      print('Error getting users: $e');
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
      await _firestore.collection('users').doc(userId).update({
        'status': 'suspended',
        'suspendedAt': DateTime.now().toIso8601String(),
        'suspensionReason': reason,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      print('Error suspending user: $e');
      return false;
    }
  }

  Future<bool> activateUser(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'status': 'active',
        'suspendedAt': FieldValue.delete(),
        'suspensionReason': FieldValue.delete(),
        'updatedAt': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      print('Error activating user: $e');
      return false;
    }
  }

  Future<bool> deleteUser(String userId) async {
    try {
      // Soft delete - just mark as deleted
      await _firestore.collection('users').doc(userId).update({
        'status': 'deleted',
        'deletedAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      print('Error deleting user: $e');
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
