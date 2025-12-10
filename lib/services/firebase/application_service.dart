import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/firebase_constants.dart';
import '../../models/application_model.dart';

class ApplicationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _applications =>
      _db.collection(FirebaseConstants.applicationsCollection);

  // Submit Application
  Future<ApplicationModel> submitApplication(ApplicationModel application) async {
    final docRef = _applications.doc();
    final now = DateTime.now();

    final newApplication = application.copyWith(
      applicationId: docRef.id,
      status: 'pending',
      appliedAt: now,
      updatedAt: now,
      statusHistory: [
        StatusHistory(
          status: 'pending',
          timestamp: now,
          note: 'Application submitted',
        ),
      ],
    );

    await docRef.set(newApplication.toJson());

    // Increment job application count
    await _db.collection(FirebaseConstants.jobsCollection)
        .doc(application.jobId)
        .update({
      FirebaseConstants.fieldApplications: FieldValue.increment(1),
    });

    return newApplication;
  }

  // Get Application by ID
  Future<ApplicationModel?> getApplication(String applicationId) async {
    final doc = await _applications.doc(applicationId).get();
    if (!doc.exists) return null;
    return ApplicationModel.fromJson(doc.data() as Map<String, dynamic>);
  }

  // Stream Application
  Stream<ApplicationModel?> streamApplication(String applicationId) {
    return _applications.doc(applicationId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return ApplicationModel.fromJson(doc.data() as Map<String, dynamic>);
    });
  }

  // Get Applications by Applicant (Job Seeker)
  Future<List<ApplicationModel>> getApplicationsByApplicant(
    String applicantId, {
    int limit = 50,
    String? status,
  }) async {
    Query query = _applications
        .where(FirebaseConstants.fieldApplicantId, isEqualTo: applicantId)
        .orderBy(FirebaseConstants.fieldAppliedAt, descending: true);

    if (status != null && status.isNotEmpty) {
      query = query.where(FirebaseConstants.fieldStatus, isEqualTo: status);
    }

    query = query.limit(limit);

    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => ApplicationModel.fromJson(doc.data() as Map<String, dynamic>))
        .toList();
  }

  // Stream Applications by Applicant
  Stream<List<ApplicationModel>> streamApplicationsByApplicant(String applicantId) {
    return _applications
        .where(FirebaseConstants.fieldApplicantId, isEqualTo: applicantId)
        .orderBy(FirebaseConstants.fieldAppliedAt, descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ApplicationModel.fromJson(doc.data() as Map<String, dynamic>))
            .toList());
  }

  // Get Applications for Job (Provider)
  Future<List<ApplicationModel>> getApplicationsForJob(
    String jobId, {
    int limit = 50,
    String? status,
  }) async {
    Query query = _applications
        .where(FirebaseConstants.fieldJobId, isEqualTo: jobId)
        .orderBy(FirebaseConstants.fieldAppliedAt, descending: true);

    if (status != null && status.isNotEmpty) {
      query = query.where(FirebaseConstants.fieldStatus, isEqualTo: status);
    }

    query = query.limit(limit);

    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => ApplicationModel.fromJson(doc.data() as Map<String, dynamic>))
        .toList();
  }

  // Stream Applications for Job
  Stream<List<ApplicationModel>> streamApplicationsForJob(String jobId) {
    return _applications
        .where(FirebaseConstants.fieldJobId, isEqualTo: jobId)
        .orderBy(FirebaseConstants.fieldAppliedAt, descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ApplicationModel.fromJson(doc.data() as Map<String, dynamic>))
            .toList());
  }

  // Get Applications by Provider
  Future<List<ApplicationModel>> getApplicationsByProvider(
    String providerId, {
    int limit = 50,
    String? status,
  }) async {
    Query query = _applications
        .where(FirebaseConstants.fieldProviderId, isEqualTo: providerId)
        .orderBy(FirebaseConstants.fieldAppliedAt, descending: true);

    if (status != null && status.isNotEmpty) {
      query = query.where(FirebaseConstants.fieldStatus, isEqualTo: status);
    }

    query = query.limit(limit);

    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => ApplicationModel.fromJson(doc.data() as Map<String, dynamic>))
        .toList();
  }

  // Stream Applications by Provider
  Stream<List<ApplicationModel>> streamApplicationsByProvider(String providerId) {
    return _applications
        .where(FirebaseConstants.fieldProviderId, isEqualTo: providerId)
        .orderBy(FirebaseConstants.fieldAppliedAt, descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ApplicationModel.fromJson(doc.data() as Map<String, dynamic>))
            .toList());
  }

  // Update Application Status
  Future<void> updateApplicationStatus(
    String applicationId,
    String newStatus, {
    String? note,
    String? updatedBy,
  }) async {
    final doc = await _applications.doc(applicationId).get();
    if (!doc.exists) return;

    final application = ApplicationModel.fromJson(doc.data() as Map<String, dynamic>);
    final now = DateTime.now();

    final updatedHistory = [
      ...application.statusHistory,
      StatusHistory(
        status: newStatus,
        timestamp: now,
        note: note,
        updatedBy: updatedBy,
      ),
    ];

    await _applications.doc(applicationId).update({
      FirebaseConstants.fieldStatus: newStatus,
      'statusHistory': updatedHistory.map((h) => h.toJson()).toList(),
      FirebaseConstants.fieldUpdatedAt: Timestamp.fromDate(now),
    });
  }

  // Shortlist Application
  Future<void> shortlistApplication(String applicationId, {String? note}) async {
    await updateApplicationStatus(applicationId, 'shortlisted', note: note);
  }

  // Reject Application
  Future<void> rejectApplication(String applicationId, {String? note}) async {
    await updateApplicationStatus(applicationId, 'rejected', note: note);
  }

  // Schedule Interview
  Future<void> scheduleInterview(
    String applicationId,
    InterviewDetails interview,
  ) async {
    final now = DateTime.now();

    final doc = await _applications.doc(applicationId).get();
    if (!doc.exists) return;

    final application = ApplicationModel.fromJson(doc.data() as Map<String, dynamic>);

    final updatedHistory = [
      ...application.statusHistory,
      StatusHistory(
        status: 'interview',
        timestamp: now,
        note: 'Interview scheduled for ${interview.scheduledAt}',
      ),
    ];

    await _applications.doc(applicationId).update({
      FirebaseConstants.fieldStatus: 'interview',
      'interview': interview.toJson(),
      'statusHistory': updatedHistory.map((h) => h.toJson()).toList(),
      FirebaseConstants.fieldUpdatedAt: Timestamp.fromDate(now),
    });
  }

  // Update Interview Details
  Future<void> updateInterview(
    String applicationId,
    InterviewDetails interview,
  ) async {
    await _applications.doc(applicationId).update({
      'interview': interview.toJson(),
      FirebaseConstants.fieldUpdatedAt: FieldValue.serverTimestamp(),
    });
  }

  // Cancel Interview
  Future<void> cancelInterview(String applicationId, {String? note}) async {
    final now = DateTime.now();

    final doc = await _applications.doc(applicationId).get();
    if (!doc.exists) return;

    final application = ApplicationModel.fromJson(doc.data() as Map<String, dynamic>);

    final updatedHistory = [
      ...application.statusHistory,
      StatusHistory(
        status: 'shortlisted',
        timestamp: now,
        note: note ?? 'Interview cancelled',
      ),
    ];

    await _applications.doc(applicationId).update({
      FirebaseConstants.fieldStatus: 'shortlisted',
      'interview': null,
      'statusHistory': updatedHistory.map((h) => h.toJson()).toList(),
      FirebaseConstants.fieldUpdatedAt: Timestamp.fromDate(now),
    });
  }

  // Make Offer
  Future<void> makeOffer(String applicationId, {String? note}) async {
    await updateApplicationStatus(applicationId, 'offered', note: note);
  }

  // Withdraw Application (by applicant)
  Future<void> withdrawApplication(String applicationId) async {
    final doc = await _applications.doc(applicationId).get();
    if (!doc.exists) return;

    final application = ApplicationModel.fromJson(doc.data() as Map<String, dynamic>);

    await updateApplicationStatus(applicationId, 'withdrawn', note: 'Withdrawn by applicant');

    // Decrement job application count
    await _db.collection(FirebaseConstants.jobsCollection)
        .doc(application.jobId)
        .update({
      FirebaseConstants.fieldApplications: FieldValue.increment(-1),
    });
  }

  // Accept Offer
  Future<void> acceptOffer(String applicationId) async {
    await updateApplicationStatus(applicationId, 'accepted', note: 'Offer accepted');
  }

  // Add Provider Notes
  Future<void> addProviderNotes(String applicationId, String notes) async {
    await _applications.doc(applicationId).update({
      'providerNotes': notes,
      FirebaseConstants.fieldUpdatedAt: FieldValue.serverTimestamp(),
    });
  }

  // Rate Applicant
  Future<void> rateApplicant(String applicationId, int rating) async {
    if (rating < 1 || rating > 5) return;

    await _applications.doc(applicationId).update({
      'rating': rating,
      FirebaseConstants.fieldUpdatedAt: FieldValue.serverTimestamp(),
    });
  }

  // Check if Already Applied
  Future<bool> hasApplied(String jobId, String applicantId) async {
    final snapshot = await _applications
        .where(FirebaseConstants.fieldJobId, isEqualTo: jobId)
        .where(FirebaseConstants.fieldApplicantId, isEqualTo: applicantId)
        .limit(1)
        .get();

    return snapshot.docs.isNotEmpty;
  }

  // Get Application Count for Job
  Future<int> getApplicationCount(String jobId) async {
    final snapshot = await _applications
        .where(FirebaseConstants.fieldJobId, isEqualTo: jobId)
        .count()
        .get();

    return snapshot.count ?? 0;
  }

  // Get Application Stats for Provider
  Future<Map<String, int>> getProviderApplicationStats(String providerId) async {
    final snapshot = await _applications
        .where(FirebaseConstants.fieldProviderId, isEqualTo: providerId)
        .get();

    int pending = 0;
    int reviewed = 0;
    int shortlisted = 0;
    int interview = 0;
    int offered = 0;
    int accepted = 0;
    int rejected = 0;

    for (var doc in snapshot.docs) {
      final status = (doc.data() as Map<String, dynamic>)[FirebaseConstants.fieldStatus] as String?;

      switch (status) {
        case 'pending':
          pending++;
          break;
        case 'reviewed':
          reviewed++;
          break;
        case 'shortlisted':
          shortlisted++;
          break;
        case 'interview':
          interview++;
          break;
        case 'offered':
          offered++;
          break;
        case 'accepted':
          accepted++;
          break;
        case 'rejected':
          rejected++;
          break;
      }
    }

    return {
      'total': snapshot.docs.length,
      'pending': pending,
      'reviewed': reviewed,
      'shortlisted': shortlisted,
      'interview': interview,
      'offered': offered,
      'accepted': accepted,
      'rejected': rejected,
    };
  }

  // Get Upcoming Interviews
  Future<List<ApplicationModel>> getUpcomingInterviews(String providerId) async {
    final now = DateTime.now();

    final snapshot = await _applications
        .where(FirebaseConstants.fieldProviderId, isEqualTo: providerId)
        .where(FirebaseConstants.fieldStatus, isEqualTo: 'interview')
        .get();

    final applications = snapshot.docs
        .map((doc) => ApplicationModel.fromJson(doc.data() as Map<String, dynamic>))
        .where((app) => app.interview?.scheduledAt?.isAfter(now) ?? false)
        .toList();

    applications.sort((a, b) =>
        (a.interview?.scheduledAt ?? now).compareTo(b.interview?.scheduledAt ?? now));

    return applications;
  }

  // Get Applicant's Upcoming Interviews
  Future<List<ApplicationModel>> getApplicantUpcomingInterviews(String applicantId) async {
    final now = DateTime.now();

    final snapshot = await _applications
        .where(FirebaseConstants.fieldApplicantId, isEqualTo: applicantId)
        .where(FirebaseConstants.fieldStatus, isEqualTo: 'interview')
        .get();

    final applications = snapshot.docs
        .map((doc) => ApplicationModel.fromJson(doc.data() as Map<String, dynamic>))
        .where((app) => app.interview?.scheduledAt?.isAfter(now) ?? false)
        .toList();

    applications.sort((a, b) =>
        (a.interview?.scheduledAt ?? now).compareTo(b.interview?.scheduledAt ?? now));

    return applications;
  }

  // Delete Application
  Future<void> deleteApplication(String applicationId) async {
    final doc = await _applications.doc(applicationId).get();
    if (!doc.exists) return;

    final application = ApplicationModel.fromJson(doc.data() as Map<String, dynamic>);

    await _applications.doc(applicationId).delete();

    // Decrement job application count
    await _db.collection(FirebaseConstants.jobsCollection)
        .doc(application.jobId)
        .update({
      FirebaseConstants.fieldApplications: FieldValue.increment(-1),
    });
  }

  // Batch Update Application Status
  Future<void> batchUpdateStatus(List<String> applicationIds, String status) async {
    final batch = _db.batch();
    final now = DateTime.now();

    for (final id in applicationIds) {
      batch.update(_applications.doc(id), {
        FirebaseConstants.fieldStatus: status,
        FirebaseConstants.fieldUpdatedAt: Timestamp.fromDate(now),
      });
    }

    await batch.commit();
  }

  // Mark Application as Reviewed
  Future<void> markAsReviewed(String applicationId) async {
    final doc = await _applications.doc(applicationId).get();
    if (!doc.exists) return;

    final application = ApplicationModel.fromJson(doc.data() as Map<String, dynamic>);

    if (application.status == 'pending') {
      await updateApplicationStatus(applicationId, 'reviewed');
    }
  }
}
