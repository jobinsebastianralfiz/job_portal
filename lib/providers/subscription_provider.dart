import 'package:flutter/material.dart';
import '../models/subscription_model.dart';
import '../services/payment/subscription_service.dart';

class SubscriptionProvider extends ChangeNotifier {
  final SubscriptionService _service = SubscriptionService();

  // State
  bool _isLoading = false;
  bool _isPaymentInProgress = false;
  String? _error;
  UserSubscription? _currentSubscription;
  Map<String, dynamic>? _jobPostingEligibility;

  // Payment state
  SubscriptionPlan? _selectedPlan;
  bool _isYearlyBilling = false;
  String? _pendingUserId;

  // Getters
  bool get isLoading => _isLoading;
  bool get isPaymentInProgress => _isPaymentInProgress;
  String? get error => _error;
  UserSubscription? get currentSubscription => _currentSubscription;
  Map<String, dynamic>? get jobPostingEligibility => _jobPostingEligibility;
  SubscriptionPlan? get selectedPlan => _selectedPlan;
  bool get isYearlyBilling => _isYearlyBilling;

  // Derived getters
  bool get hasActiveSubscription => _currentSubscription?.isValid ?? false;
  SubscriptionTier get currentTier => _currentSubscription?.tier ?? SubscriptionTier.free;
  SubscriptionPlan get currentPlan => SubscriptionPlans.getPlan(currentTier);
  bool get canPostJobs => _jobPostingEligibility?['canPost'] ?? false;
  int get remainingJobPosts => _jobPostingEligibility?['remaining'] ?? 0;
  bool get hasAIAccess => currentPlan.hasAIFeatures && hasActiveSubscription;

  /// Initialize Razorpay for payments
  void initializePayment({
    required Function() onSuccess,
    required Function(String error) onError,
  }) {
    _service.initializeRazorpay(
      onSuccess: (paymentId, orderId) async {
        debugPrint('Payment successful, creating subscription...');
        await _completeSubscription(paymentId, orderId);
        onSuccess();
      },
      onFailure: (errorMessage) {
        debugPrint('Payment failed: $errorMessage');
        _isPaymentInProgress = false;
        _error = errorMessage;
        notifyListeners();
        onError(errorMessage);
      },
    );
  }

  /// Dispose payment resources
  void disposePayment() {
    _service.dispose();
  }

  /// Load current subscription
  Future<void> loadCurrentSubscription(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentSubscription = await _service.getCurrentSubscription(userId);
      await checkJobPostingEligibility(userId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Check job posting eligibility
  Future<void> checkJobPostingEligibility(String userId) async {
    try {
      _jobPostingEligibility = await _service.checkJobPostingEligibility(userId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
    }
  }

  /// Set billing cycle
  void setBillingCycle(bool isYearly) {
    _isYearlyBilling = isYearly;
    notifyListeners();
  }

  /// Start subscription purchase
  void startPurchase({
    required String userId,
    required String userEmail,
    required String userName,
    required String userPhone,
    required SubscriptionPlan plan,
  }) {
    _selectedPlan = plan;
    _pendingUserId = userId;
    _isPaymentInProgress = true;
    _error = null;
    notifyListeners();

    final amount = _isYearlyBilling ? plan.priceYearly : plan.priceMonthly;
    final description = '${plan.name} - ${_isYearlyBilling ? 'Yearly' : 'Monthly'}';

    _service.openCheckout(
      amountInPaise: amount,
      description: description,
      userName: userName,
      userEmail: userEmail,
      userPhone: userPhone,
    );
  }

  /// Complete subscription after successful payment
  Future<void> _completeSubscription(String paymentId, String? orderId) async {
    if (_selectedPlan == null || _pendingUserId == null) {
      _isPaymentInProgress = false;
      _error = 'Invalid subscription data';
      notifyListeners();
      return;
    }

    try {
      final amount = _isYearlyBilling
          ? _selectedPlan!.priceYearly
          : _selectedPlan!.priceMonthly;

      final subscription = await _service.createSubscription(
        userId: _pendingUserId!,
        tier: _selectedPlan!.tier,
        isYearly: _isYearlyBilling,
        paymentId: paymentId,
        orderId: orderId,
        amountPaid: amount,
      );

      if (subscription != null) {
        _currentSubscription = subscription;
        await checkJobPostingEligibility(_pendingUserId!);
      } else {
        _error = 'Failed to activate subscription';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isPaymentInProgress = false;
      _selectedPlan = null;
      _pendingUserId = null;
      notifyListeners();
    }
  }

  /// Activate free plan (no payment needed)
  Future<bool> activateFreePlan(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final subscription = await _service.createSubscription(
        userId: userId,
        tier: SubscriptionTier.free,
        isYearly: false,
        paymentId: 'free_${DateTime.now().millisecondsSinceEpoch}',
        amountPaid: 0,
      );

      if (subscription != null) {
        _currentSubscription = subscription;
        await checkJobPostingEligibility(userId);
        return true;
      }
      _error = 'Failed to activate free plan';
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Cancel subscription
  Future<bool> cancelSubscription(String reason) async {
    if (_currentSubscription == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      final success = await _service.cancelSubscription(
        _currentSubscription!.subscriptionId,
        reason,
      );

      if (success) {
        _currentSubscription = _currentSubscription!.copyWith(
          isActive: false,
          cancelledAt: DateTime.now(),
          cancellationReason: reason,
        );
      }

      return success;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Reset payment state (useful when user cancels or navigates away)
  void resetPaymentState() {
    _isPaymentInProgress = false;
    _selectedPlan = null;
    _pendingUserId = null;
    notifyListeners();
  }
}
