import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../models/subscription_model.dart';

class SubscriptionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Razorpay? _razorpay;
  bool _isInitialized = false;

  // Razorpay Test Key
  static const String _razorpayKey = 'rzp_test_SHXkRbcNWvrk0G';

  // Callbacks stored for payment handling
  Function(String paymentId, String? orderId)? _onPaymentSuccess;
  Function(String errorMessage)? _onPaymentFailure;

  /// Initialize Razorpay - must be called before starting payment
  void initializeRazorpay({
    required Function(String paymentId, String? orderId) onSuccess,
    required Function(String errorMessage) onFailure,
  }) {
    _onPaymentSuccess = onSuccess;
    _onPaymentFailure = onFailure;

    _razorpay = Razorpay();

    _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    _isInitialized = true;
    debugPrint('Razorpay initialized successfully');
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    debugPrint('Payment Success - ID: ${response.paymentId}');
    _onPaymentSuccess?.call(
      response.paymentId ?? '',
      response.orderId,
    );
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    debugPrint('Payment Failed - Code: ${response.code}, Message: ${response.message}');
    String errorMsg = response.message ?? 'Payment failed';
    if (response.code == 2) {
      errorMsg = 'Payment cancelled by user';
    }
    _onPaymentFailure?.call(errorMsg);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    debugPrint('External Wallet Selected: ${response.walletName}');
  }

  /// Open Razorpay checkout
  void openCheckout({
    required int amountInPaise,
    required String description,
    required String userName,
    required String userEmail,
    required String userPhone,
  }) {
    if (!_isInitialized || _razorpay == null) {
      debugPrint('ERROR: Razorpay not initialized');
      _onPaymentFailure?.call('Payment system not ready. Please try again.');
      return;
    }

    // Ensure phone has country code
    String phone = userPhone;
    if (phone.isNotEmpty && !phone.startsWith('+')) {
      phone = '+91$phone';
    }

    final options = {
      'key': _razorpayKey,
      'amount': amountInPaise,
      'name': 'Job Portal',
      'description': description,
      'prefill': {
        'name': userName,
        'email': userEmail,
        'contact': phone,
      },
      'theme': {
        'color': '#6366F1',
      },
    };

    debugPrint('Opening Razorpay with amount: $amountInPaise paise');

    try {
      _razorpay!.open(options);
    } catch (e) {
      debugPrint('Error opening Razorpay: $e');
      _onPaymentFailure?.call('Could not open payment gateway');
    }
  }

  /// Dispose Razorpay instance
  void dispose() {
    _razorpay?.clear();
    _razorpay = null;
    _isInitialized = false;
    _onPaymentSuccess = null;
    _onPaymentFailure = null;
  }

  // ============ Firestore Operations ============

  /// Create subscription record after successful payment
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

      final doc = await _firestore.collection('subscriptions').doc(subscriptionId).get();
      if (doc.exists) {
        final userId = doc.data()?['userId'];
        if (userId != null) {
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

  /// Update provider status (for admin approval flow)
  Future<bool> updateProviderStatus(String userId, ProviderStatus status, {String? reason}) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'providerStatus': status.name,
        'statusReason': reason,
        'updatedAt': Timestamp.now(),
      });
      return true;
    } catch (e) {
      debugPrint('Error updating provider status: $e');
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

      final subscription = await getCurrentSubscription(userId);
      if (subscription == null || !subscription.isValid) {
        return {'canPost': false, 'reason': 'No active subscription'};
      }

      final plan = subscription.plan;
      if (plan.jobPostsPerMonth == -1) {
        return {'canPost': true, 'remaining': -1};
      }

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
          'reason': 'Monthly job posting limit reached',
          'remaining': 0,
        };
      }

      return {'canPost': true, 'remaining': remaining};
    } catch (e) {
      debugPrint('Error checking eligibility: $e');
      return {'canPost': false, 'reason': 'Error checking eligibility'};
    }
  }
}
