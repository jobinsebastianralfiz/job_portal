import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../models/subscription_model.dart';

class SubscriptionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Razorpay? _razorpay;

  // TODO: Replace with your Razorpay API keys
  static const String _razorpayKeyId = 'rzp_test_your_key_here';
  static const String _razorpayKeySecret = 'your_secret_here';

  // Callbacks
  Function(PaymentSuccessResponse)? onPaymentSuccess;
  Function(PaymentFailureResponse)? onPaymentError;
  Function(ExternalWalletResponse)? onExternalWallet;

  void initRazorpay({
    required Function(PaymentSuccessResponse) onSuccess,
    required Function(PaymentFailureResponse) onError,
    Function(ExternalWalletResponse)? onWallet,
  }) {
    _razorpay = Razorpay();
    onPaymentSuccess = onSuccess;
    onPaymentError = onError;
    onExternalWallet = onWallet;

    _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    debugPrint('Payment Success: ${response.paymentId}');
    onPaymentSuccess?.call(response);
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    debugPrint('Payment Error: ${response.code} - ${response.message}');
    onPaymentError?.call(response);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    debugPrint('External Wallet: ${response.walletName}');
    onExternalWallet?.call(response);
  }

  void dispose() {
    _razorpay?.clear();
  }

  /// Start payment for a subscription plan
  void startPayment({
    required String userId,
    required String userEmail,
    required String userName,
    required String userPhone,
    required SubscriptionPlan plan,
    required bool isYearly,
  }) {
    final amount = isYearly ? plan.priceYearly : plan.priceMonthly;
    final description = '${plan.name} Plan - ${isYearly ? 'Yearly' : 'Monthly'} Subscription';

    var options = {
      'key': _razorpayKeyId,
      'amount': amount, // Amount in paise
      'name': 'Job Portal',
      'description': description,
      'prefill': {
        'contact': userPhone,
        'email': userEmail,
        'name': userName,
      },
      'notes': {
        'userId': userId,
        'plan': plan.tier.name,
        'isYearly': isYearly.toString(),
      },
      'theme': {
        'color': '#6366F1', // Primary color
      },
    };

    try {
      _razorpay?.open(options);
    } catch (e) {
      debugPrint('Error opening Razorpay: $e');
    }
  }

  /// Create subscription after successful payment
  Future<UserSubscription?> createSubscription({
    required String userId,
    required SubscriptionTier tier,
    required bool isYearly,
    required String paymentId,
    String? orderId,
    required int amountPaid,
  }) async {
    try {
      final now = DateTime.now();
      final endDate = isYearly
          ? now.add(const Duration(days: 365))
          : now.add(const Duration(days: 30));

      final subscription = UserSubscription(
        userId: userId,
        tier: tier,
        startDate: now,
        endDate: endDate,
        isActive: true,
        isYearly: isYearly,
        paymentId: paymentId,
        razorpayOrderId: orderId,
        amountPaid: amountPaid,
        createdAt: now,
      );

      final docRef = await _firestore
          .collection('subscriptions')
          .add(subscription.toJson());

      // Update user's subscription info
      await _firestore.collection('users').doc(userId).update({
        'subscriptionTier': tier.name,
        'subscriptionId': docRef.id,
        'subscriptionExpiresAt': Timestamp.fromDate(endDate),
        'providerStatus': 'active',
        'updatedAt': Timestamp.now(),
      });

      return subscription.copyWith(subscriptionId: docRef.id);
    } catch (e) {
      debugPrint('Error creating subscription: $e');
      return null;
    }
  }

  /// Get user's current subscription
  Future<UserSubscription?> getCurrentSubscription(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('subscriptions')
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      final doc = snapshot.docs.first;
      return UserSubscription.fromJson({
        ...doc.data(),
        'subscriptionId': doc.id,
      });
    } catch (e) {
      debugPrint('Error getting subscription: $e');
      return null;
    }
  }

  /// Get subscription history for a user
  Future<List<UserSubscription>> getSubscriptionHistory(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('subscriptions')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => UserSubscription.fromJson({
                ...doc.data(),
                'subscriptionId': doc.id,
              }))
          .toList();
    } catch (e) {
      debugPrint('Error getting subscription history: $e');
      return [];
    }
  }

  /// Cancel a subscription
  Future<bool> cancelSubscription(String subscriptionId, String reason) async {
    try {
      await _firestore.collection('subscriptions').doc(subscriptionId).update({
        'isActive': false,
        'cancelledAt': Timestamp.now(),
        'cancellationReason': reason,
      });

      // Get subscription to find user
      final doc = await _firestore.collection('subscriptions').doc(subscriptionId).get();
      if (doc.exists) {
        final userId = doc.data()?['userId'];
        if (userId != null) {
          // Downgrade user to free tier
          await _firestore.collection('users').doc(userId).update({
            'subscriptionTier': 'free',
            'updatedAt': Timestamp.now(),
          });
        }
      }

      return true;
    } catch (e) {
      debugPrint('Error cancelling subscription: $e');
      return false;
    }
  }

  /// Check if user can post jobs based on subscription
  Future<Map<String, dynamic>> checkJobPostingEligibility(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        return {'canPost': false, 'reason': 'User not found'};
      }

      final userData = userDoc.data()!;
      final providerStatus = userData['providerStatus'] ?? 'pending_approval';

      // Check if approved and active
      if (providerStatus != 'active') {
        return {
          'canPost': false,
          'reason': providerStatus == 'pending_approval'
              ? 'Your account is pending approval'
              : providerStatus == 'approved'
                  ? 'Please select a subscription plan'
                  : 'Your account is not active',
        };
      }

      // Get subscription
      final subscription = await getCurrentSubscription(userId);
      if (subscription == null || !subscription.isValid) {
        return {'canPost': false, 'reason': 'No active subscription'};
      }

      // Check job posting limit
      final plan = subscription.plan;
      if (plan.jobPostsPerMonth == -1) {
        return {'canPost': true, 'remaining': -1}; // Unlimited
      }

      // Count jobs posted this month
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final jobsThisMonth = await _firestore
          .collection('jobs')
          .where('providerId', isEqualTo: userId)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .count()
          .get();

      final jobCount = jobsThisMonth.count ?? 0;
      final remaining = plan.jobPostsPerMonth - jobCount;

      if (remaining <= 0) {
        return {
          'canPost': false,
          'reason': 'You have reached your monthly job posting limit (${plan.jobPostsPerMonth} jobs)',
          'remaining': 0,
        };
      }

      return {'canPost': true, 'remaining': remaining};
    } catch (e) {
      debugPrint('Error checking eligibility: $e');
      return {'canPost': false, 'reason': 'Error checking eligibility'};
    }
  }

  /// Check if user has AI features access
  Future<bool> hasAIAccess(String userId) async {
    try {
      final subscription = await getCurrentSubscription(userId);
      if (subscription == null || !subscription.isValid) return false;
      return subscription.plan.hasAIFeatures;
    } catch (e) {
      return false;
    }
  }

  /// Update provider status
  Future<bool> updateProviderStatus(String userId, ProviderStatus status, {String? reason}) async {
    try {
      final updateData = <String, dynamic>{
        'providerStatus': status.name,
        'updatedAt': Timestamp.now(),
      };

      if (status == ProviderStatus.rejected && reason != null) {
        updateData['rejectionReason'] = reason;
        updateData['rejectedAt'] = Timestamp.now();
      }

      if (status == ProviderStatus.approved) {
        updateData['approvedAt'] = Timestamp.now();
      }

      await _firestore.collection('users').doc(userId).update(updateData);
      return true;
    } catch (e) {
      debugPrint('Error updating provider status: $e');
      return false;
    }
  }

  /// Get pending provider approvals
  Future<List<Map<String, dynamic>>> getPendingProviders() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'job_provider')
          .where('providerStatus', isEqualTo: 'pending_approval')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => {...doc.data(), 'userId': doc.id}).toList();
    } catch (e) {
      debugPrint('Error getting pending providers: $e');
      return [];
    }
  }
}
