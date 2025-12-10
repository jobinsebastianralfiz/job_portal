import 'package:cloud_firestore/cloud_firestore.dart';

/// Subscription plan types
enum SubscriptionTier {
  free,
  basic,
  pro,
  enterprise,
}

/// Subscription plan details
class SubscriptionPlan {
  final SubscriptionTier tier;
  final String name;
  final String description;
  final int priceMonthly; // in smallest currency unit (paise for INR)
  final int priceYearly;
  final int jobPostsPerMonth;
  final bool hasAIFeatures;
  final bool hasPriorityListing;
  final bool hasFeaturedListing;
  final bool hasAnalytics;
  final bool hasBulkPosting;
  final bool hasDedicatedSupport;
  final bool hasEmailSupport;
  final List<String> features;

  const SubscriptionPlan({
    required this.tier,
    required this.name,
    required this.description,
    required this.priceMonthly,
    required this.priceYearly,
    required this.jobPostsPerMonth,
    this.hasAIFeatures = false,
    this.hasPriorityListing = false,
    this.hasFeaturedListing = false,
    this.hasAnalytics = false,
    this.hasBulkPosting = false,
    this.hasDedicatedSupport = false,
    this.hasEmailSupport = false,
    this.features = const [],
  });

  /// Check if this plan includes a specific feature
  bool hasFeature(String feature) => features.contains(feature);

  /// Get price display string
  String get monthlyPriceDisplay => priceMonthly == 0 ? 'Free' : '₹${priceMonthly ~/ 100}/month';
  String get yearlyPriceDisplay => priceYearly == 0 ? 'Free' : '₹${priceYearly ~/ 100}/year';

  /// Get jobs limit display
  String get jobsLimitDisplay => jobPostsPerMonth == -1 ? 'Unlimited' : '$jobPostsPerMonth jobs/month';
}

/// Available subscription plans
class SubscriptionPlans {
  static const free = SubscriptionPlan(
    tier: SubscriptionTier.free,
    name: 'Free',
    description: 'Get started with basic job posting',
    priceMonthly: 0,
    priceYearly: 0,
    jobPostsPerMonth: 1,
    hasEmailSupport: false,
    features: [
      '1 job post per month',
      'Basic job listing',
      'Standard visibility',
      'Community support',
    ],
  );

  static const basic = SubscriptionPlan(
    tier: SubscriptionTier.basic,
    name: 'Basic',
    description: 'Perfect for small businesses',
    priceMonthly: 99900, // ₹999
    priceYearly: 999900, // ₹9,999 (2 months free)
    jobPostsPerMonth: 5,
    hasPriorityListing: true,
    hasEmailSupport: true,
    features: [
      '5 job posts per month',
      'Priority listing',
      'Email support',
      'Basic analytics',
      'Job post templates',
    ],
  );

  static const pro = SubscriptionPlan(
    tier: SubscriptionTier.pro,
    name: 'Pro',
    description: 'Best for growing companies',
    priceMonthly: 249900, // ₹2,499
    priceYearly: 2499900, // ₹24,999 (2 months free)
    jobPostsPerMonth: 20,
    hasAIFeatures: true,
    hasPriorityListing: true,
    hasFeaturedListing: true,
    hasAnalytics: true,
    hasEmailSupport: true,
    features: [
      '20 job posts per month',
      'All AI features',
      'Featured job listings',
      'Advanced analytics',
      'Priority support',
      'Candidate recommendations',
      'Custom branding',
    ],
  );

  static const enterprise = SubscriptionPlan(
    tier: SubscriptionTier.enterprise,
    name: 'Enterprise',
    description: 'For large organizations',
    priceMonthly: 499900, // ₹4,999
    priceYearly: 4999900, // ₹49,999 (2 months free)
    jobPostsPerMonth: -1, // Unlimited
    hasAIFeatures: true,
    hasPriorityListing: true,
    hasFeaturedListing: true,
    hasAnalytics: true,
    hasBulkPosting: true,
    hasDedicatedSupport: true,
    hasEmailSupport: true,
    features: [
      'Unlimited job posts',
      'All AI features',
      'Featured & promoted listings',
      'Advanced analytics & reports',
      'Dedicated account manager',
      'Bulk job posting',
      'API access',
      'Custom integrations',
      'White-label options',
    ],
  );

  static const List<SubscriptionPlan> allPlans = [free, basic, pro, enterprise];

  static SubscriptionPlan getPlan(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.free:
        return free;
      case SubscriptionTier.basic:
        return basic;
      case SubscriptionTier.pro:
        return pro;
      case SubscriptionTier.enterprise:
        return enterprise;
    }
  }

  static SubscriptionPlan? getPlanByName(String name) {
    return allPlans.where((p) => p.name.toLowerCase() == name.toLowerCase()).firstOrNull;
  }
}

