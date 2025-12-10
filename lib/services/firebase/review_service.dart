import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/firebase_constants.dart';

class ReviewModel {
  final String reviewId;
  final String companyId;
  final String userId;
  final String userName;
  final String? userImage;
  final double rating;
  final String? title;
  final String content;
  final List<String>? pros;
  final List<String>? cons;
  final bool isAnonymous;
  final bool isVerified;
  final String? jobTitle;
  final String? employmentStatus; // current, former
  final int helpfulCount;
  final List<String> helpfulBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  ReviewModel({
    required this.reviewId,
    required this.companyId,
    required this.userId,
    required this.userName,
    this.userImage,
    required this.rating,
    this.title,
    required this.content,
    this.pros,
    this.cons,
    this.isAnonymous = false,
    this.isVerified = false,
    this.jobTitle,
    this.employmentStatus,
    this.helpfulCount = 0,
    this.helpfulBy = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'reviewId': reviewId,
      'companyId': companyId,
      'userId': userId,
      'userName': userName,
      'userImage': userImage,
      'rating': rating,
      'title': title,
      'content': content,
      'pros': pros,
      'cons': cons,
      'isAnonymous': isAnonymous,
      'isVerified': isVerified,
      'jobTitle': jobTitle,
      'employmentStatus': employmentStatus,
      'helpfulCount': helpfulCount,
      'helpfulBy': helpfulBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      reviewId: json['reviewId'] as String? ?? '',
      companyId: json['companyId'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      userName: json['userName'] as String? ?? '',
      userImage: json['userImage'] as String?,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      title: json['title'] as String?,
      content: json['content'] as String? ?? '',
      pros: (json['pros'] as List<dynamic>?)?.cast<String>(),
      cons: (json['cons'] as List<dynamic>?)?.cast<String>(),
      isAnonymous: json['isAnonymous'] as bool? ?? false,
      isVerified: json['isVerified'] as bool? ?? false,
      jobTitle: json['jobTitle'] as String?,
      employmentStatus: json['employmentStatus'] as String?,
      helpfulCount: json['helpfulCount'] as int? ?? 0,
      helpfulBy: (json['helpfulBy'] as List<dynamic>?)?.cast<String>() ?? [],
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? (json['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  ReviewModel copyWith({
    String? reviewId,
    String? companyId,
    String? userId,
    String? userName,
    String? userImage,
    double? rating,
    String? title,
    String? content,
    List<String>? pros,
    List<String>? cons,
    bool? isAnonymous,
    bool? isVerified,
    String? jobTitle,
    String? employmentStatus,
    int? helpfulCount,
    List<String>? helpfulBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ReviewModel(
      reviewId: reviewId ?? this.reviewId,
      companyId: companyId ?? this.companyId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userImage: userImage ?? this.userImage,
      rating: rating ?? this.rating,
      title: title ?? this.title,
      content: content ?? this.content,
      pros: pros ?? this.pros,
      cons: cons ?? this.cons,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      isVerified: isVerified ?? this.isVerified,
      jobTitle: jobTitle ?? this.jobTitle,
      employmentStatus: employmentStatus ?? this.employmentStatus,
      helpfulCount: helpfulCount ?? this.helpfulCount,
      helpfulBy: helpfulBy ?? this.helpfulBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get displayName => isAnonymous ? 'Anonymous' : userName;
}

class ReviewService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _reviews => _db.collection(FirebaseConstants.reviewsCollection);

  // Create Review
  Future<ReviewModel> createReview(ReviewModel review) async {
    final docRef = _reviews.doc();
    final now = DateTime.now();

    final newReview = review.copyWith(
      reviewId: docRef.id,
      createdAt: now,
      updatedAt: now,
    );

    await docRef.set(newReview.toJson());

    // Update company rating
    await _updateCompanyRating(review.companyId);

    return newReview;
  }

  // Update Review
  Future<void> updateReview(ReviewModel review) async {
    final updatedReview = review.copyWith(updatedAt: DateTime.now());
    await _reviews.doc(review.reviewId).update(updatedReview.toJson());

    // Update company rating
    await _updateCompanyRating(review.companyId);
  }

  // Delete Review
  Future<void> deleteReview(String reviewId, String companyId) async {
    await _reviews.doc(reviewId).delete();

    // Update company rating
    await _updateCompanyRating(companyId);
  }

  // Get Review by ID
  Future<ReviewModel?> getReview(String reviewId) async {
    final doc = await _reviews.doc(reviewId).get();
    if (!doc.exists) return null;
    return ReviewModel.fromJson(doc.data() as Map<String, dynamic>);
  }

  // Get Reviews for Company
  Future<List<ReviewModel>> getCompanyReviews(
    String companyId, {
    int limit = 20,
    DocumentSnapshot? startAfter,
    String sortBy = 'createdAt', // 'createdAt', 'rating', 'helpfulCount'
  }) async {
    Query query = _reviews
        .where('companyId', isEqualTo: companyId)
        .orderBy(sortBy, descending: true);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    query = query.limit(limit);

    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => ReviewModel.fromJson(doc.data() as Map<String, dynamic>))
        .toList();
  }

  // Stream Company Reviews
  Stream<List<ReviewModel>> streamCompanyReviews(String companyId) {
    return _reviews
        .where('companyId', isEqualTo: companyId)
        .orderBy(FirebaseConstants.fieldCreatedAt, descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ReviewModel.fromJson(doc.data() as Map<String, dynamic>))
            .toList());
  }

  // Get Reviews by User
  Future<List<ReviewModel>> getUserReviews(String userId, {int limit = 20}) async {
    final snapshot = await _reviews
        .where(FirebaseConstants.fieldUserId, isEqualTo: userId)
        .orderBy(FirebaseConstants.fieldCreatedAt, descending: true)
        .limit(limit)
        .get();

    return snapshot.docs
        .map((doc) => ReviewModel.fromJson(doc.data() as Map<String, dynamic>))
        .toList();
  }

  // Check if User has Reviewed Company
  Future<bool> hasUserReviewed(String companyId, String userId) async {
    final snapshot = await _reviews
        .where('companyId', isEqualTo: companyId)
        .where(FirebaseConstants.fieldUserId, isEqualTo: userId)
        .limit(1)
        .get();

    return snapshot.docs.isNotEmpty;
  }

  // Mark Review as Helpful
  Future<void> markHelpful(String reviewId, String userId) async {
    await _reviews.doc(reviewId).update({
      'helpfulCount': FieldValue.increment(1),
      'helpfulBy': FieldValue.arrayUnion([userId]),
    });
  }

  // Unmark Review as Helpful
  Future<void> unmarkHelpful(String reviewId, String userId) async {
    await _reviews.doc(reviewId).update({
      'helpfulCount': FieldValue.increment(-1),
      'helpfulBy': FieldValue.arrayRemove([userId]),
    });
  }

  // Get Company Rating Stats
  Future<Map<String, dynamic>> getCompanyRatingStats(String companyId) async {
    final snapshot = await _reviews
        .where('companyId', isEqualTo: companyId)
        .get();

    if (snapshot.docs.isEmpty) {
      return {
        'averageRating': 0.0,
        'totalReviews': 0,
        'ratingDistribution': {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
      };
    }

    double totalRating = 0;
    Map<int, int> distribution = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};

    for (var doc in snapshot.docs) {
      final rating = (doc.data() as Map<String, dynamic>)['rating'] as num? ?? 0;
      totalRating += rating.toDouble();

      final roundedRating = rating.round();
      if (roundedRating >= 1 && roundedRating <= 5) {
        distribution[roundedRating] = (distribution[roundedRating] ?? 0) + 1;
      }
    }

    return {
      'averageRating': totalRating / snapshot.docs.length,
      'totalReviews': snapshot.docs.length,
      'ratingDistribution': distribution,
    };
  }

  // Update Company Rating
  Future<void> _updateCompanyRating(String companyId) async {
    final stats = await getCompanyRatingStats(companyId);

    await _db.collection(FirebaseConstants.companiesCollection).doc(companyId).update({
      'rating': stats['averageRating'],
      'totalReviews': stats['totalReviews'],
      FirebaseConstants.fieldUpdatedAt: FieldValue.serverTimestamp(),
    });
  }

  // Get Top Reviews (most helpful)
  Future<List<ReviewModel>> getTopReviews(String companyId, {int limit = 5}) async {
    final snapshot = await _reviews
        .where('companyId', isEqualTo: companyId)
        .orderBy('helpfulCount', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs
        .map((doc) => ReviewModel.fromJson(doc.data() as Map<String, dynamic>))
        .toList();
  }

  // Get Recent Reviews Across All Companies
  Future<List<ReviewModel>> getRecentReviews({int limit = 20}) async {
    final snapshot = await _reviews
        .orderBy(FirebaseConstants.fieldCreatedAt, descending: true)
        .limit(limit)
        .get();

    return snapshot.docs
        .map((doc) => ReviewModel.fromJson(doc.data() as Map<String, dynamic>))
        .toList();
  }

  // Verify Review (Admin)
  Future<void> verifyReview(String reviewId) async {
    await _reviews.doc(reviewId).update({
      'isVerified': true,
      FirebaseConstants.fieldUpdatedAt: FieldValue.serverTimestamp(),
    });
  }

  // Report Review
  Future<void> reportReview(String reviewId, String reporterId, String reason) async {
    await _db.collection(FirebaseConstants.reportsCollection).add({
      'type': 'review',
      'targetId': reviewId,
      'reporterId': reporterId,
      'reason': reason,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Get Reviews by Rating
  Future<List<ReviewModel>> getReviewsByRating(
    String companyId,
    int rating, {
    int limit = 20,
  }) async {
    final snapshot = await _reviews
        .where('companyId', isEqualTo: companyId)
        .where('rating', isGreaterThanOrEqualTo: rating)
        .where('rating', isLessThan: rating + 1)
        .orderBy('rating')
        .orderBy(FirebaseConstants.fieldCreatedAt, descending: true)
        .limit(limit)
        .get();

    return snapshot.docs
        .map((doc) => ReviewModel.fromJson(doc.data() as Map<String, dynamic>))
        .toList();
  }
}
