import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/firebase_constants.dart';
import '../../models/company_model.dart';

class CompanyService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _companies =>
      _db.collection(FirebaseConstants.companiesCollection);

  // Create Company
  Future<CompanyModel> createCompany(CompanyModel company) async {
    final docRef = _companies.doc();
    final now = DateTime.now();

    final newCompany = company.copyWith(
      companyId: docRef.id,
      createdAt: now,
      updatedAt: now,
    );

    await docRef.set(newCompany.toJson());

    // Update user with company ID
    await _db.collection(FirebaseConstants.usersCollection)
        .doc(company.ownerId)
        .update({
      'companyId': docRef.id,
    });

    return newCompany;
  }

  // Update Company
  Future<void> updateCompany(CompanyModel company) async {
    final updatedCompany = company.copyWith(updatedAt: DateTime.now());
    await _companies.doc(company.companyId).update(updatedCompany.toJson());
  }

  // Delete Company
  Future<void> deleteCompany(String companyId) async {
    await _companies.doc(companyId).delete();
  }

  // Get Company by ID
  Future<CompanyModel?> getCompany(String companyId) async {
    final doc = await _companies.doc(companyId).get();
    if (!doc.exists) return null;
    return CompanyModel.fromJson(doc.data() as Map<String, dynamic>);
  }

  // Stream Company
  Stream<CompanyModel?> streamCompany(String companyId) {
    return _companies.doc(companyId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return CompanyModel.fromJson(doc.data() as Map<String, dynamic>);
    });
  }

  // Get Company by Owner
  Future<CompanyModel?> getCompanyByOwner(String ownerId) async {
    final snapshot = await _companies
        .where('ownerId', isEqualTo: ownerId)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return CompanyModel.fromJson(snapshot.docs.first.data() as Map<String, dynamic>);
  }

  // Alias for getCompanyByOwner
  Future<CompanyModel?> getCompanyByUserId(String userId) => getCompanyByOwner(userId);

  // Stream Company by Owner
  Stream<CompanyModel?> streamCompanyByOwner(String ownerId) {
    return _companies
        .where('ownerId', isEqualTo: ownerId)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      return CompanyModel.fromJson(snapshot.docs.first.data() as Map<String, dynamic>);
    });
  }

  // Search Companies
  Future<List<CompanyModel>> searchCompanies(String query, {int limit = 20}) async {
    final queryLower = query.toLowerCase();

    final snapshot = await _companies.limit(100).get();

    return snapshot.docs
        .map((doc) => CompanyModel.fromJson(doc.data() as Map<String, dynamic>))
        .where((company) =>
            company.name.toLowerCase().contains(queryLower) ||
            company.industry.toLowerCase().contains(queryLower) ||
            company.description.toLowerCase().contains(queryLower))
        .take(limit)
        .toList();
  }

  // Get Verified Companies
  Future<List<CompanyModel>> getVerifiedCompanies({int limit = 50}) async {
    final snapshot = await _companies
        .where(FirebaseConstants.fieldIsVerified, isEqualTo: true)
        .orderBy(FirebaseConstants.fieldCreatedAt, descending: true)
        .limit(limit)
        .get();

    return snapshot.docs
        .map((doc) => CompanyModel.fromJson(doc.data() as Map<String, dynamic>))
        .toList();
  }

  // Get Companies by Industry
  Future<List<CompanyModel>> getCompaniesByIndustry(
    String industry, {
    int limit = 20,
  }) async {
    final snapshot = await _companies
        .where('industry', isEqualTo: industry)
        .orderBy(FirebaseConstants.fieldCreatedAt, descending: true)
        .limit(limit)
        .get();

    return snapshot.docs
        .map((doc) => CompanyModel.fromJson(doc.data() as Map<String, dynamic>))
        .toList();
  }

  // Get Top Rated Companies
  Future<List<CompanyModel>> getTopRatedCompanies({int limit = 10}) async {
    final snapshot = await _companies
        .where('rating', isGreaterThan: 0)
        .orderBy('rating', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs
        .map((doc) => CompanyModel.fromJson(doc.data() as Map<String, dynamic>))
        .toList();
  }

  // Verify Company (Admin)
  Future<void> verifyCompany(String companyId) async {
    await _companies.doc(companyId).update({
      FirebaseConstants.fieldIsVerified: true,
      FirebaseConstants.fieldUpdatedAt: FieldValue.serverTimestamp(),
    });
  }

  // Unverify Company (Admin)
  Future<void> unverifyCompany(String companyId) async {
    await _companies.doc(companyId).update({
      FirebaseConstants.fieldIsVerified: false,
      FirebaseConstants.fieldUpdatedAt: FieldValue.serverTimestamp(),
    });
  }

  // Update Company Logo
  Future<void> updateLogo(String companyId, String logoUrl) async {
    await _companies.doc(companyId).update({
      'logo': logoUrl,
      FirebaseConstants.fieldUpdatedAt: FieldValue.serverTimestamp(),
    });
  }

  // Add Team Member
  Future<void> addTeamMember(String companyId, String userId) async {
    await _companies.doc(companyId).update({
      'teamMembers': FieldValue.arrayUnion([userId]),
      FirebaseConstants.fieldUpdatedAt: FieldValue.serverTimestamp(),
    });
  }

  // Remove Team Member
  Future<void> removeTeamMember(String companyId, String userId) async {
    await _companies.doc(companyId).update({
      'teamMembers': FieldValue.arrayRemove([userId]),
      FirebaseConstants.fieldUpdatedAt: FieldValue.serverTimestamp(),
    });
  }

  // Increment Active Jobs
  Future<void> incrementActiveJobs(String companyId) async {
    await _companies.doc(companyId).update({
      'activeJobs': FieldValue.increment(1),
    });
  }

  // Decrement Active Jobs
  Future<void> decrementActiveJobs(String companyId) async {
    await _companies.doc(companyId).update({
      'activeJobs': FieldValue.increment(-1),
    });
  }

  // Increment Total Hires
  Future<void> incrementTotalHires(String companyId) async {
    await _companies.doc(companyId).update({
      'totalHires': FieldValue.increment(1),
    });
  }

  // Update Rating
  Future<void> updateRating(String companyId, double newRating, int totalReviews) async {
    await _companies.doc(companyId).update({
      'rating': newRating,
      'totalReviews': totalReviews,
      FirebaseConstants.fieldUpdatedAt: FieldValue.serverTimestamp(),
    });
  }

  // Add Review and Update Rating
  Future<void> addReviewAndUpdateRating(
    String companyId,
    double reviewRating,
  ) async {
    final doc = await _companies.doc(companyId).get();
    if (!doc.exists) return;

    final company = CompanyModel.fromJson(doc.data() as Map<String, dynamic>);

    final newTotalReviews = company.totalReviews + 1;
    final newRating = ((company.rating * company.totalReviews) + reviewRating) / newTotalReviews;

    await updateRating(companyId, newRating, newTotalReviews);
  }

  // Get All Companies (Admin)
  Future<List<CompanyModel>> getAllCompanies({
    int limit = 50,
    bool? isVerified,
    DocumentSnapshot? startAfter,
  }) async {
    Query query = _companies.orderBy(FirebaseConstants.fieldCreatedAt, descending: true);

    if (isVerified != null) {
      query = query.where(FirebaseConstants.fieldIsVerified, isEqualTo: isVerified);
    }

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    query = query.limit(limit);

    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => CompanyModel.fromJson(doc.data() as Map<String, dynamic>))
        .toList();
  }

  // Stream All Companies (Admin)
  Stream<List<CompanyModel>> streamAllCompanies({int limit = 100}) {
    return _companies
        .orderBy(FirebaseConstants.fieldCreatedAt, descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CompanyModel.fromJson(doc.data() as Map<String, dynamic>))
            .toList());
  }

  // Get Company Stats
  Future<Map<String, dynamic>> getCompanyStats(String companyId) async {
    final company = await getCompany(companyId);
    if (company == null) return {};

    // Get job stats
    final jobsSnapshot = await _db.collection(FirebaseConstants.jobsCollection)
        .where(FirebaseConstants.fieldCompanyId, isEqualTo: companyId)
        .get();

    int activeJobs = 0;
    int totalViews = 0;
    int totalApplications = 0;

    for (var doc in jobsSnapshot.docs) {
      final data = doc.data();
      if (data[FirebaseConstants.fieldStatus] == 'active') activeJobs++;
      totalViews += (data[FirebaseConstants.fieldViews] as int?) ?? 0;
      totalApplications += (data[FirebaseConstants.fieldApplications] as int?) ?? 0;
    }

    return {
      'activeJobs': activeJobs,
      'totalJobs': jobsSnapshot.docs.length,
      'totalViews': totalViews,
      'totalApplications': totalApplications,
      'totalHires': company.totalHires,
      'rating': company.rating,
      'totalReviews': company.totalReviews,
    };
  }

  // Check if Company Name Exists
  Future<bool> companyNameExists(String name, {String? excludeId}) async {
    final snapshot = await _companies
        .where('name', isEqualTo: name)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return false;
    if (excludeId != null && snapshot.docs.first.id == excludeId) return false;
    return true;
  }

  // Get Industries List
  Future<List<String>> getIndustries() async {
    final snapshot = await _companies.get();

    final industries = snapshot.docs
        .map((doc) => (doc.data() as Map<String, dynamic>)['industry'] as String?)
        .where((industry) => industry != null && industry.isNotEmpty)
        .cast<String>()
        .toSet()
        .toList();

    industries.sort();
    return industries;
  }
}