/// User's subscription status
class UserSubscription {
  final String subscriptionId;
  final String userId;
  final SubscriptionTier tier;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final bool isYearly;
  final String? paymentId;
  final String? razorpayOrderId;
  final String? razorpaySubscriptionId;
  final int amountPaid;
  final DateTime createdAt;
  final DateTime? cancelledAt;
  final String? cancellationReason;

  UserSubscription({
    this.subscriptionId = '',
    required this.userId,
    required this.tier,
    required this.startDate,
    required this.endDate,
    required this.isActive,
    this.isYearly = false,
    this.paymentId,
    this.razorpayOrderId,
    this.razorpaySubscriptionId,
    this.amountPaid = 0,
    required this.createdAt,
    this.cancelledAt,
    this.cancellationReason,
  });

  /// Check if subscription is currently valid
  bool get isValid => isActive && DateTime.now().isBefore(endDate);

  /// Days remaining in subscription
  int get daysRemaining => endDate.difference(DateTime.now()).inDays;

  /// Get the plan details
  SubscriptionPlan get plan => SubscriptionPlans.getPlan(tier);

  Map<String, dynamic> toJson() {
    return {
      'subscriptionId': subscriptionId,
      'userId': userId,
      'tier': tier.name,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'isActive': isActive,
      'isYearly': isYearly,
      'paymentId': paymentId,
      'razorpayOrderId': razorpayOrderId,
      'razorpaySubscriptionId': razorpaySubscriptionId,
      'amountPaid': amountPaid,
      'createdAt': Timestamp.fromDate(createdAt),
      'cancelledAt': cancelledAt != null ? Timestamp.fromDate(cancelledAt!) : null,
      'cancellationReason': cancellationReason,
    };
  }

  factory UserSubscription.fromJson(Map<String, dynamic> json) {
    return UserSubscription(
      subscriptionId: json['subscriptionId'] ?? '',
      userId: json['userId'] ?? '',
      tier: SubscriptionTier.values.firstWhere(
        (t) => t.name == json['tier'],
        orElse: () => SubscriptionTier.free,
      ),
      startDate: (json['startDate'] as Timestamp).toDate(),
      endDate: (json['endDate'] as Timestamp).toDate(),
      isActive: json['isActive'] ?? false,
      isYearly: json['isYearly'] ?? false,
      paymentId: json['paymentId'],
      razorpayOrderId: json['razorpayOrderId'],
      razorpaySubscriptionId: json['razorpaySubscriptionId'],
      amountPaid: json['amountPaid'] ?? 0,
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      cancelledAt: json['cancelledAt'] != null
          ? (json['cancelledAt'] as Timestamp).toDate()
          : null,
      cancellationReason: json['cancellationReason'],
    );
  }

  UserSubscription copyWith({
    String? subscriptionId,
    String? userId,
    SubscriptionTier? tier,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    bool? isYearly,
    String? paymentId,
    String? razorpayOrderId,
    String? razorpaySubscriptionId,
    int? amountPaid,
    DateTime? createdAt,
    DateTime? cancelledAt,
    String? cancellationReason,
  }) {
    return UserSubscription(
      subscriptionId: subscriptionId ?? this.subscriptionId,
      userId: userId ?? this.userId,
      tier: tier ?? this.tier,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      isYearly: isYearly ?? this.isYearly,
      paymentId: paymentId ?? this.paymentId,
      razorpayOrderId: razorpayOrderId ?? this.razorpayOrderId,
      razorpaySubscriptionId: razorpaySubscriptionId ?? this.razorpaySubscriptionId,
      amountPaid: amountPaid ?? this.amountPaid,
      createdAt: createdAt ?? this.createdAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      cancellationReason: cancellationReason ?? this.cancellationReason,
    );
  }
}

/// Provider approval status
enum ProviderStatus {
  pendingApproval, // Just registered, waiting for admin approval
  approved, // Admin approved, can select plan
  rejected, // Admin rejected
  active, // Approved + paid, can post jobs
  suspended, // Account suspended
}

extension ProviderStatusExtension on ProviderStatus {
  String get displayName {
    switch (this) {
      case ProviderStatus.pendingApproval:
        return 'Pending Approval';
      case ProviderStatus.approved:
        return 'Approved';
      case ProviderStatus.rejected:
        return 'Rejected';
      case ProviderStatus.active:
        return 'Active';
      case ProviderStatus.suspended:
        return 'Suspended';
    }
  }

  bool get canPostJobs => this == ProviderStatus.active;
  bool get canSelectPlan => this == ProviderStatus.approved || this == ProviderStatus.active;
}
