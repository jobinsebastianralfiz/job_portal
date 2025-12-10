import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/job_model.dart';
import '../core/constants/firebase_constants.dart';

class JobProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  List<JobModel> _jobs = [];
  List<JobModel> _savedJobs = [];
  List<JobModel> _myJobs = [];
  JobModel? _selectedJob;
  bool _isLoading = false;
  String? _error;
  DocumentSnapshot? _lastDocument;
  bool _hasMore = true;
  String? _searchQuery;
  Map<String, dynamic>? _filters;

  List<JobModel> get jobs => _jobs;
  List<JobModel> get savedJobs => _savedJobs;
  List<JobModel> get myJobs => _myJobs;
  JobModel? get selectedJob => _selectedJob;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMore => _hasMore;

  // Load Jobs with Pagination
  Future<void> loadJobs({bool refresh = false}) async {
    if (refresh) {
      _jobs.clear();
      _lastDocument = null;
      _hasMore = true;
    }

    if (!_hasMore || _isLoading) return;

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // First try with status filter, fallback to all jobs if index not ready
      QuerySnapshot snapshot;
      try {
        Query query = _db
            .collection(FirebaseConstants.jobsCollection)
            .where('status', isEqualTo: 'active')
            .orderBy('createdAt', descending: true)
            .limit(20);

        if (_lastDocument != null) {
          query = query.startAfterDocument(_lastDocument!);
        }

        snapshot = await query.get();
      } catch (indexError) {
        // Fallback: load all jobs without composite index requirement
        debugPrint('Index error, falling back to simple query: $indexError');
        Query query = _db
            .collection(FirebaseConstants.jobsCollection)
            .orderBy('createdAt', descending: true)
            .limit(20);

        if (_lastDocument != null) {
          query = query.startAfterDocument(_lastDocument!);
        }

        snapshot = await query.get();
      }

      if (snapshot.docs.isEmpty) {
        _hasMore = false;
      } else {
        _lastDocument = snapshot.docs.last;
        final newJobs = snapshot.docs
            .map((doc) => JobModel.fromJson({...doc.data() as Map<String, dynamic>, 'jobId': doc.id}))
            .where((job) => job.status == 'active') // Filter in memory if needed
            .toList();
        _jobs.addAll(newJobs);
        _hasMore = snapshot.docs.length == 20;
      }
    } catch (e) {
      _error = 'Failed to load jobs: $e';
      debugPrint('Error loading jobs: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Search Jobs
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
      _isLoading = true;
      _error = null;
      notifyListeners();

      final snapshot = await _db
          .collection(FirebaseConstants.jobsCollection)
          .where('status', isEqualTo: 'active')
          .get();

      _jobs = snapshot.docs
          .map((doc) => JobModel.fromJson({...doc.data(), 'jobId': doc.id}))
          .where((job) =>
              job.title.toLowerCase().contains(_searchQuery!) ||
              job.description.toLowerCase().contains(_searchQuery!) ||
              job.companyName.toLowerCase().contains(_searchQuery!) ||
              job.skills.any((s) => s.toLowerCase().contains(_searchQuery!)))
          .toList();

      _hasMore = false;
    } catch (e) {
      _error = 'Search failed: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Filter Jobs
  Future<void> filterJobs(Map<String, dynamic> filters) async {
    _filters = filters;
    _jobs.clear();
    _lastDocument = null;
    _hasMore = true;

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      Query query = _db
          .collection(FirebaseConstants.jobsCollection)
          .where('status', isEqualTo: 'active');

      if (filters['category'] != null) {
        query = query.where('category', isEqualTo: filters['category']);
      }

      if (filters['employmentType'] != null) {
        query = query.where('employmentType', isEqualTo: filters['employmentType']);
      }

      if (filters['workLocation'] != null) {
        query = query.where('workLocation', isEqualTo: filters['workLocation']);
      }

      if (filters['experienceLevel'] != null) {
        query = query.where('experienceLevel', isEqualTo: filters['experienceLevel']);
      }

      query = query.orderBy('createdAt', descending: true).limit(20);

      final snapshot = await query.get();

      _jobs = snapshot.docs
          .map((doc) => JobModel.fromJson({...doc.data() as Map<String, dynamic>, 'jobId': doc.id}))
          .toList();

      _hasMore = _jobs.length == 20;
    } catch (e) {
      _error = 'Filter failed: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get Job by ID
  Future<JobModel?> getJobById(String jobId) async {
    try {
      _isLoading = true;
      notifyListeners();

      final doc = await _db.collection(FirebaseConstants.jobsCollection).doc(jobId).get();

      if (doc.exists) {
        _selectedJob = JobModel.fromJson({...doc.data()!, 'jobId': doc.id});
        notifyListeners();
        return _selectedJob;
      }
      return null;
    } catch (e) {
      _error = 'Failed to load job: $e';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create Job
  Future<bool> createJob(JobModel job) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final docRef = _db.collection(FirebaseConstants.jobsCollection).doc();
      final newJob = job.copyWith(jobId: docRef.id);
      await docRef.set(newJob.toJson());

      _myJobs.insert(0, newJob);
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to create job: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update Job
  Future<bool> updateJob(String jobId, Map<String, dynamic> updates) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      updates['updatedAt'] = FieldValue.serverTimestamp();
      await _db.collection(FirebaseConstants.jobsCollection).doc(jobId).update(updates);

      final index = _myJobs.indexWhere((j) => j.jobId == jobId);
      if (index != -1) {
        await getJobById(jobId);
        if (_selectedJob != null) {
          _myJobs[index] = _selectedJob!;
        }
      }

      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to update job: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Delete Job
  Future<bool> deleteJob(String jobId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _db.collection(FirebaseConstants.jobsCollection).doc(jobId).delete();
      _myJobs.removeWhere((j) => j.jobId == jobId);
      _jobs.removeWhere((j) => j.jobId == jobId);

      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to delete job: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load My Jobs (Provider)
  Future<void> loadMyJobs(String providerId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final snapshot = await _db
          .collection(FirebaseConstants.jobsCollection)
          .where('providerId', isEqualTo: providerId)
          .orderBy('createdAt', descending: true)
          .get();

      _myJobs = snapshot.docs
          .map((doc) => JobModel.fromJson({...doc.data(), 'jobId': doc.id}))
          .toList();
    } catch (e) {
      _error = 'Failed to load my jobs: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Toggle Save Job
  Future<bool> toggleSaveJob(String jobId, String userId) async {
    try {
      final userRef = _db.collection(FirebaseConstants.usersCollection).doc(userId);
      final userDoc = await userRef.get();
      final savedJobs = List<String>.from(userDoc.data()?['savedJobs'] ?? []);

      if (savedJobs.contains(jobId)) {
        savedJobs.remove(jobId);
        await _db.collection(FirebaseConstants.jobsCollection).doc(jobId).update({
          'saves': FieldValue.increment(-1),
        });
      } else {
        savedJobs.add(jobId);
        await _db.collection(FirebaseConstants.jobsCollection).doc(jobId).update({
          'saves': FieldValue.increment(1),
        });
      }

      await userRef.update({'savedJobs': savedJobs});
      await loadSavedJobs(userId);
      return true;
    } catch (e) {
      _error = 'Failed to save job: $e';
      return false;
    }
  }

  // Load Saved Jobs
  Future<void> loadSavedJobs(String userId) async {
    try {
      _isLoading = true;
      notifyListeners();

      final userDoc = await _db.collection(FirebaseConstants.usersCollection).doc(userId).get();
      final savedJobIds = List<String>.from(userDoc.data()?['savedJobs'] ?? []);

      if (savedJobIds.isEmpty) {
        _savedJobs = [];
      } else {
        final snapshot = await _db
            .collection(FirebaseConstants.jobsCollection)
            .where(FieldPath.documentId, whereIn: savedJobIds)
            .get();

        _savedJobs = snapshot.docs
            .map((doc) => JobModel.fromJson({...doc.data(), 'jobId': doc.id}))
            .toList();
      }
    } catch (e) {
      _error = 'Failed to load saved jobs: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Increment Job Views
  Future<void> incrementViews(String jobId) async {
    try {
      await _db.collection(FirebaseConstants.jobsCollection).doc(jobId).update({
        'views': FieldValue.increment(1),
      });
    } catch (e) {
      debugPrint('Failed to increment views: $e');
    }
  }

  // Clear Filters
  void clearFilters() {
    _filters = null;
    _searchQuery = null;
    _jobs.clear();
    _lastDocument = null;
    _hasMore = true;
    loadJobs();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
