import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/firebase_constants.dart';
import '../../models/job_model.dart';

class JobService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _jobs => _db.collection(FirebaseConstants.jobsCollection);

  // Create Job
  Future<JobModel> createJob(JobModel job) async {
    final docRef = _jobs.doc();
    final newJob = job.copyWith(
      jobId: docRef.id,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await docRef.set(newJob.toJson());
    return newJob;
  }

  // Update Job
  Future<void> updateJob(JobModel job) async {
    final updatedJob = job.copyWith(updatedAt: DateTime.now());
    await _jobs.doc(job.jobId).update(updatedJob.toJson());
  }

  // Delete Job
  Future<void> deleteJob(String jobId) async {
    await _jobs.doc(jobId).delete();
  }

  // Get Job by ID
  Future<JobModel?> getJob(String jobId) async {
    final doc = await _jobs.doc(jobId).get();
    if (!doc.exists) return null;
    return JobModel.fromJson(doc.data() as Map<String, dynamic>);
  }

  // Stream Job
  Stream<JobModel?> streamJob(String jobId) {
    return _jobs.doc(jobId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return JobModel.fromJson(doc.data() as Map<String, dynamic>);
    });
  }

  // Get Jobs by Provider
  Future<List<JobModel>> getJobsByProvider(String providerId, {int limit = 20}) async {
    final query = await _jobs
        .where(FirebaseConstants.fieldProviderId, isEqualTo: providerId)
        .orderBy(FirebaseConstants.fieldCreatedAt, descending: true)
        .limit(limit)
        .get();

    return query.docs
        .map((doc) => JobModel.fromJson(doc.data() as Map<String, dynamic>))
        .toList();
  }

  // Stream Jobs by Provider
  Stream<List<JobModel>> streamJobsByProvider(String providerId) {
    return _jobs
        .where(FirebaseConstants.fieldProviderId, isEqualTo: providerId)
        .orderBy(FirebaseConstants.fieldCreatedAt, descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => JobModel.fromJson(doc.data() as Map<String, dynamic>))
            .toList());
  }

  // Get Active Jobs (for job seekers)
  Future<List<JobModel>> getActiveJobs({
    int limit = 20,
    DocumentSnapshot? startAfter,
    String? category,
    String? workLocation,
    String? experienceLevel,
    String? employmentType,
    double? minSalary,
    double? maxSalary,
  }) async {
    Query query = _jobs
        .where(FirebaseConstants.fieldStatus, isEqualTo: 'active')
        .orderBy(FirebaseConstants.fieldCreatedAt, descending: true);

    if (category != null && category.isNotEmpty) {
      query = query.where(FirebaseConstants.fieldCategory, isEqualTo: category);
    }

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    query = query.limit(limit);

    final snapshot = await query.get();
    List<JobModel> jobs = snapshot.docs
        .map((doc) => JobModel.fromJson(doc.data() as Map<String, dynamic>))
        .toList();

    // Client-side filtering for complex conditions
    if (workLocation != null && workLocation.isNotEmpty) {
      jobs = jobs.where((job) => job.workLocation == workLocation).toList();
    }
    if (experienceLevel != null && experienceLevel.isNotEmpty) {
      jobs = jobs.where((job) => job.experienceLevel == experienceLevel).toList();
    }
    if (employmentType != null && employmentType.isNotEmpty) {
      jobs = jobs.where((job) => job.employmentType == employmentType).toList();
    }
    if (minSalary != null) {
      jobs = jobs.where((job) => (job.salaryMin ?? 0) >= minSalary).toList();
    }
    if (maxSalary != null) {
      jobs = jobs.where((job) => (job.salaryMax ?? double.infinity) <= maxSalary).toList();
    }

    return jobs;
  }

  // Stream Active Jobs
  Stream<List<JobModel>> streamActiveJobs({int limit = 50}) {
    return _jobs
        .where(FirebaseConstants.fieldStatus, isEqualTo: 'active')
        .orderBy(FirebaseConstants.fieldCreatedAt, descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => JobModel.fromJson(doc.data() as Map<String, dynamic>))
            .toList());
  }

  // Search Jobs
  Future<List<JobModel>> searchJobs(String query, {int limit = 20}) async {
    final queryLower = query.toLowerCase();

    // Get all active jobs and filter client-side for comprehensive search
    final snapshot = await _jobs
        .where(FirebaseConstants.fieldStatus, isEqualTo: 'active')
        .orderBy(FirebaseConstants.fieldCreatedAt, descending: true)
        .limit(100)
        .get();

    final jobs = snapshot.docs
        .map((doc) => JobModel.fromJson(doc.data() as Map<String, dynamic>))
        .where((job) =>
            job.title.toLowerCase().contains(queryLower) ||
            job.description.toLowerCase().contains(queryLower) ||
            job.companyName.toLowerCase().contains(queryLower) ||
            job.category.toLowerCase().contains(queryLower) ||
            job.skills.any((skill) => skill.toLowerCase().contains(queryLower)))
        .take(limit)
        .toList();

    return jobs;
  }

  // Get Featured Jobs
  Future<List<JobModel>> getFeaturedJobs({int limit = 10}) async {
    final snapshot = await _jobs
        .where(FirebaseConstants.fieldStatus, isEqualTo: 'active')
        .where('isFeatured', isEqualTo: true)
        .orderBy(FirebaseConstants.fieldCreatedAt, descending: true)
        .limit(limit)
        .get();

    return snapshot.docs
        .map((doc) => JobModel.fromJson(doc.data() as Map<String, dynamic>))
        .toList();
  }

  // Get Urgent Jobs
  Future<List<JobModel>> getUrgentJobs({int limit = 10}) async {
    final snapshot = await _jobs
        .where(FirebaseConstants.fieldStatus, isEqualTo: 'active')
        .where('isUrgent', isEqualTo: true)
        .orderBy(FirebaseConstants.fieldCreatedAt, descending: true)
        .limit(limit)
        .get();

    return snapshot.docs
        .map((doc) => JobModel.fromJson(doc.data() as Map<String, dynamic>))
        .toList();
  }

  // Get Jobs by Category
  Future<List<JobModel>> getJobsByCategory(String category, {int limit = 20}) async {
    final snapshot = await _jobs
        .where(FirebaseConstants.fieldStatus, isEqualTo: 'active')
        .where(FirebaseConstants.fieldCategory, isEqualTo: category)
        .orderBy(FirebaseConstants.fieldCreatedAt, descending: true)
        .limit(limit)
        .get();

    return snapshot.docs
        .map((doc) => JobModel.fromJson(doc.data() as Map<String, dynamic>))
        .toList();
  }

  // Get Jobs by Company
  Future<List<JobModel>> getJobsByCompany(String companyId, {int limit = 20}) async {
    final snapshot = await _jobs
        .where(FirebaseConstants.fieldCompanyId, isEqualTo: companyId)
        .where(FirebaseConstants.fieldStatus, isEqualTo: 'active')
        .orderBy(FirebaseConstants.fieldCreatedAt, descending: true)
        .limit(limit)
        .get();

    return snapshot.docs
        .map((doc) => JobModel.fromJson(doc.data() as Map<String, dynamic>))
        .toList();
  }

  // Publish Job (change status from draft to active)
  Future<void> publishJob(String jobId) async {
    await _jobs.doc(jobId).update({
      FirebaseConstants.fieldStatus: 'active',
      'publishedAt': FieldValue.serverTimestamp(),
      FirebaseConstants.fieldUpdatedAt: FieldValue.serverTimestamp(),
    });
  }

  // Close Job
  Future<void> closeJob(String jobId) async {
    await _jobs.doc(jobId).update({
      FirebaseConstants.fieldStatus: 'closed',
      FirebaseConstants.fieldUpdatedAt: FieldValue.serverTimestamp(),
    });
  }

  // Reopen Job
  Future<void> reopenJob(String jobId) async {
    await _jobs.doc(jobId).update({
      FirebaseConstants.fieldStatus: 'active',
      FirebaseConstants.fieldUpdatedAt: FieldValue.serverTimestamp(),
    });
  }

  // Increment View Count
  Future<void> incrementViews(String jobId) async {
    await _jobs.doc(jobId).update({
      FirebaseConstants.fieldViews: FieldValue.increment(1),
    });
  }

  // Increment Application Count
  Future<void> incrementApplications(String jobId) async {
    await _jobs.doc(jobId).update({
      FirebaseConstants.fieldApplications: FieldValue.increment(1),
    });
  }

  // Decrement Application Count
  Future<void> decrementApplications(String jobId) async {
    await _jobs.doc(jobId).update({
      FirebaseConstants.fieldApplications: FieldValue.increment(-1),
    });
  }

  // Increment Save Count
  Future<void> incrementSaves(String jobId) async {
    await _jobs.doc(jobId).update({
      FirebaseConstants.fieldSaves: FieldValue.increment(1),
    });
  }

  // Decrement Save Count
  Future<void> decrementSaves(String jobId) async {
    await _jobs.doc(jobId).update({
      FirebaseConstants.fieldSaves: FieldValue.increment(-1),
    });
  }

  // Get All Jobs (for admin)
  Future<List<JobModel>> getAllJobs({
    int limit = 50,
    String? status,
    DocumentSnapshot? startAfter,
  }) async {
    Query query = _jobs.orderBy(FirebaseConstants.fieldCreatedAt, descending: true);

    if (status != null && status.isNotEmpty) {
      query = query.where(FirebaseConstants.fieldStatus, isEqualTo: status);
    }

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    query = query.limit(limit);

    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => JobModel.fromJson(doc.data() as Map<String, dynamic>))
        .toList();
  }

  // Stream All Jobs (for admin)
  Stream<List<JobModel>> streamAllJobs({int limit = 100}) {
    return _jobs
        .orderBy(FirebaseConstants.fieldCreatedAt, descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => JobModel.fromJson(doc.data() as Map<String, dynamic>))
            .toList());
  }

  // Get Job Categories (distinct)
  Future<List<String>> getJobCategories() async {
    final snapshot = await _jobs
        .where(FirebaseConstants.fieldStatus, isEqualTo: 'active')
        .get();

    final categories = snapshot.docs
        .map((doc) => (doc.data() as Map<String, dynamic>)[FirebaseConstants.fieldCategory] as String?)
        .where((category) => category != null && category.isNotEmpty)
        .cast<String>()
        .toSet()
        .toList();

    categories.sort();
    return categories;
  }

  // Get Job Stats for Provider
  Future<Map<String, int>> getProviderJobStats(String providerId) async {
    final snapshot = await _jobs
        .where(FirebaseConstants.fieldProviderId, isEqualTo: providerId)
        .get();

    int active = 0;
    int draft = 0;
    int closed = 0;
    int totalViews = 0;
    int totalApplications = 0;

    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final status = data[FirebaseConstants.fieldStatus] as String?;

      if (status == 'active') active++;
      if (status == 'draft') draft++;
      if (status == 'closed') closed++;

      totalViews += (data[FirebaseConstants.fieldViews] as int?) ?? 0;
      totalApplications += (data[FirebaseConstants.fieldApplications] as int?) ?? 0;
    }

    return {
      'total': snapshot.docs.length,
      'active': active,
      'draft': draft,
      'closed': closed,
      'totalViews': totalViews,
      'totalApplications': totalApplications,
    };
  }

  // Batch Update Job Status
  Future<void> batchUpdateJobStatus(List<String> jobIds, String status) async {
    final batch = _db.batch();

    for (final jobId in jobIds) {
      batch.update(_jobs.doc(jobId), {
        FirebaseConstants.fieldStatus: status,
        FirebaseConstants.fieldUpdatedAt: FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  // Get Similar Jobs
  Future<List<JobModel>> getSimilarJobs(JobModel job, {int limit = 5}) async {
    final snapshot = await _jobs
        .where(FirebaseConstants.fieldStatus, isEqualTo: 'active')
        .where(FirebaseConstants.fieldCategory, isEqualTo: job.category)
        .limit(limit + 1)
        .get();

    return snapshot.docs
        .map((doc) => JobModel.fromJson(doc.data() as Map<String, dynamic>))
        .where((j) => j.jobId != job.jobId)
        .take(limit)
        .toList();
  }

  // Check if Job Exists
  Future<bool> jobExists(String jobId) async {
    final doc = await _jobs.doc(jobId).get();
    return doc.exists;
  }
}
